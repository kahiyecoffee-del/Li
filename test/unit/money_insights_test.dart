import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/engines/budget_engine.dart';
import 'package:lifeos/domain/engines/money_insights.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/money_models.dart';
import 'package:lifeos/services/notifications/notification_planner.dart';

import 'fixtures.dart';

void main() {
  final t0 = DateTime(2026);
  RecurringBill bill(String id, int day, {String? paid, ExpenseCategory c = ExpenseCategory.bills}) => RecurringBill(
    id: id,
    updatedAt: t0,
    name: id,
    amountMinor: 50000,
    category: c,
    dayOfMonth: day,
    lastPaidMonth: paid,
  );

  test('month summary compares with last month and finds the biggest expense', () {
    final s = summarizeMonth(
      [
        expense(100, DateTime(2026, 6, 2)),
        expense(300, DateTime(2026, 6, 9), ExpenseCategory.transport),
        expense(200, DateTime(2026, 5, 20)),
      ],
      DateTime(2026, 6, 15),
      DateTime(2026, 6, 10),
    );
    expect(s.spentMinor, 40000);
    expect(s.previousSpentMinor, 20000);
    expect(s.changePercent, 100);
    expect(s.dailyAverageMinor, 4000); // 400 over 10 days so far
    expect(s.biggest!.category, ExpenseCategory.transport);
    expect(s.ranked.first.key, ExpenseCategory.transport);
  });

  test('bills: overdue first, then by due date, paid last; day 31 fits short months', () {
    final now = DateTime(2026, 2, 10);
    final list = billsThisMonth([
      bill('rent', 1, paid: '2026-02'),
      bill('phone', 25),
      bill('gym', 31),
      bill('power', 5),
      bill('net', 12),
    ], now);
    expect(list.map((s) => s.bill.id), ['power', 'net', 'phone', 'gym', 'rent']);
    expect(list.first.state, BillState.overdue);
    expect(list[1].state, BillState.dueSoon);
    expect(list[3].due, DateTime(2026, 2, 28));
    expect(list.last.state, BillState.paid);
    expect(billsUnpaidMinor([bill('a', 1, paid: '2026-02'), bill('b', 20)], now), 50000);
    // Only fixed-cost bills are reserved from the budget.
    expect(billsMonthlyTotal([bill('a', 1), bill('bus', 1, c: ExpenseCategory.transport)]), 50000);
  });

  test('savings jar: monthly amount needed to reach the target in time', () {
    final g = SavingsGoal(
      id: 'g',
      updatedAt: t0,
      name: 'Holiday',
      targetMinor: 1200000,
      savedMinor: 200000,
      deadline: DateTime(2026, 10, 1),
      createdAt: t0,
    );
    // 10,000 left over Jun..Oct = 5 months → 2,000/month.
    expect(g.monthlyNeededMinor(DateTime(2026, 6, 15)), 200000);
    expect(g.progress, closeTo(1 / 6, 0.001));
  });

  test('limits repeat: last month\'s category limit and an old weekly limit still apply', () {
    const plan = BudgetPlan(monthlyIncomeMinor: 3000000, fixedExpensesMinor: 1000000, savingsGoalMinor: 500000);
    final s = const BudgetEngine().compute(
      plan: plan,
      now: DateTime(2026, 7, 15),
      transactions: [expense(100, DateTime(2026, 7, 2))],
      budgets: [
        Budget(
          id: 'c',
          updatedAt: t0,
          period: BudgetPeriod.month,
          periodStart: DateTime(2026, 5),
          limitMinor: 80000,
          currency: 'TRY',
          category: ExpenseCategory.food,
        ),
        Budget(
          id: 'w',
          updatedAt: t0,
          period: BudgetPeriod.week,
          periodStart: DateTime(2026, 6, 1),
          limitMinor: 70000,
          currency: 'TRY',
        ),
      ],
    );
    expect(s.byCategory.firstWhere((c) => c.category == ExpenseCategory.food).limitMinor, 80000);
    expect(s.activeWeeklyLimitMinor, 70000);
    expect(s.safeDailyMinor, lessThanOrEqualTo(70000 ~/ 5 + 1));
  });

  test('monthly total limit caps the daily allowance', () {
    const plan = BudgetPlan(monthlyIncomeMinor: 3000000);
    final s = const BudgetEngine().compute(
      plan: plan,
      now: DateTime(2026, 6, 1),
      transactions: const [],
      budgets: [
        Budget(
          id: 'm',
          updatedAt: t0,
          period: BudgetPeriod.month,
          periodStart: DateTime(2026, 6),
          limitMinor: 300000,
          currency: 'TRY',
        ),
      ],
    );
    expect(s.safeDailyMinor, 10000); // 3,000 / 30 days
  });

  test('bill reminders: the day before and on the day, not once paid', () {
    final plan = const NotificationPlanner().plan(
      NotificationState(
        now: DateTime(2026, 6, 9, 8),
        frequency: NotificationFrequency.low,
        dailyCap: 2,
        bills: [
          bill('Rent', 10),
          bill('Paid', 10, paid: '2026-06'),
        ],
      ),
    );
    final bills = plan.where((n) => n.kind == NotificationKind.billDue).toList();
    expect(bills.map((n) => n.at), [DateTime(2026, 6, 9, 10), DateTime(2026, 6, 10, 10)]);
    expect(bills.every((n) => n.title == 'Rent'), isTrue);
  });
}
