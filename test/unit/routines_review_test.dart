import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/habit.dart';
import 'package:lifeos/domain/models/money_models.dart';
import 'package:lifeos/domain/models/routine_goal.dart';
import 'package:lifeos/domain/models/task_item.dart';
import 'package:lifeos/domain/models/wellbeing.dart';
import 'package:lifeos/domain/plan/routines.dart';
import 'package:lifeos/domain/plan/week_review.dart';

void main() {
  final now = DateTime(2026, 6, 10, 8);

  test('a routine becomes back-to-back tasks with one reminder', () {
    var n = 0;
    final r = routineTemplates.first.toRoutine('tpl-morning', 'tr');
    final tasks = routineTasks(r, DateTime(2026, 6, 11), 7 * 60, now: now, newId: () => 'id${n++}');
    expect(tasks.length, r.steps.length);
    expect(tasks.first.title, 'Bir bardak su iç');
    expect(tasks.first.scheduledAt, DateTime(2026, 6, 11, 7));
    expect(tasks[1].scheduledAt, DateTime(2026, 6, 11, 7, 5));
    expect(tasks.last.scheduledAt!.add(Duration(minutes: tasks.last.estimatedMinutes)), DateTime(2026, 6, 11, 8));
    expect(tasks.first.reminderLead, isNotNull);
    expect(tasks.skip(1).every((t) => t.reminderLead == null), isTrue);
  });

  test('goal progress counts steps done directly or through their task', () {
    final g = LifeGoal(
      id: 'g',
      updatedAt: now,
      title: 'English B1',
      steps: const [
        GoalStep(id: 'a', title: 'Placement test', done: true),
        GoalStep(id: 'b', title: 'Book a course', taskId: 't1'),
        GoalStep(id: 'c', title: 'Speak 10 min'),
      ],
      createdAt: now,
    );
    expect(g.doneSteps(const {}), 1);
    expect(g.doneSteps(const {'t1'}), 2);
    expect(g.progress(const {'t1'}), closeTo(2 / 3, 0.001));
    final back = LifeGoal.fromJson({...g.toJson(), 'id': 'g', 'updatedAt': 0});
    expect(back.steps[1].taskId, 't1');
  });

  test('week summary: tasks, wins, habits, spending, mood', () {
    TaskItem t(String id, DateTime at, {bool done = false}) =>
        TaskItem(id: id, updatedAt: now, title: id, scheduledAt: at, completedAt: done ? at : null, createdAt: now);
    MoneyTransaction e(int major, DateTime d) => MoneyTransaction(
      id: '$major$d',
      updatedAt: now,
      type: TransactionType.expense,
      amountMinor: major * 100,
      currency: 'TRY',
      category: ExpenseCategory.food,
      date: d,
    );
    final habit = Habit(id: 'h', updatedAt: now, name: 'Water', type: HabitType.water, createdAt: DateTime(2026));
    final w = summarizeWeek(
      today: DateTime(2026, 6, 10),
      tasks: [
        t('Report', DateTime(2026, 6, 9, 10), done: true),
        t('Gym', DateTime(2026, 6, 8, 18)),
        t('Old', DateTime(2026, 5, 1)),
      ],
      habits: [habit],
      habitLogs: [
        HabitLog(id: HabitLog.idFor('h', '2026-06-10'), updatedAt: now, habitId: 'h', day: '2026-06-10', count: 1),
      ],
      transactions: [e(100, DateTime(2026, 6, 9)), e(200, DateTime(2026, 6, 1))],
      moods: [
        MoodLog(id: '2026-06-09', updatedAt: now, mood: 4),
        MoodLog(id: '2026-06-10', updatedAt: now, mood: 2),
      ],
      journalDates: [DateTime(2026, 6, 9)],
    );
    expect(w.tasksTotal, 2);
    expect(w.tasksDone, 1);
    expect(w.wins, ['Report']);
    expect(w.habitRate, closeTo(1 / 7, 0.001));
    expect(w.spentMinor, 10000);
    expect(w.previousSpentMinor, 20000);
    expect(w.moodAverage, 3);
    expect(w.journalCount, 1);
  });
}
