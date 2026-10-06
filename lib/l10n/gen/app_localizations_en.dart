// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Dayly';

  @override
  String get appTagline => 'Make every day a good one.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get skip => 'Skip';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Try again';

  @override
  String get confirm => 'Confirm';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get undo => 'Undo';

  @override
  String get seeAll => 'See all';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get optional => 'Optional';

  @override
  String get learnMore => 'Learn more';

  @override
  String get loading => 'Loading…';

  @override
  String get saved => 'Saved';

  @override
  String get deleted => 'Deleted';

  @override
  String get premium => 'Premium';

  @override
  String get free => 'Free';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String hoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String percentValue(int value) {
    return '$value%';
  }

  @override
  String outOf100(int value) {
    return '$value/100';
  }

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get errorNetwork => 'You\'re offline. Check your connection and try again.';

  @override
  String get errorTimeout => 'This is taking too long. Try again.';

  @override
  String get errorUnavailable => 'This feature isn\'t available right now.';

  @override
  String get errorAiUnavailable =>
      'The assistant needs an internet connection and a configured backend. Everything else works offline.';

  @override
  String get errorQuota => 'You\'ve used today\'s free AI requests.';

  @override
  String get errorRateLimited => 'You\'re going a bit fast. Wait a moment and try again.';

  @override
  String get errorAuth => 'Please sign in again.';

  @override
  String get errorPermission => 'You don\'t have permission to do that.';

  @override
  String get errorInvalidInput => 'Please check what you entered.';

  @override
  String get errorEmailInUse => 'This account already exists. Try signing in instead.';

  @override
  String get errorWrongCredentials => 'Email or password doesn\'t match.';

  @override
  String get errorWeakPassword => 'Use at least 8 characters for your password.';

  @override
  String get errorRecentLogin => 'For your security, sign in again and retry.';

  @override
  String get offlineBanner => 'Offline — changes are saved and will sync later.';

  @override
  String get navHome => 'Home';

  @override
  String get navPlan => 'Plan';

  @override
  String get navMoney => 'Money';

  @override
  String get navLife => 'Life';

  @override
  String get navAi => 'AI';

  @override
  String get profileAndSettings => 'Profile and settings';

  @override
  String get welcomeTitle => 'Hi, I’m Lio! Let’s make today a good day.';

  @override
  String get welcomeBody => 'Plans, money, food, habits and an assistant that connects them — in one calm place.';

  @override
  String get getStarted => 'Get started';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Create account';

  @override
  String get signOut => 'Sign out';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get passwordResetSent => 'Check your inbox for a reset link.';

  @override
  String get orDivider => 'or';

  @override
  String get localModeNotice =>
      'Running in on-device mode: cloud sync, AI and purchases need Firebase to be configured.';

  @override
  String get linkAccountTitle => 'Secure your data';

  @override
  String get linkAccountBody =>
      'You\'re using a guest account. Link Google or email to keep your data if you change phones.';

  @override
  String get linkGoogle => 'Link Google account';

  @override
  String get linkEmail => 'Link email';

  @override
  String get accountLinked => 'Account linked. Your data is safe.';

  @override
  String get guestAccount => 'Guest account';

  @override
  String get onbNameTitle => 'What\'s your name?';

  @override
  String get onbNameHint => 'Your first name';

  @override
  String get onbFocusTitle => 'What do you want to improve?';

  @override
  String get onbFocusSubtitle => 'Pick as many as you like. This shapes your home screen.';

  @override
  String get onbIncomeTitle => 'Typical monthly income';

  @override
  String get onbIncomeSubtitle => 'Used only to calculate your safe daily spending. Stays private.';

  @override
  String get onbFixedLabel => 'Fixed monthly costs (rent, bills)';

  @override
  String get onbSavingsTitle => 'Monthly savings goal';

  @override
  String get onbSavingsSubtitle => 'We\'ll set aside this amount before telling you what\'s safe to spend.';

  @override
  String get onbRoutineTitle => 'Your daily routine';

  @override
  String get onbWake => 'I usually wake up at';

  @override
  String get onbSleep => 'I usually go to bed at';

  @override
  String get onbFoodTitle => 'Food preferences';

  @override
  String get onbDiet => 'Diet';

  @override
  String get onbAllergies => 'Allergies or foods to avoid';

  @override
  String get onbAllergiesHint => 'e.g. peanuts, mushrooms';

  @override
  String get onbNotifTitle => 'Gentle reminders';

  @override
  String get onbNotifBody => 'Meeting reminders and at most a few helpful nudges a day. You can change this anytime.';

  @override
  String get onbNotifAllow => 'Allow notifications';

  @override
  String get onbLocationTitle => 'Local weather';

  @override
  String get onbLocationBody => 'Use your approximate location, or pick a city. Location is optional.';

  @override
  String get onbUseLocation => 'Use my location';

  @override
  String get onbPickCity => 'Search a city';

  @override
  String get onbReadyTitle => 'Dayly is ready for you!';

  @override
  String get onbReadyBody => 'Your home screen now shows what matters for you today.';

  @override
  String get onbOpenHome => 'Open my day';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get myLocation => 'My location';

  @override
  String greetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String greetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String greetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get greetingNoName => 'Hello';

  @override
  String get dayAtAGlance => 'Your day at a glance.';

  @override
  String get homeToday => 'Today';

  @override
  String get homeNoPlan => 'Nothing planned yet.';

  @override
  String get homePlanDay => 'Plan my day';

  @override
  String get homeMoney => 'Money';

  @override
  String get safeSpendingToday => 'Today\'s safe spending';

  @override
  String leftToday(String amount) {
    return '$amount left today';
  }

  @override
  String overToday(String amount) {
    return '$amount over today';
  }

  @override
  String get setUpBudget => 'Set up your budget';

  @override
  String get setUpBudgetBody => 'Add your income to see how much you can safely spend each day.';

  @override
  String get homeFood => 'Food';

  @override
  String suggestedMeal(String meal) {
    return 'Suggested $meal';
  }

  @override
  String get homeWellbeing => 'Wellbeing';

  @override
  String get howAreYou => 'How are you feeling?';

  @override
  String get lifeScore => 'Life Score';

  @override
  String todaysGoal(int target) {
    return 'Today\'s goal: reach $target';
  }

  @override
  String get scoreNoData => 'Log a few things today to see your score.';

  @override
  String get forYou => 'For you';

  @override
  String importantStories(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count stories', one: '1 story');
    return '$_temp0 for you';
  }

  @override
  String get insight => 'Insight';

  @override
  String get dailyGoals => 'Daily goals';

  @override
  String lifeProgress(int value) {
    return 'Life progress $value%';
  }

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count-day streak', one: '1-day streak');
    return '$_temp0';
  }

  @override
  String get streakAtRisk => 'Log anything today to keep your streak.';

  @override
  String get quickAdd => 'Quick add';

  @override
  String get quickExpense => 'Expense';

  @override
  String get quickTask => 'Task';

  @override
  String get quickMood => 'Mood';

  @override
  String get quickAsk => 'Ask AI';

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherFog => 'Foggy';

  @override
  String get weatherDrizzle => 'Drizzle';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherThunder => 'Thunderstorm';

  @override
  String rainChance(int value) {
    return '$value% rain';
  }

  @override
  String highLow(int high, int low) {
    return 'H $high° · L $low°';
  }

  @override
  String get setCityForWeather => 'Add your city for local weather';

  @override
  String get scoreComponentMoney => 'Money';

  @override
  String get scoreComponentHealth => 'Health';

  @override
  String get scoreComponentProductivity => 'Productivity';

  @override
  String get scoreComponentHabits => 'Habits';

  @override
  String get scoreComponentMood => 'Mood';

  @override
  String get scoreComponentSleep => 'Sleep';

  @override
  String get scoreComponentPlanning => 'Planning';

  @override
  String scoreUp(int points, String reasons) {
    return 'Your score rose $points points today, mainly thanks to $reasons.';
  }

  @override
  String scoreDown(int points, String reasons) {
    return 'Your score dropped $points points today, mainly because of $reasons.';
  }

  @override
  String get scoreSame => 'Your score is steady compared with yesterday.';

  @override
  String get scoreFirstDay => 'This is your first score. Come back tomorrow to see what changed.';

  @override
  String reasonAnd(String a, String b) {
    return '$a and $b';
  }

  @override
  String get reasonMoneyUp => 'lower spending';

  @override
  String get reasonMoneyDown => 'higher spending';

  @override
  String get reasonHealthUp => 'healthier habits';

  @override
  String get reasonHealthDown => 'fewer health habits';

  @override
  String get reasonProductivityUp => 'finished tasks';

  @override
  String get reasonProductivityDown => 'unfinished tasks';

  @override
  String get reasonHabitsUp => 'habit progress';

  @override
  String get reasonHabitsDown => 'missed habits';

  @override
  String get reasonMoodUp => 'a better mood';

  @override
  String get reasonMoodDown => 'a lower mood';

  @override
  String get reasonSleepUp => 'better sleep';

  @override
  String get reasonSleepDown => 'reduced sleep';

  @override
  String get reasonPlanningUp => 'better planning';

  @override
  String get reasonPlanningDown => 'less planning';

  @override
  String get scoreHowCalculated => 'How is this calculated?';

  @override
  String get scoreExplainer =>
      'Your Life Score is a weighted average of the areas you track: money 20%, productivity 20%, health 15%, habits 15%, mood 10%, sleep 10%, planning 10%. Areas without data are left out, so not using a feature never lowers your score. AI never decides your score.';

  @override
  String scoreWeakest(String area) {
    return 'Biggest opportunity: $area';
  }

  @override
  String get scoreBreakdown => 'Breakdown';

  @override
  String get scoreHistory => 'Last 14 days';

  @override
  String get unlockBreakdown => 'Watch a short ad to see today’s breakdown';

  @override
  String get logSleep => 'Log sleep';

  @override
  String get sleepHoursQuestion => 'How long did you sleep last night?';

  @override
  String goalSpending(String amount) {
    return 'Stay under $amount';
  }

  @override
  String goalHabit(String name, int done, int target) {
    return '$name: $done/$target';
  }

  @override
  String goalTopTask(String title) {
    return 'Finish: $title';
  }

  @override
  String get goalLogMood => 'Check in with your mood';

  @override
  String get goalLogSleep => 'Log last night\'s sleep';

  @override
  String get goalPlanDay => 'Plan your day';

  @override
  String insightWeeklyUp(int percent) {
    return 'Your spending this week is $percent% higher than your weekly average.';
  }

  @override
  String insightWeeklyDown(int percent) {
    return 'Your spending this week is $percent% lower than your weekly average.';
  }

  @override
  String insightCategoryUp(int percent, String category) {
    return 'You spent $percent% more on $category this month.';
  }

  @override
  String insightCategoryDown(int percent, String category) {
    return 'You spent $percent% less on $category this month.';
  }

  @override
  String insightHabitUp(int percent) {
    return 'Your habit completion rate improved $percent% this week.';
  }

  @override
  String insightHabitDown(int percent) {
    return 'Your habit completion rate dropped $percent% this week.';
  }

  @override
  String get insightMoodSleep => 'You tend to report a lower mood on days with less sleep.';

  @override
  String get insightBudgetTight => 'Your budget is getting tight today.';

  @override
  String get insightNone => 'Keep logging — insights appear once there’s enough data.';

  @override
  String get planToday => 'Today';

  @override
  String get planWeek => 'This week';

  @override
  String get planMonth => 'Month';

  @override
  String get planEmpty => 'No tasks here yet. Add one or ask AI to plan your day.';

  @override
  String get planOptimize => 'Optimize my plan';

  @override
  String planOptimized(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Scheduled $count tasks.',
      one: 'Scheduled 1 task.',
      zero: 'Nothing to schedule.',
    );
    return '$_temp0';
  }

  @override
  String get planUnscheduled => 'Anytime';

  @override
  String get planOverdue => 'Overdue';

  @override
  String get planCompleted => 'Completed';

  @override
  String get newTask => 'New task';

  @override
  String get editTask => 'Edit task';

  @override
  String get taskTitle => 'Title';

  @override
  String get taskTitleHint => 'e.g. Gym, Call mom';

  @override
  String get taskPriority => 'Priority';

  @override
  String get taskDuration => 'Estimated duration';

  @override
  String get taskCategory => 'Category';

  @override
  String get taskDate => 'Date';

  @override
  String get taskTime => 'Time';

  @override
  String get taskNoTime => 'No time';

  @override
  String get taskDeadline => 'Deadline';

  @override
  String get taskRepeat => 'Repeat';

  @override
  String get taskAddedNextOccurrence => 'Next occurrence added.';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get repeatNone => 'Never';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get taskCatWork => 'Work';

  @override
  String get taskCatPersonal => 'Personal';

  @override
  String get taskCatHealth => 'Health';

  @override
  String get taskCatErrands => 'Errands';

  @override
  String get taskCatLearning => 'Learning';

  @override
  String get taskCatSocial => 'Social';

  @override
  String get taskCatOther => 'Other';

  @override
  String get markDone => 'Mark as done';

  @override
  String get markNotDone => 'Mark as not done';

  @override
  String get moneyIncome => 'Monthly income';

  @override
  String get moneySpent => 'Spent';

  @override
  String get moneySaved => 'Savings goal';

  @override
  String get moneyRemaining => 'Remaining';

  @override
  String get moneyDailySafe => 'Daily safe spending';

  @override
  String get moneyOnTrack => 'On track';

  @override
  String get moneyAtRisk => 'At risk';

  @override
  String moneyProjected(String amount) {
    return 'Projected month-end spend: $amount';
  }

  @override
  String moneyWeeklyLeft(String amount) {
    return 'Weekly budget: $amount left';
  }

  @override
  String get moneyCategories => 'Categories';

  @override
  String get moneyRecent => 'Recent';

  @override
  String get moneyNoTransactions => 'No expenses yet. Try typing “250 lunch”.';

  @override
  String get moneyBudgetSettings => 'Budget settings';

  @override
  String get moneyAddBudget => 'Add a limit';

  @override
  String get budgetPeriodWeek => 'Weekly';

  @override
  String get budgetPeriodMonth => 'Monthly';

  @override
  String get budgetLimit => 'Limit';

  @override
  String get budgetAllCategories => 'All spending';

  @override
  String get budgetCreated => 'Budget saved.';

  @override
  String ofLimit(String spent, String limit) {
    return '$spent of $limit';
  }

  @override
  String get currency => 'Currency';

  @override
  String get addExpense => 'Add expense';

  @override
  String get addIncome => 'Add income';

  @override
  String get smartInputHint => 'e.g. 250 lunch';

  @override
  String get smartInputHelp => 'Type an amount and what it was for. We’ll fill in the rest.';

  @override
  String get amount => 'Amount';

  @override
  String get category => 'Category';

  @override
  String get description => 'Description';

  @override
  String get date => 'Date';

  @override
  String get scanReceipt => 'Scan receipt';

  @override
  String get receiptReview => 'Check the receipt';

  @override
  String get receiptReviewBody => 'We read this from your photo. Fix anything that looks wrong before saving.';

  @override
  String get receiptMerchant => 'Merchant';

  @override
  String get receiptItems => 'Items';

  @override
  String get receiptNothingFound => 'We couldn\'t read this receipt. Try a clearer photo or enter it manually.';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get expenseSaved => 'Expense saved';

  @override
  String get aiParsing => 'Understanding…';

  @override
  String get catHousing => 'Housing';

  @override
  String get catFood => 'Food';

  @override
  String get catTransport => 'Transport';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catBills => 'Bills';

  @override
  String get catEntertainment => 'Entertainment';

  @override
  String get catHealth => 'Health';

  @override
  String get catSubscriptions => 'Subscriptions';

  @override
  String get catOther => 'Other';

  @override
  String get incomeLabel => 'Income';

  @override
  String get lifeHabits => 'Habits';

  @override
  String get lifeMood => 'Mood';

  @override
  String get lifeJournal => 'Journal';

  @override
  String get lifeFood => 'Food';

  @override
  String get lifePantry => 'Pantry';

  @override
  String get lifeShopping => 'Shopping list';

  @override
  String get lifeReports => 'Reports';

  @override
  String get lifeNews => 'News';

  @override
  String get lifeAchievements => 'Achievements';

  @override
  String get habitsEmpty => 'Start with one small habit. Consistency beats intensity.';

  @override
  String get newHabit => 'New habit';

  @override
  String get habitName => 'Name';

  @override
  String get habitTarget => 'Daily target';

  @override
  String get habitUnit => 'Unit';

  @override
  String get habitDays => 'Days';

  @override
  String habitStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String habitWeeklyRate(int value) {
    return 'This week: $value% complete';
  }

  @override
  String get habitArchive => 'Archive habit';

  @override
  String get habitWater => 'Water';

  @override
  String get habitReading => 'Reading';

  @override
  String get habitExercise => 'Exercise';

  @override
  String get habitMeditation => 'Meditation';

  @override
  String get habitSleep => 'Sleep';

  @override
  String get habitCustom => 'Custom';

  @override
  String habitIncrement(String name) {
    return 'Add one to $name';
  }

  @override
  String habitDecrement(String name) {
    return 'Remove one from $name';
  }

  @override
  String get moodGreat => 'Great';

  @override
  String get moodGood => 'Good';

  @override
  String get moodOkay => 'Okay';

  @override
  String get moodLow => 'Low';

  @override
  String get moodBad => 'Exhausted';

  @override
  String get moodWhy => 'Why? (optional)';

  @override
  String get moodSaved => 'Mood saved';

  @override
  String get moodHistory => 'This week';

  @override
  String get moodDisclaimer =>
      'Mood tracking is for self-reflection only and is not a medical or mental health assessment. If you are struggling, please reach out to a professional or someone you trust.';

  @override
  String get journalEmpty => 'A private space for your thoughts. Entries stay encrypted on this device.';

  @override
  String get journalNew => 'New entry';

  @override
  String get journalHint => 'How was your day?';

  @override
  String get journalPrivacy =>
      'Encrypted on this device. Never synced. Shared with AI only if you allow it in Privacy settings.';

  @override
  String get journalSummarize => 'Summarize my week';

  @override
  String get foodWhatToEat => 'What should I eat?';

  @override
  String get foodMealBreakfast => 'Breakfast';

  @override
  String get foodMealLunch => 'Lunch';

  @override
  String get foodMealDinner => 'Dinner';

  @override
  String get foodMealSnack => 'Snack';

  @override
  String foodCalories(int value) {
    return '$value kcal';
  }

  @override
  String foodMacros(int p, int c, int f) {
    return 'P ${p}g · C ${c}g · F ${f}g';
  }

  @override
  String get foodDifficultyEasy => 'Easy';

  @override
  String get foodDifficultyMedium => 'Medium';

  @override
  String get foodDifficultyHard => 'Hard';

  @override
  String get foodCostLow => 'Budget-friendly';

  @override
  String get foodCostMedium => 'Moderate cost';

  @override
  String get foodCostHigh => 'Higher cost';

  @override
  String foodEstimatedCost(String amount) {
    return 'About $amount';
  }

  @override
  String get foodRefreshLocal => 'Suggest from my pantry';

  @override
  String get foodGenerateAi => 'Create a plan with AI';

  @override
  String get foodIngredients => 'Ingredients';

  @override
  String get foodSteps => 'Steps';

  @override
  String foodMissing(String items) {
    return 'Missing: $items';
  }

  @override
  String get foodAddMissing => 'Add missing to shopping list';

  @override
  String foodAddedToList(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'Added $count items', one: 'Added 1 item');
    return '$_temp0';
  }

  @override
  String get foodPreferences => 'Food preferences';

  @override
  String get foodSkill => 'Cooking skill';

  @override
  String get foodBudget => 'Food budget';

  @override
  String get skillBeginner => 'Beginner';

  @override
  String get skillIntermediate => 'Intermediate';

  @override
  String get skillAdvanced => 'Advanced';

  @override
  String get budgetLow => 'Low';

  @override
  String get budgetMedium => 'Medium';

  @override
  String get budgetHigh => 'High';

  @override
  String get dietNone => 'No restrictions';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietPescatarian => 'Pescatarian';

  @override
  String get dietKeto => 'Keto';

  @override
  String get dietHalal => 'Halal';

  @override
  String get dietGlutenFree => 'Gluten-free';

  @override
  String get nutritionDisclaimer => 'Nutrition values are estimates.';

  @override
  String get pantryEmpty => 'Add what you have at home to get meal ideas that use it.';

  @override
  String get pantryAddHint => 'e.g. chicken, rice, tomato';

  @override
  String pantryCanMake(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You can make $count meals with what you already have.',
      one: 'You can make 1 meal with what you already have.',
      zero: 'Add a few more ingredients to unlock meals.',
    );
    return '$_temp0';
  }

  @override
  String get shoppingEmpty => 'Your list is empty.';

  @override
  String get shoppingAddHint => 'Add item';

  @override
  String get shoppingClearChecked => 'Clear checked';

  @override
  String get shopProduce => 'Produce';

  @override
  String get shopMeat => 'Meat & fish';

  @override
  String get shopDairy => 'Dairy & eggs';

  @override
  String get shopBakery => 'Bakery';

  @override
  String get shopPantry => 'Pantry';

  @override
  String get shopFrozen => 'Frozen';

  @override
  String get shopDrinks => 'Drinks';

  @override
  String get shopHousehold => 'Household';

  @override
  String get shopPersonalCare => 'Personal care';

  @override
  String get shopOther => 'Other';

  @override
  String get aiTitle => 'Assistant';

  @override
  String get aiInputHint => 'Ask anything about your day…';

  @override
  String get aiSend => 'Send';

  @override
  String get aiThinking => 'Thinking…';

  @override
  String get aiEmptyTitle => 'How can I help today?';

  @override
  String get aiSuggestion1 => 'Plan my day';

  @override
  String get aiSuggestion2 => 'I want to save 10,000 this month';

  @override
  String get aiSuggestion3 => 'I have chicken, rice and tomatoes';

  @override
  String get aiSuggestion4 => 'Why did I spend more this month?';

  @override
  String get aiSuggestion5 => 'What do you know about me?';

  @override
  String aiCreditsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count free requests left today',
      one: '1 free request left today',
      zero: 'No free requests left today',
    );
    return '$_temp0';
  }

  @override
  String get aiUnlimited => 'Premium · unlimited';

  @override
  String aiWatchAd(int count) {
    return 'Watch an ad for +$count requests';
  }

  @override
  String get aiGoPremium => 'Go Premium for unlimited AI';

  @override
  String get aiRewardEarned => 'Thanks! You earned more requests.';

  @override
  String get aiRewardUnavailable => 'No ad is available right now. Try again later.';

  @override
  String get aiActionsProposed => 'Suggested actions';

  @override
  String aiActionCreateTask(String title) {
    return 'Add task “$title”';
  }

  @override
  String aiActionCreateTaskAt(String title, String when) {
    return 'Add “$title” on $when';
  }

  @override
  String get aiActionOptimize => 'Optimize today’s plan';

  @override
  String aiActionBudget(String period, String amount) {
    return 'Create a $period budget of $amount';
  }

  @override
  String aiActionExpense(String amount, String category) {
    return 'Log $amount for $category';
  }

  @override
  String aiActionSavings(String amount) {
    return 'Set savings goal to $amount';
  }

  @override
  String aiActionMeal(String date) {
    return 'Create a meal plan for $date';
  }

  @override
  String aiActionShopping(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count items to shopping list',
      one: 'Add 1 item to shopping list',
    );
    return '$_temp0';
  }

  @override
  String aiActionHabit(String name) {
    return 'Start habit “$name”';
  }

  @override
  String aiActionMood(String mood) {
    return 'Log mood: $mood';
  }

  @override
  String aiActionMemory(String content) {
    return 'Remember: $content';
  }

  @override
  String get aiActionDone => 'Done';

  @override
  String get aiActionDismissed => 'Dismissed';

  @override
  String get aiActionFailed => 'Couldn\'t complete this action.';

  @override
  String aiMemorySaved(String content) {
    return 'Saved to memory: $content';
  }

  @override
  String get aiNewChat => 'New chat';

  @override
  String get aiDisclaimer => 'AI can make mistakes. It never moves money, and every change needs your confirmation.';

  @override
  String aiDataNotice(String scopes) {
    return 'Uses: $scopes. Change in Privacy settings.';
  }

  @override
  String get aiNoScopes => 'only your profile basics';

  @override
  String get weeklyReport => 'Your week';

  @override
  String get weeklyReportSubtitle => 'Your week in 60 seconds.';

  @override
  String get monthlyReport => 'Monthly Life Report';

  @override
  String get reportScore => 'Life Score';

  @override
  String reportScoreChange(int from, int to) {
    return '$from → $to';
  }

  @override
  String get reportMoney => 'Money';

  @override
  String reportSaved(String amount) {
    return 'Saved vs last period: $amount';
  }

  @override
  String reportSpendChange(String percent) {
    return 'Spending $percent% vs last period';
  }

  @override
  String get reportHabits => 'Habits';

  @override
  String get reportMood => 'Average mood';

  @override
  String reportMoodValue(String value) {
    return '$value/10';
  }

  @override
  String get reportProductivity => 'Productivity';

  @override
  String get reportSleep => 'Average sleep';

  @override
  String get reportNextWeek => 'Next week';

  @override
  String get reportNextMonth => 'Next month';

  @override
  String get reportAiSummary => 'AI summary';

  @override
  String get reportGenerateSummary => 'Write my summary';

  @override
  String get reportNoData => 'Not enough data yet.';

  @override
  String suggestReduceCategory(String category) {
    return 'Reduce $category spending';
  }

  @override
  String get suggestSleepEarlier => 'Go to bed 30 minutes earlier';

  @override
  String get suggestKeepStreak => 'Keep your current habit streak';

  @override
  String get suggestPlanMore => 'Plan at least one task a day';

  @override
  String get suggestLogMood => 'Check in with your mood daily';

  @override
  String get suggestStartHabit => 'Start one small habit';

  @override
  String get achievements => 'Achievements';

  @override
  String get badgeFirstWeek => 'First Week';

  @override
  String get badgeFirstWeekDesc => 'Active on 7 different days';

  @override
  String get badgeBudgetMaster => 'Budget Master';

  @override
  String get badgeBudgetMasterDesc => 'Stayed within your daily allowance 7 days in a row';

  @override
  String get badgeStreak => '7 Day Streak';

  @override
  String get badgeStreakDesc => 'Checked in 7 days in a row';

  @override
  String get badgeHealthyWeek => 'Healthy Week';

  @override
  String get badgeHealthyWeekDesc => 'Hit 80% of your health habits in a week';

  @override
  String get badgeEarlyBird => 'Early Bird';

  @override
  String get badgeEarlyBirdDesc => 'Finished 5 tasks before 9 AM';

  @override
  String get badgePlanner => 'Planner';

  @override
  String get badgePlannerDesc => 'Planned tasks on 7 different days';

  @override
  String get badgeMoneySaver => 'Money Saver';

  @override
  String get badgeMoneySaverDesc => 'Reached your monthly savings goal';

  @override
  String badgeUnlocked(String name) {
    return 'Achievement unlocked: $name';
  }

  @override
  String get newsWhyMatters => 'Why this matters';

  @override
  String get newsTopics => 'Topics';

  @override
  String get newsTopicTechnology => 'Technology';

  @override
  String get newsTopicFinance => 'Finance';

  @override
  String get newsTopicSports => 'Sports';

  @override
  String get newsTopicWorld => 'World';

  @override
  String get newsTopicScience => 'Science';

  @override
  String get newsTopicEntertainment => 'Entertainment';

  @override
  String get newsUnavailable => 'News is unavailable right now.';

  @override
  String get openArticle => 'Open article';

  @override
  String get settings => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get highContrast => 'High contrast';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get notifOff => 'Off';

  @override
  String get notifLow => 'Reminders only';

  @override
  String get notifNormal => 'Reminders + daily nudges';

  @override
  String get notifExplain => 'We never send more than a few notifications a day and nothing at night.';

  @override
  String get settingsPrivacy => 'Privacy & data';

  @override
  String get settingsAiMemory => 'AI memory';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsAbout => 'About';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get analyticsToggle => 'Share anonymous usage analytics';

  @override
  String get crashToggle => 'Send crash reports';

  @override
  String get personalizedAdsToggle => 'Personalized ads';

  @override
  String get aiDataTitle => 'What the AI can see';

  @override
  String get aiDataBody =>
      'When you use the assistant, Dayly sends your message and only the data you allow below to our server, which forwards it to an AI provider to generate a reply. It is not used to train AI models by Dayly. Your journal is never shared unless you turn it on.';

  @override
  String get scopeMoney => 'Money (budget totals and categories)';

  @override
  String get scopeTasks => 'Tasks and schedule';

  @override
  String get scopeHabits => 'Habits';

  @override
  String get scopeMood => 'Mood and sleep (last 7 days)';

  @override
  String get scopeFood => 'Food preferences and pantry';

  @override
  String get scopeJournal => 'Journal (last 5 entries)';

  @override
  String get scopeShortMoney => 'money';

  @override
  String get scopeShortTasks => 'tasks';

  @override
  String get scopeShortHabits => 'habits';

  @override
  String get scopeShortMood => 'mood';

  @override
  String get scopeShortFood => 'food';

  @override
  String get scopeShortJournal => 'journal';

  @override
  String get memoryEnabledToggle => 'Let the assistant remember things';

  @override
  String get memoryEmpty => 'The assistant hasn\'t saved anything about you yet.';

  @override
  String get memoryDeleteAll => 'Delete all memories';

  @override
  String memoryLimit(int used, int limit) {
    return '$used of $limit memories used';
  }

  @override
  String get memCatPreferences => 'Preferences';

  @override
  String get memCatGoals => 'Goals';

  @override
  String get memCatHabits => 'Habits';

  @override
  String get memCatFood => 'Food';

  @override
  String get memCatBudget => 'Budget';

  @override
  String get memCatSchedule => 'Schedule';

  @override
  String get exportData => 'Export my data';

  @override
  String exportDone(String path) {
    return 'Export saved to $path';
  }

  @override
  String get deleteDataSection => 'Delete data';

  @override
  String get deleteJournal => 'Delete all journal entries';

  @override
  String get deleteExpenses => 'Delete all expenses';

  @override
  String get deleteMemories => 'Delete AI memory';

  @override
  String get deleteChats => 'Delete AI conversations';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account and all data in the cloud and on this device. Active subscriptions must be cancelled in Google Play.';

  @override
  String get deleteConfirmTitle => 'Are you sure?';

  @override
  String get deleteConfirmBody => 'This cannot be undone.';

  @override
  String get typeDeleteToConfirm => 'Type DELETE to confirm';

  @override
  String get syncStatus => 'Sync';

  @override
  String get syncUpToDate => 'Up to date';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get syncLocalOnly => 'On this device only';

  @override
  String version(String value) {
    return 'Version $value';
  }

  @override
  String get placeholderLegal => 'This is a placeholder. Replace it with your published policy before release.';

  @override
  String get city => 'City';

  @override
  String get newsTopicsSetting => 'News topics';

  @override
  String get premiumTitle => 'Dayly Premium';

  @override
  String get premiumSubtitle => 'More insight, no ads, unlimited assistant.';

  @override
  String get premiumFeatureAi => 'Unlimited AI assistant (fair use)';

  @override
  String get premiumFeatureScore => 'Full Life Score breakdown and history';

  @override
  String get premiumFeatureNoAds => 'No ads';

  @override
  String get premiumFeatureAnalytics => 'Advanced analytics and monthly reports';

  @override
  String get premiumFeatureMeals => 'Unlimited AI meal plans';

  @override
  String get premiumFeatureMemory => 'Unlimited AI memory';

  @override
  String get premiumMonthly => 'Monthly';

  @override
  String get premiumYearly => 'Yearly';

  @override
  String get premiumSubscribe => 'Subscribe';

  @override
  String get premiumRestore => 'Restore purchases';

  @override
  String get premiumActive => 'You\'re Premium. Thank you!';

  @override
  String get premiumManage => 'Manage subscription in Google Play';

  @override
  String get premiumUnavailable => 'Subscriptions are not available on this device right now.';

  @override
  String get premiumPending => 'Purchase pending…';

  @override
  String get premiumSuccess => 'Welcome to Premium!';

  @override
  String get premiumDisclosure =>
      'Subscriptions renew automatically at the price shown until cancelled. Cancel anytime in Google Play at least 24 hours before renewal. Payment is charged to your Google Play account.';

  @override
  String get premiumLocked => 'Premium feature';

  @override
  String get tryWithAd => 'Try once with a short ad';

  @override
  String get notifTaskTitle => 'Coming up';

  @override
  String notifTaskBody(String title) {
    return '“$title” starts in 30 minutes.';
  }

  @override
  String get notifSpendingTitle => 'Quick check';

  @override
  String get notifSpendingBody => 'You haven\'t logged today\'s spending.';

  @override
  String get notifBudgetTitle => 'Budget';

  @override
  String get notifBudgetBody => 'Your budget is getting tight. Here’s your safe amount for today.';

  @override
  String get notifStreakTitle => 'Keep it going';

  @override
  String notifStreakBody(int count) {
    return 'Your $count-day streak is at risk.';
  }

  @override
  String get notifMoodTitle => 'Check in';

  @override
  String get notifMoodBody => 'How are you feeling today?';

  @override
  String get notifWeeklyTitle => 'Your week in 60 seconds';

  @override
  String get notifWeeklyBody => 'Your weekly review is ready.';

  @override
  String get focusMoney => 'Money';

  @override
  String get focusHealth => 'Health';

  @override
  String get focusProductivity => 'Productivity';

  @override
  String get focusFood => 'Food';

  @override
  String get focusHabits => 'Habits';

  @override
  String get focusPlanning => 'Planning';

  @override
  String weekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Mon',
      '2': 'Tue',
      '3': 'Wed',
      '4': 'Thu',
      '5': 'Fri',
      '6': 'Sat',
      'other': 'Sun',
    });
    return '$_temp0';
  }

  @override
  String get offlineAiTitle => 'Offline assistant';

  @override
  String get offlineAiBody =>
      'Download a small AI model to your phone so the assistant can answer without internet. Answers stay on your device. It is less capable than the online assistant and cannot make changes in the app.';

  @override
  String offlineAiSize(int size) {
    return 'Download size: about $size MB. Wi-Fi recommended; works best on phones with 4 GB+ RAM.';
  }

  @override
  String get offlineAiDownload => 'Download model';

  @override
  String offlineAiDownloading(int progress) {
    return 'Downloading… $progress%';
  }

  @override
  String get offlineAiReady => 'Ready — works without internet';

  @override
  String get offlineAiError => 'Download failed. Check your connection and try again.';

  @override
  String get offlineAiDelete => 'Delete model';

  @override
  String get offlineAiPrefer => 'Use offline assistant even when online';

  @override
  String get offlineAiPreferHelp =>
      'Private and free, but less accurate. Otherwise it is used automatically when you are offline.';

  @override
  String get offlineAiUnavailable => 'The offline assistant is not available yet.';

  @override
  String get aiSetupTitle => 'Turn on your assistant';

  @override
  String get aiSetupBody =>
      'Download the free on-device assistant once and chat any time — even without internet. Your messages never leave your phone.';

  @override
  String get aiSetupCta => 'Set up assistant';

  @override
  String mascotTip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'I have $count ideas for your day.',
      one: 'I have 1 idea for your day.',
      zero: 'Nothing urgent today — enjoy it.',
    );
    return '$_temp0';
  }

  @override
  String get mascotAsk => 'Tap to ask Lio anything';

  @override
  String get allGoalsDone => 'All goals done today — amazing!';

  @override
  String get offlineAnswerLabel => 'Offline answer · on-device model';

  @override
  String get offlineModeChip => 'Offline mode';

  @override
  String get localModelsInfo =>
      'Expense and shopping categories are recognised by small models that run on your device.';

  @override
  String get lioName => 'Lio, your companion';

  @override
  String get lioAsk => 'Ask Lio';

  @override
  String get lioAnother => 'Another one';

  @override
  String get lioHide => 'Hide Lio';

  @override
  String get lioHidden => 'Lio is resting. Bring him back in Settings.';

  @override
  String get lioSetting => 'Lio companion';

  @override
  String get lioSettingHelp => 'Lio walks around the app with tips and a little inspiration.';

  @override
  String lioGoalsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals left today. One at a time.',
      one: 'One goal left today. You’ve got this!',
    );
    return '$_temp0';
  }

  @override
  String get lioAllDone => 'Every goal done today. I’m so proud of you!';

  @override
  String get lioOverBudget => 'We went a bit over today. Tomorrow we take it slow — no stress.';

  @override
  String lioUnderBudget(String amount) {
    return 'You still have $amount for today. Nicely balanced!';
  }

  @override
  String lioStreak(int days) {
    return '$days-day streak! Let’s keep the fire going.';
  }

  @override
  String get lioMoodCheck => 'How are you feeling? A quick mood check helps me help you.';

  @override
  String get lioNight => 'It’s getting late. A good night’s sleep is the best plan for tomorrow.';

  @override
  String get lioTipHome1 => 'Tap the + button to log anything in two seconds.';

  @override
  String get lioTipHome2 => 'Pull down to refresh your day.';

  @override
  String get lioTipPlan1 => 'Put your hardest task first — your energy is highest early.';

  @override
  String get lioTipPlan2 => 'Small tasks under 15 minutes? Batch them together.';

  @override
  String get lioTipPlan3 => 'Ask me to plan your day and I’ll arrange everything for you.';

  @override
  String get lioTipMoney1 => 'Just type “250 lunch” — I’ll figure out the rest.';

  @override
  String get lioTipMoney2 => 'Small daily savings add up to big months.';

  @override
  String get lioTipMoney3 => 'Snap a receipt and I’ll read the total for you.';

  @override
  String get lioTipLife1 => 'Two minutes of journaling can clear a whole day’s noise.';

  @override
  String get lioTipLife2 => 'Tell me what’s in your fridge and I’ll suggest a meal.';

  @override
  String get lioTipLife3 => 'Habits stick best when they’re tiny. Start with one glass of water.';

  @override
  String get lioInspire1 => 'Small steps every day beat big plans someday.';

  @override
  String get lioInspire2 => 'You don’t have to do everything. Just the next right thing.';

  @override
  String get lioInspire3 => 'Rest is part of the plan, not a break from it.';

  @override
  String get lioInspire4 => 'Progress, not perfection.';

  @override
  String get lioInspire5 => 'A calm morning makes a kind day.';

  @override
  String get lioInspire6 => 'Be proud of how far you’ve come today.';

  @override
  String get lioInspire7 => 'Drink some water. Future you says thanks.';

  @override
  String get lioInspire8 => 'Every “no” to a small expense is a “yes” to a bigger dream.';

  @override
  String get lioInspire9 => 'Done is a beautiful word.';

  @override
  String get lioInspire10 => 'Take a deep breath. You’re doing better than you think.';

  @override
  String get lioInspire11 => 'Today is a good day to start something small.';

  @override
  String get lioInspire12 => 'Kindness to yourself counts too.';
}
