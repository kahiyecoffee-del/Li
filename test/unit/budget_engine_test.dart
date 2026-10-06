import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/utils/money.dart';
import 'package:lifeos/domain/engines/budget_engine.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/money_models.dart';

import 'fixtures.dart';

void main() {
  const engine = BudgetEngine();
  const plan = BudgetPlan(monthlyIncomeMinor: 3000000, fixedExpensesMinor: 1000000, savingsGoalMinor: 500000);

  group('safe daily spending', () {
    test('splits the discretionary pool evenly on day 1 with no spending', () {
      // 30,000 − 10,000 fixed − 5,000 savings = 15,000 over 30 days = 500/day.
      final s = engine.compute(plan: plan, transactions: const [], now: DateTime(2026, 6, 1, 9));
      expect(s.safeDailyMinor, 50000);
      expect(s.daysLeftInMonth, 30);
      expect(s.remainingMinor, 1500000);
      expect(s.savingsOnTrack, isTrue);
    });

    test('earlier variable spending reduces the allowance; today does not', () {
      final now = DateTime(2026, 6, 11, 12);
      final s = engine.compute(
        plan: plan,
        now: now,
        transactions: [
          expense(4000, DateTime(2026, 6, 5)), // before today
          expense(300, DateTime(2026, 6, 11, 8)), // today
        ],
      );
      // (15,000 − 4,000) / 20 days left = 550.
      expect(s.safeDailyMinor, 55000);
      expect(s.spentTodayMinor, 30000);
      expect(s.remainingTodayMinor, 25000);
      expect(s.spentMinor, 430000);
    });

    test('logged fixed costs do not double count against the plan', () {
      final s = engine.compute(
        plan: plan,
        now: DateTime(2026, 6, 1),
        transactions: [expense(8000, DateTime(2026, 6, 1), ExpenseCategory.housing)],
      );
      // Fixed plan 10,000 still reserved (8,000 paid + 2,000 outstanding).
      expect(s.safeDailyMinor, 50000);
      expect(s.fixedSpentMinor, 800000);
      expect(s.remainingMinor, 1500000);
    });

    test('fixed overspend beyond plan reduces the pool', () {
      final s = engine.compute(
        plan: plan,
        now: DateTime(2026, 6, 1),
        transactions: [expense(13000, DateTime(2026, 6, 1), ExpenseCategory.bills)],
      );
      // pool = 30,000 − 5,000 − 13,000 = 12,000 / 30 = 400.
      expect(s.safeDailyMinor, 40000);
    });

    test('extra income increases the pool', () {
      final s = engine.compute(
        plan: plan,
        now: DateTime(2026, 6, 1),
        transactions: [income(3000, DateTime(2026, 6, 1))],
      );
      expect(s.incomeMinor, 3300000);
      expect(s.safeDailyMinor, 60000);
    });

    test('never negative when overspent, and flags savings at risk', () {
      final s = engine.compute(
        plan: plan,
        now: DateTime(2026, 6, 20),
        transactions: [expense(20000, DateTime(2026, 6, 2))],
      );
      expect(s.safeDailyMinor, 0);
      expect(s.savingsOnTrack, isFalse);
      expect(s.remainingMinor, lessThan(0));
      expect(s.isTight, isTrue);
    });

    test('ignores other months and deleted entries', () {
      final deleted = expense(9000, DateTime(2026, 6, 2)).copyWith(deleted: true);
      final s = engine.compute(
        plan: plan,
        now: DateTime(2026, 6, 1),
        transactions: [expense(9000, DateTime(2026, 5, 31)), expense(9000, DateTime(2026, 7, 1)), deleted],
      );
      expect(s.spentMinor, 0);
    });

    test('last day of month gets the whole remaining pool', () {
      final s = engine.compute(
        plan: plan,
        now: DateTime(2026, 6, 30, 23),
        transactions: [expense(14000, DateTime(2026, 6, 10))],
      );
      expect(s.daysLeftInMonth, 1);
      expect(s.safeDailyMinor, 100000);
    });

    test('weekly total budget caps the daily allowance', () {
      final weekStart = DateTime(2026, 6, 8); // Monday
      final budget = Budget(
        id: 'w',
        updatedAt: epoch,
        period: BudgetPeriod.week,
        periodStart: weekStart,
        limitMinor: 210000,
        currency: 'TRY',
      );
      final s = engine.compute(
        plan: plan,
        now: DateTime(2026, 6, 10, 10), // Wednesday
        budgets: [budget],
        transactions: [expense(600, DateTime(2026, 6, 8))],
      );
      // Week: (2,100 − 600) / 5 days left = 300 < monthly 15,000−600/21 ≈ 685.
      expect(s.safeDailyMinor, 30000);
      expect(s.weeklyRemainingMinor, 150000);
    });

    test('category breakdown sorted by spend with limits', () {
      final limit = Budget(
        id: 'c',
        updatedAt: epoch,
        period: BudgetPeriod.month,
        periodStart: DateTime(2026, 6),
        limitMinor: 100000,
        currency: 'TRY',
        category: ExpenseCategory.entertainment,
      );
      final s = engine.compute(
        plan: plan,
        now: DateTime(2026, 6, 15),
        budgets: [limit],
        transactions: [
          expense(100, DateTime(2026, 6, 2)),
          expense(500, DateTime(2026, 6, 3), ExpenseCategory.transport),
        ],
      );
      expect(s.byCategory.first.category, ExpenseCategory.transport);
      expect(s.byCategory.any((c) => c.category == ExpenseCategory.entertainment && c.limitMinor == 100000), isTrue);
    });
  });

  group('Money.parseMinor', () {
    test('handles locale formats', () {
      expect(Money.parseMinor('250'), 25000);
      expect(Money.parseMinor('250.5'), 25050);
      expect(Money.parseMinor('1,250.75'), 125075);
      expect(Money.parseMinor('1.250,75'), 125075);
      expect(Money.parseMinor('₺1.250'), 125000);
      expect(Money.parseMinor('abc'), isNull);
    });
  });
}
