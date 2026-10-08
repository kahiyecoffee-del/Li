import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../core/widgets/mascot.dart';
import '../../domain/plan/day_timeline.dart';
import '../../domain/plan/week_review.dart';
import '../goals/goals_screen.dart';
import '../life/mood_sheet.dart';

/// Sunday ritual: what the week looked like, then three focuses for the
/// next one, each placed on a day.
class WeeklyReviewScreen extends ConsumerStatefulWidget {
  const WeeklyReviewScreen({super.key});

  @override
  ConsumerState<WeeklyReviewScreen> createState() => _WeeklyReviewScreenState();
}

class _WeeklyReviewScreenState extends ConsumerState<WeeklyReviewScreen> {
  final _focus = [TextEditingController(), TextEditingController(), TextEditingController()];
  final _days = <int>[0, 1, 2];
  final _cardKey = GlobalKey();

  /// The week card as a picture, through the share sheet (Instagram, WhatsApp…).
  Future<void> _share() async {
    final l = context.l10n;
    final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null || !mounted) return;
    await ref
        .read(servicesProvider)
        .share
        .shareImage(bytes.buffer.asUint8List(), name: 'dayly-week.png', text: l.reviewShareText);
  }

  @override
  void dispose() {
    for (final c in _focus) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final loc = Localizations.localeOf(context).toString();
    final today = ref.watch(todayProvider);
    final w = summarizeWeek(
      today: today,
      tasks: ref.watch(tasksProvider).list,
      habits: ref.watch(habitsProvider).list,
      habitLogs: ref.watch(habitLogsProvider).list,
      transactions: ref.watch(transactionsProvider).list,
      moods: ref.watch(moodsProvider).list,
      journalDates: [for (final e in ref.watch(journalProvider).list) e.createdAt],
    );
    final goals = ref.watch(lifeGoalsProvider).list.where((g) => !g.deleted && !g.archived).toList();
    final doneIds = {
      for (final t in ref.watch(tasksProvider).list)
        if (t.isCompleted) t.id,
    };
    // Next week starts tomorrow; focuses go on its first days by default.
    final nextDays = [for (var i = 1; i <= 7; i++) Dates.addDays(today, i)];
    final change = w.previousSpentMinor == 0
        ? null
        : ((w.spentMinor - w.previousSpentMinor) * 100 / w.previousSpentMinor).round();

    Widget stat(IconData icon, String text, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? context.colors.primary),
          const SizedBox(width: Space.md),
          Expanded(child: Text(text, style: context.text.bodyLarge)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.reviewTitle)),
      body: PageList(
        children: [
          Eyebrow('${DateFormat.MMMd(loc).format(w.start)} – ${DateFormat.MMMd(loc).format(w.end)}'),
          const SizedBox(height: Space.xs),
          Text(l.reviewIntro, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
          const SizedBox(height: Space.lg),
          RepaintBoundary(
            key: _cardKey,
            child: _WeekCard(
              range: '${DateFormat.MMMd(loc).format(w.start)} – ${DateFormat.MMMd(loc).format(w.end)}',
              done: w.tasksDone,
              habits: w.habitRate == null ? null : (w.habitRate! * 100).round(),
              streak: ref.watch(streakProvider).current,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('review-share'),
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: Text(l.reviewShare),
            ),
          ),
          const SizedBox(height: Space.sm),
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    ProgressRing(
                      value: w.tasksTotal == 0 ? 0 : w.tasksDone / w.tasksTotal,
                      size: 64,
                      child: Text('${w.tasksDone}', style: context.text.titleLarge),
                    ),
                    const SizedBox(width: Space.lg),
                    Expanded(child: Text(l.reviewTasks(w.tasksDone, w.tasksTotal), style: context.text.titleMedium)),
                  ],
                ),
                const Divider(height: Space.xl),
                if (w.habitRate != null) stat(Icons.repeat_rounded, l.reviewHabits((w.habitRate! * 100).round())),
                stat(
                  Icons.account_balance_wallet_outlined,
                  [
                    l.reviewSpent(fmt.money(w.spentMinor)),
                    if (change != null && change != 0)
                      change > 0 ? l.reviewMoreThanLast(change) : l.reviewLessThanLast(-change),
                  ].join(' · '),
                ),
                if (w.moodAverage != null)
                  stat(
                    Icons.favorite_outline_rounded,
                    '${l.reviewMood}: ${moodEmojis[w.moodAverage!.round().clamp(1, 5)]}',
                  ),
                if (w.journalCount > 0) stat(Icons.menu_book_outlined, l.reviewJournal(w.journalCount)),
              ],
            ),
          ),
          SectionTitle(l.reviewWins),
          if (w.wins.isEmpty)
            Text(l.reviewNoWins, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted))
          else
            for (final win in w.wins)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 18, color: context.semantic.positive),
                    const SizedBox(width: Space.sm),
                    Expanded(child: Text(win, style: context.text.bodyLarge)),
                  ],
                ),
              ),
          if (goals.isNotEmpty) ...[
            SectionTitle(l.goalsLife),
            for (final g in goals.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: GoalCard(goal: g, doneTaskIds: doneIds),
              ),
          ],
          SectionTitle(l.reviewFocus),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(Space.lg, Space.xs, Space.sm, Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: Key('focus-$i'),
                      controller: _focus[i],
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l.reviewFocusHint,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        prefixIcon: Padding(
                          padding: const EdgeInsetsDirectional.only(end: Space.sm),
                          child: Text(
                            '${i + 1}',
                            style: context.text.headlineSmall?.copyWith(color: context.colors.primary),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 28),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final (j, d) in nextDays.indexed)
                            Padding(
                              padding: const EdgeInsets.only(right: Space.xs),
                              child: ChoiceChip(
                                label: Text(DateFormat.E(loc).format(d)),
                                selected: _days[i] == j,
                                showCheckmark: false,
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) => setState(() => _days[i] = j),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          FilledButton.icon(
            onPressed: () async {
              var n = 0;
              final actions = ref.read(actionsProvider);
              for (var i = 0; i < 3; i++) {
                final q = parseQuickTask(_focus[i].text);
                if (q.title.isEmpty) continue;
                await actions.addQuickTask(q, nextDays[_days[i]]);
                n++;
              }
              if (n == 0 || !context.mounted) return;
              unawaited(HapticFeedback.mediumImpact());
              for (final c in _focus) {
                c.clear();
              }
              showSnack(context, l.reviewPlanned(n));
            },
            icon: const Icon(Icons.event_available_rounded),
            label: Text(l.reviewPlanWeek),
          ),
        ],
      ),
    );
  }
}

/// The shareable summary: three numbers, Lio and the week's dates.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.range, required this.done, required this.habits, required this.streak});
  final String range;
  final int done;
  final int? habits;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget stat(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: context.text.headlineMedium?.copyWith(color: Colors.white)),
          Text(label, style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A6B52), Color(0xFF2F4A37)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.reviewShareText, style: context.text.titleLarge?.copyWith(color: Colors.white)),
                    Text(range, style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              const Mascot(mood: MascotMood.excited, size: 56, float: false),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              stat('$done', l.reviewCardTasks),
              if (habits != null) stat(l.percentValue(habits!), l.reviewCardHabits),
              stat('$streak', l.reviewCardStreak),
            ],
          ),
          const SizedBox(height: Space.md),
          Text('dayly', style: context.text.labelLarge?.copyWith(color: const Color(0xFFD9BC82), letterSpacing: 2)),
        ],
      ),
    );
  }
}
