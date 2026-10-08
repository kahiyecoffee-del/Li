import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../lio/advice_view.dart';
import '../premium/banner_slot.dart';
import '../lio/garden.dart';
import 'home_today.dart';
import 'problem_flow.dart';

/// Home: Lio greets you with what he noticed in your data, then three big
/// actions — Solve, Plan, Journal — his suggestions, and quick tools.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final name = ref.watch(profileProvider.select((p) => p.value?.name ?? ''));
    final advice = ref.watch(adviceProvider);
    final recent = [...?ref.watch(savedProvider).value]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = advice.isEmpty ? null : describeAdvice(advice.first, l, ref.fmt(context));
    String nonce() => '${DateTime.now().microsecondsSinceEpoch}';

    return Scaffold(
      body: AmbientBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, 120),
            children: staggered([
              FadeSlideIn(
                child: HeroBanner(
                  gradient: dark ? Gradients.meadowDark : Gradients.meadow,
                  padding: const EdgeInsets.all(Space.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? l.homeHelloNoName : l.homeHello(name),
                        style: context.text.titleMedium?.copyWith(color: context.semantic.muted),
                      ),
                      const SizedBox(height: Space.xs),
                      Semantics(header: true, child: Text(l.homeQuestion, style: context.text.headlineMedium)),
                      const SizedBox(height: Space.md),
                      // Lio speaks: the most useful thing he noticed today.
                      // He walks along the bottom of the screen too.
                      _SpeechBubble(
                        text: top?.text ?? l.lioAllGood,
                        action: top?.action,
                        onAction: top == null ? null : () => top.go(context),
                      ),
                      const SizedBox(height: Space.lg),
                      Row(
                        children: [
                          Expanded(
                            child: _HeroAction(
                              icon: Icons.auto_awesome_rounded,
                              label: l.solve,
                              primary: true,
                              onTap: () => context.push('/ai'),
                            ),
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: _HeroAction(
                              icon: Icons.event_available_rounded,
                              label: l.quickPlan,
                              onTap: () => context.push('/ai?topic=plan&n=${nonce()}'),
                            ),
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: _HeroAction(
                              icon: Icons.menu_book_rounded,
                              label: l.quickJournal,
                              onTap: () => context.push('/journal/new'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.lg),
              const StreakSaverCard(),
              const QuickCaptureCard(),
              const SizedBox(height: Space.md),
              const TodayFlowCard(),
              const SizedBox(height: Space.md),
              const GardenCard(),
              // Sundays: invite the weekly review.
              if (DateTime.now().weekday == DateTime.sunday) ...[
                const SizedBox(height: Space.md),
                AppCard(
                  onTap: () => context.push('/review'),
                  child: Row(
                    children: [
                      const IconBubble(icon: Icons.event_repeat_rounded, accent: Accent.insight),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.reviewTitle, style: context.text.titleMedium),
                            Text(l.reviewIntro, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ],
              if (advice.length > 1) ...[
                const SizedBox(height: Space.xl),
                SectionTitle(
                  l.lioSuggestions,
                  trailing: advice.length > 4
                      ? TextButton(onPressed: () => context.push('/insights'), child: Text(l.seeAll))
                      : null,
                ),
                for (final a in advice.skip(1).take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: FadeSlideIn(child: AdviceCard(a)),
                  ),
              ],
              const SizedBox(height: Space.xl),
              const _QuickTools(),
              // Light banner (hidden for Premium; Remote Config can switch it off).
              const SizedBox(height: Space.md),
              const Center(child: BannerSlot()),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: Space.xl),
                SectionTitle(
                  l.recentlySolved,
                  trailing: TextButton(onPressed: () => context.go('/saved'), child: Text(l.seeAll)),
                ),
                for (final item in recent.take(3))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bookmark_rounded),
                    title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(item.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => openSavedItem(context, ref, item),
                  ),
              ],
              const SizedBox(height: Space.lg),
              AppCard(
                onTap: () => context.push('/today'),
                child: Row(
                  children: [
                    IconBubble(icon: Icons.wb_sunny_rounded, accent: Accent.plan),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.exploreMyDay, style: context.text.titleMedium),
                          Text(
                            l.exploreMyDayBody,
                            style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.xs),
    decoration: BoxDecoration(
      color: context.colors.surface.withValues(alpha: 0.9),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(Radii.lg),
        topRight: Radius.circular(Radii.lg),
        bottomRight: Radius.circular(Radii.lg),
        bottomLeft: Radius.circular(Radii.lg),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(liveRegion: true, child: Text(text, style: context.text.bodyMedium)),
        if (action != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onAction, child: Text(action!)),
          )
        else
          const SizedBox(height: Space.sm),
      ],
    ),
  );
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({required this.icon, required this.label, required this.onTap, this.primary = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? context.colors.primary : context.colors.surface;
    final fg = primary ? context.colors.onPrimary : context.colors.primary;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            height: 68,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: fg),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge?.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickTools extends StatelessWidget {
  const _QuickTools();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tools = <(IconData, String, Accent, VoidCallback)>[
      (Icons.account_balance_wallet_rounded, l.quickMoney, Accent.money, () => context.push('/money')),
      (Icons.balance_rounded, l.quickDecide, Accent.insight, () => context.push('/decide')),
      (Icons.restaurant_menu_rounded, l.quickFood, Accent.food, () => context.push('/food')),
      (Icons.calculate_rounded, l.quickCalc, Accent.score, () => context.push('/calc')),
      (
        Icons.edit_note_rounded,
        l.quickWrite,
        Accent.ai,
        () => context.push('/ai?topic=write&n=${DateTime.now().microsecondsSinceEpoch}'),
      ),
      (Icons.event_available_rounded, l.quickPlan, Accent.plan, () => context.push('/plan')),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.md,
      crossAxisSpacing: Space.md,
      childAspectRatio: 1.05,
      children: [
        for (final (icon, label, accent, onTap) in tools)
          AppCard(
            onTap: onTap,
            padding: const EdgeInsets.all(Space.md),
            semanticLabel: label,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBubble(icon: icon, accent: accent, size: 44),
                const SizedBox(height: Space.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
