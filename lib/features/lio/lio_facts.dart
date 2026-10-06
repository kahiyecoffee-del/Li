import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/meal_engine.dart';
import '../../domain/engines/recipe_library.dart';
import '../../domain/lio/lio_brain.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/user_profile.dart';

/// Today's facts Lio talks about (plan, budget, score, a meal idea), read
/// from live app data. Works with both `Ref.read` and `WidgetRef.read`.
LioFacts buildLioFacts(T Function<T>(ProviderListenable<T>) read, Locale loc) {
  final fmt = Fmt(loc.toLanguageTag(), read(profileProvider).value?.currency ?? 'USD');
  final now = DateTime.now();
  final today = read(todayProvider);
  final tasks =
      read(tasksProvider).list.where((t) => t.anchorDate != null && Dates.sameDay(t.anchorDate!, today)).toList()
        ..sort((a, b) => (a.scheduledAt ?? DateTime(9999)).compareTo(b.scheduledAt ?? DateTime(9999)));
  final b = read(budgetSnapshotProvider);
  final goals = read(dailyGoalsProvider);
  final profile = read(profileProvider).value ?? UserProfile.empty();
  final mealType = now.hour < 10 ? MealType.breakfast : (now.hour < 15 ? MealType.lunch : MealType.dinner);
  final meal = const MealEngine()
      .suggestDay(
        recipes: RecipeLibrary.all(loc.languageCode),
        prefs: profile.food,
        pantry: read(pantryProvider).list.map((p) => p.name),
        day: now,
        types: [mealType],
      )
      .firstOrNull;
  return LioFacts(
    name: profile.name,
    todayTasks: [
      for (final t in tasks) (t.title, t.scheduledAt == null ? null : fmt.time(t.scheduledAt!), t.isCompleted),
    ],
    safeDaily: b == null ? null : fmt.money(b.safeDailyMinor),
    leftToday: b == null || b.overToday ? null : fmt.money(b.remainingTodayMinor),
    overToday: b != null && b.overToday ? fmt.money(-b.remainingTodayMinor) : null,
    score: read(lifeScoreProvider).score.total,
    goalsLeft: goals.where((g) => !g.completed).length,
    streak: read(streakProvider).current,
    mealName: meal?.name,
    mealMinutes: meal?.prepMinutes,
    hour: now.hour,
  );
}
