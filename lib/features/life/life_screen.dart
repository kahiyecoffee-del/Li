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
    final tiles = <(IconData, String, String, String?)>[
      (Icons.repeat_rounded, l.lifeHabits, '/habits', null),
      (Icons.mood_outlined, l.lifeMood, '/mood', null),
      (Icons.book_outlined, l.lifeJournal, '/journal', null),
      (Icons.restaurant_menu_outlined, l.lifeFood, '/food', null),
      if (flags.isEnabled(Feature.pantry)) (Icons.kitchen_outlined, l.lifePantry, '/pantry', null),
      (Icons.shopping_cart_outlined, l.lifeShopping, '/shopping', shopping > 0 ? '$shopping' : null),
      if (flags.isEnabled(Feature.weeklyReport)) (Icons.insights_outlined, l.weeklyReport, '/reports/weekly', null),
      if (flags.isEnabled(Feature.monthlyReport))
        (Icons.calendar_month_outlined, l.monthlyReport, '/reports/monthly', null),
      if (services.cloudEnabled && flags.isEnabled(Feature.news)) (Icons.newspaper_outlined, l.lifeNews, '/news', null),
      (Icons.emoji_events_outlined, l.lifeAchievements, '/achievements', badges > 0 ? '$badges' : null),
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
            childAspectRatio: 1.35,
            children: tiles
                .map(
                  (t) => AppCard(
                    onTap: () => context.push(t.$3),
                    semanticLabel: t.$2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(t.$1, color: context.colors.primary, size: 28),
                            const Spacer(),
                            if (t.$4 != null) Badge(label: Text(t.$4!)),
                          ],
                        ),
                        const Spacer(),
                        Text(t.$2, style: context.text.titleMedium),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: Space.lg),
          const BannerSlot(),
        ],
      ),
    );
  }
}
