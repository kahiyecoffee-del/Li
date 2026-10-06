import '../../core/utils/dates.dart';
import '../models/enums.dart';
import '../models/habit.dart';
import '../models/money_models.dart';
import '../models/progress.dart';
import '../models/task_item.dart';
import '../models/wellbeing.dart';
import 'insight_engine.dart';
import 'life_score_engine.dart';

enum Suggestion { reduceCategorySpend, sleepEarlier, keepHabitStreak, planMoreTasks, logMoodDaily, startAHabit }

class PeriodReport {
  const PeriodReport({
    required this.from,
    required this.to,
    required this.avgScore,
    required this.scoreStart,
    required this.scoreEnd,
    required this.spentMinor,
    required this.previousSpentMinor,
    required this.spendChangePercent,
    required this.topCategory,
    required this.topCategoryChangePercent,
    required this.habitCompletionPercent,
    required this.avgMoodOutOf10,
    required this.productivityPercent,
    required this.avgSleepMinutes,
    required this.suggestions,
    required this.dailyScores,
    required this.dailySpend,
  });

  final DateTime from;
  final DateTime to;
  final int? avgScore;
  final int? scoreStart;
  final int? scoreEnd;
  final int spentMinor;
  final int previousSpentMinor;

  /// Spend vs previous equal-length period (null without history).
  final int? spendChangePercent;
  final ExpenseCategory? topCategory;
  final int? topCategoryChangePercent;
  final int? habitCompletionPercent;

  /// Self-reported mood converted from 1–5 to a 0–10 scale (mood × 2).
  final double? avgMoodOutOf10;
  final int? productivityPercent;
  final int? avgSleepMinutes;
  final List<Suggestion> suggestions;

  /// Day key → total score, for charts.
  final Map<String, int> dailyScores;

  /// Day key → variable spend, for charts.
  final Map<String, int> dailySpend;

  /// Money saved vs the previous period (positive = spent less).
  int get savedVsPreviousMinor => previousSpentMinor - spentMinor;
}

class ReportInput {
  const ReportInput({
    required this.from,
    required this.to,
    this.scores = const [],
    this.transactions = const [],
    this.habits = const [],
    this.habitLogs = const [],
    this.tasks = const [],
    this.moods = const [],
    this.sleeps = const [],
    this.sleepTargetMinutes = 480,
    this.bestHabitStreak = 0,
  });

  final DateTime from;
  final DateTime to;
  final List<DailyScoreRecord> scores;
  final List<MoneyTransaction> transactions;
  final List<Habit> habits;
  final List<HabitLog> habitLogs;
  final List<TaskItem> tasks;
  final List<MoodLog> moods;
  final List<SleepLog> sleeps;
  final int sleepTargetMinutes;
  final int bestHabitStreak;
}

/// Builds weekly / monthly reports from stored data. Numbers are computed here;
/// the AI only writes the optional narrative summary from these numbers.
class ReportEngine {
  const ReportEngine();

  PeriodReport build(ReportInput i) {
    final from = Dates.dateOnly(i.from);
    final to = Dates.dateOnly(i.to);
    final endExclusive = Dates.addDays(to, 1);
    final days = Dates.daysBetween(from, to) + 1;
    final prevFrom = Dates.addDays(from, -days);

    bool inRange(DateTime d, DateTime a, DateTime bExclusive) => !d.isBefore(a) && d.isBefore(bExclusive);
    bool inPeriod(String dayKey) => inRange(Dates.parseDayKey(dayKey), from, endExclusive);

    // Scores
    final scores = i.scores.where((s) => !s.deleted && inPeriod(s.id)).toList()..sort((a, b) => a.id.compareTo(b.id));
    final dailyScores = {for (final s in scores) s.id: s.total};
    final avgScore = scores.isEmpty ? null : (scores.fold(0, (s, x) => s + x.total) / scores.length).round();

    // Money
    final expenses = i.transactions.where((t) => !t.deleted && t.isExpense).toList();
    var spent = 0;
    var prevSpent = 0;
    final cat = <ExpenseCategory, int>{};
    final prevCat = <ExpenseCategory, int>{};
    final dailySpend = <String, int>{};
    for (final t in expenses) {
      if (inRange(t.date, from, endExclusive)) {
        spent += t.amountMinor;
        cat[t.category] = (cat[t.category] ?? 0) + t.amountMinor;
        if (!t.category.isFixed) {
          final k = Dates.dayKey(t.date);
          dailySpend[k] = (dailySpend[k] ?? 0) + t.amountMinor;
        }
      } else if (inRange(t.date, prevFrom, from)) {
        prevSpent += t.amountMinor;
        prevCat[t.category] = (prevCat[t.category] ?? 0) + t.amountMinor;
      }
    }
    final hasPrev = prevSpent > 0;
    final spendChange = hasPrev ? ((spent - prevSpent) * 100 / prevSpent).round() : null;

    ExpenseCategory? topCat;
    int? topCatChange;
    var topIncrease = 0;
    for (final c in cat.keys) {
      if (c.isFixed) continue;
      final inc = cat[c]! - (prevCat[c] ?? 0);
      if (inc > topIncrease && (prevCat[c] ?? 0) > 0) {
        topIncrease = inc;
        topCat = c;
        topCatChange = (inc * 100 / prevCat[c]!).round();
      }
    }

    // Habits
    final rate = InsightEngine.habitRate(i.habits, i.habitLogs, to);
    final habitPct = days == 7
        ? (rate == null ? null : (rate * 100).round())
        : _habitRateRange(i.habits, i.habitLogs, from, to);

    // Mood
    final moods = i.moods.where((m) => !m.deleted && inPeriod(m.day)).toList();
    final avgMood = moods.isEmpty ? null : moods.fold(0, (s, m) => s + m.mood) * 2 / moods.length;

    // Sleep
    final sleeps = i.sleeps.where((s) => !s.deleted && inPeriod(s.day)).toList();
    final avgSleep = sleeps.isEmpty ? null : (sleeps.fold(0, (s, x) => s + x.minutes) / sleeps.length).round();

    // Productivity: average of daily productivity scores over days with tasks.
    final prodDays = <int>[];
    for (final d in Dates.range(from, to)) {
      final p = LifeScoreEngine.productivityScore(i.tasks, d);
      if (p != null) prodDays.add(p);
    }
    final productivity = prodDays.isEmpty ? null : (prodDays.reduce((a, b) => a + b) / prodDays.length).round();

    final suggestions = <Suggestion>[];
    if (topCat != null && (topCatChange ?? 0) >= 15) suggestions.add(Suggestion.reduceCategorySpend);
    if (avgSleep != null && avgSleep < i.sleepTargetMinutes - 30) suggestions.add(Suggestion.sleepEarlier);
    if (i.habits.where((h) => !h.deleted).isEmpty) {
      suggestions.add(Suggestion.startAHabit);
    } else if (i.bestHabitStreak >= 3 || (habitPct ?? 0) >= 70) {
      suggestions.add(Suggestion.keepHabitStreak);
    }
    if (productivity == null) suggestions.add(Suggestion.planMoreTasks);
    if (moods.length < (days / 2).ceil()) suggestions.add(Suggestion.logMoodDaily);

    return PeriodReport(
      from: from,
      to: to,
      avgScore: avgScore,
      scoreStart: scores.isEmpty ? null : scores.first.total,
      scoreEnd: scores.isEmpty ? null : scores.last.total,
      spentMinor: spent,
      previousSpentMinor: prevSpent,
      spendChangePercent: spendChange,
      topCategory: topCat,
      topCategoryChangePercent: topCatChange,
      habitCompletionPercent: habitPct,
      avgMoodOutOf10: avgMood,
      productivityPercent: productivity,
      avgSleepMinutes: avgSleep,
      suggestions: suggestions.take(3).toList(),
      dailyScores: dailyScores,
      dailySpend: dailySpend,
    );
  }

  static int? _habitRateRange(List<Habit> habits, List<HabitLog> logs, DateTime from, DateTime to) {
    final byId = {
      for (final l in logs)
        if (!l.deleted) l.id: l.count,
    };
    var expected = 0;
    var met = 0;
    for (final d in Dates.range(from, to)) {
      for (final h in habits) {
        if (h.deleted || !h.isScheduledOn(d) || Dates.dateOnly(h.createdAt).isAfter(d)) continue;
        expected++;
        if ((byId[HabitLog.idFor(h.id, Dates.dayKey(d))] ?? 0) >= h.targetPerDay) met++;
      }
    }
    return expected == 0 ? null : (met * 100 / expected).round();
  }

  /// Monday–Sunday week containing [day].
  static (DateTime, DateTime) weekOf(DateTime day) {
    final start = Dates.startOfWeek(day);
    return (start, Dates.addDays(start, 6));
  }

  /// Calendar month containing [day].
  static (DateTime, DateTime) monthOf(DateTime day) =>
      (Dates.startOfMonth(day), Dates.addDays(Dates.startOfNextMonth(day), -1));
}
