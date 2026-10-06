import '../../core/utils/dates.dart';
import '../models/enums.dart';
import '../models/money_models.dart';

/// Inputs describing the user's monthly money plan.
class BudgetPlan {
  const BudgetPlan({required this.monthlyIncomeMinor, this.fixedExpensesMinor = 0, this.savingsGoalMinor = 0});

  final int monthlyIncomeMinor;

  /// Expected recurring costs (rent, bills, subscriptions).
  final int fixedExpensesMinor;
  final int savingsGoalMinor;
}

class CategorySpend {
  const CategorySpend(this.category, this.amountMinor, this.limitMinor);

  final ExpenseCategory category;
  final int amountMinor;
  final int? limitMinor;
}

/// Result of a budget calculation for a given "today".
class BudgetSnapshot {
  const BudgetSnapshot({
    required this.incomeMinor,
    required this.spentMinor,
    required this.fixedSpentMinor,
    required this.variableSpentMinor,
    required this.spentTodayMinor,
    required this.remainingMinor,
    required this.savingsGoalMinor,
    required this.savingsOnTrack,
    required this.safeDailyMinor,
    required this.remainingTodayMinor,
    required this.daysLeftInMonth,
    required this.projectedMonthSpendMinor,
    required this.byCategory,
    this.activeWeeklyLimitMinor,
    this.weeklyRemainingMinor,
  });

  /// Planned monthly income plus any extra income logged this month.
  final int incomeMinor;
  final int spentMinor;
  final int fixedSpentMinor;
  final int variableSpentMinor;
  final int spentTodayMinor;

  /// Money still available this month after reserving unpaid fixed costs and
  /// the savings goal. Can be negative when overspent.
  final int remainingMinor;
  final int savingsGoalMinor;

  /// Whether the savings goal is still reachable at the current spend.
  final bool savingsOnTrack;

  /// How much the user can spend per day (today included) for the rest of the
  /// month and still meet the plan. Never negative.
  final int safeDailyMinor;

  /// Today's allowance minus today's variable spending (can be negative).
  final int remainingTodayMinor;
  final int daysLeftInMonth;

  /// Linear projection of month-end variable + fixed spend.
  final int projectedMonthSpendMinor;
  final List<CategorySpend> byCategory;
  final int? activeWeeklyLimitMinor;
  final int? weeklyRemainingMinor;

  bool get overToday => remainingTodayMinor < 0;

  /// "Tight" when less than 20% of today's allowance is left.
  bool get isTight => safeDailyMinor == 0 || remainingTodayMinor * 5 < safeDailyMinor;
}

/// Deterministic budgeting maths. See docs/ARCHITECTURE.md § Budget engine.
///
/// Model:
/// * Fixed categories (housing, bills, subscriptions) draw from the fixed
///   bucket; unpaid fixed costs stay reserved until logged.
/// * Discretionary pool = income + extra income − savings goal − max(fixed
///   plan, fixed actually spent).
/// * Safe daily = (pool − variable spent before today) / days left incl. today.
/// * An active weekly total budget further caps the daily allowance to
///   (weekly limit − week spend before today) / days left in that week.
class BudgetEngine {
  const BudgetEngine();

  BudgetSnapshot compute({
    required BudgetPlan plan,
    required List<MoneyTransaction> transactions,
    required DateTime now,
    List<Budget> budgets = const [],
  }) {
    final monthStart = Dates.startOfMonth(now);
    final monthEnd = Dates.startOfNextMonth(now);
    final today = Dates.dateOnly(now);

    var extraIncome = 0;
    var fixedSpent = 0;
    var variableSpent = 0;
    var variableBeforeToday = 0;
    var spentToday = 0;
    final byCat = <ExpenseCategory, int>{};

    for (final t in transactions) {
      if (t.deleted || t.date.isBefore(monthStart) || !t.date.isBefore(monthEnd)) continue;
      if (t.type == TransactionType.income) {
        extraIncome += t.amountMinor;
        continue;
      }
      byCat[t.category] = (byCat[t.category] ?? 0) + t.amountMinor;
      final isToday = Dates.sameDay(t.date, today);
      if (t.category.isFixed) {
        fixedSpent += t.amountMinor;
      } else {
        variableSpent += t.amountMinor;
        if (isToday) {
          spentToday += t.amountMinor;
        } else if (t.date.isBefore(today)) {
          variableBeforeToday += t.amountMinor;
        }
      }
    }

    final income = plan.monthlyIncomeMinor + extraIncome;
    final fixedReserved = plan.fixedExpensesMinor > fixedSpent ? plan.fixedExpensesMinor - fixedSpent : 0;
    final fixedCost = fixedSpent + fixedReserved;
    final pool = income - plan.savingsGoalMinor - fixedCost;

    final daysInMonth = Dates.daysInMonth(now);
    final daysLeft = daysInMonth - now.day + 1;

    var safeDaily = _divFloor(pool - variableBeforeToday, daysLeft);

    int? weeklyLimit;
    int? weeklyRemaining;
    // Limits repeat: the latest weekly total limit set in any earlier week
    // applies to this week too (same for monthly limits below).
    final weekly = _latest(budgets.where((b) => b.period == BudgetPeriod.week && b.category == null), now);
    if (weekly != null) {
      final w = Budget(
        id: weekly.id,
        updatedAt: weekly.updatedAt,
        period: BudgetPeriod.week,
        periodStart: Dates.startOfWeek(now),
        limitMinor: weekly.limitMinor,
        currency: weekly.currency,
      );
      weeklyLimit = w.limitMinor;
      var weekBeforeToday = 0;
      var weekTotal = 0;
      for (final t in transactions) {
        if (t.deleted || !t.isExpense || t.category.isFixed || !w.covers(t.date)) continue;
        weekTotal += t.amountMinor;
        if (t.date.isBefore(today)) weekBeforeToday += t.amountMinor;
      }
      weeklyRemaining = w.limitMinor - weekTotal;
      final daysLeftInWeek = Dates.daysBetween(today, w.periodEnd).clamp(1, 7);
      final weeklyDaily = _divFloor(w.limitMinor - weekBeforeToday, daysLeftInWeek);
      if (weeklyDaily < safeDaily) safeDaily = weeklyDaily;
    }
    final monthlyTotal = _latest(budgets.where((b) => b.period == BudgetPeriod.month && b.category == null), now);
    if (monthlyTotal != null) {
      final capDaily = _divFloor(monthlyTotal.limitMinor - variableBeforeToday, daysLeft);
      if (capDaily < safeDaily) safeDaily = capDaily;
    }
    if (safeDaily < 0) safeDaily = 0;

    final remaining = income - fixedCost - variableSpent - plan.savingsGoalMinor;
    final daysElapsed = now.day;
    final projectedVariable = daysElapsed == 0 ? variableSpent : (variableSpent * daysInMonth) ~/ daysElapsed;

    final limits = <ExpenseCategory, int>{
      for (final c in ExpenseCategory.values)
        if (_latest(budgets.where((b) => b.period == BudgetPeriod.month && b.category == c), now) case final b?)
          c: b.limitMinor,
    };
    final categories =
        ExpenseCategory.values
            .where((c) => (byCat[c] ?? 0) > 0 || limits.containsKey(c))
            .map((c) => CategorySpend(c, byCat[c] ?? 0, limits[c]))
            .toList()
          ..sort((a, b) => b.amountMinor.compareTo(a.amountMinor));

    return BudgetSnapshot(
      incomeMinor: income,
      spentMinor: fixedSpent + variableSpent,
      fixedSpentMinor: fixedSpent,
      variableSpentMinor: variableSpent,
      spentTodayMinor: spentToday,
      remainingMinor: remaining,
      savingsGoalMinor: plan.savingsGoalMinor,
      savingsOnTrack: remaining >= 0,
      safeDailyMinor: safeDaily,
      remainingTodayMinor: safeDaily - spentToday,
      daysLeftInMonth: daysLeft,
      projectedMonthSpendMinor: fixedCost + projectedVariable,
      byCategory: categories,
      activeWeeklyLimitMinor: weeklyLimit,
      weeklyRemainingMinor: weeklyRemaining,
    );
  }

  /// The most recently set limit that started on or before [now].
  static Budget? _latest(Iterable<Budget> budgets, DateTime now) {
    Budget? best;
    for (final b in budgets) {
      if (b.deleted || b.periodStart.isAfter(now)) continue;
      if (best == null ||
          b.periodStart.isAfter(best.periodStart) ||
          (b.periodStart == best.periodStart && b.updatedAt.isAfter(best.updatedAt))) {
        best = b;
      }
    }
    return best;
  }

  /// Floor division that rounds toward negative infinity (Dart's `~/`
  /// truncates toward zero).
  static int _divFloor(int a, int b) {
    final q = a ~/ b;
    return (a % b != 0 && (a < 0) != (b < 0)) ? q - 1 : q;
  }
}
