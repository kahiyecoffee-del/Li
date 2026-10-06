import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/habit.dart';
import 'package:lifeos/domain/models/money_models.dart';
import 'package:lifeos/domain/models/task_item.dart';

final epoch = DateTime(2026);
var _seq = 0;

MoneyTransaction expense(int major, DateTime date, [ExpenseCategory c = ExpenseCategory.food]) => MoneyTransaction(
  id: 't${_seq++}',
  updatedAt: epoch,
  type: TransactionType.expense,
  amountMinor: major * 100,
  currency: 'TRY',
  category: c,
  date: date,
);

MoneyTransaction income(int major, DateTime date) => MoneyTransaction(
  id: 'i${_seq++}',
  updatedAt: epoch,
  type: TransactionType.income,
  amountMinor: major * 100,
  currency: 'TRY',
  category: ExpenseCategory.other,
  date: date,
);

Habit habit(String id, {HabitType type = HabitType.custom, int target = 1, DateTime? created}) =>
    Habit(id: id, updatedAt: epoch, name: id, type: type, targetPerDay: target, createdAt: created ?? DateTime(2025));

HabitLog log(String habitId, String day, int count) =>
    HabitLog(id: HabitLog.idFor(habitId, day), updatedAt: epoch, habitId: habitId, day: day, count: count);

TaskItem task(
  String id, {
  DateTime? scheduledAt,
  DateTime? deadline,
  DateTime? completedAt,
  TaskPriority priority = TaskPriority.medium,
  int minutes = 30,
}) => TaskItem(
  id: id,
  updatedAt: epoch,
  title: id,
  scheduledAt: scheduledAt,
  deadline: deadline,
  completedAt: completedAt,
  priority: priority,
  estimatedMinutes: minutes,
  createdAt: DateTime(2025),
);
