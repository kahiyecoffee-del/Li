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

/// Explore: every tool in one place. Solving tools first, then the
/// trackers (money, habits, mood, journal, food, reports) as secondary.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final services = ref.watch(servicesProvider);
    final flags = services.flags;
    final shopping = (ref.watch(shoppingProvider).list).where((s) => !s.checked).length;
    final badges = ref.watch(achievementsProvider).value?.length ?? 0;
    final solve = <(IconData, String, String, String?, Accent)>[
      (Icons.balance_rounded, l.quickDecide, '/decide', null, Accent.insight),
      (Icons.calculate_rounded, l.calcTitle, '/calc', null, Accent.score),
      (Icons.edit_note_rounded, l.quickWrite, '/ai?topic=write', null, Accent.ai),
      (Icons.event_available_rounded, l.quickPlan, '/plan', null, Accent.plan),
      (Icons.wb_sunny_rounded, l.exploreMyDay, '/today', null, Accent.goals),
      (Icons.auto_mode_rounded, l.routinesTitle, '/routines', null, Accent.wellbeing),
      (Icons.flag_rounded, l.goalsLife, '/goals', null, Accent.goals),
      (Icons.event_repeat_rounded, l.reviewTitle, '/review', null, Accent.insight),
    ];
    final tiles = <(IconData, String, String, String?, Accent)>[
      (Icons.account_balance_wallet_rounded, l.navMoney, '/money', null, Accent.money),
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
      appBar: AppBar(title: Text(l.exploreTitle)),
      body: PageList(
        children: [
          SectionTitle(l.exploreSolve),
          _grid(context, solve),
          const SizedBox(height: Space.xl),
          SectionTitle(l.exploreLife),
          if (streak.current > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: Accent.goals.color),
                  const SizedBox(width: Space.xs),
                  Text(l.streakDays(streak.current), style: context.text.titleMedium),
                ],
              ),
            ),
          _grid(context, tiles),
          const SizedBox(height: Space.lg),
          const BannerSlot(),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, List<(IconData, String, String, String?, Accent)> tiles) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: Space.md,
    crossAxisSpacing: Space.md,
    childAspectRatio: 2.3,
    children: [
      for (final (i, t) in tiles.indexed)
        FadeSlideIn(
          delay: Duration(milliseconds: 40 * i),
          child: _tile(context, t),
        ),
    ],
  );

  Widget _tile(BuildContext context, (IconData, String, String, String?, Accent) t) => AppCard(
    onTap: () => t.$3.startsWith('/ai') ? context.go(t.$3) : context.push(t.$3),
    semanticLabel: t.$2,
    padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
    child: Row(
      children: [
        IconBubble(icon: t.$1, accent: t.$5, size: 38),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Text(t.$2, style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        if (t.$4 != null) Badge(label: Text(t.$4!)),
      ],
    ),
  );
}
