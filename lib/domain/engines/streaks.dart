import '../../core/utils/dates.dart';

class StreakInfo {
  const StreakInfo({required this.current, required this.best, required this.atRisk});

  /// Consecutive active days ending today (or yesterday if today is not yet
  /// active — the streak is still alive until the day ends).
  final int current;
  final int best;

  /// True when yesterday was active but today is not yet.
  final bool atRisk;
}

/// Computes streaks from a set of active day keys (`yyyy-MM-dd`).
class StreakCalculator {
  const StreakCalculator();

  StreakInfo compute(Set<String> activeDays, DateTime today) {
    if (activeDays.isEmpty) return const StreakInfo(current: 0, best: 0, atRisk: false);
    final todayKey = Dates.dayKey(today);
    final activeToday = activeDays.contains(todayKey);

    var cursor = activeToday ? Dates.dateOnly(today) : Dates.addDays(Dates.dateOnly(today), -1);
    var current = 0;
    while (activeDays.contains(Dates.dayKey(cursor))) {
      current++;
      cursor = Dates.addDays(cursor, -1);
    }

    final sorted = activeDays.map(Dates.parseDayKey).toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final d in sorted) {
      run = (prev != null && Dates.daysBetween(prev, d) == 1) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return StreakInfo(current: current, best: best, atRisk: !activeToday && current > 0);
  }

  /// Streak for a habit: a day counts when the habit target was met, and days
  /// on which the habit is not scheduled are skipped rather than breaking it.
  int habitStreak({
    required Set<String> completedDays,
    required Set<int> weekdays,
    required DateTime today,
    int maxLookbackDays = 400,
  }) {
    if (weekdays.isEmpty) return 0;
    var cursor = Dates.dateOnly(today);
    var streak = 0;
    // Today not being done yet does not break the streak.
    if (!completedDays.contains(Dates.dayKey(cursor))) cursor = Dates.addDays(cursor, -1);
    for (var i = 0; i < maxLookbackDays; i++) {
      if (!weekdays.contains(cursor.weekday)) {
        cursor = Dates.addDays(cursor, -1);
        continue;
      }
      if (!completedDays.contains(Dates.dayKey(cursor))) break;
      streak++;
      cursor = Dates.addDays(cursor, -1);
    }
    return streak;
  }
}
