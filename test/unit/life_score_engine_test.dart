import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/engines/budget_engine.dart';
import 'package:lifeos/domain/engines/life_score_engine.dart';
import 'package:lifeos/domain/models/enums.dart';

import 'fixtures.dart';

BudgetSnapshot snap({required int safe, required int spentToday}) => BudgetSnapshot(
  incomeMinor: 0,
  spentMinor: spentToday,
  fixedSpentMinor: 0,
  variableSpentMinor: spentToday,
  spentTodayMinor: spentToday,
  remainingMinor: 0,
  savingsGoalMinor: 0,
  savingsOnTrack: true,
  safeDailyMinor: safe,
  remainingTodayMinor: safe - spentToday,
  daysLeftInMonth: 10,
  projectedMonthSpendMinor: 0,
  byCategory: const [],
);

void main() {
  const engine = LifeScoreEngine();
  final day = DateTime(2026, 6, 10);

  test('no data → no score (planning alone does not count)', () {
    final s = engine.compute(LifeScoreInput(day: day));
    expect(s.total, isNull);
    expect(s.hasData, isFalse);
  });

  test('missing components are excluded, not penalized', () {
    final s = engine.compute(LifeScoreInput(day: day, mood: 5));
    // mood 100 (w .10) + planning 0 (w .10) → 50.
    expect(s.components.keys, containsAll([ScoreComponent.mood, ScoreComponent.planning]));
    expect(s.components.containsKey(ScoreComponent.money), isFalse);
    expect(s.total, 50);
  });

  test('is deterministic and matches the weighted formula', () {
    final input = LifeScoreInput(
      day: day,
      budget: snap(safe: 50000, spentToday: 75000), // 50% over → 50
      habits: [
        habit('water', type: HabitType.water, target: 8),
        habit('read'),
      ],
      habitLogs: [log('water', '2026-06-10', 4), log('read', '2026-06-10', 1)],
      tasks: [
        task('a', scheduledAt: DateTime(2026, 6, 10, 9), completedAt: DateTime(2026, 6, 10, 10)),
        task('b', scheduledAt: DateTime(2026, 6, 10, 14)),
      ],
      mood: 4,
      sleepMinutes: 420,
      sleepTargetMinutes: 480,
      checkedInToday: true,
    );
    final a = engine.compute(input);
    final b = engine.compute(input);
    expect(a.total, b.total);
    expect(a.components[ScoreComponent.money], 50);
    expect(a.components[ScoreComponent.health], 50); // water 4/8
    expect(a.components[ScoreComponent.habits], 75); // (0.5 + 1)/2
    expect(a.components[ScoreComponent.productivity], 50);
    expect(a.components[ScoreComponent.mood], 80);
    expect(a.components[ScoreComponent.sleep], 90); // 30 min short of window → −10
    expect(a.components[ScoreComponent.planning], 100);
    // .2*50 + .15*50 + .2*50 + .15*75 + .1*80 + .1*90 + .1*100 = 65.75 → 66
    expect(a.total, 66);
  });

  test('money score boundaries', () {
    expect(LifeScoreEngine.moneyScore(snap(safe: 100, spentToday: 100)), 100);
    expect(LifeScoreEngine.moneyScore(snap(safe: 100, spentToday: 200)), 0);
    expect(LifeScoreEngine.moneyScore(snap(safe: 0, spentToday: 0)), 100);
    expect(LifeScoreEngine.moneyScore(snap(safe: 0, spentToday: 1)), 0);
    expect(LifeScoreEngine.moneyScore(null), isNull);
  });

  test('sleep score windows', () {
    expect(LifeScoreEngine.sleepScore(480, 480), 100);
    expect(LifeScoreEngine.sleepScore(450, 480), 100);
    expect(LifeScoreEngine.sleepScore(570, 480), 100);
    expect(LifeScoreEngine.sleepScore(330, 480), 60); // 2h short of window
    expect(LifeScoreEngine.sleepScore(0, 480), 0);
    expect(LifeScoreEngine.sleepScore(630, 480), 90); // 1h over window
  });

  test('overdue open tasks count against productivity', () {
    final p = LifeScoreEngine.productivityScore([
      task('old', deadline: DateTime(2026, 6, 1)),
      task('today', scheduledAt: DateTime(2026, 6, 10, 9), completedAt: DateTime(2026, 6, 10, 9, 30)),
    ], day);
    expect(p, 50);
  });

  test('explain picks the components that moved the score', () {
    final yesterday = LifeScore(
      total: 80,
      components: {ScoreComponent.money: 100, ScoreComponent.sleep: 100, ScoreComponent.mood: 60},
    );
    final today = LifeScore(
      total: 70,
      components: {ScoreComponent.money: 70, ScoreComponent.sleep: 80, ScoreComponent.mood: 80},
    );
    final e = engine.explain(today, yesterday);
    expect(e.totalDelta, -10);
    expect(e.topFactors.map((f) => f.component), [ScoreComponent.money, ScoreComponent.sleep]);
    expect(e.topFactors.every((f) => f.delta < 0), isTrue);
  });

  test('weakest component', () {
    final s = LifeScore(total: 70, components: {ScoreComponent.money: 90, ScoreComponent.sleep: 40});
    expect(engine.weakest(s), ScoreComponent.sleep);
  });
}
