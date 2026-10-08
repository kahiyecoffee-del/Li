import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/dates.dart';
import '../core/utils/ids.dart';
import '../data/repositories/user_repos.dart';
import '../domain/models/enums.dart';
import '../domain/models/food.dart';
import '../domain/models/habit.dart';
import '../domain/models/money_models.dart';
import '../domain/models/progress.dart';
import '../domain/models/task_item.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/wellbeing.dart';
import '../domain/models/routine_goal.dart';
import '../domain/plan/day_timeline.dart';
import '../domain/plan/routines.dart';
import '../services/ai/ai_action_executor.dart';
import '../services/analytics/analytics_service.dart';
import 'ml_providers.dart';
import 'providers.dart';

/// Write use-cases shared by all screens. Each one persists locally (so it
/// works offline) and logs the matching analytics event.
class AppActions {
  AppActions(this._ref);

  final Ref _ref;

  UserRepos get _repos => _ref.read(reposProvider);
  AnalyticsService get _analytics => _ref.read(servicesProvider).analytics;
  DateTime get _now => _ref.read(clockProvider)();
  UserProfile get _profile => _ref.read(profileProvider).value ?? UserProfile.empty();

  Future<void> saveProfile(UserProfile p) => _repos.profile.save(p);

  // Money ------------------------------------------------------------------
  Future<MoneyTransaction> addTransaction({
    required int amountMinor,
    required ExpenseCategory category,
    String description = '',
    DateTime? date,
    TransactionType type = TransactionType.expense,
    TransactionSource source = TransactionSource.manual,
    String? merchant,
  }) async {
    final t = MoneyTransaction(
      id: newId(),
      updatedAt: _now,
      type: type,
      amountMinor: amountMinor,
      currency: _profile.currency,
      category: category,
      date: date ?? _now,
      description: description,
      merchant: merchant,
      source: source,
    );
    await _repos.transactions.save(t);
    unawaited(
      _analytics.log(AnalyticsEvent.expenseAdded, {
        'category': category.name,
        'source': source.name,
        'type': type.name,
      }),
    );
    return t;
  }

  Future<void> deleteTransaction(String id) => _repos.transactions.delete(id);

  Future<void> restore(MoneyTransaction t) => _repos.transactions.save(t);

  Future<void> saveBudget({required BudgetPeriod period, required int limitMinor, ExpenseCategory? category}) async {
    final start = period == BudgetPeriod.week ? Dates.startOfWeek(_now) : Dates.startOfMonth(_now);
    await _repos.budgets.save(
      Budget(
        id: '${period.name}_${Dates.dayKey(start)}_${category?.name ?? 'all'}',
        updatedAt: _now,
        period: period,
        periodStart: start,
        limitMinor: limitMinor,
        currency: _profile.currency,
        category: category,
      ),
    );
    unawaited(_analytics.log(AnalyticsEvent.budgetCreated, {'period': period.name}));
  }

  Future<void> deleteBudget(String id) => _repos.budgets.delete(id);

  Future<void> saveSavingsGoal(SavingsGoal g) => _repos.savingsGoals.save(g);

  Future<void> deleteSavingsGoal(String id) => _repos.savingsGoals.delete(id);

  /// Puts [amountMinor] into (or, when negative, takes it out of) a jar.
  Future<SavingsGoal> addToSavingsGoal(SavingsGoal g, int amountMinor) async {
    final next = g.copyWith(savedMinor: (g.savedMinor + amountMinor).clamp(0, 1 << 40));
    await _repos.savingsGoals.save(next);
    unawaited(_analytics.log(AnalyticsEvent.savingsGoalUpdated, {'reached': next.reached}));
    return next;
  }

  Future<void> saveBill(RecurringBill b) => _repos.bills.save(b);

  Future<void> deleteBill(String id) => _repos.bills.delete(id);

  /// Logs the bill as this month's expense and marks it paid.
  Future<void> payBill(RecurringBill b) async {
    await addTransaction(amountMinor: b.amountMinor, category: b.category, description: b.name);
    await _repos.bills.save(b.copyWith(lastPaidMonth: Dates.monthKey(_now)));
  }

  // Tasks ------------------------------------------------------------------
  Future<void> saveTask(TaskItem t, {required bool isNew}) async {
    await _repos.tasks.save(t);
    if (isNew) unawaited(_analytics.log(AnalyticsEvent.taskCreated, {'priority': t.priority.name}));
  }

  /// Toggles completion. Completing a recurring task creates its next
  /// occurrence so the series continues.
  Future<bool> toggleTask(TaskItem t) async {
    if (t.isCompleted) {
      await _repos.tasks.save(t.copyWith(clearCompleted: true));
      return false;
    }
    await _repos.tasks.save(t.copyWith(completedAt: _now));
    unawaited(_analytics.log(AnalyticsEvent.taskCompleted));
    if (t.recurrence != Recurrence.none) {
      DateTime? shift(DateTime? d) => d == null
          ? null
          : switch (t.recurrence) {
              Recurrence.daily => Dates.addDays(d, 1),
              Recurrence.weekly => Dates.addDays(d, 7),
              Recurrence.monthly => DateTime(d.year, d.month + 1, d.day, d.hour, d.minute),
              Recurrence.none => d,
            };
      final base = t.anchorDate ?? _now;
      await _repos.tasks.save(
        TaskItem(
          id: newId(),
          updatedAt: _now,
          title: t.title,
          priority: t.priority,
          estimatedMinutes: t.estimatedMinutes,
          category: t.category,
          scheduledAt: shift(t.scheduledAt),
          deadline: t.scheduledAt == null ? shift(t.deadline ?? base) : null,
          recurrence: t.recurrence,
          createdAt: _now,
        ),
      );
      return true;
    }
    return false;
  }

  Future<void> deleteTask(String id) => _repos.tasks.delete(id);

  /// Creates a task from the quick-add line on [day].
  Future<TaskItem> addQuickTask(QuickTask q, DateTime day) async {
    final at = q.hasTime ? DateTime(day.year, day.month, day.day, q.hour!, q.minute) : null;
    final t = TaskItem(
      id: newId(),
      updatedAt: _now,
      title: q.title,
      estimatedMinutes: q.minutes ?? 30,
      scheduledAt: at,
      deadline: at == null ? Dates.dateOnly(day) : null,
      createdAt: _now,
    );
    await saveTask(t, isNew: true);
    return t;
  }

  // Routines & goals -----------------------------------------------------
  Future<void> saveRoutine(Routine r) => _repos.routines.save(r);

  Future<void> deleteRoutine(String id) => _repos.routines.delete(id);

  /// Adds the routine's steps to [day] as back-to-back tasks.
  Future<int> applyRoutine(Routine r, DateTime day, int startMinutes) async {
    final tasks = routineTasks(r, day, startMinutes, now: _now, newId: newId);
    for (final t in tasks) {
      await _repos.tasks.save(t);
    }
    unawaited(_analytics.log(AnalyticsEvent.taskCreated, {'source': 'routine', 'count': tasks.length}));
    return tasks.length;
  }

  Future<void> saveLifeGoal(LifeGoal g) => _repos.lifeGoals.save(g);

  Future<void> deleteLifeGoal(String id) => _repos.lifeGoals.delete(id);

  /// Turns a goal step into a task on [day] and links it.
  Future<void> planGoalStep(LifeGoal g, GoalStep step, DateTime day) async {
    final t = await addQuickTask(QuickTask(step.title), day);
    await _repos.lifeGoals.save(
      g.copyWith(steps: [for (final s in g.steps) s.id == step.id ? s.copyWith(taskId: t.id) : s]),
    );
  }

  /// Puts [t] at [start] (keeps its length).
  Future<void> scheduleTask(TaskItem t, DateTime start) =>
      _repos.tasks.save(t.copyWith(scheduledAt: start, clearDeadline: true));

  /// Moves [t] one day later (same time when it had one).
  Future<void> postponeTask(TaskItem t, DateTime from) {
    final s = t.scheduledAt;
    return _repos.tasks.save(
      s != null
          ? t.copyWith(scheduledAt: Dates.addDays(s, 1))
          : t.copyWith(deadline: Dates.addDays(Dates.dateOnly(from), 1)),
    );
  }

  /// Brings an overdue task to [day] (keeps the time of day if it had one).
  Future<void> moveTaskTo(TaskItem t, DateTime day) {
    final s = t.scheduledAt;
    return _repos.tasks.save(
      s != null
          ? t.copyWith(scheduledAt: DateTime(day.year, day.month, day.day, s.hour, s.minute))
          : t.copyWith(deadline: Dates.dateOnly(day)),
    );
  }

  Future<int> optimizePlan() async {
    final n = await AiActionExecutor.optimizeToday(_repos, _profile, _now);
    unawaited(_analytics.log(AnalyticsEvent.planOptimized, {'count': n}));
    return n;
  }

  // Habits -----------------------------------------------------------------
  Future<void> saveHabit(Habit h, {required bool isNew}) async {
    await _repos.habits.save(h);
    if (isNew) unawaited(_analytics.log(AnalyticsEvent.habitCreated, {'type': h.type.name}));
  }

  Future<void> deleteHabit(String id) => _repos.habits.delete(id);

  /// Adds [delta] to today's count for [habit] (clamped at 0).
  Future<void> logHabit(Habit habit, int delta, {DateTime? day}) async {
    final key = Dates.dayKey(day ?? _now);
    final id = HabitLog.idFor(habit.id, key);
    final cur = await _repos.habitLogs.get(id);
    final next = ((cur?.count ?? 0) + delta).clamp(0, 999);
    await _repos.habitLogs.save(HabitLog(id: id, updatedAt: _now, habitId: habit.id, day: key, count: next));
    if ((cur?.count ?? 0) < habit.targetPerDay && next >= habit.targetPerDay) {
      unawaited(_analytics.log(AnalyticsEvent.habitCompleted, {'type': habit.type.name}));
    }
  }

  // Wellbeing --------------------------------------------------------------
  Future<void> logMood(int mood, {String? note}) async {
    final n = note?.trim();
    await _repos.moods.save(
      MoodLog(id: Dates.dayKey(_now), updatedAt: _now, mood: mood, note: n == null || n.isEmpty ? null : n),
    );
    unawaited(_analytics.log(AnalyticsEvent.moodLogged));
  }

  Future<void> logSleep(int minutes) =>
      _repos.sleeps.save(SleepLog(id: Dates.dayKey(_now), updatedAt: _now, minutes: minutes));

  Future<void> addJournal(String text) async {
    await _repos.journal.save(JournalEntry(id: newId(), updatedAt: _now, createdAt: _now, text: text.trim()));
    unawaited(_analytics.log(AnalyticsEvent.journalEntryAdded));
  }

  Future<void> deleteJournal(String id) => _repos.journal.delete(id);

  // Goals ------------------------------------------------------------------
  Future<void> toggleManualGoal(String goalId, bool completed) async {
    final key = Dates.dayKey(_now);
    final cur = await _repos.goals.get(key);
    final ids = {...?cur?.completedGoalIds};
    completed ? ids.add(goalId) : ids.remove(goalId);
    await _repos.goals.save(DailyGoalsRecord(id: key, updatedAt: _now, completedGoalIds: ids));
    if (completed) unawaited(_analytics.log(AnalyticsEvent.dailyGoalCompleted, {'goal': goalId.split(':').first}));
  }

  // Food -------------------------------------------------------------------
  Future<void> saveMealPlan(DateTime day, List<Recipe> meals, {required bool ai}) async {
    await _repos.mealPlans.save(MealPlan(id: Dates.dayKey(day), updatedAt: _now, meals: meals));
    unawaited(_analytics.log(AnalyticsEvent.mealGenerated, {'source': ai ? 'ai' : 'local'}));
  }

  /// Puts [r] in the [slot] meal of [day] (replacing what was there). [base]
  /// is what the day showed before when nothing was saved yet (suggestions).
  Future<void> setMeal(DateTime day, MealType slot, Recipe r, {List<Recipe> base = const []}) async {
    final current = (await _repos.mealPlans.get(Dates.dayKey(day)))?.meals ?? base;
    final picked = r.mealType == slot ? r : Recipe.fromJson({...r.toJson(), 'mealType': slot.name});
    final meals = [...current.where((m) => m.mealType != slot), picked]
      ..sort((a, b) => a.mealType.index.compareTo(b.mealType.index));
    await _repos.mealPlans.save(MealPlan(id: Dates.dayKey(day), updatedAt: _now, meals: meals));
    unawaited(_analytics.log(AnalyticsEvent.mealGenerated, {'source': 'manual'}));
  }

  Future<void> removeMeal(DateTime day, MealType slot, {List<Recipe> base = const []}) async {
    final current = (await _repos.mealPlans.get(Dates.dayKey(day)))?.meals ?? base;
    await _repos.mealPlans.save(
      MealPlan(id: Dates.dayKey(day), updatedAt: _now, meals: current.where((m) => m.mealType != slot).toList()),
    );
  }

  Future<void> addPantryItems(Iterable<String> names) async {
    final existing = (await _repos.pantry.getAll()).map((p) => p.name.toLowerCase()).toSet();
    for (final n in names.map((e) => e.trim()).where((e) => e.isNotEmpty)) {
      if (existing.add(n.toLowerCase())) {
        await _repos.pantry.save(PantryItem(id: newId(), updatedAt: _now, name: n));
      }
    }
  }

  Future<void> deletePantryItem(String id) => _repos.pantry.delete(id);

  Future<int> addShoppingItems(List<String> names) async {
    final n = await AiActionExecutor.addShoppingItems(
      _repos,
      names,
      _now,
      cat: _ref.read(localModelsNowProvider).shoppingCategorizer,
    );
    if (n > 0) unawaited(_analytics.log(AnalyticsEvent.shoppingItemAdded, {'count': n}));
    return n;
  }

  Future<void> toggleShopping(ShoppingItem i) => _repos.shopping.save(i.copyWith(checked: !i.checked));

  Future<void> clearCheckedShopping() async {
    for (final i in await _repos.shopping.getAll()) {
      if (i.checked) await _repos.shopping.delete(i.id);
    }
  }
}

final actionsProvider = Provider<AppActions>(AppActions.new);
