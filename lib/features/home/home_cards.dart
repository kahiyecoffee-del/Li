import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../core/widgets/mascot.dart';
import '../../domain/engines/daily_goals_engine.dart';
import '../../domain/engines/meal_engine.dart';
import '../../domain/engines/recipe_library.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/user_profile.dart';
import '../../services/weather/weather_service.dart';
import '../life/mood_sheet.dart';
import '../plan/task_editor.dart';

class LifeScoreCard extends ConsumerWidget {
  const LifeScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(lifeScoreProvider);
    final total = s.score.total;
    // A small, reachable target: +3 over today's (or yesterday's) score.
    final target = ((total ?? s.previous?.total ?? 70) + 3).clamp(0, 100);
    return AppCard(
      onTap: () => context.push('/score'),
      child: Row(
        children: [
          ScoreRing(score: total, size: 104, stroke: 10),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardHeader(icon: Icons.local_fire_department_rounded, title: l.lifeScore, accent: Accent.score),
                const SizedBox(height: Space.sm),
                if (total == null)
                  Text(l.scoreNoData, style: context.text.bodyMedium)
                else ...[
                  Text(l.todaysGoal(target), style: context.text.titleSmall),
                  const SizedBox(height: Space.xs),
                  Text(
                    l.scoreExplanation(s.explanation, hasPrevious: s.previous != null),
                    style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DailyGoalsCard extends ConsumerWidget {
  const DailyGoalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final goals = ref.watch(dailyGoalsProvider);
    final todayKey = Dates.dayKey(ref.watch(todayProvider));
    final logs = {
      for (final h in ref.watch(habitLogsProvider).list)
        if (h.day == todayKey) h.habitId: h.count,
    };
    final progress = DailyGoalsEngine.progress(goals);
    final streak = ref.watch(streakProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            icon: Icons.flag_rounded,
            title: l.dailyGoals,
            accent: Accent.goals,
            trailing: streak.current > 1
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Accent.goals.tint(Theme.of(context).brightness),
                      borderRadius: BorderRadius.circular(Radii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded, size: 15, color: Accent.goals.color),
                        const SizedBox(width: 4),
                        Text(
                          l.streakDays(streak.current),
                          style: context.text.labelMedium?.copyWith(color: Accent.goals.color),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          const SizedBox(height: Space.md),
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress / 100),
            duration: Motion.of(context, Motion.slow),
            curve: Motion.curve,
            builder: (_, v, _) => ProgressBar(value: v, color: Accent.goals.color, label: l.lifeProgress(progress)),
          ),
          const SizedBox(height: Space.xs),
          Text(l.lifeProgress(progress), style: context.text.labelSmall?.copyWith(color: context.semantic.muted)),
          const SizedBox(height: Space.sm),
          ...goals.map(
            (g) => _GoalTile(
              goal: g,
              label: l.goal(g, fmt.money, habitDone: logs[g.habit?.id] ?? 0),
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.normal),
            curve: Motion.bounce,
            child: goals.isNotEmpty && goals.every((g) => g.completed)
                ? Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: Row(
                      children: [
                        const Mascot(mood: MascotMood.heart, size: 64),
                        const SizedBox(width: Space.md),
                        Expanded(child: Text('🎉 ${l.allGoalsDone}', style: context.text.titleSmall)),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          if (streak.atRisk) ...[
            const SizedBox(height: Space.sm),
            Text(l.streakAtRisk, style: context.text.bodySmall?.copyWith(color: context.semantic.warning)),
          ],
        ],
      ),
    );
  }
}

class _GoalTile extends ConsumerWidget {
  const _GoalTile({required this.goal, required this.label});

  final DailyGoal goal;
  final String label;

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(actionsProvider);
    switch (goal.kind) {
      case GoalKind.habit:
        await actions.logHabit(goal.habit!, goal.completed ? -1 : 1);
      case GoalKind.topTask:
        await actions.toggleTask(goal.task!);
      case GoalKind.logMood:
        await showMoodSheet(context);
      case GoalKind.logSleep:
        await showSleepSheet(context, ref);
      case GoalKind.planDay:
        if (!goal.completed) await showTaskEditor(context);
      case GoalKind.spending:
        await context.push('/money');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => MergeSemantics(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: kMinTouchTarget,
      leading: AnimatedSwitcher(
        duration: Motion.of(context, Motion.normal),
        switchInCurve: Motion.bounce,
        transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
        child: Icon(
          goal.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          key: ValueKey(goal.completed),
          color: goal.completed ? context.semantic.positive : context.semantic.muted,
        ),
      ),
      title: Text(
        label,
        style: context.text.bodyMedium?.copyWith(
          decoration: goal.completed && goal.kind != GoalKind.spending ? TextDecoration.lineThrough : null,
          color: goal.completed ? context.semantic.muted : null,
        ),
      ),
      onTap: () => _onTap(context, ref),
    ),
  );
}

class TodayPlanCard extends ConsumerWidget {
  const TodayPlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final today = ref.watch(todayProvider);
    final tasks =
        (ref.watch(tasksProvider).list)
            .where((t) => t.anchorDate != null && Dates.sameDay(t.anchorDate!, today))
            .toList()
          ..sort((a, b) => (a.scheduledAt ?? DateTime(9999)).compareTo(b.scheduledAt ?? DateTime(9999)));
    return AppCard(
      onTap: () => context.go('/plan'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(icon: Icons.event_note_rounded, title: l.homeToday, accent: Accent.plan),
          const SizedBox(height: Space.sm),
          if (tasks.isEmpty) ...[
            Text(l.homeNoPlan, style: context.text.bodyMedium),
            const SizedBox(height: Space.sm),
            FilledButton.tonal(
              onPressed: () => context.push('/ai?q=${Uri.encodeComponent(l.aiSuggestion1)}'),
              child: Text(l.homePlanDay),
            ),
          ] else
            ...tasks
                .take(4)
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.xs),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            t.scheduledAt == null ? '—' : fmt.time(t.scheduledAt!),
                            style: context.text.titleSmall?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodyMedium?.copyWith(
                              decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                              color: t.isCompleted ? context.semantic.muted : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class MoneyCard extends ConsumerWidget {
  const MoneyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final b = ref.watch(budgetSnapshotProvider);
    return AppCard(
      onTap: () => context.push('/money'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(icon: Icons.account_balance_wallet_rounded, title: l.homeMoney, accent: Accent.money),
          const SizedBox(height: Space.sm),
          if (b == null) ...[
            Text(l.setUpBudget, style: context.text.titleMedium),
            const SizedBox(height: Space.xs),
            Text(l.setUpBudgetBody, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
          ] else ...[
            Text(l.safeSpendingToday, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
            AnimatedCount(value: b.safeDailyMinor, format: fmt.money, style: context.text.headlineMedium),
            const SizedBox(height: Space.sm),
            ProgressBar(
              value: b.safeDailyMinor == 0 ? 1 : b.spentTodayMinor / b.safeDailyMinor,
              color: b.overToday
                  ? context.semantic.negative
                  : (b.isTight ? context.semantic.warning : context.semantic.positive),
            ),
            const SizedBox(height: Space.xs),
            Text(
              b.overToday
                  ? l.overToday(fmt.money(-b.remainingTodayMinor))
                  : l.leftToday(fmt.money(b.remainingTodayMinor)),
              style: context.text.labelMedium?.copyWith(
                color: b.overToday ? context.semantic.negative : context.semantic.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FoodCard extends ConsumerWidget {
  const FoodCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = currentNowOf(ref);
    final mealType = now.hour < 10 ? MealType.breakfast : (now.hour < 15 ? MealType.lunch : MealType.dinner);
    final plan = (ref.watch(mealPlansProvider).list).where((p) => p.id == Dates.dayKey(now)).firstOrNull;
    var meal = plan?.meals.where((m) => m.mealType == mealType).firstOrNull;
    if (meal == null) {
      final profile = ref.watch(profileProvider).value;
      final suggestions = const MealEngine().suggestDay(
        recipes: RecipeLibrary.all(Localizations.localeOf(context).languageCode),
        prefs: profile?.food ?? const FoodPreferences(),
        pantry: (ref.watch(pantryProvider).list).map((p) => p.name),
        day: now,
        types: [mealType],
      );
      meal = suggestions.firstOrNull;
    }
    if (meal == null) return const SizedBox.shrink();
    return AppCard(
      onTap: () => context.push('/food'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(icon: Icons.restaurant_rounded, title: l.homeFood, accent: Accent.food),
          const SizedBox(height: Space.sm),
          Text(
            l.suggestedMeal(l.mealType(mealType).toLowerCase()),
            style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
          ),
          Text(meal.name, style: context.text.titleLarge),
          const SizedBox(height: Space.xs),
          Text(
            '${l.foodCalories(meal.calories)} · ${l.minutesShort(meal.prepMinutes)}',
            style: context.text.labelMedium?.copyWith(color: context.semantic.muted),
          ),
        ],
      ),
    );
  }
}

class WellbeingCard extends ConsumerWidget {
  const WellbeingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final key = Dates.dayKey(ref.watch(todayProvider));
    final mood = (ref.watch(moodsProvider).list).where((m) => m.day == key).firstOrNull;
    final sleep = (ref.watch(sleepsProvider).list).where((s) => s.day == key).firstOrNull;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(icon: Icons.self_improvement_rounded, title: l.homeWellbeing, accent: Accent.wellbeing),
          const SizedBox(height: Space.md),
          if (mood == null) ...[
            Text(l.howAreYou, style: context.text.titleSmall),
            const SizedBox(height: Space.sm),
            MoodPicker(selected: null, onSelected: (m) => showMoodSheet(context, initial: m)),
          ] else
            Row(
              children: [
                Text(moodEmojis[mood.mood]!, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: Space.md),
                Expanded(child: Text(l.mood(mood.mood), style: context.text.titleMedium)),
                TextButton(
                  onPressed: () => showMoodSheet(context, initial: mood.mood),
                  child: Text(l.edit),
                ),
              ],
            ),
          const SizedBox(height: Space.sm),
          if (sleep == null)
            TextButton.icon(
              onPressed: () => showSleepSheet(context, ref),
              icon: const Icon(Icons.bedtime_outlined),
              label: Text(l.logSleep),
            )
          else
            Text('🌙 ${l.hoursMinutes(sleep.minutes ~/ 60, sleep.minutes % 60)}', style: context.text.bodyMedium),
        ],
      ),
    );
  }
}

class InsightCard extends ConsumerWidget {
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final insights = ref.watch(insightsProvider);
    return AppCard(
      onTap: insights.isEmpty
          ? null
          : () => context.push('/ai?q=${Uri.encodeComponent(l.insightText(insights.first))}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBubble(icon: Icons.auto_awesome_rounded, accent: Accent.insight),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.insight, style: context.text.titleSmall?.copyWith(color: context.semantic.muted)),
                const SizedBox(height: Space.xs),
                Text(insights.isEmpty ? l.insightNone : l.insightText(insights.first), style: context.text.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherChip extends ConsumerWidget {
  const WeatherChip({super.key});

  static IconData icon(WeatherCondition c) => switch (c) {
    WeatherCondition.clear => Icons.wb_sunny_outlined,
    WeatherCondition.partlyCloudy => Icons.wb_cloudy_outlined,
    WeatherCondition.cloudy => Icons.cloud_outlined,
    WeatherCondition.fog => Icons.foggy,
    WeatherCondition.drizzle || WeatherCondition.rain => Icons.umbrella_outlined,
    WeatherCondition.snow => Icons.ac_unit,
    WeatherCondition.thunderstorm => Icons.thunderstorm_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final hasPlace = ref.watch(profileProvider.select((p) => p.value?.place != null));
    if (!hasPlace) {
      return ActionChip(
        avatar: const Icon(Icons.wb_sunny_outlined, size: 18),
        label: Text(l.setCityForWeather),
        onPressed: () => context.push('/settings'),
      );
    }
    final w = ref.watch(weatherProvider).value;
    if (w == null) return const SizedBox.shrink();
    return Semantics(
      label: '${l.weather(w.condition)}, ${w.temperatureC.round()}°, ${l.rainChance(w.rainProbability)}',
      child: ExcludeSemantics(
        child: Chip(
          avatar: Icon(icon(w.condition), size: 18),
          label: Text('${w.temperatureC.round()}° · ${l.weather(w.condition)} · ${l.rainChance(w.rainProbability)}'),
        ),
      ),
    );
  }
}

class NewsTeaserCard extends ConsumerWidget {
  const NewsTeaserCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final news = ref.watch(newsProvider(Localizations.localeOf(context).languageCode));
    final count = news.value?.length ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return AppCard(
      onTap: () => context.push('/news'),
      child: Row(
        children: [
          const IconBubble(icon: Icons.newspaper_rounded, accent: Accent.news),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.forYou, style: context.text.titleSmall?.copyWith(color: context.semantic.muted)),
                Text(l.importantStories(count.clamp(0, 3)), style: context.text.titleMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class WeeklyReviewCard extends StatelessWidget {
  const WeeklyReviewCard({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => context.push('/reports/weekly'),
    child: Row(
      children: [
        const IconBubble(icon: Icons.insights_rounded, accent: Accent.score),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.weeklyReport, style: context.text.titleMedium),
              Text(
                context.l10n.weeklyReportSubtitle,
                style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

DateTime currentNowOf(WidgetRef ref) => ref.watch(nowProvider).value ?? ref.watch(clockProvider)();
