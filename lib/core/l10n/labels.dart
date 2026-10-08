import 'package:flutter/widgets.dart';

import '../../domain/engines/badge_engine.dart';
import '../../domain/engines/daily_goals_engine.dart';
import '../../domain/engines/insight_engine.dart';
import '../../domain/engines/life_score_engine.dart';
import '../../domain/engines/report_engine.dart';
import '../../domain/models/enums.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../services/notifications/notification_planner.dart';
import '../../services/settings/app_settings.dart';
import '../../services/weather/weather_service.dart';
import '../errors/app_failure.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localized labels for domain enums and engine outputs. Keeping them here
/// means engines stay free of UI and locale concerns.
extension Labels on AppLocalizations {
  String expenseCategory(ExpenseCategory c) => switch (c) {
    ExpenseCategory.housing => catHousing,
    ExpenseCategory.food => catFood,
    ExpenseCategory.transport => catTransport,
    ExpenseCategory.shopping => catShopping,
    ExpenseCategory.bills => catBills,
    ExpenseCategory.entertainment => catEntertainment,
    ExpenseCategory.health => catHealth,
    ExpenseCategory.subscriptions => catSubscriptions,
    ExpenseCategory.other => catOther,
  };

  String focusArea(FocusArea f) => switch (f) {
    FocusArea.money => focusMoney,
    FocusArea.health => focusHealth,
    FocusArea.productivity => focusProductivity,
    FocusArea.food => focusFood,
    FocusArea.habits => focusHabits,
    FocusArea.planning => focusPlanning,
  };

  String scoreComponent(ScoreComponent c) => switch (c) {
    ScoreComponent.money => scoreComponentMoney,
    ScoreComponent.health => scoreComponentHealth,
    ScoreComponent.productivity => scoreComponentProductivity,
    ScoreComponent.habits => scoreComponentHabits,
    ScoreComponent.mood => scoreComponentMood,
    ScoreComponent.sleep => scoreComponentSleep,
    ScoreComponent.planning => scoreComponentPlanning,
  };

  String scoreReason(ScoreFactor f) {
    final up = f.delta > 0;
    return switch (f.component) {
      ScoreComponent.money => up ? reasonMoneyUp : reasonMoneyDown,
      ScoreComponent.health => up ? reasonHealthUp : reasonHealthDown,
      ScoreComponent.productivity => up ? reasonProductivityUp : reasonProductivityDown,
      ScoreComponent.habits => up ? reasonHabitsUp : reasonHabitsDown,
      ScoreComponent.mood => up ? reasonMoodUp : reasonMoodDown,
      ScoreComponent.sleep => up ? reasonSleepUp : reasonSleepDown,
      ScoreComponent.planning => up ? reasonPlanningUp : reasonPlanningDown,
    };
  }

  /// Deterministic sentence explaining the day's score change.
  String scoreExplanation(ScoreExplanation e, {required bool hasPrevious}) {
    if (!hasPrevious) return scoreFirstDay;
    if (e.totalDelta == 0 || e.topFactors.isEmpty) return scoreSame;
    final reasons = e.topFactors.map(scoreReason).toList();
    final joined = reasons.length == 1 ? reasons.first : reasonAnd(reasons[0], reasons[1]);
    return e.totalDelta > 0 ? scoreUp(e.totalDelta, joined) : scoreDown(-e.totalDelta, joined);
  }

  String priorityLabel(TaskPriority p) => switch (p) {
    TaskPriority.low => priorityLow,
    TaskPriority.medium => priorityMedium,
    TaskPriority.high => priorityHigh,
  };

  String recurrence(Recurrence r) => switch (r) {
    Recurrence.none => repeatNone,
    Recurrence.daily => repeatDaily,
    Recurrence.weekly => repeatWeekly,
    Recurrence.monthly => repeatMonthly,
  };

  String taskCategoryLabel(TaskCategory c) => switch (c) {
    TaskCategory.work => taskCatWork,
    TaskCategory.personal => taskCatPersonal,
    TaskCategory.health => taskCatHealth,
    TaskCategory.errands => taskCatErrands,
    TaskCategory.learning => taskCatLearning,
    TaskCategory.social => taskCatSocial,
    TaskCategory.other => taskCatOther,
  };

  String habitType(HabitType t) => switch (t) {
    HabitType.water => habitWater,
    HabitType.reading => habitReading,
    HabitType.exercise => habitExercise,
    HabitType.meditation => habitMeditation,
    HabitType.sleep => habitSleep,
    HabitType.custom => habitCustom,
  };

  String mood(int m) => switch (m) {
    5 => moodGreat,
    4 => moodGood,
    3 => moodOkay,
    2 => moodLow,
    _ => moodBad,
  };

  String mealType(MealType t) => switch (t) {
    MealType.breakfast => foodMealBreakfast,
    MealType.lunch => foodMealLunch,
    MealType.dinner => foodMealDinner,
    MealType.snack => foodMealSnack,
  };

  String difficulty(Difficulty d) => switch (d) {
    Difficulty.easy => foodDifficultyEasy,
    Difficulty.medium => foodDifficultyMedium,
    Difficulty.hard => foodDifficultyHard,
  };

  String cookingSkill(CookingSkill s) => switch (s) {
    CookingSkill.beginner => skillBeginner,
    CookingSkill.intermediate => skillIntermediate,
    CookingSkill.advanced => skillAdvanced,
  };

  String foodBudgetLabel(FoodBudget b) => switch (b) {
    FoodBudget.low => budgetLow,
    FoodBudget.medium => budgetMedium,
    FoodBudget.high => budgetHigh,
  };

  String diet(String d) => switch (d) {
    'vegetarian' => dietVegetarian,
    'vegan' => dietVegan,
    'pescatarian' => dietPescatarian,
    'keto' => dietKeto,
    'halal' => dietHalal,
    'glutenFree' => dietGlutenFree,
    _ => dietNone,
  };

  String shoppingCategory(ShoppingCategory c) => switch (c) {
    ShoppingCategory.produce => shopProduce,
    ShoppingCategory.meat => shopMeat,
    ShoppingCategory.dairy => shopDairy,
    ShoppingCategory.bakery => shopBakery,
    ShoppingCategory.pantry => shopPantry,
    ShoppingCategory.frozen => shopFrozen,
    ShoppingCategory.drinks => shopDrinks,
    ShoppingCategory.household => shopHousehold,
    ShoppingCategory.personalCare => shopPersonalCare,
    ShoppingCategory.other => shopOther,
  };

  String memoryCategory(MemoryCategory c) => switch (c) {
    MemoryCategory.preferences => memCatPreferences,
    MemoryCategory.goals => memCatGoals,
    MemoryCategory.habits => memCatHabits,
    MemoryCategory.food => memCatFood,
    MemoryCategory.budget => memCatBudget,
    MemoryCategory.schedule => memCatSchedule,
  };

  String budgetPeriod(BudgetPeriod p) => p == BudgetPeriod.week ? budgetPeriodWeek : budgetPeriodMonth;

  String notificationFrequency(NotificationFrequency f) => switch (f) {
    NotificationFrequency.off => notifOff,
    NotificationFrequency.low => notifLow,
    NotificationFrequency.normal => notifNormal,
  };

  String weather(WeatherCondition c) => switch (c) {
    WeatherCondition.clear => weatherClear,
    WeatherCondition.partlyCloudy => weatherPartlyCloudy,
    WeatherCondition.cloudy => weatherCloudy,
    WeatherCondition.fog => weatherFog,
    WeatherCondition.drizzle => weatherDrizzle,
    WeatherCondition.rain => weatherRain,
    WeatherCondition.snow => weatherSnow,
    WeatherCondition.thunderstorm => weatherThunder,
  };

  String newsTopic(String t) => switch (t) {
    'nation' => newsTopicNation,
    'health' => newsTopicHealth,
    'technology' => newsTopicTechnology,
    'finance' => newsTopicFinance,
    'sports' => newsTopicSports,
    'world' => newsTopicWorld,
    'science' => newsTopicScience,
    'entertainment' => newsTopicEntertainment,
    _ => t,
  };

  String scopeLong(AiDataScope s) => switch (s) {
    AiDataScope.money => scopeMoney,
    AiDataScope.tasks => scopeTasks,
    AiDataScope.habits => scopeHabits,
    AiDataScope.mood => scopeMood,
    AiDataScope.food => scopeFood,
    AiDataScope.journal => scopeJournal,
  };

  String scopeShort(AiDataScope s) => switch (s) {
    AiDataScope.money => scopeShortMoney,
    AiDataScope.tasks => scopeShortTasks,
    AiDataScope.habits => scopeShortHabits,
    AiDataScope.mood => scopeShortMood,
    AiDataScope.food => scopeShortFood,
    AiDataScope.journal => scopeShortJournal,
  };

  String insightText(Insight i) => switch (i.kind) {
    InsightKind.weeklySpendVsAverage => i.percent >= 0 ? insightWeeklyUp(i.percent) : insightWeeklyDown(-i.percent),
    InsightKind.categorySpendChange =>
      i.percent >= 0
          ? insightCategoryUp(i.percent, expenseCategory(i.category ?? ExpenseCategory.other).toLowerCase())
          : insightCategoryDown(-i.percent, expenseCategory(i.category ?? ExpenseCategory.other).toLowerCase()),
    InsightKind.habitRateChange => i.percent >= 0 ? insightHabitUp(i.percent) : insightHabitDown(-i.percent),
    InsightKind.moodLowerOnShortSleep => insightMoodSleep,
    InsightKind.budgetTight => insightBudgetTight,
  };

  String suggestion(Suggestion s, {ExpenseCategory? category}) => switch (s) {
    Suggestion.reduceCategorySpend => suggestReduceCategory(
      expenseCategory(category ?? ExpenseCategory.other).toLowerCase(),
    ),
    Suggestion.sleepEarlier => suggestSleepEarlier,
    Suggestion.keepHabitStreak => suggestKeepStreak,
    Suggestion.planMoreTasks => suggestPlanMore,
    Suggestion.logMoodDaily => suggestLogMood,
    Suggestion.startAHabit => suggestStartHabit,
  };

  (String, String) badge(BadgeId b) => switch (b) {
    BadgeId.firstWeek => (badgeFirstWeek, badgeFirstWeekDesc),
    BadgeId.budgetMaster => (badgeBudgetMaster, badgeBudgetMasterDesc),
    BadgeId.sevenDayStreak => (badgeStreak, badgeStreakDesc),
    BadgeId.healthyWeek => (badgeHealthyWeek, badgeHealthyWeekDesc),
    BadgeId.earlyBird => (badgeEarlyBird, badgeEarlyBirdDesc),
    BadgeId.planner => (badgePlanner, badgePlannerDesc),
    BadgeId.moneySaver => (badgeMoneySaver, badgeMoneySaverDesc),
  };

  String goal(DailyGoal g, String Function(int) money, {int habitDone = 0}) => switch (g.kind) {
    GoalKind.spending => goalSpending(money(g.amountMinor ?? 0)),
    GoalKind.habit => goalHabit(g.habit!.name, habitDone, g.habit!.targetPerDay),
    GoalKind.topTask => goalTopTask(g.task!.title),
    GoalKind.logMood => goalLogMood,
    GoalKind.logSleep => goalLogSleep,
    GoalKind.planDay => goalPlanDay,
  };

  ({String title, String body}) notification(PlannedNotification n, {int streak = 0}) => switch (n.kind) {
    NotificationKind.taskReminder => (
      title: notifTaskTitle,
      body: n.leadMinutes <= 0 ? notifTaskNow(n.title) : notifTaskBody(n.title, n.leadMinutes),
    ),
    NotificationKind.logSpending => (title: notifSpendingTitle, body: notifSpendingBody),
    NotificationKind.budgetTight => (title: notifBudgetTitle, body: notifBudgetBody),
    NotificationKind.streakAtRisk => (title: notifStreakTitle, body: notifStreakBody(streak)),
    NotificationKind.moodCheckIn => (title: notifMoodTitle, body: notifMoodBody),
    NotificationKind.weeklyReview => (title: notifWeeklyTitle, body: notifWeeklyBody),
    NotificationKind.planDay => (title: notifPlanTitle, body: notifPlanBody),
    NotificationKind.journal => (title: notifJournalTitle, body: notifJournalBody),
    NotificationKind.billDue => (title: notifBillTitle, body: notifBillBody(n.title)),
    NotificationKind.morningBrief => (
      title: notifBriefTitle(n.count),
      body: [
        notifBriefFirst(n.title),
        if (n.extra != null) notifBriefSpend(n.extra!),
        if (n.news) notifBriefNews,
      ].join(' · '),
    ),
    NotificationKind.closeDay => (title: notifCloseTitle, body: notifCloseBody(n.count)),
    NotificationKind.gardenGift => (title: notifGardenTitle, body: notifGardenBody),
    NotificationKind.medication => (title: notifMedTitle, body: notifMedBody(n.title)),
  };

  /// Friendly message for any error; raw exceptions are never displayed.
  String failure(Object? error) {
    final kind = error is AppFailure ? error.kind : FailureKind.unknown;
    return switch (kind) {
      FailureKind.network => errorNetwork,
      FailureKind.timeout => errorTimeout,
      FailureKind.unavailable => errorUnavailable,
      FailureKind.quotaExceeded => errorQuota,
      FailureKind.rateLimited => errorRateLimited,
      FailureKind.unauthenticated => errorAuth,
      FailureKind.permissionDenied => errorPermission,
      FailureKind.invalidInput => errorInvalidInput,
      FailureKind.emailInUse => errorEmailInUse,
      FailureKind.wrongCredentials => errorWrongCredentials,
      FailureKind.weakPassword => errorWeakPassword,
      FailureKind.requiresRecentLogin => errorRecentLogin,
      FailureKind.cancelled || FailureKind.unknown => errorGeneric,
    };
  }
}

/// Upper-cases with the right dotted/dotless i for Turkish ("Önerilen" →
/// "ÖNERİLEN", not "ÖNERILEN").
extension LocaleUpper on BuildContext {
  String upper(String s) {
    if (Localizations.localeOf(this).languageCode != 'tr') return s.toUpperCase();
    return s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
  }
}
