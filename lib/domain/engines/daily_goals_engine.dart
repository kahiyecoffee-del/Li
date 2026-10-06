import '../models/enums.dart';
import '../models/habit.dart';
import '../models/task_item.dart';
import '../../core/utils/dates.dart';
import 'budget_engine.dart';

enum GoalKind { habit, spending, topTask, logMood, logSleep, planDay }

/// A small, achievable goal for today.
class DailyGoal {
  const DailyGoal({
    required this.id,
    required this.kind,
    required this.completed,
    this.habit,
    this.task,
    this.amountMinor,
    this.autoTracked = true,
  });

  /// Stable per-day id (e.g. `habit:<id>`, `spending`), used to persist manual
  /// completion.
  final String id;
  final GoalKind kind;
  final bool completed;
  final Habit? habit;
  final TaskItem? task;

  /// For spending goals: the allowance to stay under.
  final int? amountMinor;

  /// Auto-tracked goals are evaluated from data; others are ticked manually.
  final bool autoTracked;
}

class DailyGoalsInput {
  const DailyGoalsInput({
    required this.day,
    required this.focusAreas,
    this.habits = const [],
    this.habitLogs = const [],
    this.tasks = const [],
    this.budget,
    this.moodLogged = false,
    this.sleepLogged = false,
    this.manuallyCompleted = const {},
  });

  final DateTime day;
  final Set<FocusArea> focusAreas;
  final List<Habit> habits;
  final List<HabitLog> habitLogs;
  final List<TaskItem> tasks;
  final BudgetSnapshot? budget;
  final bool moodLogged;
  final bool sleepLogged;
  final Set<String> manuallyCompleted;
}

/// Picks 3–5 daily goals deterministically from the user's own data and focus
/// areas, in priority order. Same input always yields the same goals.
class DailyGoalsEngine {
  const DailyGoalsEngine();

  static const maxGoals = 5;
  static const minGoals = 3;

  List<DailyGoal> build(DailyGoalsInput i) {
    final goals = <DailyGoal>[];
    final logCounts = {
      for (final l in i.habitLogs)
        if (!l.deleted) l.habitId: l.count,
    };

    // 1. Spending: only if a budget exists.
    if (i.budget != null) {
      goals.add(
        DailyGoal(
          id: 'spending',
          kind: GoalKind.spending,
          amountMinor: i.budget!.safeDailyMinor,
          // Staying under can only be confirmed when the day ends; it shows as
          // "on track" during the day and counts as done while within limit.
          completed: i.budget!.spentTodayMinor <= i.budget!.safeDailyMinor,
        ),
      );
    }

    // 2. Top-priority open task for today.
    final todayTasks = i.tasks.where((t) {
      final a = t.anchorDate;
      return !t.deleted && a != null && Dates.sameDay(a, i.day);
    }).toList()..sort((a, b) => b.priority.index.compareTo(a.priority.index));
    if (todayTasks.isNotEmpty) {
      final top = todayTasks.firstWhere((t) => !t.isCompleted, orElse: () => todayTasks.first);
      goals.add(DailyGoal(id: 'task:${top.id}', kind: GoalKind.topTask, task: top, completed: top.isCompleted));
    }

    // 3. Habits scheduled today: health habits first if Health is a focus.
    final scheduled = i.habits.where((h) => !h.deleted && h.isScheduledOn(i.day)).toList()
      ..sort((a, b) {
        final healthFirst = i.focusAreas.contains(FocusArea.health);
        final ah = healthFirst && a.type.isHealth ? 0 : 1;
        final bh = healthFirst && b.type.isHealth ? 0 : 1;
        if (ah != bh) return ah - bh;
        return a.createdAt.compareTo(b.createdAt);
      });
    for (final h in scheduled.take(2)) {
      goals.add(
        DailyGoal(
          id: 'habit:${h.id}',
          kind: GoalKind.habit,
          habit: h,
          completed: (logCounts[h.id] ?? 0) >= h.targetPerDay,
        ),
      );
    }

    // 4. Lightweight check-ins fill the remaining slots.
    if (goals.length < maxGoals) {
      goals.add(DailyGoal(id: 'mood', kind: GoalKind.logMood, completed: i.moodLogged));
    }
    if (goals.length < maxGoals && i.focusAreas.contains(FocusArea.health)) {
      goals.add(DailyGoal(id: 'sleep', kind: GoalKind.logSleep, completed: i.sleepLogged));
    }
    if (goals.length < minGoals || (goals.length < maxGoals && todayTasks.isEmpty)) {
      goals.add(
        DailyGoal(
          id: 'plan',
          kind: GoalKind.planDay,
          completed: todayTasks.isNotEmpty || i.manuallyCompleted.contains('plan'),
          autoTracked: false,
        ),
      );
    }
    if (goals.length < minGoals && !goals.any((g) => g.kind == GoalKind.logSleep)) {
      goals.add(DailyGoal(id: 'sleep', kind: GoalKind.logSleep, completed: i.sleepLogged));
    }
    return goals.take(maxGoals).toList();
  }

  /// Share of today's goals completed, 0–100 ("Life Progress").
  static int progress(List<DailyGoal> goals) {
    if (goals.isEmpty) return 0;
    return (goals.where((g) => g.completed).length * 100 / goals.length).round();
  }
}
