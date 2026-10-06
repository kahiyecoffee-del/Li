import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../domain/engines/life_score_engine.dart';
import '../../services/ads/ads_service.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/config/feature_flags.dart';
import '../premium/rewarded.dart';

/// Life Score detail: total, deterministic explanation, per-area breakdown
/// (Premium, or unlocked for the day with a rewarded ad) and 14-day history.
class ScoreScreen extends ConsumerStatefulWidget {
  const ScoreScreen({super.key});

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(servicesProvider).analytics.log(AnalyticsEvent.lifeScoreViewed));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(lifeScoreProvider);
    final premium = ref.watch(isPremiumProvider);
    final gated = ref.watch(servicesProvider).flags.isPremiumOnly(PremiumFeature.advancedScore);
    final unlocked = !gated || premium || ref.watch(rewardUnlocksProvider).isUnlocked(RewardPlacement.detailedScore);
    final today = ref.watch(todayProvider);
    final history = {for (final r in ref.watch(scoresProvider).list) r.id: r.total};

    return Scaffold(
      appBar: AppBar(title: Text(l.lifeScore)),
      body: PageList(
        children: [
          Center(child: ScoreRing(score: s.score.total, size: 160, stroke: 14)),
          const SizedBox(height: Space.lg),
          Text(
            s.score.total == null ? l.scoreNoData : l.scoreExplanation(s.explanation, hasPrevious: s.previous != null),
            textAlign: TextAlign.center,
            style: context.text.bodyLarge,
          ),
          if (s.weakest != null) ...[
            const SizedBox(height: Space.sm),
            Text(
              l.scoreWeakest(l.scoreComponent(s.weakest!)),
              textAlign: TextAlign.center,
              style: context.text.titleSmall?.copyWith(color: context.colors.primary),
            ),
          ],
          SectionTitle(l.scoreBreakdown),
          if (unlocked)
            AppCard(
              child: Column(
                children: ScoreComponent.values.map((c) {
                  final v = s.score.components[c];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.sm),
                    child: Row(
                      children: [
                        SizedBox(width: 110, child: Text(l.scoreComponent(c), style: context.text.bodyMedium)),
                        Expanded(
                          child: ProgressBar(
                            value: (v ?? 0) / 100,
                            color: v == null ? null : context.semantic.forScore(v),
                            label: l.scoreComponent(c),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(v?.toString() ?? '–', textAlign: TextAlign.end, style: context.text.titleSmall),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else
            AppCard(
              child: Column(
                children: [
                  const Icon(Icons.lock_outline),
                  const SizedBox(height: Space.sm),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      if (await watchRewardedAd(context, ref, RewardPlacement.detailedScore)) {
                        await ref.read(rewardUnlocksProvider).unlock(RewardPlacement.detailedScore);
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: Text(l.unlockBreakdown),
                  ),
                  TextButton(onPressed: () => context.push('/premium?from=score'), child: Text(l.aiGoPremium)),
                ],
              ),
            ),
          SectionTitle(l.scoreHistory),
          AppCard(
            child: SizedBox(
              height: 160,
              child: _History(
                points: [
                  for (var i = 13; i >= 0; i--)
                    (Dates.addDays(today, -i), history[Dates.dayKey(Dates.addDays(today, -i))]),
                ],
              ),
            ),
          ),
          SectionTitle(l.scoreHowCalculated),
          Text(l.scoreExplainer, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.points});

  final List<(DateTime, int?)> points;

  @override
  Widget build(BuildContext context) {
    final spots = [
      for (var i = 0; i < points.length; i++)
        if (points[i].$2 != null) FlSpot(i.toDouble(), points[i].$2!.toDouble()),
    ];
    if (spots.isEmpty) return Center(child: Text(context.l10n.reportNoData));
    final color = context.colors.primary;
    return Semantics(
      label: context.l10n.scoreHistory,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
            ),
          ],
        ),
      ),
    );
  }
}
