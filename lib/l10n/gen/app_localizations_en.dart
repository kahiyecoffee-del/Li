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
  String get appTagline => 'Leave the hard part of life to us.';

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
  String get navExplore => 'Explore';

  @override
  String get navSaved => 'Saved';

  @override
  String get navProfile => 'Profile';

  @override
  String get profileAndSettings => 'Profile and settings';

  @override
  String get welcomeTitle => 'Leave the hard part of life to us.';

  @override
  String get welcomeBody =>
      'Money, decisions, food, writing: type an everyday problem and Dayly solves it in seconds, right on your phone.';

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
  String get onbOpenHome => 'Solve my first problem';

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
  String planFree(String time) {
    return 'Free · $time';
  }

  @override
  String get planNow => 'Now';

  @override
  String get planEmptyShort => 'A free day';

  @override
  String get planQuickHint => 'Add a task… e.g. 15:00 dentist 30 min';

  @override
  String planQuickAdded(String title) {
    return 'Added: $title';
  }

  @override
  String get planDetails => 'More options';

  @override
  String get planScheduleIt => 'Schedule';

  @override
  String planScheduledAt(String time) {
    return 'Scheduled for $time';
  }

  @override
  String get planNoSlot => 'No free slot left on this day';

  @override
  String get planPostpone => 'Tomorrow';

  @override
  String get planPostponed => 'Moved to tomorrow';

  @override
  String get planToToday => 'Do today';

  @override
  String planProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String planPlannedTime(String time) {
    return '$time planned';
  }

  @override
  String planFreeTime(String time) {
    return '$time free';
  }

  @override
  String get planDayEmpty => 'Nothing planned for this day yet. Write a task below or let Lio plan it with you.';

  @override
  String get planWithLio => 'Plan with Lio';

  @override
  String get planTimeline => 'Timeline';

  @override
  String get planPickDate => 'Pick a date';

  @override
  String durHM(int h, int m) {
    return '$h h $m min';
  }

  @override
  String durH(int h) {
    return '$h h';
  }

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
  String get moneyTabOverview => 'Overview';

  @override
  String get moneyTabActivity => 'Activity';

  @override
  String get moneyTabPlan => 'Plan';

  @override
  String moneyMoreThanLast(int p) {
    return '$p% more than last month';
  }

  @override
  String moneyLessThanLast(int p) {
    return '$p% less than last month';
  }

  @override
  String moneyMonthTotal(String amount) {
    return 'Spent $amount';
  }

  @override
  String moneyDailyAvg(String amount) {
    return 'Daily average $amount';
  }

  @override
  String moneyBiggest(String what, String amount) {
    return 'Biggest: $what · $amount';
  }

  @override
  String get moneySearch => 'Search expenses';

  @override
  String get moneyNoMatch => 'Nothing here for this month.';

  @override
  String get moneyAddIncome => 'Add income';

  @override
  String get moneyChartTitle => 'Where the money went';

  @override
  String get moneyPrevMonth => 'Previous month';

  @override
  String get moneyNextMonth => 'Next month';

  @override
  String advBillsDue(int count, String name, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills are due soon, $amount in total. $name is first.',
      one: '$name is due ($amount). Pay it and mark it here so your budget stays right.',
    );
    return '$_temp0';
  }

  @override
  String get billsTitle => 'Bills & subscriptions';

  @override
  String get billsEmpty =>
      'Add rent, bills and subscriptions once. Dayly reminds you the day before and keeps that money aside in your daily budget.';

  @override
  String get billAdd => 'Add bill';

  @override
  String get billName => 'Name (e.g. Electricity, Netflix)';

  @override
  String get billDay => 'Day of the month';

  @override
  String get billRemind => 'Remind me the day before';

  @override
  String get billPay => 'Mark paid';

  @override
  String get billPaid => 'Paid';

  @override
  String billOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days late', one: '1 day late');
    return '$_temp0';
  }

  @override
  String get billDueToday => 'Due today';

  @override
  String billDueIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: 'In $count days', one: 'Tomorrow');
    return '$_temp0';
  }

  @override
  String billsMonthly(String amount) {
    return 'Every month: $amount';
  }

  @override
  String billsLeft(String amount) {
    return '$amount still to pay this month';
  }

  @override
  String get billPaidSnack => 'Logged as an expense';

  @override
  String get goalsTitle => 'Savings jars';

  @override
  String get goalsEmpty => 'Saving for something? Make a jar and watch it fill up.';

  @override
  String get goalAdd => 'New jar';

  @override
  String get goalName => 'What for? (e.g. Holiday)';

  @override
  String get goalTarget => 'Target';

  @override
  String get goalDeadline => 'By when (optional)';

  @override
  String get goalNoDeadline => 'No deadline';

  @override
  String goalProgress(String saved, String target) {
    return '$saved of $target';
  }

  @override
  String goalMonthly(String amount) {
    return 'Put aside $amount a month to make it';
  }

  @override
  String get goalReached => 'Goal reached! 🎉';

  @override
  String get goalDeposit => 'Add money';

  @override
  String get goalWithdraw => 'Take out';

  @override
  String get goalAmount => 'Amount';

  @override
  String get limitsTitle => 'Spending limits';

  @override
  String get limitsEmpty =>
      'Set a weekly limit, a monthly limit or one per category. They repeat every week or month by themselves.';

  @override
  String get limitWeekly => 'Weekly total';

  @override
  String get limitMonthlyAll => 'Monthly total';

  @override
  String get notifBillTitle => 'Bill reminder';

  @override
  String notifBillBody(String name) {
    return '$name is due. Tap to mark it paid.';
  }

  @override
  String get foodChange => 'Change';

  @override
  String get foodPick => 'Choose';

  @override
  String foodPickTitle(String meal) {
    return 'Choose $meal';
  }

  @override
  String get foodAddMeal => 'Add a meal';

  @override
  String get foodRemoveMeal => 'Remove';

  @override
  String get foodShowAllTypes => 'Show every recipe';

  @override
  String get foodTabToday => 'Today';

  @override
  String widgetToday(String date) {
    return 'Today · $date';
  }

  @override
  String widgetLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things left today',
      one: '1 thing left today',
    );
    return '$_temp0';
  }

  @override
  String get widgetAllDone => 'All done for today 🎉';

  @override
  String get widgetEmpty => 'No plan yet. Tap to plan your day.';

  @override
  String get widgetStale => 'Open Dayly to see today\'s plan';

  @override
  String get foodTabRecipes => 'Recipes';

  @override
  String get foodTabWeek => 'Week';

  @override
  String get foodSearchHint => 'Search a dish or an ingredient';

  @override
  String get foodFilterFavorites => 'Favorites';

  @override
  String get foodFilterCanMake => 'Can make now';

  @override
  String get foodFilterQuick => 'Quick (≤20 min)';

  @override
  String get foodFilterVeg => 'Vegetarian';

  @override
  String get foodFilterProtein => 'High protein';

  @override
  String get foodFilterBudget => 'Budget';

  @override
  String get foodAllMeals => 'All';

  @override
  String get foodNoRecipes => 'No recipe matches. Try removing a filter.';

  @override
  String foodRecipeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count recipes', one: '1 recipe');
    return '$_temp0';
  }

  @override
  String foodMissingCount(int count) {
    return '$count missing';
  }

  @override
  String get foodHaveAll => 'You have it all';

  @override
  String foodServings(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count servings', one: '1 serving');
    return '$_temp0';
  }

  @override
  String get foodAddToToday => 'Add to today\'s menu';

  @override
  String get foodAddedToToday => 'Added to today\'s menu';

  @override
  String get foodFavoriteAdd => 'Add to favorites';

  @override
  String get foodFavoriteRemove => 'Remove from favorites';

  @override
  String get foodCopyRecipe => 'Copy recipe';

  @override
  String get foodStepsHint => 'Tap a step when it is done.';

  @override
  String foodCanMakeNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You can cook $count recipes with what you have',
      one: 'You can cook 1 recipe with what you have',
    );
    return '$_temp0';
  }

  @override
  String get foodWeekIntro =>
      'Lio picks varied meals for 7 days, using what you have at home first. Then make one shopping list for the whole week.';

  @override
  String get foodWeekPlan => 'Plan the week';

  @override
  String get foodWeekReplan => 'Re-plan the week';

  @override
  String get foodWeekPlanned => 'Your week is planned.';

  @override
  String get foodWeekShopping => 'Make the shopping list';

  @override
  String get foodWeekNothingMissing => 'You already have everything for this week.';

  @override
  String get foodNotPlanned => 'Not planned yet';

  @override
  String foodWeekCalories(int value) {
    return '~$value kcal a day';
  }

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
  String get notifPlanTitle => 'Good morning ☀️';

  @override
  String get notifPlanBody => 'Two minutes with Lio and your day has a plan.';

  @override
  String get notifJournalTitle => 'Your journal';

  @override
  String get notifJournalBody => 'How was today? A few lines are enough.';

  @override
  String get journalReminderSetting => 'Evening journal reminder';

  @override
  String get planReminderSetting => 'Morning plan reminder';

  @override
  String get assistantNameSetting => 'Assistant’s name';

  @override
  String get assistantNameHelp => 'Call your helper whatever you like.';

  @override
  String get lioLearnsSetting => 'Let Lio learn from my journal';

  @override
  String get lioLearnsHelp =>
      'Lio finds patterns in your entries (what lifts or lowers your mood) on this phone only. Nothing leaves your device.';

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

  @override
  String brainGreeting(String name) {
    return 'Hi $name! I’m Lio. Ask me about your plan, money, food or how you’re doing.';
  }

  @override
  String get brainGreetingNoName => 'Hi! I’m Lio. Ask me about your plan, money, food or how you’re doing.';

  @override
  String get brainThanks => 'Anytime! I’m right here whenever you need me.';

  @override
  String get brainPlanNone =>
      'Your plan for today is empty. Start by adding the one task that matters most — tap + on the Plan tab.';

  @override
  String brainPlanList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count things on your list today:',
      one: 'You have 1 thing on your list today:',
    );
    return '$_temp0';
  }

  @override
  String brainPlanNext(String title) {
    return 'Start with “$title” — once it’s done, the rest feels lighter.';
  }

  @override
  String get brainPlanAllDone => 'Everything on today’s list is done. Rest, or get a head start on tomorrow.';

  @override
  String get brainMoneyNoBudget =>
      'You haven’t set a budget yet. Add your monthly income in Money and I’ll work out a safe daily amount.';

  @override
  String brainMoneySafe(String left, String safe) {
    return 'You can still spend $left today. Your safe daily amount is $safe.';
  }

  @override
  String brainMoneyOver(String over) {
    return 'You’re $over over today’s safe amount. Let’s go easy for the rest of the day.';
  }

  @override
  String get brainMoneyTip => 'Tip: log expenses right away — just type “250 lunch”.';

  @override
  String brainFood(String meal, int minutes) {
    return 'How about $meal? It takes about $minutes minutes. You’ll find more ideas in Food.';
  }

  @override
  String get brainFoodNone => 'Add what’s in your pantry and I’ll suggest meals that use it.';

  @override
  String brainScore(int score) {
    return 'Your Life Score today is $score/100.';
  }

  @override
  String get brainScoreNone => 'No score yet today — log your mood or finish a goal and it will appear.';

  @override
  String get brainFeelLow =>
      'I’m sorry today feels heavy. Try one tiny thing: a glass of water, a short walk or three slow breaths. Logging your mood can help too.';

  @override
  String get brainSleep =>
      'Keep a steady bedtime and put screens away 30 minutes before. You can log your sleep from Home.';

  @override
  String get brainHabit => 'Small habits win. Pick something that takes under two minutes and track it in Habits.';

  @override
  String get brainHelp =>
      'Pick a topic below — money, decisions, food, messages or a quick calculation — and I’ll walk you through it.';

  @override
  String get brainFallback =>
      'I’m still learning that one. Try asking about your plan, money, food or how your day is going.';

  @override
  String get brainAnswerLabel => 'Lio · on your phone';

  @override
  String homeHello(String name) {
    return 'Hi $name 👋';
  }

  @override
  String get homeHelloNoName => 'Hi there 👋';

  @override
  String get homeQuestion => 'What should we solve today?';

  @override
  String get problemHint => 'Type a problem…';

  @override
  String get problemEx1 => 'I have 3,000 left and 20 days to go';

  @override
  String get problemEx2 => '1 L for 45 or 1.5 L for 60 — which is cheaper?';

  @override
  String get problemEx3 => 'I have eggs, tomatoes and cheese at home';

  @override
  String get problemEx4 => 'iPhone or Samsung?';

  @override
  String get problemEx5 => 'Split a 1,840 bill between 4 people';

  @override
  String get problemEx6 => '30% off 1,299 — what do I pay?';

  @override
  String get problemEx7 => 'How many days until December 31?';

  @override
  String get solve => 'Solve';

  @override
  String get voiceInput => 'Speak';

  @override
  String get photoInput => 'Photo';

  @override
  String get listening => 'Listening…';

  @override
  String get voiceUnavailable => 'Voice input isn’t available on this device.';

  @override
  String get photoNoText => 'I couldn’t read any text in that photo.';

  @override
  String get quickMoney => 'Money';

  @override
  String get quickDecide => 'Decide';

  @override
  String get quickFood => 'Food';

  @override
  String get quickCalc => 'Calculate';

  @override
  String get quickWrite => 'Write';

  @override
  String get quickPlan => 'Plan';

  @override
  String get recentlySolved => 'Recently solved';

  @override
  String get solutionTitle => 'Solution';

  @override
  String get solvedOnDevice => 'Calculated on your phone';

  @override
  String get savedToast => 'Saved';

  @override
  String get askLioAbout => 'Ask Lio about this';

  @override
  String get solveAnother => 'Solve something else';

  @override
  String get rowPerDay => 'Per day';

  @override
  String get rowPerWeek => 'Per week';

  @override
  String get rowDays => 'Days';

  @override
  String get rowTotal => 'Total';

  @override
  String get rowYouSave => 'You save';

  @override
  String get rowTax => 'Tax';

  @override
  String get rowIncrease => 'Increase';

  @override
  String get rowPrice => 'Price';

  @override
  String get rowPerPerson => 'Per person';

  @override
  String get rowPeople => 'People';

  @override
  String get rowTip => 'Tip';

  @override
  String get rowMonthly => 'Monthly';

  @override
  String get rowMonths => 'Months';

  @override
  String get rowCash => 'Cash price';

  @override
  String get rowExtra => 'Extra you pay';

  @override
  String get rowDistance => 'Distance';

  @override
  String get rowFuel => 'Fuel';

  @override
  String get rowYearly => 'Yearly';

  @override
  String get rowDate => 'Date';

  @override
  String runwayHeadline(String amount) {
    return 'You can spend $amount a day.';
  }

  @override
  String runwayMonthEnd(int days) {
    return 'Counted to the end of the month ($days days, today included).';
  }

  @override
  String discountHeadline(String amount) {
    return 'You pay $amount.';
  }

  @override
  String vatHeadline(String amount) {
    return 'Total with VAT: $amount.';
  }

  @override
  String raiseHeadline(String amount) {
    return 'New amount: $amount.';
  }

  @override
  String percentOfHeadline(String percent, String base, String result) {
    return '$percent% of $base is $result.';
  }

  @override
  String splitHeadline(String amount) {
    return 'Each person pays $amount.';
  }

  @override
  String installmentMore(String amount, String percent) {
    return 'Instalments cost $amount more than paying cash ($percent%).';
  }

  @override
  String get installmentNoMore => 'Instalments cost no more than cash — spreading it out is fine.';

  @override
  String installmentTotal(String amount) {
    return 'You will pay $amount in total.';
  }

  @override
  String unitPriceHeadline(int n, String price, String unit) {
    return 'Option $n is cheaper: $price per $unit.';
  }

  @override
  String unitPriceSaving(String percent) {
    return 'About $percent% cheaper per unit.';
  }

  @override
  String get unitPriceSame => 'They cost the same per unit — pick the size you’ll actually use.';

  @override
  String get unitPieceLabel => 'piece';

  @override
  String fuelHeadline(String amount) {
    return 'The trip costs about $amount in fuel.';
  }

  @override
  String yearlyHeadline(String amount) {
    return 'That is $amount a year.';
  }

  @override
  String daysUntilHeadline(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days to go.',
      one: '1 day to go.',
      zero: 'It’s today!',
    );
    return '$_temp0';
  }

  @override
  String optionN(int n) {
    return 'Option $n';
  }

  @override
  String get decideTitle => 'Decide';

  @override
  String get decideIntro => 'Add your options and what matters to you. I’ll weigh them up.';

  @override
  String get decideAddOption => 'Add option';

  @override
  String get decidePrice => 'Price (optional)';

  @override
  String get decideWhatMatters => 'What matters?';

  @override
  String get critPrice => 'Price';

  @override
  String get critQuality => 'Quality';

  @override
  String get critFit => 'Fits my needs';

  @override
  String get critLongTerm => 'Long-term value';

  @override
  String get critRisk => 'Low risk';

  @override
  String get critCustomHint => 'Something else that matters';

  @override
  String get weight1 => 'Nice to have';

  @override
  String get weight2 => 'Important';

  @override
  String get weight3 => 'Must';

  @override
  String get decideRate => 'Rate each option';

  @override
  String get decideRateHelp => '1 = poor, 5 = great. Price is scored from the prices you entered.';

  @override
  String get decideShow => 'Show the best option';

  @override
  String get decideRecommended => 'Recommended';

  @override
  String get decideWhy => 'Why?';

  @override
  String decideStrength(String criterion) {
    return 'Better on $criterion';
  }

  @override
  String decideWeakness(String criterion) {
    return 'Weaker on $criterion';
  }

  @override
  String get decideTooClose => 'It’s very close — both are reasonable. Let what you value most decide.';

  @override
  String get decideSlight => 'A slight edge, not a big one.';

  @override
  String get decideClear => 'A clear winner for your priorities.';

  @override
  String get decideDisclaimer => 'Based on your own ratings. Check current prices and details before you buy.';

  @override
  String get decideNeedTwo => 'Add at least two options.';

  @override
  String decideScore(int score) {
    return '$score/100';
  }

  @override
  String get calcTitle => 'Calculator';

  @override
  String get calcError => 'Check the expression';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get exploreSolve => 'Solve';

  @override
  String get exploreLife => 'Track';

  @override
  String get exploreMyDay => 'My day';

  @override
  String get exploreMyDayBody => 'Plan, budget and goals for today';

  @override
  String get savedTitle => 'Saved';

  @override
  String get savedEmptyTitle => 'Nothing saved yet';

  @override
  String get savedEmptyBody => 'Solve a problem and tap Save to keep it here.';

  @override
  String get removed => 'Removed';

  @override
  String get recipeHeadline => 'You can make these with what you have';

  @override
  String recipeMissing(String items) {
    return 'Missing: $items';
  }

  @override
  String get recipeHaveAll => 'You have everything';

  @override
  String recipeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get addMissingToList => 'Add missing to shopping list';

  @override
  String get addedToList => 'Added to your shopping list';

  @override
  String get recipeNoMatch => 'I couldn’t match those ingredients to a recipe yet. Ask Lio for ideas.';

  @override
  String get gTypeHint => 'Or type your problem…';

  @override
  String get gAnswerHint => 'Type your answer…';

  @override
  String get gRestart => 'Start over';

  @override
  String get gMainMenu => 'Main menu';

  @override
  String get gSomethingElse => 'Something else';

  @override
  String get gNotUnderstood => 'I can’t do that one yet. Pick a topic and I’ll help step by step.';

  @override
  String get gInvalidNumber => 'That doesn’t look like a number. Try again?';

  @override
  String get gMood => 'Mood boost';

  @override
  String get gRemind => 'Remind me';

  @override
  String get gRemindPrompt => 'What should I remind you about?';

  @override
  String get gMoneyPrompt => 'What should we figure out?';

  @override
  String get gRunway => 'Will my money last?';

  @override
  String get gDiscount => 'Discount';

  @override
  String get gSplit => 'Split the bill';

  @override
  String get gInstallment => 'Instalments or cash?';

  @override
  String get gUnitPrice => 'Which is cheaper?';

  @override
  String get gVat => 'Add VAT';

  @override
  String get gRaise => 'Salary raise';

  @override
  String get gYearly => 'Yearly cost of subscriptions';

  @override
  String get gCalcPrompt => 'What should we calculate?';

  @override
  String get gPercentOf => 'Percent of a number';

  @override
  String get gConvert => 'Convert units';

  @override
  String get gDaysUntil => 'Days until a date';

  @override
  String get gFuel => 'Trip fuel cost';

  @override
  String get gOpenCalculator => 'Open the calculator';

  @override
  String get qAmountLeft => 'How much money do you have left?';

  @override
  String get qDaysLeft => 'How many days does it need to last?';

  @override
  String get qMonthEnd => 'Until month end';

  @override
  String get qPrice => 'What’s the price?';

  @override
  String get qDiscountPct => 'How many percent off?';

  @override
  String get qTotal => 'What’s the total bill?';

  @override
  String get qPeople => 'How many people?';

  @override
  String get qTip => 'Any tip?';

  @override
  String get qNoTip => 'No tip';

  @override
  String get qMonthly => 'How much is each instalment?';

  @override
  String get qMonths => 'How many months?';

  @override
  String get qCash => 'What’s the cash price? (skip if you don’t know)';

  @override
  String get qSize1 => 'First option: how much is in it? (e.g. 1 L, 500 g, 6 pcs)';

  @override
  String get qPrice1 => 'And its price?';

  @override
  String get qSize2 => 'Second option: how much is in it?';

  @override
  String get qPrice2 => 'And its price?';

  @override
  String get qNeedUnit => 'Add a unit, like 1 L, 500 g or 6 pcs.';

  @override
  String get qVatRate => 'Which VAT rate?';

  @override
  String get qSalary => 'What’s the current amount?';

  @override
  String get qRaisePct => 'How many percent is the raise?';

  @override
  String get qSubs => 'Monthly amounts, separated by commas (e.g. 99, 149)';

  @override
  String get qNumber => 'Which number?';

  @override
  String get qPercent => 'What percent?';

  @override
  String get qConvert => 'What should I convert? (e.g. 5 kg to lb)';

  @override
  String get qDate => 'Which date? (e.g. 31 December)';

  @override
  String get qKm => 'How many km is the trip?';

  @override
  String get qConsumption => 'How many litres per 100 km?';

  @override
  String get qFuelPrice => 'Fuel price per litre?';

  @override
  String get gConvertFail => 'I couldn’t read that. Try “5 kg to lb” or “30 C to F”.';

  @override
  String get gDateFail => 'I couldn’t read that date. Try “31 December”.';

  @override
  String get gDecidePrompt => 'Let’s decide. What are your options?';

  @override
  String get qOptions => 'Write your options (e.g. pizza sushi)';

  @override
  String get gDecideCompare => 'Compare them properly';

  @override
  String get gCoin => 'Flip a coin';

  @override
  String get gRandomPick => 'Pick one for me';

  @override
  String get coinHeads => 'Heads! 🪙';

  @override
  String get coinTails => 'Tails! 🪙';

  @override
  String randomPicked(String option) {
    return 'I pick $option! 🎲';
  }

  @override
  String get gFoodPrompt => 'Food time! What do you need?';

  @override
  String get gCookWithWhatIHave => 'Cook with what I have';

  @override
  String get qIngredients => 'What do you have? (e.g. eggs tomatoes cheese)';

  @override
  String get gWhatToEat => 'What should I eat?';

  @override
  String get gShoppingList => 'My shopping list';

  @override
  String get gRecipes => 'Recipes';

  @override
  String mealIdea(String meal, int minutes) {
    return 'How about $meal? Ready in about $minutes min.';
  }

  @override
  String get gAnotherIdea => 'Another idea';

  @override
  String get gWritePrompt => 'What kind of message should we write?';

  @override
  String get tplBirthday => 'Birthday wishes';

  @override
  String get tplThanks => 'Thank you';

  @override
  String get tplApology => 'Apology';

  @override
  String get tplLate => 'Running late';

  @override
  String get tplLeave => 'Asking for time off';

  @override
  String get tplDecline => 'Saying no politely';

  @override
  String get tplCongrats => 'Congratulations';

  @override
  String get tplCondolence => 'Condolences';

  @override
  String get tplPayment => 'Payment reminder';

  @override
  String get tplComplaint => 'Complaint to a company';

  @override
  String get tplJob => 'Job application';

  @override
  String get tplLandlord => 'Message to the landlord';

  @override
  String get qTone => 'Which tone?';

  @override
  String get toneWarm => 'Warm';

  @override
  String get toneFormal => 'Formal';

  @override
  String get toneShort => 'Short';

  @override
  String get fName => 'Who is it for? (a name, or skip)';

  @override
  String get fCompany => 'Which company?';

  @override
  String get fWhatThanks => 'What are you thanking them for?';

  @override
  String get fWhatApology => 'What are you apologising for?';

  @override
  String get fWhatLeave => 'What’s the reason?';

  @override
  String get fWhatDecline => 'What are you saying no to?';

  @override
  String get fWhatCongrats => 'What are you congratulating them on?';

  @override
  String get fWhatPayment => 'Which payment? (e.g. the 500 rent)';

  @override
  String get fWhatComplaint => 'What’s the problem?';

  @override
  String get fWhatJob => 'Which position?';

  @override
  String get fWhatLandlord => 'What needs fixing? (e.g. the boiler)';

  @override
  String get fWhenLate => 'When will you get there? (e.g. in 15 minutes)';

  @override
  String get fWhenLeave => 'Which day(s)? (e.g. on Friday)';

  @override
  String get writeResult => 'Here are a few versions. Copy the one you like.';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get gOtherTone => 'Another tone';

  @override
  String get gOtherMessage => 'Another message';

  @override
  String get gMoodPrompt => 'How are you feeling right now?';

  @override
  String get mTired => 'Tired';

  @override
  String get mStressed => 'Stressed';

  @override
  String get mUnmotivated => 'No motivation';

  @override
  String get mCantSleep => 'Can’t sleep';

  @override
  String get mLonely => 'Lonely';

  @override
  String get mVeryBad => 'Really bad';

  @override
  String get mTiredReply =>
      'That happens. Try this:\n• a glass of water and a 10-minute walk\n• one small task, then a real break\n• an early night tonight';

  @override
  String get mStressedReply =>
      'Let’s slow down for a minute:\n• breathe in for 4, hold for 4, out for 6 — five times\n• write down the one thing that matters most today\n• everything else can wait a little';

  @override
  String get mUnmotivatedReply =>
      'Motivation often comes after starting, not before:\n• pick a 2-minute version of the task\n• set a 10-minute timer and just begin\n• reward yourself when it rings';

  @override
  String get mCantSleepReply =>
      'For tonight:\n• put the screen away and dim the lights\n• keep the room cool\n• if you’re still awake after 20 minutes, get up, read something calm, then try again';

  @override
  String get mLonelyReply =>
      'Feeling lonely is hard, and you’re not the only one. A small step can help: message one person you miss, or go somewhere with people around for a bit — a café, a park, a class.';

  @override
  String get mVeryBadReply =>
      'I’m really sorry you’re feeling this way. You don’t have to carry it alone — please talk to someone you trust today. If you are in danger or thinking about hurting yourself, call your local emergency number now (112 in Türkiye and Europe, 911 in the US).';

  @override
  String get gInspire => 'Inspire me';

  @override
  String get gMyDayPrompt => 'What would you like to know about today?';

  @override
  String get gTodayPlan => 'Today’s plan';

  @override
  String get gSpendToday => 'How much can I spend today?';

  @override
  String get gMyScore => 'My Life Score';

  @override
  String get gOpenMyDay => 'Open My day';

  @override
  String get pPrompt =>
      'Let’s plan your day! What do you need to get done today? (e.g. write the report, call mom, gym)';

  @override
  String pAlready(String tasks) {
    return 'You already have these today: $tasks. Add them to the plan?';
  }

  @override
  String get pYes => 'Yes';

  @override
  String get pNo => 'No';

  @override
  String get pImportant => 'Which one matters most?';

  @override
  String get pAllSame => 'All equal';

  @override
  String get pDuration => 'Roughly how long does each one take?';

  @override
  String pHours(int hours) {
    return '$hours h';
  }

  @override
  String get pStart => 'When should we start?';

  @override
  String get pNow => 'Now';

  @override
  String get pTimeFail => 'Write a time like 09:30.';

  @override
  String get pResult => 'Here’s your plan for today:';

  @override
  String get pFixed => 'already scheduled';

  @override
  String get pBreaks => 'I left 10 minutes between tasks so you can breathe.';

  @override
  String pDidntFit(String tasks) {
    return 'These didn’t fit today: $tasks';
  }

  @override
  String get pAddToDay => 'Add to my day';

  @override
  String get pAdded => 'Done! Your plan is in Plan, with reminders.';

  @override
  String get pRedo => 'Plan again';

  @override
  String get pOpenPlan => 'Open Plan';

  @override
  String get pNothing => 'Nothing to plan yet. Tell me at least one thing to do.';

  @override
  String get lioSuggestions => 'Lio’s suggestions';

  @override
  String get lioAllGood => 'All looks good today. I’ll tell you when something needs attention.';

  @override
  String get insightsTitle => 'Suggestions';

  @override
  String get insightsIntro => 'I looked at your money, plans, habits, mood and journal. Here’s what stood out.';

  @override
  String insightsMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more suggestions',
      one: '1 more suggestion',
    );
    return '$_temp0';
  }

  @override
  String get insightsUnlock => 'Watch an ad to see them all today';

  @override
  String get gMySuggestions => 'My suggestions';

  @override
  String advOverBudget(String amount) {
    return 'You’re $amount over today’s budget. Let’s keep tomorrow light.';
  }

  @override
  String advBudgetTight(String amount) {
    return 'Only $amount left for today. A no-spend evening would help.';
  }

  @override
  String advSavingsOff(String amount) {
    return 'At this pace you’ll miss your savings goal by about $amount this month.';
  }

  @override
  String get advSetUpBudget =>
      'You’ve logged several expenses. Add your monthly income and I’ll work out a safe daily limit.';

  @override
  String advWeeklyUp(int percent) {
    return 'You spent $percent% more this week than usual.';
  }

  @override
  String advWeeklyDown(int percent) {
    return 'Nice! You spent $percent% less this week than usual.';
  }

  @override
  String advCategorySpike(String category, int percent) {
    return '$category spending is up $percent% compared with last month.';
  }

  @override
  String advSubscriptions(int count, String names, String amount) {
    return 'Looks like $count subscriptions ($names), about $amount a year. Still using them all?';
  }

  @override
  String advTopCategory(String category, int percent) {
    return '$category is $percent% of your spending this month.';
  }

  @override
  String advOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks are overdue.',
      one: '1 task is overdue.',
    );
    return '$_temp0 Shall we fit them into today?';
  }

  @override
  String get advNoPlan => 'Nothing planned for today yet. Two minutes with me and your day has a shape.';

  @override
  String advUnscheduled(int count) {
    return '$count tasks today have no time yet. Want me to schedule them?';
  }

  @override
  String advTasksGood(int count) {
    return '$count tasks done this week. Great rhythm!';
  }

  @override
  String advHabitRisk(int count, String name) {
    return 'Your $count-day $name streak is waiting for today.';
  }

  @override
  String advHabitDown(int percent) {
    return 'Habits slipped $percent points this week. Pick one small win for today.';
  }

  @override
  String advHabitUp(int percent) {
    return 'Habits are up $percent points this week. Keep going!';
  }

  @override
  String get advMoodDown => 'Your mood has been lower this week. Want to talk it through or write a few lines?';

  @override
  String get advMoodSleep => 'On short-sleep days your mood tends to be lower. An earlier night might help.';

  @override
  String get advJournalNudge => 'How was today? Two lines in your journal is enough.';

  @override
  String advJournalStreak(int count) {
    return '$count days of journaling in a row. Lovely habit.';
  }

  @override
  String advShopping(int count) {
    return '$count items are waiting on your shopping list.';
  }

  @override
  String advCook(String name, int minutes) {
    return 'You have everything for $name ($minutes min).';
  }

  @override
  String get actOpenMoney => 'Open Money';

  @override
  String get actPlanDay => 'Plan my day';

  @override
  String get actOpenPlan => 'Open Plan';

  @override
  String get actOpenHabits => 'Open Habits';

  @override
  String get actTalk => 'Talk to Lio';

  @override
  String get actLogMood => 'Log sleep & mood';

  @override
  String get actWrite => 'Write';

  @override
  String get actShopping => 'Open list';

  @override
  String get actRecipe => 'See recipe';

  @override
  String get quickJournal => 'Journal';

  @override
  String advJournalLift(String word) {
    return 'On days you write about “$word”, your mood is usually better. Make some room for it today?';
  }

  @override
  String advJournalDrain(String word) {
    return 'Days with “$word” in your journal tend to be harder. Anything you can plan around it?';
  }

  @override
  String get journalKnowsTitle => 'What Lio has learned';

  @override
  String get journalThemes => 'You write most about';

  @override
  String get journalLifts => 'Lifts your mood';

  @override
  String get journalDrains => 'Makes days harder';

  @override
  String get journalLearnHint => 'Keep writing and logging how you feel; I’ll spot patterns after about a week.';

  @override
  String get journalOnDevice => 'Learned on this phone only.';

  @override
  String journalStreakLabel(int count) {
    return '$count-day streak';
  }

  @override
  String journalThisMonth(int count) {
    return '$count this month';
  }

  @override
  String get journalMoodWeek => 'Mood this week';

  @override
  String get journalSearch => 'Search your journal';

  @override
  String get journalTodayPrompt => 'Today’s question';

  @override
  String get journalHowFeel => 'How do you feel?';

  @override
  String journalWords(int count) {
    return '$count words';
  }

  @override
  String get journalNoResults => 'No entries match.';

  @override
  String get journalWriteToday => 'Write today’s entry';

  @override
  String get journalSaved => 'Saved to your journal';

  @override
  String get jp1 => 'What made you smile today?';

  @override
  String get jp2 => 'What are you grateful for?';

  @override
  String get jp3 => 'What drained your energy today?';

  @override
  String get jp4 => 'What will you do differently tomorrow?';

  @override
  String get jp5 => 'One thing you learned today';

  @override
  String get jp6 => 'Who made your day better?';

  @override
  String get jp7 => 'What are you looking forward to?';
}
