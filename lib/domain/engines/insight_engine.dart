import '../../core/utils/dates.dart';
import '../models/enums.dart';
import '../models/habit.dart';
import '../models/money_models.dart';
import '../models/wellbeing.dart';

enum InsightKind {
  /// Spending in the last 7 days vs the weekly average of the 4 weeks before.
  weeklySpendVsAverage,

  /// A category's month-to-date spend vs the same period last month.
  categorySpendChange,

  /// Habit completion rate this week vs last week (percentage points).
  habitRateChange,

  /// Lower self-reported mood on short-sleep days (correlation, not causation).
  moodLowerOnShortSleep,

  /// Today's spending allowance is nearly used.
  budgetTight,
}

class Insight {
  const Insight(this.kind, {this.percent = 0, this.category, this.priority = 0});

  final InsightKind kind;

  /// Signed percentage (or percentage points for habit rate).
  final int percent;
  final ExpenseCategory? category;

  /// Higher shows first.
  final int priority;
}

class InsightInput {
  const InsightInput({
    required this.now,
    this.transactions = const [],
    this.habits = const [],
    this.habitLogs = const [],
    this.moods = const [],
    this.sleeps = const [],
    this.sleepTargetMinutes = 480,
    this.budgetTight = false,
  });

  final DateTime now;
  final List<MoneyTransaction> transactions;
  final List<Habit> habits;
  final List<HabitLog> habitLogs;
  final List<MoodLog> moods;
  final List<SleepLog> sleeps;
  final int sleepTargetMinutes;
  final bool budgetTight;
}

/// Produces factual, data-backed observations. Thresholds avoid noise: an
/// insight is only emitted when the effect is large enough to matter.
class InsightEngine {
  const InsightEngine();

  static const minPercentChange = 10;

  List<Insight> build(InsightInput i) {
    final out = <Insight>[];
    if (i.budgetTight) out.add(const Insight(InsightKind.budgetTight, priority: 100));

    final weekly = weeklySpendVsAverage(i.transactions, i.now);
    if (weekly != null && weekly.abs() >= minPercentChange) {
      out.add(Insight(InsightKind.weeklySpendVsAverage, percent: weekly, priority: 60 + weekly.abs() ~/ 5));
    }

    final cat = biggestCategoryChange(i.transactions, i.now);
    if (cat != null) out.add(cat);

    final habit = habitRateChange(i.habits, i.habitLogs, i.now);
    if (habit != null && habit.abs() >= minPercentChange) {
      out.add(Insight(InsightKind.habitRateChange, percent: habit, priority: 40 + habit.abs() ~/ 5));
    }

    if (moodLowerOnShortSleep(i.moods, i.sleeps, i.sleepTargetMinutes)) {
      out.add(const Insight(InsightKind.moodLowerOnShortSleep, priority: 30));
    }
    out.sort((a, b) => b.priority.compareTo(a.priority));
    return out;
  }

  static int _variableSpend(Iterable<MoneyTransaction> t, DateTime from, DateTime toExclusive) => t
      .where((x) => !x.deleted && x.isExpense && !x.date.isBefore(from) && x.date.isBefore(toExclusive))
      .fold(0, (s, x) => s + x.amountMinor);

  /// % difference of the last 7 days vs the average of the 4 preceding weeks.
  static int? weeklySpendVsAverage(List<MoneyTransaction> t, DateTime now) {
    final end = Dates.addDays(Dates.dateOnly(now), 1);
    final start = Dates.addDays(end, -7);
    final recent = _variableSpend(t, start, end);
    final prior = _variableSpend(t, Dates.addDays(start, -28), start);
    if (prior <= 0 || recent <= 0) return null;
    final avg = prior / 4;
    return ((recent - avg) * 100 / avg).round();
  }

  /// Largest month-to-date category change vs the same days last month.
  static Insight? biggestCategoryChange(List<MoneyTransaction> t, DateTime now) {
    final thisStart = Dates.startOfMonth(now);
    final thisEnd = Dates.addDays(Dates.dateOnly(now), 1);
    final lastStart = DateTime(now.year, now.month - 1);
    final lastDays = Dates.daysInMonth(lastStart);
    final lastEnd = DateTime(lastStart.year, lastStart.month, (now.day > lastDays ? lastDays : now.day) + 1);
    Insight? best;
    for (final c in ExpenseCategory.values) {
      if (c.isFixed) continue;
      final cur = _variableSpend(t.where((x) => x.category == c), thisStart, thisEnd);
      final prev = _variableSpend(t.where((x) => x.category == c), lastStart, lastEnd);
      if (prev <= 0 || cur <= 0) continue;
      final pct = ((cur - prev) * 100 / prev).round();
      if (pct.abs() < 15) continue;
      // Weight by absolute money moved so tiny categories don't dominate.
      final weight = (cur - prev).abs();
      if (best == null || weight > best.priority) {
        best = Insight(InsightKind.categorySpendChange, percent: pct, category: c, priority: weight);
      }
    }
    if (best == null) return null;
    return Insight(best.kind, percent: best.percent, category: best.category, priority: 50 + best.percent.abs() ~/ 5);
  }

  /// Completion rate (target met / scheduled) for a 7-day window ending on [end].
  static double? habitRate(List<Habit> habits, List<HabitLog> logs, DateTime end) {
    final byId = {
      for (final l in logs)
        if (!l.deleted) l.id: l.count,
    };
    var expected = 0;
    var met = 0;
    for (final d in Dates.range(Dates.addDays(end, -6), end)) {
      for (final h in habits) {
        if (h.deleted || !h.isScheduledOn(d)) continue;
        if (Dates.dateOnly(h.createdAt).isAfter(d)) continue;
        expected++;
        if ((byId[HabitLog.idFor(h.id, Dates.dayKey(d))] ?? 0) >= h.targetPerDay) met++;
      }
    }
    return expected == 0 ? null : met / expected;
  }

  /// Change in percentage points: this week vs previous week.
  static int? habitRateChange(List<Habit> habits, List<HabitLog> logs, DateTime now) {
    final today = Dates.dateOnly(now);
    final cur = habitRate(habits, logs, today);
    final prev = habitRate(habits, logs, Dates.addDays(today, -7));
    if (cur == null || prev == null) return null;
    return ((cur - prev) * 100).round();
  }

  /// True when mood on short-sleep days averages ≥0.5 lower than on other
  /// days, with at least 3 days in each group.
  static bool moodLowerOnShortSleep(List<MoodLog> moods, List<SleepLog> sleeps, int target) {
    final sleepByDay = {
      for (final s in sleeps)
        if (!s.deleted) s.day: s.minutes,
    };
    final short = <int>[];
    final enough = <int>[];
    for (final m in moods) {
      if (m.deleted) continue;
      final s = sleepByDay[m.day];
      if (s == null) continue;
      (s < target - 60 ? short : enough).add(m.mood);
    }
    if (short.length < 3 || enough.length < 3) return false;
    double avg(List<int> v) => v.reduce((a, b) => a + b) / v.length;
    return avg(enough) - avg(short) >= 0.5;
  }
}
