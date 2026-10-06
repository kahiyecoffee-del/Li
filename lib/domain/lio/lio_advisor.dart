import 'dart:math' as math;

import '../../core/utils/dates.dart';
import '../engines/budget_engine.dart';
import '../engines/insight_engine.dart';
import '../engines/meal_engine.dart';
import '../models/enums.dart';
import '../models/food.dart';
import '../models/habit.dart';
import '../models/money_models.dart';
import '../models/task_item.dart';
import '../models/wellbeing.dart';
import 'journal_learner.dart';

/// Which part of life a suggestion is about (icon, colour, where it leads).
enum AdviceArea { money, plan, habits, wellbeing, journal, food }

enum AdviceKind {
  overBudgetToday,
  budgetTight,
  savingsOffTrack,
  setUpBudget,
  weeklySpendUp,
  weeklySpendDown,
  categorySpike,
  subscriptions,
  topCategory,
  overdueTasks,
  noPlanToday,
  unscheduledToday,
  tasksGoingWell,
  habitAtRisk,
  habitRateDown,
  habitRateUp,
  moodDown,
  moodShortSleep,
  journalNudge,
  journalStreak,
  journalLift,
  journalDrain,
  shoppingPending,
  cookFromPantry,
}

/// One data-backed suggestion. Numbers are computed here; the UI turns
/// [kind] and the values into a sentence and a button.
class Advice {
  const Advice(
    this.kind,
    this.area, {
    required this.priority,
    this.amountMinor,
    this.percent,
    this.count,
    this.name,
    this.category,
  });

  final AdviceKind kind;
  final AdviceArea area;

  /// Higher shows first.
  final int priority;
  final int? amountMinor;
  final int? percent;
  final int? count;
  final String? name;
  final ExpenseCategory? category;
}

class AdvisorInput {
  const AdvisorInput({
    required this.now,
    this.budget,
    this.hasIncome = false,
    this.transactions = const [],
    this.tasks = const [],
    this.habits = const [],
    this.habitLogs = const [],
    this.moods = const [],
    this.sleeps = const [],
    this.sleepTargetMinutes = 480,
    this.journalDates = const [],
    this.shopping = const [],
    this.pantry = const [],
    this.recipes = const [],
    this.journalProfile,
  });

  final DateTime now;
  final BudgetSnapshot? budget;
  final bool hasIncome;
  final List<MoneyTransaction> transactions;
  final List<TaskItem> tasks;
  final List<Habit> habits;
  final List<HabitLog> habitLogs;
  final List<MoodLog> moods;
  final List<SleepLog> sleeps;
  final int sleepTargetMinutes;

  /// When each journal entry was written (entries stay encrypted).
  final List<DateTime> journalDates;
  final List<ShoppingItem> shopping;
  final List<String> pantry;
  final List<Recipe> recipes;

  /// Patterns learned from the journal (null when the user turned it off).
  final JournalProfile? journalProfile;
}

/// Lio's advisor: looks across everything the user has entered and returns
/// the few things worth saying today, most useful first. Rule-based and
/// explainable — every suggestion comes from the user's own numbers.
class LioAdvisor {
  const LioAdvisor();

  List<Advice> advise(AdvisorInput i) {
    final out = <Advice>[..._money(i), ..._plan(i), ..._habits(i), ..._wellbeing(i), ..._journal(i), ..._food(i)]
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return out;
  }

  // ---------------------------------------------------------------- money

  List<Advice> _money(AdvisorInput i) {
    final out = <Advice>[];
    final b = i.budget;
    final expenses = i.transactions.where((t) => !t.deleted && t.isExpense).toList();
    if (b != null) {
      if (b.overToday) {
        out.add(
          Advice(AdviceKind.overBudgetToday, AdviceArea.money, priority: 100, amountMinor: -b.remainingTodayMinor),
        );
      } else if (b.isTight) {
        out.add(Advice(AdviceKind.budgetTight, AdviceArea.money, priority: 90, amountMinor: b.remainingTodayMinor));
      }
      final allowed = b.incomeMinor - b.savingsGoalMinor;
      final gap = b.projectedMonthSpendMinor - allowed;
      if (b.savingsGoalMinor > 0 && i.now.day >= 7 && gap > 0) {
        out.add(Advice(AdviceKind.savingsOffTrack, AdviceArea.money, priority: 85, amountMinor: gap));
      }
      final month = b.byCategory.where((c) => !c.category.isFixed && c.amountMinor > 0).toList();
      final total = month.fold<int>(0, (s, c) => s + c.amountMinor);
      if (total > 0) {
        final top = month.reduce((a, c) => c.amountMinor > a.amountMinor ? c : a);
        final share = (top.amountMinor * 100 / total).round();
        if (share >= 35 && month.length >= 2) {
          out.add(
            Advice(
              AdviceKind.topCategory,
              AdviceArea.money,
              priority: 30,
              category: top.category,
              percent: share,
              amountMinor: top.amountMinor,
            ),
          );
        }
      }
    } else if (!i.hasIncome && expenses.length >= 5) {
      out.add(const Advice(AdviceKind.setUpBudget, AdviceArea.money, priority: 40));
    }

    final weekly = InsightEngine.weeklySpendVsAverage(i.transactions, i.now);
    if (weekly != null && weekly >= 15) {
      out.add(Advice(AdviceKind.weeklySpendUp, AdviceArea.money, priority: 70, percent: weekly));
    } else if (weekly != null && weekly <= -15) {
      out.add(Advice(AdviceKind.weeklySpendDown, AdviceArea.money, priority: 35, percent: -weekly));
    }

    final cat = InsightEngine.biggestCategoryChange(i.transactions, i.now);
    if (cat != null && cat.percent >= 25) {
      out.add(
        Advice(AdviceKind.categorySpike, AdviceArea.money, priority: 65, percent: cat.percent, category: cat.category),
      );
    }

    final subs = subscriptions(expenses, i.now);
    if (subs.isNotEmpty) {
      final monthly = subs.fold<int>(0, (s, x) => s + x.$2);
      out.add(
        Advice(
          AdviceKind.subscriptions,
          AdviceArea.money,
          priority: 45,
          count: subs.length,
          amountMinor: monthly * 12,
          name: subs.map((x) => x.$1).join(', '),
        ),
      );
    }
    return out;
  }

  /// Payments with the same description and amount in at least two
  /// different months of the last ~100 days: likely subscriptions.
  /// Returns (description, monthly amount).
  static List<(String, int)> subscriptions(List<MoneyTransaction> expenses, DateTime now) {
    final since = Dates.addDays(Dates.dateOnly(now), -100);
    final months = <String, Set<String>>{};
    final shown = <String, String>{};
    for (final t in expenses) {
      if (t.date.isBefore(since)) continue;
      final d = t.description.trim();
      if (d.length < 2) continue;
      final key = '${d.toLowerCase()}|${t.amountMinor}';
      (months[key] ??= {}).add('${t.date.year}-${t.date.month}');
      shown[key] = d;
    }
    return [
      for (final e in months.entries)
        if (e.value.length >= 2) (shown[e.key]!, int.parse(e.key.split('|').last)),
    ];
  }

  // ---------------------------------------------------------------- plan

  List<Advice> _plan(AdvisorInput i) {
    final out = <Advice>[];
    final today = Dates.dateOnly(i.now);
    final open = i.tasks.where((t) => !t.deleted && !t.isCompleted).toList();
    final overdue = open.where((t) => t.anchorDate != null && Dates.dateOnly(t.anchorDate!).isBefore(today)).length;
    if (overdue > 0) out.add(Advice(AdviceKind.overdueTasks, AdviceArea.plan, priority: 75, count: overdue));

    final todays = open.where((t) => t.anchorDate != null && Dates.sameDay(t.anchorDate!, today)).toList();
    if (todays.isEmpty && i.now.hour < 14) {
      out.add(const Advice(AdviceKind.noPlanToday, AdviceArea.plan, priority: 55));
    }
    final loose = todays.where((t) => t.scheduledAt == null).length;
    if (loose >= 2) out.add(Advice(AdviceKind.unscheduledToday, AdviceArea.plan, priority: 50, count: loose));

    final weekAgo = Dates.addDays(today, -7);
    final done = i.tasks.where((t) => !t.deleted && t.completedAt != null && !t.completedAt!.isBefore(weekAgo)).length;
    final due = i.tasks
        .where(
          (t) =>
              !t.deleted && t.anchorDate != null && !t.anchorDate!.isBefore(weekAgo) && t.anchorDate!.isBefore(today),
        )
        .length;
    if (done >= 5 && (due == 0 || done / due >= 0.7)) {
      out.add(Advice(AdviceKind.tasksGoingWell, AdviceArea.plan, priority: 20, count: done));
    }
    return out;
  }

  // ---------------------------------------------------------------- habits

  List<Advice> _habits(AdvisorInput i) {
    final out = <Advice>[];
    final today = Dates.dateOnly(i.now);
    final counts = {
      for (final l in i.habitLogs)
        if (!l.deleted) l.id: l.count,
    };
    bool met(Habit h, DateTime d) => (counts[HabitLog.idFor(h.id, Dates.dayKey(d))] ?? 0) >= h.targetPerDay;
    if (i.now.hour >= 17) {
      Habit? best;
      var bestStreak = 0;
      for (final h in i.habits.where((h) => !h.deleted && !h.archived && h.isScheduledOn(today))) {
        if (met(h, today)) continue;
        var streak = 0;
        for (var d = Dates.addDays(today, -1); streak < 365; d = Dates.addDays(d, -1)) {
          if (!h.isScheduledOn(d)) continue;
          if (!met(h, d)) break;
          streak++;
        }
        if (streak >= 3 && streak > bestStreak) {
          best = h;
          bestStreak = streak;
        }
      }
      if (best != null) {
        out.add(Advice(AdviceKind.habitAtRisk, AdviceArea.habits, priority: 80, name: best.name, count: bestStreak));
      }
    }
    final change = InsightEngine.habitRateChange(i.habits, i.habitLogs, i.now);
    if (change != null && change <= -15) {
      out.add(Advice(AdviceKind.habitRateDown, AdviceArea.habits, priority: 45, percent: -change));
    } else if (change != null && change >= 15) {
      out.add(Advice(AdviceKind.habitRateUp, AdviceArea.habits, priority: 25, percent: change));
    }
    return out;
  }

  // ---------------------------------------------------------------- wellbeing

  List<Advice> _wellbeing(AdvisorInput i) {
    final out = <Advice>[];
    final today = Dates.dateOnly(i.now);
    double? avg(int fromDaysAgo, int toDaysAgo) {
      final from = Dates.addDays(today, -fromDaysAgo);
      final to = Dates.addDays(today, -toDaysAgo);
      final xs = i.moods
          .where((m) => !m.deleted)
          .where((m) {
            final d = Dates.parseDayKey(m.id);
            return !d.isBefore(from) && !d.isAfter(to);
          })
          .map((m) => m.mood)
          .toList();
      return xs.length < 3 ? null : xs.reduce((a, b) => a + b) / xs.length;
    }

    final recent = avg(6, 0), before = avg(13, 7);
    if (recent != null && before != null && before - recent >= 0.7) {
      out.add(const Advice(AdviceKind.moodDown, AdviceArea.wellbeing, priority: 70));
    }
    if (InsightEngine.moodLowerOnShortSleep(i.moods, i.sleeps, i.sleepTargetMinutes)) {
      out.add(const Advice(AdviceKind.moodShortSleep, AdviceArea.wellbeing, priority: 40));
    }
    return out;
  }

  // ---------------------------------------------------------------- journal

  List<Advice> _journal(AdvisorInput i) => [..._journalHabit(i), ..._journalPatterns(i)];

  List<Advice> _journalPatterns(AdvisorInput i) {
    final p = i.journalProfile;
    if (p == null) return const [];
    return [
      if (p.drains.isNotEmpty)
        Advice(AdviceKind.journalDrain, AdviceArea.journal, priority: 38, name: p.drains.first.word),
      if (p.lifts.isNotEmpty)
        Advice(AdviceKind.journalLift, AdviceArea.journal, priority: 33, name: p.lifts.first.word),
    ];
  }

  List<Advice> _journalHabit(AdvisorInput i) {
    final today = Dates.dateOnly(i.now);
    final days = i.journalDates.map(Dates.dateOnly).toSet();
    var streak = 0;
    for (var d = days.contains(today) ? today : Dates.addDays(today, -1); days.contains(d); d = Dates.addDays(d, -1)) {
      streak++;
    }
    if (streak >= 3) return [Advice(AdviceKind.journalStreak, AdviceArea.journal, priority: 22, count: streak)];
    final last = days.isEmpty ? null : days.reduce((a, b) => a.isAfter(b) ? a : b);
    final quiet = last == null || today.difference(last).inDays >= 3;
    if (quiet && i.now.hour >= 18 && !days.contains(today)) {
      return const [Advice(AdviceKind.journalNudge, AdviceArea.journal, priority: 35)];
    }
    return const [];
  }

  // ---------------------------------------------------------------- food

  List<Advice> _food(AdvisorInput i) {
    final out = <Advice>[];
    final open = i.shopping.where((s) => !s.deleted && !s.checked).length;
    if (open >= 3) out.add(Advice(AdviceKind.shoppingPending, AdviceArea.food, priority: 25, count: open));
    if (i.pantry.length >= 3 && i.recipes.isNotEmpty) {
      final best = bestForIngredients(i.recipes, i.pantry, limit: 1);
      if (best.isNotEmpty && best.first.missing.isEmpty) {
        out.add(
          Advice(
            AdviceKind.cookFromPantry,
            AdviceArea.food,
            priority: 30,
            name: best.first.recipe.name,
            count: math.max(1, best.first.recipe.prepMinutes),
          ),
        );
      }
    }
    return out;
  }
}
