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
import '../../core/utils/json.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/badge_engine.dart';
import '../../domain/engines/report_engine.dart';
import '../../domain/models/progress.dart';
import '../../services/ads/ads_service.dart';
import '../../services/ai/ai_models.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/config/feature_flags.dart';
import '../premium/banner_slot.dart';
import '../premium/interstitial.dart';
import '../premium/rewarded.dart';

/// "Your week in 60 seconds" and the Monthly Life Report.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.monthly});

  final bool monthly;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  int _offset = 0; // 0 = current period, 1 = previous…
  String? _summary;
  bool _summarizing = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref
          .read(servicesProvider)
          .analytics
          .log(widget.monthly ? AnalyticsEvent.monthlyReportViewed : AnalyticsEvent.weeklyReportViewed),
    );
  }

  (DateTime, DateTime) _period(DateTime today) {
    if (widget.monthly) return ReportEngine.monthOf(DateTime(today.year, today.month - _offset, 1));
    return ReportEngine.weekOf(Dates.addDays(today, -7 * _offset));
  }

  Future<void> _summarize(PeriodReport r, String money) async {
    setState(() => _summarizing = true);
    try {
      final res = await ref.read(servicesProvider).ai.task(
        widget.monthly ? AiTaskType.monthlySummary : AiTaskType.weeklySummary,
        {
          'locale': Localizations.localeOf(context).languageCode,
          'from': Dates.dayKey(r.from),
          'to': Dates.dayKey(r.to),
          'avgScore': r.avgScore,
          'scoreStart': r.scoreStart,
          'scoreEnd': r.scoreEnd,
          'spent': money,
          'spendChangePercent': r.spendChangePercent,
          'topCategory': r.topCategory?.name,
          'topCategoryChangePercent': r.topCategoryChangePercent,
          'habitCompletionPercent': r.habitCompletionPercent,
          'avgMoodOutOf10': r.avgMoodOutOf10,
          'productivityPercent': r.productivityPercent,
          'avgSleepHours': r.avgSleepMinutes == null ? null : (r.avgSleepMinutes! / 60).toStringAsFixed(1),
          'suggestions': r.suggestions.map((s) => s.name).toList(),
        },
      );
      ref.read(creditsProvider.notifier).set(res.credits);
      if (mounted) setState(() => _summary = J.str(res.result, 'text'));
    } catch (e) {
      if (mounted) showSnack(context, context.l10n.failure(e));
    } finally {
      if (mounted) setState(() => _summarizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final services = ref.watch(servicesProvider);
    final premium = ref.watch(isPremiumProvider);
    final gated =
        widget.monthly &&
        services.flags.isPremiumOnly(PremiumFeature.monthlyReport) &&
        !premium &&
        !ref.watch(rewardUnlocksProvider).isUnlocked(RewardPlacement.advancedAnalysis);
    final today = ref.watch(todayProvider);
    final period = _period(today);
    final r = ref.watch(reportProvider(period));
    final title = widget.monthly ? l.monthlyReport : l.weeklyReport;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(maybeShowInterstitial(ref));
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: gated
            ? _Locked(onUnlocked: () => setState(() {}))
            : PageList(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: l.back,
                        onPressed: () => setState(() {
                          _offset++;
                          _summary = null;
                        }),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          widget.monthly ? fmt.monthYear(r.from) : '${fmt.dayMonth(r.from)} – ${fmt.dayMonth(r.to)}',
                          textAlign: TextAlign.center,
                          style: context.text.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: l.next,
                        onPressed: _offset == 0
                            ? null
                            : () => setState(() {
                                _offset--;
                                _summary = null;
                              }),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  if (!widget.monthly)
                    Text(
                      l.weeklyReportSubtitle,
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                    ),
                  const SizedBox(height: Space.md),
                  _MetricsGrid(report: r, fmt: fmt),
                  if (r.dailyScores.isNotEmpty) ...[
                    SectionTitle(l.reportScore),
                    AppCard(
                      child: SizedBox(height: 150, child: _ScoreChart(report: r)),
                    ),
                  ],
                  if (r.dailySpend.isNotEmpty) ...[
                    SectionTitle(l.reportMoney),
                    AppCard(
                      child: SizedBox(height: 150, child: _SpendChart(report: r)),
                    ),
                  ],
                  SectionTitle(widget.monthly ? l.reportNextMonth : l.reportNextWeek),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: r.suggestions.isEmpty
                          ? [Text(l.reportNoData)]
                          : [
                              for (final (i, s) in r.suggestions.indexed)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: Space.xs),
                                  child: Text(
                                    '${i + 1}. ${l.suggestion(s, category: r.topCategory)}',
                                    style: context.text.bodyLarge,
                                  ),
                                ),
                            ],
                    ),
                  ),
                  if (services.cloudEnabled) ...[
                    SectionTitle(l.reportAiSummary),
                    if (_summary != null)
                      AppCard(child: Text(_summary!, style: context.text.bodyLarge))
                    else
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: _summarizing ? null : () => _summarize(r, fmt.money(r.spentMinor)),
                          icon: _summarizing
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome),
                          label: Text(l.reportGenerateSummary),
                        ),
                      ),
                  ],
                  if (widget.monthly) ...[SectionTitle(l.achievements), const _MonthBadges()],
                  const SizedBox(height: Space.lg),
                  const BannerSlot(),
                ],
              ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.report, required this.fmt});

  final PeriodReport report;
  final Fmt fmt;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = report;
    String pct(int? v) => v == null ? '–' : l.percentValue(v);
    final items = <(String, String, String?)>[
      (
        l.reportScore,
        r.avgScore?.toString() ?? '–',
        r.scoreStart != null && r.scoreEnd != null ? l.reportScoreChange(r.scoreStart!, r.scoreEnd!) : null,
      ),
      (
        l.reportMoney,
        fmt.money(r.spentMinor),
        r.spendChangePercent == null
            ? null
            : r.savedVsPreviousMinor > 0
            ? l.reportSaved(fmt.money(r.savedVsPreviousMinor))
            : l.reportSpendChange('${r.spendChangePercent! > 0 ? '+' : ''}${r.spendChangePercent}'),
      ),
      (l.reportHabits, pct(r.habitCompletionPercent), null),
      (l.reportMood, r.avgMoodOutOf10 == null ? '–' : l.reportMoodValue(r.avgMoodOutOf10!.toStringAsFixed(1)), null),
      (l.reportProductivity, pct(r.productivityPercent), null),
      (
        l.reportSleep,
        r.avgSleepMinutes == null ? '–' : l.hoursMinutes(r.avgSleepMinutes! ~/ 60, r.avgSleepMinutes! % 60),
        null,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Space.md,
      crossAxisSpacing: Space.md,
      childAspectRatio: 1.45,
      children: items
          .map(
            (i) => AppCard(
              padding: const EdgeInsets.all(Space.md),
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.upper(i.$1), style: context.text.labelSmall?.copyWith(color: context.semantic.muted)),
                    const SizedBox(height: Space.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(i.$2, style: context.text.headlineSmall),
                    ),
                    if (i.$3 != null)
                      Text(i.$3!, style: context.text.labelSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ScoreChart extends StatelessWidget {
  const _ScoreChart({required this.report});

  final PeriodReport report;

  @override
  Widget build(BuildContext context) {
    final days = Dates.range(report.from, report.to).toList();
    final spots = [
      for (var i = 0; i < days.length; i++)
        if (report.dailyScores[Dates.dayKey(days[i])] != null)
          FlSpot(i.toDouble(), report.dailyScores[Dates.dayKey(days[i])]!.toDouble()),
    ];
    return Semantics(
      label: context.l10n.reportScore,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          minX: 0,
          maxX: (days.length - 1).toDouble(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: context.colors.primary, barWidth: 3)],
        ),
      ),
    );
  }
}

class _SpendChart extends StatelessWidget {
  const _SpendChart({required this.report});

  final PeriodReport report;

  @override
  Widget build(BuildContext context) {
    final days = Dates.range(report.from, report.to).toList();
    final values = days.map((d) => (report.dailySpend[Dates.dayKey(d)] ?? 0) / 100).toList();
    final max = values.fold<double>(0, (a, b) => a > b ? a : b);
    return Semantics(
      label: context.l10n.reportMoney,
      child: BarChart(
        BarChartData(
          maxY: max == 0 ? 1 : max * 1.15,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          barTouchData: BarTouchData(enabled: false),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: days.length > 10 ? 6 : 16,
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthBadges extends ConsumerWidget {
  const _MonthBadges();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(achievementsProvider).list;
    if (list.isEmpty) return Text(l.reportNoData);
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: list.map((AchievementRecord a) {
        final id = BadgeLookup.byName(a.id);
        return Chip(
          avatar: const Icon(Icons.emoji_events_outlined, size: 18),
          label: Text(id == null ? a.id : l.badge(id).$1),
        );
      }).toList(),
    );
  }
}

class _Locked extends ConsumerWidget {
  const _Locked({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return EmptyState(
      icon: Icons.lock_outline,
      message: l.premiumLocked,
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(onPressed: () => context.push('/premium?from=monthly_report'), child: Text(l.premiumTitle)),
          const SizedBox(height: Space.sm),
          TextButton.icon(
            onPressed: () async {
              if (await watchRewardedAd(context, ref, RewardPlacement.advancedAnalysis)) {
                await ref.read(rewardUnlocksProvider).unlock(RewardPlacement.advancedAnalysis);
                onUnlocked();
              }
            },
            icon: const Icon(Icons.play_circle_outline),
            label: Text(l.tryWithAd),
          ),
        ],
      ),
    );
  }
}
