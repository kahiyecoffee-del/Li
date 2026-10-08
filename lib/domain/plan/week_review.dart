import '../../core/utils/dates.dart';
import '../models/habit.dart';
import '../models/money_models.dart';
import '../models/task_item.dart';
import '../models/wellbeing.dart';

/// The last seven days (today included) in numbers.
class WeekSummary {
  const WeekSummary({
    required this.start,
    required this.end,
    required this.tasksDone,
    required this.tasksTotal,
    required this.wins,
    required this.habitRate,
    required this.spentMinor,
    required this.previousSpentMinor,
    required this.moodAverage,
    required this.journalCount,
  });

  final DateTime start, end;
  final int tasksDone, tasksTotal;

  /// Titles of tasks finished this week, latest first.
  final List<String> wins;

  /// Share of scheduled habit-days that reached their target (null: none).
  final double? habitRate;
  final int spentMinor, previousSpentMinor;

  /// 1–5, or null without mood logs.
  final double? moodAverage;
  final int journalCount;
}

WeekSummary summarizeWeek({
  required DateTime today,
  required List<TaskItem> tasks,
  required List<Habit> habits,
  required List<HabitLog> habitLogs,
  required List<MoneyTransaction> transactions,
  required List<MoodLog> moods,
  required List<DateTime> journalDates,
}) {
  final end = Dates.dateOnly(today);
  final start = Dates.addDays(end, -6);
  final after = Dates.addDays(end, 1);
  final prevStart = Dates.addDays(start, -7);
  bool inWeek(DateTime d) => !d.isBefore(start) && d.isBefore(after);

  final weekTasks = tasks.where((t) => !t.deleted && t.anchorDate != null && inWeek(t.anchorDate!)).toList();
  final finished = tasks.where((t) => !t.deleted && t.completedAt != null && inWeek(t.completedAt!)).toList()
    ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

  var scheduled = 0, kept = 0;
  final logs = {for (final g in habitLogs) g.id: g.count};
  for (var d = start; d.isBefore(after); d = Dates.addDays(d, 1)) {
    for (final h in habits.where(
      (h) => !h.deleted && h.isScheduledOn(d) && !h.createdAt.isAfter(Dates.addDays(d, 1)),
    )) {
      scheduled++;
      if ((logs[HabitLog.idFor(h.id, Dates.dayKey(d))] ?? 0) >= h.targetPerDay) kept++;
    }
  }

  var spent = 0, prev = 0;
  for (final t in transactions) {
    if (t.deleted || !t.isExpense) continue;
    if (inWeek(t.date)) spent += t.amountMinor;
    if (!t.date.isBefore(prevStart) && t.date.isBefore(start)) prev += t.amountMinor;
  }

  final weekKeys = {for (var d = start; d.isBefore(after); d = Dates.addDays(d, 1)) Dates.dayKey(d)};
  final weekMoods = moods.where((m) => !m.deleted && weekKeys.contains(m.day)).map((m) => m.mood).toList();

  return WeekSummary(
    start: start,
    end: end,
    tasksDone: weekTasks.where((t) => t.isCompleted).length,
    tasksTotal: weekTasks.length,
    wins: finished.map((t) => t.title).toSet().take(5).toList(),
    habitRate: scheduled == 0 ? null : kept / scheduled,
    spentMinor: spent,
    previousSpentMinor: prev,
    moodAverage: weekMoods.isEmpty ? null : weekMoods.reduce((a, b) => a + b) / weekMoods.length,
    journalCount: journalDates.where(inWeek).length,
  );
}
