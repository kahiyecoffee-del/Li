import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/mascot.dart';
import 'problem_flow.dart';

/// Home: "What should we solve today?" and one big Solve button that opens
/// the conversation with Lio, plus quick tools and recent answers.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final name = ref.watch(profileProvider.select((p) => p.value?.name ?? ''));
    final recent = [...?ref.watch(savedProvider).value]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, 120),
          children: [
            FadeSlideIn(
              child: HeroBanner(
                gradient: dark ? Gradients.meadowDark : Gradients.meadow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? l.homeHelloNoName : l.homeHello(name),
                                style: context.text.titleMedium?.copyWith(color: context.semantic.muted),
                              ),
                              const SizedBox(height: Space.xs),
                              Semantics(header: true, child: Text(l.homeQuestion, style: context.text.headlineMedium)),
                            ],
                          ),
                        ),
                        const Mascot(mood: MascotMood.happy, size: 72),
                      ],
                    ),
                    const SizedBox(height: Space.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.go('/ai');
                        },
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: Text(l.solve),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.xl),
            const _QuickTools(),
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
          ],
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
        () => context.go('/ai?topic=write&n=${DateTime.now().microsecondsSinceEpoch}'),
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
