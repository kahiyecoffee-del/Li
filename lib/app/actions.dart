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
