import '../models/enums.dart';

/// Intents the assistant may propose. Anything else is rejected by
/// [AiActionValidator]. There is deliberately no intent that moves money,
/// contacts third parties or runs code.
enum AiIntent {
  createTask('create_task'),
  optimizePlan('optimize_plan'),
  createBudget('create_budget'),
  addExpense('add_expense'),
  setSavingsGoal('set_savings_goal'),
  generateMealPlan('generate_meal_plan'),
  addShoppingItems('add_shopping_items'),
  createHabit('create_habit'),
  logMood('log_mood'),
  saveMemory('save_memory');

  const AiIntent(this.wire);

  final String wire;

  static AiIntent? fromWire(Object? s) {
    for (final i in values) {
      if (i.wire == s) return i;
    }
    return null;
  }
}

/// A validated, typed action. Construction only happens through the
/// validator, so executors can trust every field.
sealed class AiAction {
  const AiAction();

  AiIntent get intent;

  /// Every AI action needs explicit user confirmation, whatever the model
  /// claims in `requires_confirmation`.
  bool get requiresConfirmation => true;
}

class CreateTaskAction extends AiAction {
  const CreateTaskAction({
    required this.title,
    this.scheduledAt,
    this.deadline,
    this.durationMinutes = 30,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.personal,
  });

  final String title;
  final DateTime? scheduledAt;
  final DateTime? deadline;
  final int durationMinutes;
  final TaskPriority priority;
  final TaskCategory category;

  @override
  AiIntent get intent => AiIntent.createTask;
}

class OptimizePlanAction extends AiAction {
  const OptimizePlanAction();

  @override
  AiIntent get intent => AiIntent.optimizePlan;
}

class CreateBudgetAction extends AiAction {
  const CreateBudgetAction({required this.period, required this.amountMinor, this.category});

  final BudgetPeriod period;
  final int amountMinor;
  final ExpenseCategory? category;

  @override
  AiIntent get intent => AiIntent.createBudget;
}

class AddExpenseAction extends AiAction {
  const AddExpenseAction({
    required this.amountMinor,
    required this.category,
    required this.description,
    required this.date,
  });

  final int amountMinor;
  final ExpenseCategory category;
  final String description;
  final DateTime date;

  @override
  AiIntent get intent => AiIntent.addExpense;
}

class SetSavingsGoalAction extends AiAction {
  const SetSavingsGoalAction(this.amountMinor);

  final int amountMinor;

  @override
  AiIntent get intent => AiIntent.setSavingsGoal;
}

class GenerateMealPlanAction extends AiAction {
  const GenerateMealPlanAction({required this.date, this.usePantry = true});

  final DateTime date;
  final bool usePantry;

  @override
  AiIntent get intent => AiIntent.generateMealPlan;
}

class AddShoppingItemsAction extends AiAction {
  const AddShoppingItemsAction(this.items);

  final List<String> items;

  @override
  AiIntent get intent => AiIntent.addShoppingItems;
}

class CreateHabitAction extends AiAction {
  const CreateHabitAction({required this.name, required this.type, this.targetPerDay = 1});

  final String name;
  final HabitType type;
  final int targetPerDay;

  @override
  AiIntent get intent => AiIntent.createHabit;
}

class LogMoodAction extends AiAction {
  const LogMoodAction(this.mood, {this.note});

  final int mood;
  final String? note;

  @override
  AiIntent get intent => AiIntent.logMood;
}

class SaveMemoryAction extends AiAction {
  const SaveMemoryAction({required this.category, required this.content});

  final MemoryCategory category;
  final String content;

  @override
  AiIntent get intent => AiIntent.saveMemory;
}
