import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/utils/dates.dart';
import 'package:lifeos/domain/care/meds.dart';
import 'package:lifeos/domain/engines/debts.dart';
import 'package:lifeos/domain/engines/subscriptions.dart';
import 'package:lifeos/domain/lio/daily_question.dart';
import 'package:lifeos/domain/models/care.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/money_models.dart';
import 'package:lifeos/services/notifications/notification_planner.dart';

final _t0 = DateTime(2026);

RecurringBill bill(String name, int major, [ExpenseCategory c = ExpenseCategory.bills]) =>
    RecurringBill(id: name, updatedAt: _t0, name: name, amountMinor: major * 100, category: c, dayOfMonth: 5);

MoneyTransaction tx(String desc, int major, DateTime date) => MoneyTransaction(
  id: '$desc$date',
  updatedAt: _t0,
  type: TransactionType.expense,
  amountMinor: major * 100,
  currency: 'USD',
  category: ExpenseCategory.other,
  description: desc,
  date: date,
);

Medication med(String name, List<String> times, {int? stock}) =>
    Medication(id: name, updatedAt: _t0, name: name, times: times, stock: stock, createdAt: _t0);

void main() {
  group('subscriptions', () {
    test('known names and the category count as subscriptions', () {
      final bills = [
        bill('Netflix', 15),
        bill('Rent', 900, ExpenseCategory.housing),
        bill('Gym', 30),
        bill('Cloud', 3, ExpenseCategory.subscriptions),
      ];
      expect(subscriptionsOf(bills).map((b) => b.name), ['Gym', 'Netflix', 'Cloud']);
      expect(subscriptionsMonthly(bills), 4800);
    });

    test('monthly repeats are found; groceries and saved bills are not', () {
      final now = DateTime(2026, 6, 20);
      final txs = [
        tx('Music Plus', 10, DateTime(2026, 4, 3)),
        tx('Music Plus', 10, DateTime(2026, 5, 3)),
        tx('Music Plus', 10, DateTime(2026, 6, 3)),
        tx('Market', 40, DateTime(2026, 5, 2)),
        tx('Market', 70, DateTime(2026, 6, 9)),
        tx('Market', 20, DateTime(2026, 6, 12)),
        tx('Netflix', 15, DateTime(2026, 6, 1)),
        tx('Spotify', 11, DateTime(2026, 6, 1)),
      ];
      final found = findSubscriptionCandidates(txs, [bill('Netflix', 15)], now);
      expect(found.map((c) => c.name), ['Spotify', 'Music Plus']);
      expect(found.last.months, 3);
      expect(found.last.dayOfMonth, 3);
    });
  });

  group('debts', () {
    test('split adds the tip and shares the cents fairly', () {
      final s = splitBill(10000, 3, tipPercent: 10);
      expect(s.totalMinor, 11000);
      expect(s.shares, [3667, 3667, 3666]);
      expect(s.shares.reduce((a, b) => a + b), 11000);
      expect(splitBill(500, 0).shares, [500]);
    });

    test('balances net out per person (case-insensitive), settled ones ignored', () {
      Debt d(String p, int major, bool theyOwe, {bool settled = false}) => Debt(
        id: '$p$major$theyOwe',
        updatedAt: _t0,
        person: p,
        amountMinor: major * 100,
        theyOwe: theyOwe,
        settledAt: settled ? _t0 : null,
        createdAt: _t0,
      );
      final debts = [
        d('Ali', 300, true),
        d('ali ', 100, false),
        d('Ayşe', 50, false),
        d('Can', 80, true, settled: true),
      ];
      expect(debtBalances(debts), [('Ali', 20000), ('Ayşe', -5000)]);
      expect(debtTotals(debts), (20000, 5000));
    });
  });

  group('medicines', () {
    test('doses for a day, what is due, and days of stock left', () {
      final m = med('Vitamin D', ['21:00', '09:00'], stock: 9);
      final restored = Medication.fromJson({
        ...m.toJson(),
        'id': m.id,
        'times': ['21:00', '09:00', '25:00'],
      });
      expect(restored.times, ['09:00', '21:00']);
      expect(restored.daysLeft, 4);
      expect(restored.needsRefill, isTrue);
      final now = DateTime(2026, 6, 1, 12);
      final taken = {MedDose.idFor('Vitamin D', '2026-06-01', '09:00')};
      final day = dosesOn(now, [restored], taken);
      expect(day.map((d) => (d.time, d.taken)), [('09:00', true), ('21:00', false)]);
      expect(dueDoses(now, [restored], {}).single.time, '09:00');
      expect(dueDoses(now, [restored], taken), isEmpty);
    });

    test('reminders for untaken doses, with a Done action id', () {
      final now = DateTime(2026, 6, 1, 12);
      final plan = const NotificationPlanner().plan(
        NotificationState(
          now: now,
          frequency: NotificationFrequency.low,
          dailyCap: 2,
          meds: [
            med('Iron', ['08:00', '23:30']),
          ],
          takenDoses: {MedDose.idFor('Iron', '2026-06-02', '08:00')},
        ),
      );
      final meds = plan.where((n) => n.kind == NotificationKind.medication).toList();
      // Today 23:30 (quiet hours do not apply) and tomorrow 23:30; tomorrow 08:00 is taken.
      expect(meds.map((n) => n.at), [DateTime(2026, 6, 1, 23, 30), DateTime(2026, 6, 2, 23, 30)]);
      expect(meds.first.taskId, '${medDonePrefix}Iron|2026-06-01|23:30');
      expect(meds.map((n) => n.id).toSet().length, 2);
    });
  });

  group('question of the day', () {
    test('every question comes once per cycle; options keep the right answer', () {
      final seen = <int>{};
      final start = DateTime(2026, 1, 1);
      for (var i = 0; i < quizBank.length; i++) {
        final q = DailyQuestion.forDay(Dates.addDays(start, i));
        seen.add(q.index);
        expect(q.options('en')[q.correct], q.item.optionsEn.first);
        expect(q.options('tr')[q.correct], q.item.options('tr').first);
        expect(q.hintHides, isNot(contains(q.correct)));
      }
      expect(seen.length, quizBank.length);
      for (final q in quizBank) {
        expect(q.optionsTr == null || q.optionsTr!.length == q.optionsEn.length, isTrue, reason: q.en);
        expect(q.optionsEn.toSet().length, q.optionsEn.length, reason: q.en);
      }
    });

    test('streak grows on right answers on consecutive days and resets', () {
      final d1 = DateTime(2026, 6, 1);
      var p = const QuizProgress();
      p = p.answerOn(d1, 0, right: true);
      expect(p.answerOn(d1, 1, right: false).streak, 1); // once a day
      p = p.answerOn(Dates.addDays(d1, 1), 2, right: true);
      expect(p.streak, 2);
      expect(p.correctTotal, 2);
      expect(p.streakOn(Dates.addDays(d1, 3)), 0); // a day missed
      p = p.answerOn(Dates.addDays(d1, 2), 1, right: false);
      expect(p.streak, 0);
      expect(p.correctTotal, 2);
    });
  });
}
