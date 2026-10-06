import '../../core/utils/dates.dart';
import '../models/habit.dart';
import '../models/progress.dart';
import '../models/task_item.dart';

enum BadgeId { firstWeek, budgetMaster, sevenDayStreak, healthyWeek, earlyBird, planner, moneySaver }

abstract final class BadgeLookup {
  static BadgeId? byName(String name) => BadgeId.values.where((b) => b.name == name).firstOrNull;
}

class BadgeInput {
  const BadgeInput({
    required this.today,
    required this.activeDays,
    required this.currentStreak,
    this.installedAt,
    this.tasks = const [],
    this.habits = const [],
    this.habitLogs = const [],
    this.dailyScores = const [],
    this.lastMonthSavedMinor,
    this.savingsGoalMinor,
  });

  final DateTime today;
  final Set<String> activeDays;
  final int currentStreak;
  final DateTime? installedAt;
  final List<TaskItem> tasks;
  final List<Habit> habits;
  final List<HabitLog> habitLogs;
  final List<DailyScoreRecord> dailyScores;

  final int? lastMonthSavedMinor;
  final int? savingsGoalMinor;
}

/// Deterministic achievement rules. Badges are quiet milestones, not a game.
class BadgeEngine {
  const BadgeEngine();

  Set<BadgeId> evaluate(BadgeInput i) {
    final earned = <BadgeId>{};
    final today = Dates.dateOnly(i.today);

    // First week: 7 distinct active days since install.
    if (i.activeDays.length >= 7) earned.add(BadgeId.firstWeek);

    if (i.currentStreak >= 7) earned.add(BadgeId.sevenDayStreak);

    // Budget master: money sub-score 100 on 7 consecutive recorded days.
    final moneyByDay = {
      for (final s in i.dailyScores)
        if (s.components.containsKey('money')) s.id: s.components['money']!,
    };
    if (_consecutive(moneyByDay.entries.where((e) => e.value >= 100).map((e) => e.key).toSet(), 7)) {
      earned.add(BadgeId.budgetMaster);
    }

    // Healthy week: ≥80% of scheduled health-habit targets met over the last 7 days.
    final health = i.habits.where((h) => !h.deleted && h.type.isHealth).toList();
    if (health.isNotEmpty) {
      var expected = 0;
      var met = 0;
      final logs = {
        for (final l in i.habitLogs)
          if (!l.deleted) l.id: l.count,
      };
      for (final d in Dates.range(Dates.addDays(today, -6), today)) {
        for (final h in health) {
          if (!h.isScheduledOn(d) || h.createdAt.isAfter(Dates.addDays(d, 1))) continue;
          expected++;
          if ((logs[HabitLog.idFor(h.id, Dates.dayKey(d))] ?? 0) >= h.targetPerDay) met++;
        }
      }
      if (expected >= 7 && met * 100 >= expected * 80) earned.add(BadgeId.healthyWeek);
    }

    // Early bird: 5 tasks completed before 09:00.
    final early = i.tasks.where((t) => !t.deleted && t.completedAt != null && t.completedAt!.hour < 9).length;
    if (early >= 5) earned.add(BadgeId.earlyBird);

    // Planner: tasks planned on 7 different days.
    final plannedDays = i.tasks
        .where((t) => !t.deleted && t.anchorDate != null)
        .map((t) => Dates.dayKey(t.anchorDate!))
        .toSet();
    if (plannedDays.length >= 7) earned.add(BadgeId.planner);

    // Money saver: last month's savings met the goal.
    if (i.lastMonthSavedMinor != null &&
        (i.savingsGoalMinor ?? 0) > 0 &&
        i.lastMonthSavedMinor! >= i.savingsGoalMinor!) {
      earned.add(BadgeId.moneySaver);
    }
    return earned;
  }

  static bool _consecutive(Set<String> days, int n) {
    final sorted = days.map(Dates.parseDayKey).toList()..sort();
    var run = 0;
    DateTime? prev;
    for (final d in sorted) {
      run = (prev != null && Dates.daysBetween(prev, d) == 1) ? run + 1 : 1;
      if (run >= n) return true;
      prev = d;
    }
    return false;
  }
}
