import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/badge_engine.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static IconData icon(BadgeId b) => switch (b) {
    BadgeId.firstWeek => Icons.flag_circle_outlined,
    BadgeId.budgetMaster => Icons.savings_outlined,
    BadgeId.sevenDayStreak => Icons.local_fire_department_outlined,
    BadgeId.healthyWeek => Icons.favorite_outline,
    BadgeId.earlyBird => Icons.wb_twilight_outlined,
    BadgeId.planner => Icons.event_available_outlined,
    BadgeId.moneySaver => Icons.account_balance_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final unlocked = {for (final a in ref.watch(achievementsProvider).list) a.id: a.unlockedAt};
    return Scaffold(
      appBar: AppBar(title: Text(l.achievements)),
      body: PageList(
        children: BadgeId.values.map((b) {
          final (name, desc) = l.badge(b);
          final at = unlocked[b.name];
          return Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: AppCard(
              child: Opacity(
                opacity: at == null ? 0.45 : 1,
                child: Row(
                  children: [
                    Icon(icon(b), size: 32, color: at == null ? context.semantic.muted : context.colors.primary),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: context.text.titleMedium),
                          Text(desc, style: context.text.bodySmall),
                          if (at != null)
                            Text(
                              fmt.fullDate(at),
                              style: context.text.labelSmall?.copyWith(color: context.semantic.muted),
                            ),
                        ],
                      ),
                    ),
                    if (at == null) const Icon(Icons.lock_outline, size: 18),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
