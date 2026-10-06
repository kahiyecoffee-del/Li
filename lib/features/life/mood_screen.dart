import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../domain/engines/insight_engine.dart';
import 'mood_sheet.dart';

/// Daily mood check-in, weekly chart and observed patterns. Not a medical or
/// mental-health tool; the disclaimer is always visible.
class MoodScreen extends ConsumerWidget {
  const MoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final today = ref.watch(todayProvider);
    final moods = {for (final m in ref.watch(moodsProvider).list) m.day: m};
    final todayMood = moods[Dates.dayKey(today)];
    final week = [for (var i = 6; i >= 0; i--) Dates.addDays(today, -i)];
    final profile = ref.watch(profileProvider).value;
    final pattern = InsightEngine.moodLowerOnShortSleep(
      ref.watch(moodsProvider).list,
      ref.watch(sleepsProvider).list,
      profile?.sleepTargetMinutes ?? 480,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.lifeMood)),
      body: PageList(
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.howAreYou, style: context.text.titleMedium),
                const SizedBox(height: Space.md),
                MoodPicker(
                  selected: todayMood?.mood,
                  onSelected: (m) => showMoodSheet(context, initial: m),
                ),
                if (todayMood?.note != null) ...[
                  const SizedBox(height: Space.sm),
                  Text('“${todayMood!.note}”', style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          SectionTitle(l.moodHistory),
          AppCard(
            child: SizedBox(
              height: 180,
              child: Semantics(
                label: l.moodHistory,
                child: BarChart(
                  BarChartData(
                    maxY: 5,
                    minY: 0,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(l.weekdayShort('${week[v.toInt()].weekday}'), style: context.text.labelSmall),
                          ),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < week.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: (moods[Dates.dayKey(week[i])]?.mood ?? 0).toDouble(),
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              color: context.colors.primary,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (pattern) ...[
            const SizedBox(height: Space.md),
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: context.colors.primary),
                  const SizedBox(width: Space.md),
                  Expanded(child: Text(l.insightMoodSleep)),
                ],
              ),
            ),
          ],
          const SizedBox(height: Space.xl),
          Text(l.moodDisclaimer, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
        ],
      ),
    );
  }
}
