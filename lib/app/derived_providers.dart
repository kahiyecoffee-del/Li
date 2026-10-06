import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/dates.dart';
import '../domain/engines/badge_engine.dart';
import '../domain/engines/budget_engine.dart';
import '../domain/engines/money_insights.dart';
import '../domain/engines/daily_goals_engine.dart';
import '../domain/engines/insight_engine.dart';
import '../domain/engines/life_score_engine.dart';
import '../domain/engines/recipe_library.dart';
import '../domain/engines/report_engine.dart';
import '../domain/engines/streaks.dart';
import '../domain/lio/journal_learner.dart';
import '../domain/lio/lio_advisor.dart';
import '../domain/models/progress.dart';
import '../services/ai/ai_models.dart';
import '../services/news/news_service.dart';
import '../services/weather/weather_service.dart';
import 'providers.dart';

/// Today's calendar day (rolls over at midnight).
final todayProvider = Provider<DateTime>((ref) => Dates.dateOnly(currentNow(ref)));

final budgetSnapshotProvider = Provider<BudgetSnapshot?>((ref) {
  final profile = ref.watch(profileProvider).value;
  if (profile == null || !profile.hasBudget) return null;
  return const BudgetEngine().compute(
    plan: BudgetPlan(
      monthlyIncomeMinor: profile.monthlyIncomeMinor ?? 0,
      fixedExpensesMinor: math.max(profile.fixedExpensesMinor ?? 0, billsMonthlyTotal(ref.watch(billsProvider).list)),
      savingsGoalMinor: profile.savingsGoalMinor ?? 0,
    ),
    transactions: ref.watch(transactionsProvider).list,
    budgets: ref.watch(budgetsProvider).list,
    now: currentNow(ref),
  );
});

/// Day keys on which the user did anything meaningful (for streaks).
final activeDaysProvider = Provider<Set<String>>((ref) {
  final days = <String>{};
  for (final t in ref.watch(transactionsProvider).list) {
    days.add(Dates.dayKey(t.date));
  }
  for (final l in ref.watch(habitLogsProvider).list) {
    if (l.count > 0) days.add(l.day);
  }
  for (final m in ref.watch(moodsProvider).list) {
    days.add(m.day);
  }
  for (final s in ref.watch(sleepsProvider).list) {
    days.add(s.day);
  }
  for (final t in ref.watch(tasksProvider).list) {
    if (t.completedAt != null) days.add(Dates.dayKey(t.completedAt!));
  }
  for (final g in ref.watch(goalsRecordsProvider).list) {
    if (g.completedGoalIds.isNotEmpty) days.add(g.id);
  }
  return days;
});

final streakProvider = Provider<StreakInfo>(
  (ref) => const StreakCalculator().compute(ref.watch(activeDaysProvider), ref.watch(todayProvider)),
);

class TodayScore {
  const TodayScore({required this.score, required this.previous, required this.explanation, required this.weakest});

  final LifeScore score;
  final LifeScore? previous;
  final ScoreExplanation explanation;
  final ScoreComponent? weakest;
}

LifeScore? _fromRecord(DailyScoreRecord? r) => r == null
    ? null
    : LifeScore(
        total: r.total,
        components: {
          for (final e in r.components.entries)
            for (final c in ScoreComponent.values)
              if (c.name == e.key) c: e.value,
        },
      );

final lifeScoreProvider = Provider<TodayScore>((ref) {
  final today = ref.watch(todayProvider);
  final key = Dates.dayKey(today);
  final profile = ref.watch(profileProvider).value;
  final logs = (ref.watch(habitLogsProvider).list).where((l) => l.day == key).toList();
  final mood = (ref.watch(moodsProvider).list).where((m) => m.day == key).firstOrNull;
  final sleep = (ref.watch(sleepsProvider).list).where((s) => s.day == key).firstOrNull;
  const engine = LifeScoreEngine();
  final score = engine.compute(
    LifeScoreInput(
      day: today,
      budget: ref.watch(budgetSnapshotProvider),
      habits: ref.watch(habitsProvider).list,
      habitLogs: logs,
      tasks: ref.watch(tasksProvider).list,
      mood: mood?.mood,
      sleepMinutes: sleep?.minutes,
      sleepTargetMinutes: profile?.sleepTargetMinutes ?? 480,
      checkedInToday: ref.watch(activeDaysProvider).contains(key),
    ),
  );
  final yesterdayKey = Dates.dayKey(Dates.addDays(today, -1));
  final prev = _fromRecord((ref.watch(scoresProvider).list).where((r) => r.id == yesterdayKey).firstOrNull);
  return TodayScore(
    score: score,
    previous: prev,
    explanation: engine.explain(score, prev),
    weakest: engine.weakest(score),
  );
});

final dailyGoalsProvider = Provider<List<DailyGoal>>((ref) {
  final today = ref.watch(todayProvider);
  final key = Dates.dayKey(today);
  final record = (ref.watch(goalsRecordsProvider).list).where((g) => g.id == key).firstOrNull;
  return const DailyGoalsEngine().build(
    DailyGoalsInput(
      day: today,
      focusAreas: ref.watch(profileProvider).value?.focusAreas ?? const {},
      habits: ref.watch(habitsProvider).list,
      habitLogs: (ref.watch(habitLogsProvider).list).where((l) => l.day == key).toList(),
      tasks: ref.watch(tasksProvider).list,
      budget: ref.watch(budgetSnapshotProvider),
      moodLogged: (ref.watch(moodsProvider).list).any((m) => m.day == key),
      sleepLogged: (ref.watch(sleepsProvider).list).any((s) => s.day == key),
      manuallyCompleted: record?.completedGoalIds ?? const {},
    ),
  );
});

final insightsProvider = Provider<List<Insight>>((ref) {
  final profile = ref.watch(profileProvider).value;
  return const InsightEngine().build(
    InsightInput(
      now: currentNow(ref),
      transactions: ref.watch(transactionsProvider).list,
      habits: ref.watch(habitsProvider).list,
      habitLogs: ref.watch(habitLogsProvider).list,
      moods: ref.watch(moodsProvider).list,
      sleeps: ref.watch(sleepsProvider).list,
      sleepTargetMinutes: profile?.sleepTargetMinutes ?? 480,
      budgetTight: ref.watch(budgetSnapshotProvider)?.isTight ?? false,
    ),
  );
});

final earnedBadgesProvider = Provider<Set<BadgeId>>((ref) {
  final profile = ref.watch(profileProvider).value;
  return const BadgeEngine().evaluate(
    BadgeInput(
      today: ref.watch(todayProvider),
      activeDays: ref.watch(activeDaysProvider),
      currentStreak: ref.watch(streakProvider).current,
      installedAt: profile?.installedAt,
      tasks: ref.watch(tasksProvider).list,
      habits: ref.watch(habitsProvider).list,
      habitLogs: ref.watch(habitLogsProvider).list,
      dailyScores: ref.watch(scoresProvider).list,
      savingsGoalMinor: profile?.savingsGoalMinor,
      lastMonthSavedMinor: ref.watch(lastMonthSavedProvider),
    ),
  );
});

/// Last calendar month: planned income + extra income − all expenses.
final lastMonthSavedProvider = Provider<int?>((ref) {
  final profile = ref.watch(profileProvider).value;
  if (profile == null || !profile.hasBudget) return null;
  final today = ref.watch(todayProvider);
  final from = DateTime(today.year, today.month - 1);
  final to = Dates.startOfMonth(today);
  final tx = ref.watch(transactionsProvider).list;
  if (!tx.any((t) => !t.date.isBefore(from) && t.date.isBefore(to))) return null;
  var net = profile.monthlyIncomeMinor ?? 0;
  for (final t in tx) {
    if (t.date.isBefore(from) || !t.date.isBefore(to)) continue;
    net += t.isExpense ? -t.amountMinor : t.amountMinor;
  }
  return net;
});

/// Weekly/monthly report for a period (`(from, to)` record key).
final reportProvider = Provider.family<PeriodReport, (DateTime, DateTime)>((ref, period) {
  final profile = ref.watch(profileProvider).value;
  final habits = ref.watch(habitsProvider).list;
  final logs = ref.watch(habitLogsProvider).list;
  final completed = <String, Set<String>>{};
  for (final l in logs) {
    completed.putIfAbsent(l.habitId, () => {}).add(l.day);
  }
  var bestHabitStreak = 0;
  for (final h in habits) {
    final s = const StreakCalculator().habitStreak(
      completedDays: {
        for (final l in logs)
          if (l.habitId == h.id && l.count >= h.targetPerDay) l.day,
      },
      weekdays: h.weekdays,
      today: period.$2,
    );
    if (s > bestHabitStreak) bestHabitStreak = s;
  }
  return const ReportEngine().build(
    ReportInput(
      from: period.$1,
      to: period.$2,
      scores: ref.watch(scoresProvider).list,
      transactions: ref.watch(transactionsProvider).list,
      habits: habits,
      habitLogs: logs,
      tasks: ref.watch(tasksProvider).list,
      moods: ref.watch(moodsProvider).list,
      sleeps: ref.watch(sleepsProvider).list,
      sleepTargetMinutes: profile?.sleepTargetMinutes ?? 480,
      bestHabitStreak: bestHabitStreak,
    ),
  );
});

// ---------------------------------------------------------------------------
// Remote data (cached; never blocks the Home screen).

final weatherProvider = FutureProvider<Weather?>((ref) async {
  final place = ref.watch(profileProvider.select((p) => p.value?.place));
  if (place == null) return null;
  return ref.watch(servicesProvider).weather.get(place);
});

final newsProvider = FutureProvider.family<List<NewsArticle>, String>((ref, language) async {
  final topics = ref.watch(profileProvider.select((p) => p.value?.newsTopics ?? const ['world']));
  return ref.watch(servicesProvider).news.headlines(topics, language);
});

/// AI credits as last reported by the backend.
class CreditsController extends AsyncNotifier<AiCredits> {
  @override
  Future<AiCredits> build() async {
    ref.watch(sessionProvider);
    try {
      return await ref.watch(servicesProvider).ai.credits();
    } catch (_) {
      return AiCredits.unknown;
    }
  }

  void set(AiCredits c) => state = AsyncData(c);

  Future<void> refresh() async => state = AsyncData(await build());
}

final creditsProvider = AsyncNotifierProvider<CreditsController, AiCredits>(CreditsController.new);

/// Lio's suggestions from everything the user has entered (money, plans,
/// habits, mood, sleep, journal dates, shopping and pantry).
final adviceProvider = Provider<List<Advice>>((ref) {
  final profile = ref.watch(profileProvider).value;
  final lang = ref.watch(localeProvider)?.languageCode ?? 'en';
  return const LioAdvisor().advise(
    AdvisorInput(
      now: currentNow(ref),
      budget: ref.watch(budgetSnapshotProvider),
      hasIncome: (profile?.monthlyIncomeMinor ?? 0) > 0,
      transactions: ref.watch(transactionsProvider).list,
      tasks: ref.watch(tasksProvider).list,
      habits: ref.watch(habitsProvider).list,
      habitLogs: ref.watch(habitLogsProvider).list,
      moods: ref.watch(moodsProvider).list,
      sleeps: ref.watch(sleepsProvider).list,
      sleepTargetMinutes: profile?.sleepTargetMinutes ?? 480,
      journalDates: [for (final e in ref.watch(journalProvider).list) e.createdAt],
      shopping: ref.watch(shoppingProvider).list,
      pantry: [for (final p in ref.watch(pantryProvider).list) p.name],
      recipes: RecipeLibrary.all(lang),
      journalProfile: ref.watch(journalProfileProvider),
      bills: ref.watch(billsProvider).list,
    ),
  );
});

/// What Lio learned from the journal on this phone; null when the user
/// turned learning off in Settings.
final journalProfileProvider = Provider<JournalProfile?>((ref) {
  if (!ref.watch(settingsProvider.select((s) => s.lioLearnsJournal))) return null;
  return const JournalLearner().learn(
    [for (final e in ref.watch(journalProvider).list) JournalNote(e.createdAt, e.text)],
    {for (final m in ref.watch(moodsProvider).list) m.id: m.mood},
    Dates.dayKey,
  );
});
