import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/utils/dates.dart';
import 'package:lifeos/domain/engines/recipe_library.dart';
import 'package:lifeos/domain/lio/lio_advisor.dart';
import 'package:lifeos/domain/models/money_models.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/wellbeing.dart';

import 'fixtures.dart';

void main() {
  const advisor = LioAdvisor();
  final now = DateTime(2026, 10, 20, 19, 0);
  List<AdviceKind> kinds(AdvisorInput i) => advisor.advise(i).map((a) => a.kind).toList();

  test('nothing entered → nothing invented', () {
    expect(kinds(AdvisorInput(now: DateTime(2026, 10, 20, 15))), isEmpty);
  });

  test('overdue tasks and an unplanned morning lead to planning', () {
    final morning = DateTime(2026, 10, 20, 9);
    final a = advisor.advise(
      AdvisorInput(
        now: morning,
        tasks: [task('report', deadline: DateTime(2026, 10, 18))],
      ),
    );
    expect(a.first.kind, AdviceKind.overdueTasks);
    expect(a.first.count, 1);
    expect(a.map((x) => x.kind), contains(AdviceKind.noPlanToday));
  });

  test('a habit streak about to break in the evening', () {
    final h = habit('Water', target: 1);
    final logs = [for (var d = 1; d <= 4; d++) log('Water', Dates.dayKey(Dates.addDays(now, -d)), 1)];
    final a = advisor.advise(AdvisorInput(now: now, habits: [h], habitLogs: logs));
    final risk = a.firstWhere((x) => x.kind == AdviceKind.habitAtRisk);
    expect(risk.name, 'Water');
    expect(risk.count, 4);
  });

  test('subscriptions: same description and amount in different months', () {
    MoneyTransaction sub(String d, int major, DateTime when) => MoneyTransaction(
      id: '$d$when',
      updatedAt: when,
      type: TransactionType.expense,
      amountMinor: major * 100,
      currency: 'TRY',
      category: ExpenseCategory.subscriptions,
      date: when,
      description: d,
    );
    final tx = [
      sub('Netflix', 230, DateTime(2026, 8, 12)),
      sub('Netflix', 230, DateTime(2026, 9, 12)),
      sub('Spotify', 100, DateTime(2026, 9, 3)),
      sub('Spotify', 100, DateTime(2026, 10, 3)),
      sub('Market', 450, DateTime(2026, 10, 1)),
      sub('Market', 380, DateTime(2026, 9, 1)),
      for (var k = 0; k < 4; k++) expense(10, DateTime(2026, 10, 10 + k)),
    ];
    final a = advisor.advise(AdvisorInput(now: now, transactions: tx));
    final s = a.firstWhere((x) => x.kind == AdviceKind.subscriptions);
    expect(s.count, 2);
    expect(s.amountMinor, (230 + 100) * 12 * 100);
    expect(a.map((x) => x.kind), contains(AdviceKind.setUpBudget));
  });

  test('mood trending down and a quiet journal', () {
    MoodLog mood(int daysAgo, int m) =>
        MoodLog(id: Dates.dayKey(Dates.addDays(now, -daysAgo)), updatedAt: now, mood: m);
    final moods = [for (var d = 0; d < 7; d++) mood(d, 2), for (var d = 7; d < 14; d++) mood(d, 4)];
    final k = kinds(AdvisorInput(now: now, moods: moods, journalDates: [DateTime(2026, 10, 10)]));
    expect(k, containsAll([AdviceKind.moodDown, AdviceKind.journalNudge]));
  });

  test('journal streak is praised instead of nudged', () {
    final k = kinds(AdvisorInput(now: now, journalDates: [for (var d = 0; d < 4; d++) Dates.addDays(now, -d)]));
    expect(k, [AdviceKind.journalStreak]);
  });

  test('pantry with everything for a recipe suggests cooking it', () {
    final a = advisor.advise(
      AdvisorInput(
        now: DateTime(2026, 10, 20, 15),
        pantry: const ['egg', 'cheese', 'butter'],
        recipes: RecipeLibrary.all('en'),
      ),
    );
    expect(a.single.kind, AdviceKind.cookFromPantry);
    expect(a.single.name, isNotEmpty);
  });
}
