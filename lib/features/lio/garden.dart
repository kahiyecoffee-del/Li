import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../core/widgets/mascot.dart';
import '../../domain/lio/lio_garden.dart';
import '../../services/ads/ads_service.dart';
import '../focus/focus_screen.dart';
import '../premium/rewarded.dart';

/// Small things done today: finished tasks, habits logged, mood, focus.
final lioEnergyProvider = Provider<int>((ref) {
  final today = ref.watch(todayProvider);
  final key = Dates.dayKey(today);
  var e = ref
      .watch(tasksProvider)
      .list
      .where((t) => !t.deleted && t.completedAt != null && Dates.sameDay(t.completedAt!, today))
      .length;
  e += ref.watch(habitLogsProvider).list.where((h) => h.day == key && h.count > 0).length;
  if (ref.watch(moodsProvider).list.any((m) => !m.deleted && m.day == key)) e++;
  e += ref.watch(focusLogProvider).$1;
  return e;
});

class GardenController extends Notifier<GardenState> {
  static const _trip = 'garden_trip', _opened = 'garden_opened', _cards = 'garden_cards';

  @override
  GardenState build() {
    final prefs = ref.watch(servicesProvider).prefs;
    final energy = ref.watch(lioEnergyProvider);
    final now = currentNow(ref);
    final today = Dates.dayKey(now);
    var trip = prefs.getInt(_trip) == null ? null : DateTime.fromMillisecondsSinceEpoch(prefs.getInt(_trip)!);
    // Enough energy: Lio sets off (once a day).
    if (energy >= LioGarden.goal && (trip == null || !Dates.sameDay(trip, now))) {
      trip = now;
      unawaited(prefs.setInt(_trip, now.millisecondsSinceEpoch));
    }
    return LioGarden.state(energy: energy, now: now, tripStart: trip, openedToday: prefs.getString(_opened) == today);
  }

  /// When Lio comes back today, if he is out (for the reminder).
  DateTime? get backAt => state.phase == GardenPhase.exploring ? state.backAt : null;

  Set<String> get collection => {...?ref.read(servicesProvider).prefs.getStringList(_cards)};

  /// Opens today's postcard ([extra] for the bonus one) and keeps it.
  Future<Postcard> open({bool extra = false}) async {
    final prefs = ref.read(servicesProvider).prefs;
    final now = currentNow(ref);
    final card = LioGarden.pick(now, collection, salt: extra ? 1 : 0);
    await prefs.setStringList(_cards, {...collection, card.id}.toList());
    await prefs.setString(_opened, Dates.dayKey(now));
    ref.invalidateSelf();
    return card;
  }
}

final gardenProvider = NotifierProvider<GardenController, GardenState>(GardenController.new);

/// Home: Lio's energy for the day, his trip and the postcard he brings back.
class GardenCard extends ConsumerStatefulWidget {
  const GardenCard({super.key});

  @override
  ConsumerState<GardenCard> createState() => _GardenCardState();
}

class _GardenCardState extends ConsumerState<GardenCard> {
  // Lio comes back on his own: check the clock now and then.
  late final Timer _clock = Timer.periodic(const Duration(minutes: 1), (_) {
    if (mounted) ref.invalidate(gardenProvider);
  });

  @override
  void initState() {
    super.initState();
    _clock;
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final g = ref.watch(gardenProvider);
    final fmt = ref.fmt(context);
    final gold = Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold;
    final (mood, line) = switch (g.phase) {
      GardenPhase.charging => (MascotMood.curious, l.gardenCharging(LioGarden.goal - g.energy)),
      GardenPhase.exploring => (MascotMood.happy, l.gardenExploring(fmt.time(g.backAt!))),
      GardenPhase.giftWaiting => (MascotMood.excited, l.gardenGift),
      GardenPhase.opened => (MascotMood.loving, l.gardenOpened),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: AppCard(
        key: const Key('garden-card'),
        onTap: g.phase == GardenPhase.giftWaiting ? () => openGift(context, ref) : null,
        child: Row(
          children: [
            Mascot(mood: mood, size: 56, float: g.phase == GardenPhase.giftWaiting),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(l.gardenTitle),
                  const SizedBox(height: 2),
                  Text(line, style: context.text.titleMedium),
                  if (g.phase == GardenPhase.charging) ...[
                    const SizedBox(height: Space.sm),
                    Row(
                      children: [
                        for (var i = 0; i < LioGarden.goal; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              i < g.energy ? Icons.bolt_rounded : Icons.bolt_outlined,
                              size: 22,
                              color: i < g.energy ? gold : context.semantic.border,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(l.gardenChargingHint, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
                  ],
                  if (g.phase == GardenPhase.giftWaiting) ...[
                    const SizedBox(height: Space.sm),
                    FilledButton.icon(
                      key: const Key('garden-open'),
                      onPressed: () => openGift(context, ref),
                      icon: const Icon(Icons.mail_outline_rounded, size: 18),
                      label: Text(l.gardenOpen),
                    ),
                  ],
                  if (g.phase == GardenPhase.opened)
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: () => context.push('/postcards'),
                      child: Text(l.gardenCollection),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> openGift(BuildContext context, WidgetRef ref) async {
  unawaited(HapticFeedback.mediumImpact());
  final card = await ref.read(gardenProvider.notifier).open();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _PostcardSheet(first: card),
  );
}

class _PostcardSheet extends ConsumerStatefulWidget {
  const _PostcardSheet({required this.first});
  final Postcard first;

  @override
  ConsumerState<_PostcardSheet> createState() => _PostcardSheetState();
}

class _PostcardSheetState extends ConsumerState<_PostcardSheet> {
  late Postcard _card = widget.first;
  bool _extraTaken = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tr = Localizations.localeOf(context).languageCode == 'tr';
    final have = ref.read(gardenProvider.notifier).collection.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PostcardView(card: _card, tr: tr),
            const SizedBox(height: Space.md),
            Text(
              l.gardenCollected(have, postcards.length),
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
            ),
            const SizedBox(height: Space.md),
            if (!_extraTaken && !ref.watch(isPremiumProvider))
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await watchRewardedAd(context, ref, RewardPlacement.extraInsights);
                  if (!ok || !mounted) return;
                  final more = await ref.read(gardenProvider.notifier).open(extra: true);
                  setState(() {
                    _card = more;
                    _extraTaken = true;
                  });
                },
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: Text(l.gardenAnother),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/postcards');
              },
              child: Text(l.gardenCollection),
            ),
          ],
        ),
      ),
    );
  }
}

/// A postcard: the place, a stamp and one fact.
class PostcardView extends StatelessWidget {
  const PostcardView({super.key, required this.card, required this.tr, this.compact = false});
  final Postcard card;
  final bool tr;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final gold = Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold;
    return Container(
      key: ValueKey('postcard-${card.id}'),
      padding: EdgeInsets.all(compact ? Space.md : Space.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: gold.withValues(alpha: 0.6), width: 1.2),
        boxShadow: Shadows.soft(Theme.of(context).brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!compact) Eyebrow(l.gardenFrom(card.place(tr))),
                    Text(card.place(tr), style: compact ? context.text.titleMedium : context.text.headlineSmall),
                  ],
                ),
              ),
              Container(
                width: compact ? 30 : 44,
                height: compact ? 36 : 52,
                decoration: BoxDecoration(
                  border: Border.all(color: gold, width: 1.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.landscape_rounded, color: gold, size: compact ? 18 : 26),
              ),
            ],
          ),
          SizedBox(height: compact ? Space.xs : Space.md),
          Text(
            card.fact(tr),
            maxLines: compact ? 3 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: (compact ? context.text.bodySmall : context.text.bodyLarge)?.copyWith(
              color: compact ? context.semantic.muted : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Every postcard: collected ones in full, the rest as "not found yet".
class PostcardsScreen extends ConsumerWidget {
  const PostcardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tr = Localizations.localeOf(context).languageCode == 'tr';
    ref.watch(gardenProvider);
    final have = ref.read(gardenProvider.notifier).collection;
    return Scaffold(
      appBar: AppBar(title: Text(l.gardenCollection)),
      body: PageList(
        animate: false,
        children: [
          Text(
            l.gardenCollected(have.length, postcards.length),
            style: context.text.bodyMedium?.copyWith(color: context.semantic.muted),
          ),
          const SizedBox(height: Space.md),
          for (final p in postcards)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: have.contains(p.id)
                  ? PostcardView(card: p, tr: tr, compact: true)
                  : AppCard(
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, color: context.semantic.muted, size: 20),
                          const SizedBox(width: Space.md),
                          Text(l.gardenLocked, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
                        ],
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
