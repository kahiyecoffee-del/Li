import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/utils/dates.dart';
import 'package:lifeos/domain/engines/daily_goals_engine.dart';
import 'package:lifeos/domain/engines/insight_engine.dart';
import 'package:lifeos/domain/engines/meal_engine.dart';
import 'package:lifeos/domain/engines/plan_optimizer.dart';
import 'package:lifeos/domain/engines/recipe_library.dart';
import 'package:lifeos/domain/engines/report_engine.dart';
import 'package:lifeos/domain/engines/streaks.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/progress.dart';
import 'package:lifeos/domain/models/user_profile.dart';
import 'package:lifeos/domain/models/wellbeing.dart';

import 'fixtures.dart';

void main() {
  group('StreakCalculator', () {
    const s = StreakCalculator();
    final today = DateTime(2026, 6, 10);

    test('current streak including today', () {
      final r = s.compute({'2026-06-08', '2026-06-09', '2026-06-10'}, today);
      expect(r.current, 3);
      expect(r.atRisk, isFalse);
    });

    test('streak alive but at risk when today not yet active', () {
      final r = s.compute({'2026-06-08', '2026-06-09'}, today);
      expect(r.current, 2);
      expect(r.atRisk, isTrue);
    });

    test('broken streak and best streak', () {
      final r = s.compute({'2026-05-01', '2026-05-02', '2026-05-03', '2026-05-04', '2026-06-01'}, today);
      expect(r.current, 0);
      expect(r.best, 4);
    });

    test('habit streak skips unscheduled days', () {
      // Weekdays only; 2026-06-06/07 is a weekend.
      final streak = s.habitStreak(
        completedDays: {'2026-06-04', '2026-06-05', '2026-06-08', '2026-06-09'},
        weekdays: {1, 2, 3, 4, 5},
        today: today,
      );
      expect(streak, 4);
    });

    test('streak works across DST and month boundaries', () {
      final r = s.compute({'2026-03-28', '2026-03-29', '2026-03-30', '2026-03-31', '2026-04-01'}, DateTime(2026, 4, 1));
      expect(r.current, 5);
    });
  });

  group('DailyGoalsEngine', () {
    const e = DailyGoalsEngine();
    test('builds 3–5 goals, deterministic', () {
      final input = DailyGoalsInput(
        day: DateTime(2026, 6, 10),
        focusAreas: {FocusArea.health},
        habits: [
          habit('read'),
          habit('water', type: HabitType.water, target: 8),
        ],
        habitLogs: [log('water', '2026-06-10', 8)],
      );
      final a = e.build(input);
      expect(a.length, inInclusiveRange(3, 5));
      expect(a.first.kind, GoalKind.habit);
      expect(a.first.habit!.id, 'water'); // health habits first
      expect(a.first.completed, isTrue);
      expect(e.build(input).map((g) => g.id), a.map((g) => g.id));
    });

    test('minimum goals even with no data', () {
      final g = e.build(DailyGoalsInput(day: DateTime(2026, 6, 10), focusAreas: const {}));
      expect(g.length, greaterThanOrEqualTo(3));
      expect(DailyGoalsEngine.progress(g), 0);
    });
  });

  group('InsightEngine', () {
    final now = DateTime(2026, 6, 28);
    test('weekly spend vs 4-week average', () {
      final tx = [for (var w = 1; w <= 4; w++) expense(1000, Dates.addDays(now, -7 * w - 1)), expense(1500, now)];
      expect(InsightEngine.weeklySpendVsAverage(tx, now), 50);
    });

    test('category change month over month', () {
      final tx = [expense(1000, DateTime(2026, 5, 10)), expense(1240, DateTime(2026, 6, 10))];
      final i = InsightEngine.biggestCategoryChange(tx, now)!;
      expect(i.category, ExpenseCategory.food);
      expect(i.percent, 24);
    });

    test('mood/sleep pattern needs enough data', () {
      MoodLog m(String d, int v) => MoodLog(id: d, updatedAt: epoch, mood: v);
      SleepLog sl(String d, int min) => SleepLog(id: d, updatedAt: epoch, minutes: min);
      final moods = [for (var d = 1; d <= 6; d++) m('2026-06-0$d', d <= 3 ? 2 : 4)];
      final sleeps = [for (var d = 1; d <= 6; d++) sl('2026-06-0$d', d <= 3 ? 300 : 480)];
      expect(InsightEngine.moodLowerOnShortSleep(moods, sleeps, 480), isTrue);
      expect(InsightEngine.moodLowerOnShortSleep(moods.take(4).toList(), sleeps, 480), isFalse);
    });
  });

  group('ReportEngine', () {
    test('weekly report numbers', () {
      final (from, to) = ReportEngine.weekOf(DateTime(2026, 6, 10));
      expect(from, DateTime(2026, 6, 8));
      final r = const ReportEngine().build(
        ReportInput(
          from: from,
          to: to,
          scores: [
            DailyScoreRecord(id: '2026-06-08', updatedAt: epoch, total: 78, components: const {}),
            DailyScoreRecord(id: '2026-06-14', updatedAt: epoch, total: 84, components: const {}),
          ],
          transactions: [expense(1000, DateTime(2026, 6, 2)), expense(800, DateTime(2026, 6, 9))],
          moods: [MoodLog(id: '2026-06-09', updatedAt: epoch, mood: 4)],
        ),
      );
      expect(r.scoreStart, 78);
      expect(r.scoreEnd, 84);
      expect(r.avgScore, 81);
      expect(r.spendChangePercent, -20);
      expect(r.savedVsPreviousMinor, 20000);
      expect(r.avgMoodOutOf10, 8);
      expect(r.suggestions, contains(Suggestion.startAHabit));
    });
  });

  group('PlanOptimizer', () {
    const o = PlanOptimizer();
    final now = DateTime(2026, 6, 10, 8, 50);

    test('prioritizes overdue, then due today, then priority', () {
      final list = o.prioritize([
        task('low', priority: TaskPriority.low),
        task('high', priority: TaskPriority.high),
        task('today', deadline: DateTime(2026, 6, 10)),
        task('overdue', deadline: DateTime(2026, 6, 1)),
        task('done', completedAt: now),
      ], now);
      expect(list.map((t) => t.id), ['overdue', 'today', 'high', 'low']);
    });

    test('schedules around fixed meetings', () {
      final slots = o.schedule(
        flexible: [task('a', minutes: 60), task('b', minutes: 30)],
        fixed: [task('meeting', scheduledAt: DateTime(2026, 6, 10, 9, 30), minutes: 60)],
        now: now,
        dayStart: DateTime(2026, 6, 10, 8),
        dayEnd: DateTime(2026, 6, 10, 22),
      );
      // Shorter b fills the 9:00–9:30 gap; a (60m) goes after meeting + buffer.
      expect(slots.first.task.id, 'b');
      expect(slots.first.start, DateTime(2026, 6, 10, 9));
      expect(slots.last.task.id, 'a');
      expect(slots.last.start, DateTime(2026, 6, 10, 10, 40));
    });
  });

  group('MealEngine', () {
    const e = MealEngine();
    final recipes = RecipeLibrary.all('en');

    test('pantry matching normalizes tr/en names', () {
      final m = e.matchPantry(recipes, ['Tavuk', 'pirinç', 'Domates', 'cucumber', 'yogurt']);
      final bowl = m.firstWhere((x) => x.recipe.id == 'chicken_bowl');
      expect(bowl.makeable, isTrue);
    });

    test('diet and allergy filters', () {
      final vegan = e.eligible(recipes, const FoodPreferences(diet: 'vegan'));
      expect(vegan.every((r) => r.tags.contains('vegan')), isTrue);
      final noEgg = e.eligible(recipes, const FoodPreferences(allergies: ['eggs']));
      expect(noEgg.any((r) => r.ingredients.contains('egg')), isFalse);
    });

    test('daily suggestions: one per meal, stable within a day', () {
      final a = e.suggestDay(
        recipes: recipes,
        prefs: const FoodPreferences(),
        pantry: const [],
        day: DateTime(2026, 6, 10),
      );
      final b = e.suggestDay(
        recipes: recipes,
        prefs: const FoodPreferences(),
        pantry: const [],
        day: DateTime(2026, 6, 10),
      );
      expect(a.map((r) => r.mealType), [MealType.breakfast, MealType.lunch, MealType.dinner]);
      expect(a.map((r) => r.id), b.map((r) => r.id));
    });
  });
}
