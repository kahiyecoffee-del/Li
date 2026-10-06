import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../data/repositories/user_repos.dart';
import '../../domain/ai/ai_action.dart';
import '../../domain/engines/meal_engine.dart';
import '../../domain/engines/plan_optimizer.dart';
import '../../domain/engines/recipe_library.dart';
import '../../domain/engines/shopping_categorizer.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/food.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/money_models.dart';
import '../../domain/models/task_item.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/wellbeing.dart';
import 'memory_manager.dart';

class ActionOutcome {
  const ActionOutcome(this.success, {this.count = 0, this.detail});

  final bool success;

  /// Items affected (e.g. tasks rescheduled, shopping items added).
  final int count;
  final String? detail;
}

/// Executes a validated, user-confirmed AI action against local data.
///
/// Only typed [AiAction]s produced by `AiActionValidator` reach this class,
/// and the UI calls [execute] only after the user tapped "Confirm". Nothing
/// here can move money or reach outside the user's own records.
class AiActionExecutor {
  AiActionExecutor({
    required this.repos,
    required this.profile,
    required this.memory,
    required this.languageCode,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final UserRepos repos;
  final UserProfile profile;
  final MemoryManager memory;
  final String languageCode;
  final DateTime Function() _clock;

  Future<ActionOutcome> execute(AiAction action) async {
    final now = _clock();
    switch (action) {
      case final CreateTaskAction a:
        await repos.tasks.save(
          TaskItem(
            id: newId(),
            updatedAt: now,
            title: a.title,
            scheduledAt: a.scheduledAt,
            deadline: a.deadline,
            estimatedMinutes: a.durationMinutes,
            priority: a.priority,
            category: a.category,
            createdAt: now,
          ),
        );
        return const ActionOutcome(true, count: 1);

      case OptimizePlanAction _:
        return ActionOutcome(true, count: await optimizeToday(repos, profile, now));

      case final CreateBudgetAction a:
        final start = a.period == BudgetPeriod.week ? Dates.startOfWeek(now) : Dates.startOfMonth(now);
        await repos.budgets.save(
          Budget(
            id: '${a.period.name}_${Dates.dayKey(start)}_${a.category?.name ?? 'all'}',
            updatedAt: now,
            period: a.period,
            periodStart: start,
            limitMinor: a.amountMinor,
            currency: profile.currency,
            category: a.category,
          ),
        );
        return const ActionOutcome(true, count: 1);

      case final AddExpenseAction a:
        await repos.transactions.save(
          MoneyTransaction(
            id: newId(),
            updatedAt: now,
            type: TransactionType.expense,
            amountMinor: a.amountMinor,
            currency: profile.currency,
            category: a.category,
            date: a.date,
            description: a.description,
            source: TransactionSource.ai,
          ),
        );
        return const ActionOutcome(true, count: 1);

      case final SetSavingsGoalAction a:
        await repos.profile.save(profile.copyWith(savingsGoalMinor: a.amountMinor));
        return const ActionOutcome(true, count: 1);

      case final GenerateMealPlanAction a:
        final pantry = a.usePantry ? (await repos.pantry.getAll()).map((p) => p.name) : const <String>[];
        final meals = const MealEngine().suggestDay(
          recipes: RecipeLibrary.all(languageCode),
          prefs: profile.food,
          pantry: pantry,
          day: a.date,
        );
        await repos.mealPlans.save(MealPlan(id: Dates.dayKey(a.date), updatedAt: now, meals: meals));
        return ActionOutcome(true, count: meals.length);

      case final AddShoppingItemsAction a:
        final n = await addShoppingItems(repos, a.items, now);
        return ActionOutcome(true, count: n);

      case final CreateHabitAction a:
        await repos.habits.save(
          Habit(id: newId(), updatedAt: now, name: a.name, type: a.type, targetPerDay: a.targetPerDay, createdAt: now),
        );
        return const ActionOutcome(true, count: 1);

      case final LogMoodAction a:
        await repos.moods.save(MoodLog(id: Dates.dayKey(now), updatedAt: now, mood: a.mood, note: a.note));
        return const ActionOutcome(true, count: 1);

      case final SaveMemoryAction a:
        final (r, _) = await memory.save(a.category, a.content);
        return ActionOutcome(r == MemorySaveResult.saved || r == MemorySaveResult.duplicate, detail: r.name);
    }
  }

  /// Adds items to the shopping list, skipping ones already unchecked on it.
  static Future<int> addShoppingItems(UserRepos repos, List<String> names, DateTime now) async {
    final existing = (await repos.shopping.getAll()).where((s) => !s.checked).map((s) => s.name.toLowerCase()).toSet();
    const cat = ShoppingCategorizer();
    var n = 0;
    for (final name in names) {
      if (existing.contains(name.toLowerCase())) continue;
      await repos.shopping.save(
        ShoppingItem(
          id: newId(),
          updatedAt: now,
          name: name,
          category: cat.categorize(name) ?? ShoppingCategory.other,
          createdAt: now,
        ),
      );
      existing.add(name.toLowerCase());
      n++;
    }
    return n;
  }

  /// Re-plans today's flexible tasks around fixed ones within the user's day.
  /// Returns how many tasks were scheduled.
  static Future<int> optimizeToday(UserRepos repos, UserProfile profile, DateTime now) async {
    final all = await repos.tasks.getAll();
    final today = Dates.dateOnly(now);
    bool isFlexible(TaskItem t) {
      if (t.isCompleted) return false;
      if (t.scheduledAt == null) {
        // Unscheduled tasks due today/overdue, or with no date at all.
        return t.deadline == null || !Dates.dateOnly(t.deadline!).isAfter(today);
      }
      // Previously auto-placed tasks today may be moved again; tasks with a
      // user-set time on another day are left alone.
      return false;
    }

    final flexible = all.where(isFlexible).toList();
    final fixed = all
        .where((t) => t.scheduledAt != null && Dates.sameDay(t.scheduledAt!, now) && !t.isCompleted)
        .toList();
    final wake = profile.wakeTime?.minutes ?? 8 * 60;
    final sleep = profile.sleepTime?.minutes ?? 23 * 60;
    final dayStart = today.add(Duration(minutes: wake + 30));
    final dayEnd = today.add(Duration(minutes: (sleep <= wake ? 23 * 60 : sleep) - 30));
    final slots = const PlanOptimizer().schedule(
      flexible: flexible,
      fixed: fixed,
      now: now,
      dayStart: dayStart,
      dayEnd: dayEnd,
    );
    for (final s in slots) {
      await repos.tasks.save(s.task.copyWith(scheduledAt: s.start));
    }
    return slots.length;
  }
}
