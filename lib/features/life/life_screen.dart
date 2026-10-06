import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../services/config/feature_flags.dart';
import '../premium/banner_slot.dart';
import '../shell/main_shell.dart';

/// Hub for habits, wellbeing, food and reports.
class LifeScreen extends ConsumerWidget {
  const LifeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final flags = services.flags;
    final shopping = (ref.watch(shoppingProvider).list).where((s) => !s.checked).length;
    final badges = ref.watch(achievementsProvider).value?.length ?? 0;
    final tiles = <(IconData, String, String, String?, Accent)>[
      (Icons.repeat_rounded, l.lifeHabits, '/habits', null, Accent.goals),
      (Icons.mood_rounded, l.lifeMood, '/mood', null, Accent.wellbeing),
      (Icons.menu_book_rounded, l.lifeJournal, '/journal', null, Accent.insight),
      (Icons.restaurant_menu_rounded, l.lifeFood, '/food', null, Accent.food),
      if (flags.isEnabled(Feature.pantry)) (Icons.kitchen_rounded, l.lifePantry, '/pantry', null, Accent.money),
      (Icons.shopping_cart_rounded, l.lifeShopping, '/shopping', shopping > 0 ? '$shopping' : null, Accent.plan),
      if (flags.isEnabled(Feature.weeklyReport))
        (Icons.insights_rounded, l.weeklyReport, '/reports/weekly', null, Accent.ai),
      if (flags.isEnabled(Feature.monthlyReport))
        (Icons.calendar_month_rounded, l.monthlyReport, '/reports/monthly', null, Accent.news),
      if (services.cloudEnabled && flags.isEnabled(Feature.news))
        (Icons.newspaper_rounded, l.lifeNews, '/news', null, Accent.news),
      (Icons.emoji_events_rounded, l.lifeAchievements, '/achievements', badges > 0 ? '$badges' : null, Accent.score),
    ];
    final streak = ref.watch(streakProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.navLife), actions: const [ProfileButton()]),
      body: PageList(
        children: [
          if (streak.current > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Text('🔥 ${l.streakDays(streak.current)}', style: context.text.titleMedium),
            ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Space.md,
            crossAxisSpacing: Space.md,
            childAspectRatio: 1.2,
            children: [
              for (final (i, t) in tiles.indexed)
                FadeSlideIn(
                  delay: Duration(milliseconds: 50 * i),
                  child: _tile(context, t),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          const BannerSlot(),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, (IconData, String, String, String?, Accent) t) => AppCard(
    color: Color.alphaBlend(t.$5.color.withValues(alpha: 0.07), context.colors.surface),
    onTap: () => context.push(t.$3),
    semanticLabel: t.$2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconBubble(icon: t.$1, accent: t.$5, size: 38),
            const Spacer(),
            if (t.$4 != null) Badge(label: Text(t.$4!)),
          ],
        ),
        const Spacer(),
        Text(t.$2, style: context.text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}
