import '../../core/utils/dates.dart';
import '../models/enums.dart';
import '../models/money_models.dart';

/// Spending of one calendar month, with a comparison to the month before.
class MonthSummary {
  const MonthSummary({
    required this.month,
    required this.extraIncomeMinor,
    required this.spentMinor,
    required this.previousSpentMinor,
    required this.byCategory,
    required this.previousByCategory,
    required this.dailyAverageMinor,
    required this.biggest,
    required this.transactionCount,
  });

  /// First day of the month.
  final DateTime month;
  final int extraIncomeMinor;
  final int spentMinor;
  final int previousSpentMinor;
  final Map<ExpenseCategory, int> byCategory;
  final Map<ExpenseCategory, int> previousByCategory;

  /// Spent divided by the days elapsed (whole month for past months).
  final int dailyAverageMinor;

  /// The largest single expense of the month.
  final MoneyTransaction? biggest;
  final int transactionCount;

  /// Change vs. the previous month in percent (null without a previous month).
  int? get changePercent =>
      previousSpentMinor == 0 ? null : ((spentMinor - previousSpentMinor) * 100 / previousSpentMinor).round();

  /// Categories sorted by spend, largest first.
  List<MapEntry<ExpenseCategory, int>> get ranked =>
      byCategory.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
}

MonthSummary summarizeMonth(List<MoneyTransaction> all, DateTime month, DateTime now) {
  final start = Dates.startOfMonth(month);
  final prevStart = DateTime(start.year, start.month - 1);
  final next = DateTime(start.year, start.month + 1);
  var income = 0, spent = 0, prevSpent = 0, count = 0;
  final byCat = <ExpenseCategory, int>{}, prevByCat = <ExpenseCategory, int>{};
  MoneyTransaction? biggest;
  for (final t in all) {
    if (t.deleted) continue;
    final inMonth = !t.date.isBefore(start) && t.date.isBefore(next);
    final inPrev = !t.date.isBefore(prevStart) && t.date.isBefore(start);
    if (!inMonth && !inPrev) continue;
    if (!t.isExpense) {
      if (inMonth) income += t.amountMinor;
      continue;
    }
    if (inMonth) {
      count++;
      spent += t.amountMinor;
      byCat[t.category] = (byCat[t.category] ?? 0) + t.amountMinor;
      if (biggest == null || t.amountMinor > biggest.amountMinor) biggest = t;
    } else {
      prevSpent += t.amountMinor;
      prevByCat[t.category] = (prevByCat[t.category] ?? 0) + t.amountMinor;
    }
  }
  final current = now.year == start.year && now.month == start.month;
  final days = current ? now.day : Dates.daysInMonth(start);
  return MonthSummary(
    month: start,
    extraIncomeMinor: income,
    spentMinor: spent,
    previousSpentMinor: prevSpent,
    byCategory: byCat,
    previousByCategory: prevByCat,
    dailyAverageMinor: days == 0 ? 0 : spent ~/ days,
    biggest: biggest,
    transactionCount: count,
  );
}

enum BillState { paid, overdue, dueSoon, upcoming }

class BillStatus {
  const BillStatus(this.bill, this.due, this.state, this.daysLeft);
  final RecurringBill bill;
  final DateTime due;
  final BillState state;

  /// Days until due (negative when overdue).
  final int daysLeft;
}

/// This month's bills: unpaid overdue first, then by due date; paid last.
List<BillStatus> billsThisMonth(List<RecurringBill> bills, DateTime now) {
  final month = Dates.monthKey(now);
  final today = Dates.dateOnly(now);
  final out = [
    for (final b in bills.where((b) => !b.deleted))
      () {
        final due = b.dueIn(now);
        final left = Dates.daysBetween(today, due);
        final state = b.lastPaidMonth == month
            ? BillState.paid
            : left < 0
            ? BillState.overdue
            : left <= 3
            ? BillState.dueSoon
            : BillState.upcoming;
        return BillStatus(b, due, state, left);
      }(),
  ];
  out.sort((a, b) {
    if ((a.state == BillState.paid) != (b.state == BillState.paid)) return a.state == BillState.paid ? 1 : -1;
    return a.due.compareTo(b.due);
  });
  return out;
}

/// Total of the fixed-cost bills per month (used as the fixed-costs reserve;
/// bills in other categories count as daily spending when paid).
int billsMonthlyTotal(List<RecurringBill> bills) =>
    bills.where((b) => !b.deleted && b.category.isFixed).fold(0, (s, b) => s + b.amountMinor);

/// Unpaid bills still to come this month.
int billsUnpaidMinor(List<RecurringBill> bills, DateTime now) =>
    billsThisMonth(bills, now).where((s) => s.state != BillState.paid).fold(0, (sum, s) => sum + s.bill.amountMinor);
