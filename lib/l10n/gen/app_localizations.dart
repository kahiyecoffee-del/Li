import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('tr')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Dayly'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Make every day a good one.'**
  String get appTagline;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @hoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String hoursMinutes(int hours, int minutes);

  /// No description provided for @percentValue.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String percentValue(int value);

  /// No description provided for @outOf100.
  ///
  /// In en, this message translates to:
  /// **'{value}/100'**
  String outOf100(int value);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check your connection and try again.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'This is taking too long. Try again.'**
  String get errorTimeout;

  /// No description provided for @errorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This feature isn\'t available right now.'**
  String get errorUnavailable;

  /// No description provided for @errorAiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The assistant needs an internet connection and a configured backend. Everything else works offline.'**
  String get errorAiUnavailable;

  /// No description provided for @errorQuota.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s free AI requests.'**
  String get errorQuota;

  /// No description provided for @errorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You\'re going a bit fast. Wait a moment and try again.'**
  String get errorRateLimited;

  /// No description provided for @errorAuth.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get errorAuth;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get errorPermission;

  /// No description provided for @errorInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Please check what you entered.'**
  String get errorInvalidInput;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This account already exists. Try signing in instead.'**
  String get errorEmailInUse;

  /// No description provided for @errorWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password doesn\'t match.'**
  String get errorWrongCredentials;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters for your password.'**
  String get errorWeakPassword;

  /// No description provided for @errorRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'For your security, sign in again and retry.'**
  String get errorRecentLogin;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — changes are saved and will sync later.'**
  String get offlineBanner;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @navMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get navMoney;

  /// No description provided for @navLife.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get navLife;

  /// No description provided for @navAi.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get navAi;

  /// No description provided for @profileAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile and settings'**
  String get profileAndSettings;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hi, I’m Lio! Let’s make today a good day.'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Plans, money, food, habits and an assistant that connects them — in one calm place.'**
  String get welcomeBody;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox for a reset link.'**
  String get passwordResetSent;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @localModeNotice.
  ///
  /// In en, this message translates to:
  /// **'Running in on-device mode: cloud sync, AI and purchases need Firebase to be configured.'**
  String get localModeNotice;

  /// No description provided for @linkAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure your data'**
  String get linkAccountTitle;

  /// No description provided for @linkAccountBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re using a guest account. Link Google or email to keep your data if you change phones.'**
  String get linkAccountBody;

  /// No description provided for @linkGoogle.
  ///
  /// In en, this message translates to:
  /// **'Link Google account'**
  String get linkGoogle;

  /// No description provided for @linkEmail.
  ///
  /// In en, this message translates to:
  /// **'Link email'**
  String get linkEmail;

  /// No description provided for @accountLinked.
  ///
  /// In en, this message translates to:
  /// **'Account linked. Your data is safe.'**
  String get accountLinked;

  /// No description provided for @guestAccount.
  ///
  /// In en, this message translates to:
  /// **'Guest account'**
  String get guestAccount;

  /// No description provided for @onbNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onbNameTitle;

  /// No description provided for @onbNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your first name'**
  String get onbNameHint;

  /// No description provided for @onbFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to improve?'**
  String get onbFocusTitle;

  /// No description provided for @onbFocusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick as many as you like. This shapes your home screen.'**
  String get onbFocusSubtitle;

  /// No description provided for @onbIncomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Typical monthly income'**
  String get onbIncomeTitle;

  /// No description provided for @onbIncomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used only to calculate your safe daily spending. Stays private.'**
  String get onbIncomeSubtitle;

  /// No description provided for @onbFixedLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed monthly costs (rent, bills)'**
  String get onbFixedLabel;

  /// No description provided for @onbSavingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly savings goal'**
  String get onbSavingsTitle;

  /// No description provided for @onbSavingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll set aside this amount before telling you what\'s safe to spend.'**
  String get onbSavingsSubtitle;

  /// No description provided for @onbRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily routine'**
  String get onbRoutineTitle;

  /// No description provided for @onbWake.
  ///
  /// In en, this message translates to:
  /// **'I usually wake up at'**
  String get onbWake;

  /// No description provided for @onbSleep.
  ///
  /// In en, this message translates to:
  /// **'I usually go to bed at'**
  String get onbSleep;

  /// No description provided for @onbFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Food preferences'**
  String get onbFoodTitle;

  /// No description provided for @onbDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get onbDiet;

  /// No description provided for @onbAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies or foods to avoid'**
  String get onbAllergies;

  /// No description provided for @onbAllergiesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. peanuts, mushrooms'**
  String get onbAllergiesHint;

  /// No description provided for @onbNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle reminders'**
  String get onbNotifTitle;

  /// No description provided for @onbNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Meeting reminders and at most a few helpful nudges a day. You can change this anytime.'**
  String get onbNotifBody;

  /// No description provided for @onbNotifAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get onbNotifAllow;

  /// No description provided for @onbLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Local weather'**
  String get onbLocationTitle;

  /// No description provided for @onbLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Use your approximate location, or pick a city. Location is optional.'**
  String get onbLocationBody;

  /// No description provided for @onbUseLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get onbUseLocation;

  /// No description provided for @onbPickCity.
  ///
  /// In en, this message translates to:
  /// **'Search a city'**
  String get onbPickCity;

  /// No description provided for @onbReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Dayly is ready for you!'**
  String get onbReadyTitle;

  /// No description provided for @onbReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your home screen now shows what matters for you today.'**
  String get onbReadyBody;

  /// No description provided for @onbOpenHome.
  ///
  /// In en, this message translates to:
  /// **'Open my day'**
  String get onbOpenHome;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String greetingMorning(String name);

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String greetingAfternoon(String name);

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String greetingEvening(String name);

  /// No description provided for @greetingNoName.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get greetingNoName;

  /// No description provided for @dayAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Your day at a glance.'**
  String get dayAtAGlance;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeNoPlan.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet.'**
  String get homeNoPlan;

  /// No description provided for @homePlanDay.
  ///
  /// In en, this message translates to:
  /// **'Plan my day'**
  String get homePlanDay;

  /// No description provided for @homeMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get homeMoney;

  /// No description provided for @safeSpendingToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s safe spending'**
  String get safeSpendingToday;

  /// No description provided for @leftToday.
  ///
  /// In en, this message translates to:
  /// **'{amount} left today'**
  String leftToday(String amount);

  /// No description provided for @overToday.
  ///
  /// In en, this message translates to:
  /// **'{amount} over today'**
  String overToday(String amount);

  /// No description provided for @setUpBudget.
  ///
  /// In en, this message translates to:
  /// **'Set up your budget'**
  String get setUpBudget;

  /// No description provided for @setUpBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'Add your income to see how much you can safely spend each day.'**
  String get setUpBudgetBody;

  /// No description provided for @homeFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get homeFood;

  /// No description provided for @suggestedMeal.
  ///
  /// In en, this message translates to:
  /// **'Suggested {meal}'**
  String suggestedMeal(String meal);

  /// No description provided for @homeWellbeing.
  ///
  /// In en, this message translates to:
  /// **'Wellbeing'**
  String get homeWellbeing;

  /// No description provided for @howAreYou.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get howAreYou;

  /// No description provided for @lifeScore.
  ///
  /// In en, this message translates to:
  /// **'Life Score'**
  String get lifeScore;

  /// No description provided for @todaysGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal: reach {target}'**
  String todaysGoal(int target);

  /// No description provided for @scoreNoData.
  ///
  /// In en, this message translates to:
  /// **'Log a few things today to see your score.'**
  String get scoreNoData;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get forYou;

  /// No description provided for @importantStories.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 story} other{{count} stories}} for you'**
  String importantStories(int count);

  /// No description provided for @insight.
  ///
  /// In en, this message translates to:
  /// **'Insight'**
  String get insight;

  /// No description provided for @dailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily goals'**
  String get dailyGoals;

  /// No description provided for @lifeProgress.
  ///
  /// In en, this message translates to:
  /// **'Life progress {value}%'**
  String lifeProgress(int value);

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1-day streak} other{{count}-day streak}}'**
  String streakDays(int count);

  /// No description provided for @streakAtRisk.
  ///
  /// In en, this message translates to:
  /// **'Log anything today to keep your streak.'**
  String get streakAtRisk;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick add'**
  String get quickAdd;

  /// No description provided for @quickExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get quickExpense;

  /// No description provided for @quickTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get quickTask;

  /// No description provided for @quickMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get quickMood;

  /// No description provided for @quickAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get quickAsk;

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClear;

  /// No description provided for @weatherPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherPartlyCloudy;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// No description provided for @weatherFog.
  ///
  /// In en, this message translates to:
  /// **'Foggy'**
  String get weatherFog;

  /// No description provided for @weatherDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherDrizzle;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// No description provided for @weatherThunder.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunder;

  /// No description provided for @rainChance.
  ///
  /// In en, this message translates to:
  /// **'{value}% rain'**
  String rainChance(int value);

  /// No description provided for @highLow.
  ///
  /// In en, this message translates to:
  /// **'H {high}° · L {low}°'**
  String highLow(int high, int low);

  /// No description provided for @setCityForWeather.
  ///
  /// In en, this message translates to:
  /// **'Add your city for local weather'**
  String get setCityForWeather;

  /// No description provided for @scoreComponentMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get scoreComponentMoney;

  /// No description provided for @scoreComponentHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get scoreComponentHealth;

  /// No description provided for @scoreComponentProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get scoreComponentProductivity;

  /// No description provided for @scoreComponentHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get scoreComponentHabits;

  /// No description provided for @scoreComponentMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get scoreComponentMood;

  /// No description provided for @scoreComponentSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get scoreComponentSleep;

  /// No description provided for @scoreComponentPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get scoreComponentPlanning;

  /// No description provided for @scoreUp.
  ///
  /// In en, this message translates to:
  /// **'Your score rose {points} points today, mainly thanks to {reasons}.'**
  String scoreUp(int points, String reasons);

  /// No description provided for @scoreDown.
  ///
  /// In en, this message translates to:
  /// **'Your score dropped {points} points today, mainly because of {reasons}.'**
  String scoreDown(int points, String reasons);

  /// No description provided for @scoreSame.
  ///
  /// In en, this message translates to:
  /// **'Your score is steady compared with yesterday.'**
  String get scoreSame;

  /// No description provided for @scoreFirstDay.
  ///
  /// In en, this message translates to:
  /// **'This is your first score. Come back tomorrow to see what changed.'**
  String get scoreFirstDay;

  /// No description provided for @reasonAnd.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b}'**
  String reasonAnd(String a, String b);

  /// No description provided for @reasonMoneyUp.
  ///
  /// In en, this message translates to:
  /// **'lower spending'**
  String get reasonMoneyUp;

  /// No description provided for @reasonMoneyDown.
  ///
  /// In en, this message translates to:
  /// **'higher spending'**
  String get reasonMoneyDown;

  /// No description provided for @reasonHealthUp.
  ///
  /// In en, this message translates to:
  /// **'healthier habits'**
  String get reasonHealthUp;

  /// No description provided for @reasonHealthDown.
  ///
  /// In en, this message translates to:
  /// **'fewer health habits'**
  String get reasonHealthDown;

  /// No description provided for @reasonProductivityUp.
  ///
  /// In en, this message translates to:
  /// **'finished tasks'**
  String get reasonProductivityUp;

  /// No description provided for @reasonProductivityDown.
  ///
  /// In en, this message translates to:
  /// **'unfinished tasks'**
  String get reasonProductivityDown;

  /// No description provided for @reasonHabitsUp.
  ///
  /// In en, this message translates to:
  /// **'habit progress'**
  String get reasonHabitsUp;

  /// No description provided for @reasonHabitsDown.
  ///
  /// In en, this message translates to:
  /// **'missed habits'**
  String get reasonHabitsDown;

  /// No description provided for @reasonMoodUp.
  ///
  /// In en, this message translates to:
  /// **'a better mood'**
  String get reasonMoodUp;

  /// No description provided for @reasonMoodDown.
  ///
  /// In en, this message translates to:
  /// **'a lower mood'**
  String get reasonMoodDown;

  /// No description provided for @reasonSleepUp.
  ///
  /// In en, this message translates to:
  /// **'better sleep'**
  String get reasonSleepUp;

  /// No description provided for @reasonSleepDown.
  ///
  /// In en, this message translates to:
  /// **'reduced sleep'**
  String get reasonSleepDown;

  /// No description provided for @reasonPlanningUp.
  ///
  /// In en, this message translates to:
  /// **'better planning'**
  String get reasonPlanningUp;

  /// No description provided for @reasonPlanningDown.
  ///
  /// In en, this message translates to:
  /// **'less planning'**
  String get reasonPlanningDown;

  /// No description provided for @scoreHowCalculated.
  ///
  /// In en, this message translates to:
  /// **'How is this calculated?'**
  String get scoreHowCalculated;

  /// No description provided for @scoreExplainer.
  ///
  /// In en, this message translates to:
  /// **'Your Life Score is a weighted average of the areas you track: money 20%, productivity 20%, health 15%, habits 15%, mood 10%, sleep 10%, planning 10%. Areas without data are left out, so not using a feature never lowers your score. AI never decides your score.'**
  String get scoreExplainer;

  /// No description provided for @scoreWeakest.
  ///
  /// In en, this message translates to:
  /// **'Biggest opportunity: {area}'**
  String scoreWeakest(String area);

  /// No description provided for @scoreBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get scoreBreakdown;

  /// No description provided for @scoreHistory.
  ///
  /// In en, this message translates to:
  /// **'Last 14 days'**
  String get scoreHistory;

  /// No description provided for @unlockBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad to see today’s breakdown'**
  String get unlockBreakdown;

  /// No description provided for @logSleep.
  ///
  /// In en, this message translates to:
  /// **'Log sleep'**
  String get logSleep;

  /// No description provided for @sleepHoursQuestion.
  ///
  /// In en, this message translates to:
  /// **'How long did you sleep last night?'**
  String get sleepHoursQuestion;

  /// No description provided for @goalSpending.
  ///
  /// In en, this message translates to:
  /// **'Stay under {amount}'**
  String goalSpending(String amount);

  /// No description provided for @goalHabit.
  ///
  /// In en, this message translates to:
  /// **'{name}: {done}/{target}'**
  String goalHabit(String name, int done, int target);

  /// No description provided for @goalTopTask.
  ///
  /// In en, this message translates to:
  /// **'Finish: {title}'**
  String goalTopTask(String title);

  /// No description provided for @goalLogMood.
  ///
  /// In en, this message translates to:
  /// **'Check in with your mood'**
  String get goalLogMood;

  /// No description provided for @goalLogSleep.
  ///
  /// In en, this message translates to:
  /// **'Log last night\'s sleep'**
  String get goalLogSleep;

  /// No description provided for @goalPlanDay.
  ///
  /// In en, this message translates to:
  /// **'Plan your day'**
  String get goalPlanDay;

  /// No description provided for @insightWeeklyUp.
  ///
  /// In en, this message translates to:
  /// **'Your spending this week is {percent}% higher than your weekly average.'**
  String insightWeeklyUp(int percent);

  /// No description provided for @insightWeeklyDown.
  ///
  /// In en, this message translates to:
  /// **'Your spending this week is {percent}% lower than your weekly average.'**
  String insightWeeklyDown(int percent);

  /// No description provided for @insightCategoryUp.
  ///
  /// In en, this message translates to:
  /// **'You spent {percent}% more on {category} this month.'**
  String insightCategoryUp(int percent, String category);

  /// No description provided for @insightCategoryDown.
  ///
  /// In en, this message translates to:
  /// **'You spent {percent}% less on {category} this month.'**
  String insightCategoryDown(int percent, String category);

  /// No description provided for @insightHabitUp.
  ///
  /// In en, this message translates to:
  /// **'Your habit completion rate improved {percent}% this week.'**
  String insightHabitUp(int percent);

  /// No description provided for @insightHabitDown.
  ///
  /// In en, this message translates to:
  /// **'Your habit completion rate dropped {percent}% this week.'**
  String insightHabitDown(int percent);

  /// No description provided for @insightMoodSleep.
  ///
  /// In en, this message translates to:
  /// **'You tend to report a lower mood on days with less sleep.'**
  String get insightMoodSleep;

  /// No description provided for @insightBudgetTight.
  ///
  /// In en, this message translates to:
  /// **'Your budget is getting tight today.'**
  String get insightBudgetTight;

  /// No description provided for @insightNone.
  ///
  /// In en, this message translates to:
  /// **'Keep logging — insights appear once there’s enough data.'**
  String get insightNone;

  /// No description provided for @planToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get planToday;

  /// No description provided for @planWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get planWeek;

  /// No description provided for @planMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get planMonth;

  /// No description provided for @planEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks here yet. Add one or ask AI to plan your day.'**
  String get planEmpty;

  /// No description provided for @planOptimize.
  ///
  /// In en, this message translates to:
  /// **'Optimize my plan'**
  String get planOptimize;

  /// No description provided for @planOptimized.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to schedule.} =1{Scheduled 1 task.} other{Scheduled {count} tasks.}}'**
  String planOptimized(int count);

  /// No description provided for @planUnscheduled.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get planUnscheduled;

  /// No description provided for @planOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get planOverdue;

  /// No description provided for @planCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get planCompleted;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get newTask;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitle;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Gym, Call mom'**
  String get taskTitleHint;

  /// No description provided for @taskPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskPriority;

  /// No description provided for @taskDuration.
  ///
  /// In en, this message translates to:
  /// **'Estimated duration'**
  String get taskDuration;

  /// No description provided for @taskCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get taskCategory;

  /// No description provided for @taskDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get taskDate;

  /// No description provided for @taskTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get taskTime;

  /// No description provided for @taskNoTime.
  ///
  /// In en, this message translates to:
  /// **'No time'**
  String get taskNoTime;

  /// No description provided for @taskDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get taskDeadline;

  /// No description provided for @taskRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get taskRepeat;

  /// No description provided for @taskAddedNextOccurrence.
  ///
  /// In en, this message translates to:
  /// **'Next occurrence added.'**
  String get taskAddedNextOccurrence;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNone;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @taskCatWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get taskCatWork;

  /// No description provided for @taskCatPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get taskCatPersonal;

  /// No description provided for @taskCatHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get taskCatHealth;

  /// No description provided for @taskCatErrands.
  ///
  /// In en, this message translates to:
  /// **'Errands'**
  String get taskCatErrands;

  /// No description provided for @taskCatLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get taskCatLearning;

  /// No description provided for @taskCatSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get taskCatSocial;

  /// No description provided for @taskCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get taskCatOther;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get markDone;

  /// No description provided for @markNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as not done'**
  String get markNotDone;

  /// No description provided for @moneyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get moneyIncome;

  /// No description provided for @moneySpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get moneySpent;

  /// No description provided for @moneySaved.
  ///
  /// In en, this message translates to:
  /// **'Savings goal'**
  String get moneySaved;

  /// No description provided for @moneyRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get moneyRemaining;

  /// No description provided for @moneyDailySafe.
  ///
  /// In en, this message translates to:
  /// **'Daily safe spending'**
  String get moneyDailySafe;

  /// No description provided for @moneyOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get moneyOnTrack;

  /// No description provided for @moneyAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get moneyAtRisk;

  /// No description provided for @moneyProjected.
  ///
  /// In en, this message translates to:
  /// **'Projected month-end spend: {amount}'**
  String moneyProjected(String amount);

  /// No description provided for @moneyWeeklyLeft.
  ///
  /// In en, this message translates to:
  /// **'Weekly budget: {amount} left'**
  String moneyWeeklyLeft(String amount);

  /// No description provided for @moneyCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get moneyCategories;

  /// No description provided for @moneyRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get moneyRecent;

  /// No description provided for @moneyNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet. Try typing “250 lunch”.'**
  String get moneyNoTransactions;

  /// No description provided for @moneyBudgetSettings.
  ///
  /// In en, this message translates to:
  /// **'Budget settings'**
  String get moneyBudgetSettings;

  /// No description provided for @moneyAddBudget.
  ///
  /// In en, this message translates to:
  /// **'Add a limit'**
  String get moneyAddBudget;

  /// No description provided for @budgetPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budgetPeriodWeek;

  /// No description provided for @budgetPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetPeriodMonth;

  /// No description provided for @budgetLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get budgetLimit;

  /// No description provided for @budgetAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All spending'**
  String get budgetAllCategories;

  /// No description provided for @budgetCreated.
  ///
  /// In en, this message translates to:
  /// **'Budget saved.'**
  String get budgetCreated;

  /// No description provided for @ofLimit.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {limit}'**
  String ofLimit(String spent, String limit);

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// No description provided for @addIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get addIncome;

  /// No description provided for @smartInputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 250 lunch'**
  String get smartInputHint;

  /// No description provided for @smartInputHelp.
  ///
  /// In en, this message translates to:
  /// **'Type an amount and what it was for. We’ll fill in the rest.'**
  String get smartInputHelp;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceipt;

  /// No description provided for @receiptReview.
  ///
  /// In en, this message translates to:
  /// **'Check the receipt'**
  String get receiptReview;

  /// No description provided for @receiptReviewBody.
  ///
  /// In en, this message translates to:
  /// **'We read this from your photo. Fix anything that looks wrong before saving.'**
  String get receiptReviewBody;

  /// No description provided for @receiptMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get receiptMerchant;

  /// No description provided for @receiptItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get receiptItems;

  /// No description provided for @receiptNothingFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read this receipt. Try a clearer photo or enter it manually.'**
  String get receiptNothingFound;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @expenseSaved.
  ///
  /// In en, this message translates to:
  /// **'Expense saved'**
  String get expenseSaved;

  /// No description provided for @aiParsing.
  ///
  /// In en, this message translates to:
  /// **'Understanding…'**
  String get aiParsing;

  /// No description provided for @catHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get catHousing;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get catBills;

  /// No description provided for @catEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get catEntertainment;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get catSubscriptions;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @incomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeLabel;

  /// No description provided for @lifeHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get lifeHabits;

  /// No description provided for @lifeMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get lifeMood;

  /// No description provided for @lifeJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get lifeJournal;

  /// No description provided for @lifeFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get lifeFood;

  /// No description provided for @lifePantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get lifePantry;

  /// No description provided for @lifeShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get lifeShopping;

  /// No description provided for @lifeReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get lifeReports;

  /// No description provided for @lifeNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get lifeNews;

  /// No description provided for @lifeAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get lifeAchievements;

  /// No description provided for @habitsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start with one small habit. Consistency beats intensity.'**
  String get habitsEmpty;

  /// No description provided for @newHabit.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get newHabit;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get habitName;

  /// No description provided for @habitTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get habitTarget;

  /// No description provided for @habitUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get habitUnit;

  /// No description provided for @habitDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get habitDays;

  /// No description provided for @habitStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String habitStreak(int count);

  /// No description provided for @habitWeeklyRate.
  ///
  /// In en, this message translates to:
  /// **'This week: {value}% complete'**
  String habitWeeklyRate(int value);

  /// No description provided for @habitArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive habit'**
  String get habitArchive;

  /// No description provided for @habitWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get habitWater;

  /// No description provided for @habitReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get habitReading;

  /// No description provided for @habitExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get habitExercise;

  /// No description provided for @habitMeditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get habitMeditation;

  /// No description provided for @habitSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get habitSleep;

  /// No description provided for @habitCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get habitCustom;

  /// No description provided for @habitIncrement.
  ///
  /// In en, this message translates to:
  /// **'Add one to {name}'**
  String habitIncrement(String name);

  /// No description provided for @habitDecrement.
  ///
  /// In en, this message translates to:
  /// **'Remove one from {name}'**
  String habitDecrement(String name);

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get moodGreat;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// No description provided for @moodOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get moodOkay;

  /// No description provided for @moodLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get moodLow;

  /// No description provided for @moodBad.
  ///
  /// In en, this message translates to:
  /// **'Exhausted'**
  String get moodBad;

  /// No description provided for @moodWhy.
  ///
  /// In en, this message translates to:
  /// **'Why? (optional)'**
  String get moodWhy;

  /// No description provided for @moodSaved.
  ///
  /// In en, this message translates to:
  /// **'Mood saved'**
  String get moodSaved;

  /// No description provided for @moodHistory.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get moodHistory;

  /// No description provided for @moodDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Mood tracking is for self-reflection only and is not a medical or mental health assessment. If you are struggling, please reach out to a professional or someone you trust.'**
  String get moodDisclaimer;

  /// No description provided for @journalEmpty.
  ///
  /// In en, this message translates to:
  /// **'A private space for your thoughts. Entries stay encrypted on this device.'**
  String get journalEmpty;

  /// No description provided for @journalNew.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get journalNew;

  /// No description provided for @journalHint.
  ///
  /// In en, this message translates to:
  /// **'How was your day?'**
  String get journalHint;

  /// No description provided for @journalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Encrypted on this device. Never synced. Shared with AI only if you allow it in Privacy settings.'**
  String get journalPrivacy;

  /// No description provided for @journalSummarize.
  ///
  /// In en, this message translates to:
  /// **'Summarize my week'**
  String get journalSummarize;

  /// No description provided for @foodWhatToEat.
  ///
  /// In en, this message translates to:
  /// **'What should I eat?'**
  String get foodWhatToEat;

  /// No description provided for @foodMealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get foodMealBreakfast;

  /// No description provided for @foodMealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get foodMealLunch;

  /// No description provided for @foodMealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get foodMealDinner;

  /// No description provided for @foodMealSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get foodMealSnack;

  /// No description provided for @foodCalories.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal'**
  String foodCalories(int value);

  /// No description provided for @foodMacros.
  ///
  /// In en, this message translates to:
  /// **'P {p}g · C {c}g · F {f}g'**
  String foodMacros(int p, int c, int f);

  /// No description provided for @foodDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get foodDifficultyEasy;

  /// No description provided for @foodDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get foodDifficultyMedium;

  /// No description provided for @foodDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get foodDifficultyHard;

  /// No description provided for @foodCostLow.
  ///
  /// In en, this message translates to:
  /// **'Budget-friendly'**
  String get foodCostLow;

  /// No description provided for @foodCostMedium.
  ///
  /// In en, this message translates to:
  /// **'Moderate cost'**
  String get foodCostMedium;

  /// No description provided for @foodCostHigh.
  ///
  /// In en, this message translates to:
  /// **'Higher cost'**
  String get foodCostHigh;

  /// No description provided for @foodEstimatedCost.
  ///
  /// In en, this message translates to:
  /// **'About {amount}'**
  String foodEstimatedCost(String amount);

  /// No description provided for @foodRefreshLocal.
  ///
  /// In en, this message translates to:
  /// **'Suggest from my pantry'**
  String get foodRefreshLocal;

  /// No description provided for @foodGenerateAi.
  ///
  /// In en, this message translates to:
  /// **'Create a plan with AI'**
  String get foodGenerateAi;

  /// No description provided for @foodIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get foodIngredients;

  /// No description provided for @foodSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get foodSteps;

  /// No description provided for @foodMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing: {items}'**
  String foodMissing(String items);

  /// No description provided for @foodAddMissing.
  ///
  /// In en, this message translates to:
  /// **'Add missing to shopping list'**
  String get foodAddMissing;

  /// No description provided for @foodAddedToList.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 item} other{Added {count} items}}'**
  String foodAddedToList(int count);

  /// No description provided for @foodPreferences.
  ///
  /// In en, this message translates to:
  /// **'Food preferences'**
  String get foodPreferences;

  /// No description provided for @foodSkill.
  ///
  /// In en, this message translates to:
  /// **'Cooking skill'**
  String get foodSkill;

  /// No description provided for @foodBudget.
  ///
  /// In en, this message translates to:
  /// **'Food budget'**
  String get foodBudget;

  /// No description provided for @skillBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get skillBeginner;

  /// No description provided for @skillIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get skillIntermediate;

  /// No description provided for @skillAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get skillAdvanced;

  /// No description provided for @budgetLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get budgetLow;

  /// No description provided for @budgetMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get budgetMedium;

  /// No description provided for @budgetHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get budgetHigh;

  /// No description provided for @dietNone.
  ///
  /// In en, this message translates to:
  /// **'No restrictions'**
  String get dietNone;

  /// No description provided for @dietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietVegetarian;

  /// No description provided for @dietVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietVegan;

  /// No description provided for @dietPescatarian.
  ///
  /// In en, this message translates to:
  /// **'Pescatarian'**
  String get dietPescatarian;

  /// No description provided for @dietKeto.
  ///
  /// In en, this message translates to:
  /// **'Keto'**
  String get dietKeto;

  /// No description provided for @dietHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get dietHalal;

  /// No description provided for @dietGlutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten-free'**
  String get dietGlutenFree;

  /// No description provided for @nutritionDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Nutrition values are estimates.'**
  String get nutritionDisclaimer;

  /// No description provided for @pantryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add what you have at home to get meal ideas that use it.'**
  String get pantryEmpty;

  /// No description provided for @pantryAddHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. chicken, rice, tomato'**
  String get pantryAddHint;

  /// No description provided for @pantryCanMake.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Add a few more ingredients to unlock meals.} =1{You can make 1 meal with what you already have.} other{You can make {count} meals with what you already have.}}'**
  String pantryCanMake(int count);

  /// No description provided for @shoppingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your list is empty.'**
  String get shoppingEmpty;

  /// No description provided for @shoppingAddHint.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get shoppingAddHint;

  /// No description provided for @shoppingClearChecked.
  ///
  /// In en, this message translates to:
  /// **'Clear checked'**
  String get shoppingClearChecked;

  /// No description provided for @shopProduce.
  ///
  /// In en, this message translates to:
  /// **'Produce'**
  String get shopProduce;

  /// No description provided for @shopMeat.
  ///
  /// In en, this message translates to:
  /// **'Meat & fish'**
  String get shopMeat;

  /// No description provided for @shopDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy & eggs'**
  String get shopDairy;

  /// No description provided for @shopBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get shopBakery;

  /// No description provided for @shopPantry.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get shopPantry;

  /// No description provided for @shopFrozen.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get shopFrozen;

  /// No description provided for @shopDrinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get shopDrinks;

  /// No description provided for @shopHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get shopHousehold;

  /// No description provided for @shopPersonalCare.
  ///
  /// In en, this message translates to:
  /// **'Personal care'**
  String get shopPersonalCare;

  /// No description provided for @shopOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get shopOther;

  /// No description provided for @aiTitle.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get aiTitle;

  /// No description provided for @aiInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about your day…'**
  String get aiInputHint;

  /// No description provided for @aiSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aiSend;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get aiThinking;

  /// No description provided for @aiEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'How can I help today?'**
  String get aiEmptyTitle;

  /// No description provided for @aiSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Plan my day'**
  String get aiSuggestion1;

  /// No description provided for @aiSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'I want to save 10,000 this month'**
  String get aiSuggestion2;

  /// No description provided for @aiSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'I have chicken, rice and tomatoes'**
  String get aiSuggestion3;

  /// No description provided for @aiSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'Why did I spend more this month?'**
  String get aiSuggestion4;

  /// No description provided for @aiSuggestion5.
  ///
  /// In en, this message translates to:
  /// **'What do you know about me?'**
  String get aiSuggestion5;

  /// No description provided for @aiCreditsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No free requests left today} =1{1 free request left today} other{{count} free requests left today}}'**
  String aiCreditsLeft(int count);

  /// No description provided for @aiUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Premium · unlimited'**
  String get aiUnlimited;

  /// No description provided for @aiWatchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad for +{count} requests'**
  String aiWatchAd(int count);

  /// No description provided for @aiGoPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium for unlimited AI'**
  String get aiGoPremium;

  /// No description provided for @aiRewardEarned.
  ///
  /// In en, this message translates to:
  /// **'Thanks! You earned more requests.'**
  String get aiRewardEarned;

  /// No description provided for @aiRewardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No ad is available right now. Try again later.'**
  String get aiRewardUnavailable;

  /// No description provided for @aiActionsProposed.
  ///
  /// In en, this message translates to:
  /// **'Suggested actions'**
  String get aiActionsProposed;

  /// No description provided for @aiActionCreateTask.
  ///
  /// In en, this message translates to:
  /// **'Add task “{title}”'**
  String aiActionCreateTask(String title);

  /// No description provided for @aiActionCreateTaskAt.
  ///
  /// In en, this message translates to:
  /// **'Add “{title}” on {when}'**
  String aiActionCreateTaskAt(String title, String when);

  /// No description provided for @aiActionOptimize.
  ///
  /// In en, this message translates to:
  /// **'Optimize today’s plan'**
  String get aiActionOptimize;

  /// No description provided for @aiActionBudget.
  ///
  /// In en, this message translates to:
  /// **'Create a {period} budget of {amount}'**
  String aiActionBudget(String period, String amount);

  /// No description provided for @aiActionExpense.
  ///
  /// In en, this message translates to:
  /// **'Log {amount} for {category}'**
  String aiActionExpense(String amount, String category);

  /// No description provided for @aiActionSavings.
  ///
  /// In en, this message translates to:
  /// **'Set savings goal to {amount}'**
  String aiActionSavings(String amount);

  /// No description provided for @aiActionMeal.
  ///
  /// In en, this message translates to:
  /// **'Create a meal plan for {date}'**
  String aiActionMeal(String date);

  /// No description provided for @aiActionShopping.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 item to shopping list} other{Add {count} items to shopping list}}'**
  String aiActionShopping(int count);

  /// No description provided for @aiActionHabit.
  ///
  /// In en, this message translates to:
  /// **'Start habit “{name}”'**
  String aiActionHabit(String name);

  /// No description provided for @aiActionMood.
  ///
  /// In en, this message translates to:
  /// **'Log mood: {mood}'**
  String aiActionMood(String mood);

  /// No description provided for @aiActionMemory.
  ///
  /// In en, this message translates to:
  /// **'Remember: {content}'**
  String aiActionMemory(String content);

  /// No description provided for @aiActionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get aiActionDone;

  /// No description provided for @aiActionDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get aiActionDismissed;

  /// No description provided for @aiActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t complete this action.'**
  String get aiActionFailed;

  /// No description provided for @aiMemorySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to memory: {content}'**
  String aiMemorySaved(String content);

  /// No description provided for @aiNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get aiNewChat;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI can make mistakes. It never moves money, and every change needs your confirmation.'**
  String get aiDisclaimer;

  /// No description provided for @aiDataNotice.
  ///
  /// In en, this message translates to:
  /// **'Uses: {scopes}. Change in Privacy settings.'**
  String aiDataNotice(String scopes);

  /// No description provided for @aiNoScopes.
  ///
  /// In en, this message translates to:
  /// **'only your profile basics'**
  String get aiNoScopes;

  /// No description provided for @weeklyReport.
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get weeklyReport;

  /// No description provided for @weeklyReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your week in 60 seconds.'**
  String get weeklyReportSubtitle;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Life Report'**
  String get monthlyReport;

  /// No description provided for @reportScore.
  ///
  /// In en, this message translates to:
  /// **'Life Score'**
  String get reportScore;

  /// No description provided for @reportScoreChange.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String reportScoreChange(int from, int to);

  /// No description provided for @reportMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get reportMoney;

  /// No description provided for @reportSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved vs last period: {amount}'**
  String reportSaved(String amount);

  /// No description provided for @reportSpendChange.
  ///
  /// In en, this message translates to:
  /// **'Spending {percent}% vs last period'**
  String reportSpendChange(String percent);

  /// No description provided for @reportHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get reportHabits;

  /// No description provided for @reportMood.
  ///
  /// In en, this message translates to:
  /// **'Average mood'**
  String get reportMood;

  /// No description provided for @reportMoodValue.
  ///
  /// In en, this message translates to:
  /// **'{value}/10'**
  String reportMoodValue(String value);

  /// No description provided for @reportProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get reportProductivity;

  /// No description provided for @reportSleep.
  ///
  /// In en, this message translates to:
  /// **'Average sleep'**
  String get reportSleep;

  /// No description provided for @reportNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get reportNextWeek;

  /// No description provided for @reportNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get reportNextMonth;

  /// No description provided for @reportAiSummary.
  ///
  /// In en, this message translates to:
  /// **'AI summary'**
  String get reportAiSummary;

  /// No description provided for @reportGenerateSummary.
  ///
  /// In en, this message translates to:
  /// **'Write my summary'**
  String get reportGenerateSummary;

  /// No description provided for @reportNoData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet.'**
  String get reportNoData;

  /// No description provided for @suggestReduceCategory.
  ///
  /// In en, this message translates to:
  /// **'Reduce {category} spending'**
  String suggestReduceCategory(String category);

  /// No description provided for @suggestSleepEarlier.
  ///
  /// In en, this message translates to:
  /// **'Go to bed 30 minutes earlier'**
  String get suggestSleepEarlier;

  /// No description provided for @suggestKeepStreak.
  ///
  /// In en, this message translates to:
  /// **'Keep your current habit streak'**
  String get suggestKeepStreak;

  /// No description provided for @suggestPlanMore.
  ///
  /// In en, this message translates to:
  /// **'Plan at least one task a day'**
  String get suggestPlanMore;

  /// No description provided for @suggestLogMood.
  ///
  /// In en, this message translates to:
  /// **'Check in with your mood daily'**
  String get suggestLogMood;

  /// No description provided for @suggestStartHabit.
  ///
  /// In en, this message translates to:
  /// **'Start one small habit'**
  String get suggestStartHabit;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @badgeFirstWeek.
  ///
  /// In en, this message translates to:
  /// **'First Week'**
  String get badgeFirstWeek;

  /// No description provided for @badgeFirstWeekDesc.
  ///
  /// In en, this message translates to:
  /// **'Active on 7 different days'**
  String get badgeFirstWeekDesc;

  /// No description provided for @badgeBudgetMaster.
  ///
  /// In en, this message translates to:
  /// **'Budget Master'**
  String get badgeBudgetMaster;

  /// No description provided for @badgeBudgetMasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Stayed within your daily allowance 7 days in a row'**
  String get badgeBudgetMasterDesc;

  /// No description provided for @badgeStreak.
  ///
  /// In en, this message translates to:
  /// **'7 Day Streak'**
  String get badgeStreak;

  /// No description provided for @badgeStreakDesc.
  ///
  /// In en, this message translates to:
  /// **'Checked in 7 days in a row'**
  String get badgeStreakDesc;

  /// No description provided for @badgeHealthyWeek.
  ///
  /// In en, this message translates to:
  /// **'Healthy Week'**
  String get badgeHealthyWeek;

  /// No description provided for @badgeHealthyWeekDesc.
  ///
  /// In en, this message translates to:
  /// **'Hit 80% of your health habits in a week'**
  String get badgeHealthyWeekDesc;

  /// No description provided for @badgeEarlyBird.
  ///
  /// In en, this message translates to:
  /// **'Early Bird'**
  String get badgeEarlyBird;

  /// No description provided for @badgeEarlyBirdDesc.
  ///
  /// In en, this message translates to:
  /// **'Finished 5 tasks before 9 AM'**
  String get badgeEarlyBirdDesc;

  /// No description provided for @badgePlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get badgePlanner;

  /// No description provided for @badgePlannerDesc.
  ///
  /// In en, this message translates to:
  /// **'Planned tasks on 7 different days'**
  String get badgePlannerDesc;

  /// No description provided for @badgeMoneySaver.
  ///
  /// In en, this message translates to:
  /// **'Money Saver'**
  String get badgeMoneySaver;

  /// No description provided for @badgeMoneySaverDesc.
  ///
  /// In en, this message translates to:
  /// **'Reached your monthly savings goal'**
  String get badgeMoneySaverDesc;

  /// No description provided for @badgeUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked: {name}'**
  String badgeUnlocked(String name);

  /// No description provided for @newsWhyMatters.
  ///
  /// In en, this message translates to:
  /// **'Why this matters'**
  String get newsWhyMatters;

  /// No description provided for @newsTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get newsTopics;

  /// No description provided for @newsTopicTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get newsTopicTechnology;

  /// No description provided for @newsTopicFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get newsTopicFinance;

  /// No description provided for @newsTopicSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get newsTopicSports;

  /// No description provided for @newsTopicWorld.
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get newsTopicWorld;

  /// No description provided for @newsTopicScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get newsTopicScience;

  /// No description provided for @newsTopicEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get newsTopicEntertainment;

  /// No description provided for @newsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'News is unavailable right now.'**
  String get newsUnavailable;

  /// No description provided for @openArticle.
  ///
  /// In en, this message translates to:
  /// **'Open article'**
  String get openArticle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfile;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @notifOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifOff;

  /// No description provided for @notifLow.
  ///
  /// In en, this message translates to:
  /// **'Reminders only'**
  String get notifLow;

  /// No description provided for @notifNormal.
  ///
  /// In en, this message translates to:
  /// **'Reminders + daily nudges'**
  String get notifNormal;

  /// No description provided for @notifExplain.
  ///
  /// In en, this message translates to:
  /// **'We never send more than a few notifications a day and nothing at night.'**
  String get notifExplain;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacy;

  /// No description provided for @settingsAiMemory.
  ///
  /// In en, this message translates to:
  /// **'AI memory'**
  String get settingsAiMemory;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @analyticsToggle.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage analytics'**
  String get analyticsToggle;

  /// No description provided for @crashToggle.
  ///
  /// In en, this message translates to:
  /// **'Send crash reports'**
  String get crashToggle;

  /// No description provided for @personalizedAdsToggle.
  ///
  /// In en, this message translates to:
  /// **'Personalized ads'**
  String get personalizedAdsToggle;

  /// No description provided for @aiDataTitle.
  ///
  /// In en, this message translates to:
  /// **'What the AI can see'**
  String get aiDataTitle;

  /// No description provided for @aiDataBody.
  ///
  /// In en, this message translates to:
  /// **'When you use the assistant, Dayly sends your message and only the data you allow below to our server, which forwards it to an AI provider to generate a reply. It is not used to train AI models by Dayly. Your journal is never shared unless you turn it on.'**
  String get aiDataBody;

  /// No description provided for @scopeMoney.
  ///
  /// In en, this message translates to:
  /// **'Money (budget totals and categories)'**
  String get scopeMoney;

  /// No description provided for @scopeTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks and schedule'**
  String get scopeTasks;

  /// No description provided for @scopeHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get scopeHabits;

  /// No description provided for @scopeMood.
  ///
  /// In en, this message translates to:
  /// **'Mood and sleep (last 7 days)'**
  String get scopeMood;

  /// No description provided for @scopeFood.
  ///
  /// In en, this message translates to:
  /// **'Food preferences and pantry'**
  String get scopeFood;

  /// No description provided for @scopeJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal (last 5 entries)'**
  String get scopeJournal;

  /// No description provided for @scopeShortMoney.
  ///
  /// In en, this message translates to:
  /// **'money'**
  String get scopeShortMoney;

  /// No description provided for @scopeShortTasks.
  ///
  /// In en, this message translates to:
  /// **'tasks'**
  String get scopeShortTasks;

  /// No description provided for @scopeShortHabits.
  ///
  /// In en, this message translates to:
  /// **'habits'**
  String get scopeShortHabits;

  /// No description provided for @scopeShortMood.
  ///
  /// In en, this message translates to:
  /// **'mood'**
  String get scopeShortMood;

  /// No description provided for @scopeShortFood.
  ///
  /// In en, this message translates to:
  /// **'food'**
  String get scopeShortFood;

  /// No description provided for @scopeShortJournal.
  ///
  /// In en, this message translates to:
  /// **'journal'**
  String get scopeShortJournal;

  /// No description provided for @memoryEnabledToggle.
  ///
  /// In en, this message translates to:
  /// **'Let the assistant remember things'**
  String get memoryEnabledToggle;

  /// No description provided for @memoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'The assistant hasn\'t saved anything about you yet.'**
  String get memoryEmpty;

  /// No description provided for @memoryDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all memories'**
  String get memoryDeleteAll;

  /// No description provided for @memoryLimit.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} memories used'**
  String memoryLimit(int used, int limit);

  /// No description provided for @memCatPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get memCatPreferences;

  /// No description provided for @memCatGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get memCatGoals;

  /// No description provided for @memCatHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get memCatHabits;

  /// No description provided for @memCatFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get memCatFood;

  /// No description provided for @memCatBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get memCatBudget;

  /// No description provided for @memCatSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get memCatSchedule;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportData;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Export saved to {path}'**
  String exportDone(String path);

  /// No description provided for @deleteDataSection.
  ///
  /// In en, this message translates to:
  /// **'Delete data'**
  String get deleteDataSection;

  /// No description provided for @deleteJournal.
  ///
  /// In en, this message translates to:
  /// **'Delete all journal entries'**
  String get deleteJournal;

  /// No description provided for @deleteExpenses.
  ///
  /// In en, this message translates to:
  /// **'Delete all expenses'**
  String get deleteExpenses;

  /// No description provided for @deleteMemories.
  ///
  /// In en, this message translates to:
  /// **'Delete AI memory'**
  String get deleteMemories;

  /// No description provided for @deleteChats.
  ///
  /// In en, this message translates to:
  /// **'Delete AI conversations'**
  String get deleteChats;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all data in the cloud and on this device. Active subscriptions must be cancelled in Google Play.'**
  String get deleteAccountBody;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteConfirmBody;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDeleteToConfirm;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get syncStatus;

  /// No description provided for @syncUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get syncUpToDate;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String syncPending(int count);

  /// No description provided for @syncLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'On this device only'**
  String get syncLocalOnly;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {value}'**
  String version(String value);

  /// No description provided for @placeholderLegal.
  ///
  /// In en, this message translates to:
  /// **'This is a placeholder. Replace it with your published policy before release.'**
  String get placeholderLegal;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @newsTopicsSetting.
  ///
  /// In en, this message translates to:
  /// **'News topics'**
  String get newsTopicsSetting;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Dayly Premium'**
  String get premiumTitle;

  /// No description provided for @premiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'More insight, no ads, unlimited assistant.'**
  String get premiumSubtitle;

  /// No description provided for @premiumFeatureAi.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI assistant (fair use)'**
  String get premiumFeatureAi;

  /// No description provided for @premiumFeatureScore.
  ///
  /// In en, this message translates to:
  /// **'Full Life Score breakdown and history'**
  String get premiumFeatureScore;

  /// No description provided for @premiumFeatureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get premiumFeatureNoAds;

  /// No description provided for @premiumFeatureAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced analytics and monthly reports'**
  String get premiumFeatureAnalytics;

  /// No description provided for @premiumFeatureMeals.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI meal plans'**
  String get premiumFeatureMeals;

  /// No description provided for @premiumFeatureMemory.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI memory'**
  String get premiumFeatureMemory;

  /// No description provided for @premiumMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get premiumMonthly;

  /// No description provided for @premiumYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get premiumYearly;

  /// No description provided for @premiumSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get premiumSubscribe;

  /// No description provided for @premiumRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get premiumRestore;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'You\'re Premium. Thank you!'**
  String get premiumActive;

  /// No description provided for @premiumManage.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription in Google Play'**
  String get premiumManage;

  /// No description provided for @premiumUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are not available on this device right now.'**
  String get premiumUnavailable;

  /// No description provided for @premiumPending.
  ///
  /// In en, this message translates to:
  /// **'Purchase pending…'**
  String get premiumPending;

  /// No description provided for @premiumSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Premium!'**
  String get premiumSuccess;

  /// No description provided for @premiumDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions renew automatically at the price shown until cancelled. Cancel anytime in Google Play at least 24 hours before renewal. Payment is charged to your Google Play account.'**
  String get premiumDisclosure;

  /// No description provided for @premiumLocked.
  ///
  /// In en, this message translates to:
  /// **'Premium feature'**
  String get premiumLocked;

  /// No description provided for @tryWithAd.
  ///
  /// In en, this message translates to:
  /// **'Try once with a short ad'**
  String get tryWithAd;

  /// No description provided for @notifTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get notifTaskTitle;

  /// No description provided for @notifTaskBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” starts in 30 minutes.'**
  String notifTaskBody(String title);

  /// No description provided for @notifSpendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick check'**
  String get notifSpendingTitle;

  /// No description provided for @notifSpendingBody.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t logged today\'s spending.'**
  String get notifSpendingBody;

  /// No description provided for @notifBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get notifBudgetTitle;

  /// No description provided for @notifBudgetBody.
  ///
  /// In en, this message translates to:
  /// **'Your budget is getting tight. Here’s your safe amount for today.'**
  String get notifBudgetBody;

  /// No description provided for @notifStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep it going'**
  String get notifStreakTitle;

  /// No description provided for @notifStreakBody.
  ///
  /// In en, this message translates to:
  /// **'Your {count}-day streak is at risk.'**
  String notifStreakBody(int count);

  /// No description provided for @notifMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get notifMoodTitle;

  /// No description provided for @notifMoodBody.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get notifMoodBody;

  /// No description provided for @notifWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your week in 60 seconds'**
  String get notifWeeklyTitle;

  /// No description provided for @notifWeeklyBody.
  ///
  /// In en, this message translates to:
  /// **'Your weekly review is ready.'**
  String get notifWeeklyBody;

  /// No description provided for @focusMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get focusMoney;

  /// No description provided for @focusHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get focusHealth;

  /// No description provided for @focusProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get focusProductivity;

  /// No description provided for @focusFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get focusFood;

  /// No description provided for @focusHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get focusHabits;

  /// No description provided for @focusPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get focusPlanning;

  /// No description provided for @weekdayShort.
  ///
  /// In en, this message translates to:
  /// **'{day, select, 1{Mon} 2{Tue} 3{Wed} 4{Thu} 5{Fri} 6{Sat} other{Sun}}'**
  String weekdayShort(String day);

  /// No description provided for @offlineAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline assistant'**
  String get offlineAiTitle;

  /// No description provided for @offlineAiBody.
  ///
  /// In en, this message translates to:
  /// **'Download a small AI model to your phone so the assistant can answer without internet. Answers stay on your device. It is less capable than the online assistant and cannot make changes in the app.'**
  String get offlineAiBody;

  /// No description provided for @offlineAiSize.
  ///
  /// In en, this message translates to:
  /// **'Download size: about {size} MB. Wi-Fi recommended; works best on phones with 4 GB+ RAM.'**
  String offlineAiSize(int size);

  /// No description provided for @offlineAiDownload.
  ///
  /// In en, this message translates to:
  /// **'Download model'**
  String get offlineAiDownload;

  /// No description provided for @offlineAiDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {progress}%'**
  String offlineAiDownloading(int progress);

  /// No description provided for @offlineAiReady.
  ///
  /// In en, this message translates to:
  /// **'Ready — works without internet'**
  String get offlineAiReady;

  /// No description provided for @offlineAiError.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Check your connection and try again.'**
  String get offlineAiError;

  /// No description provided for @offlineAiDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete model'**
  String get offlineAiDelete;

  /// No description provided for @offlineAiPrefer.
  ///
  /// In en, this message translates to:
  /// **'Use offline assistant even when online'**
  String get offlineAiPrefer;

  /// No description provided for @offlineAiPreferHelp.
  ///
  /// In en, this message translates to:
  /// **'Private and free, but less accurate. Otherwise it is used automatically when you are offline.'**
  String get offlineAiPreferHelp;

  /// No description provided for @offlineAiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The offline assistant is not available yet.'**
  String get offlineAiUnavailable;

  /// No description provided for @aiSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn on your assistant'**
  String get aiSetupTitle;

  /// No description provided for @aiSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Download the free on-device assistant once and chat any time — even without internet. Your messages never leave your phone.'**
  String get aiSetupBody;

  /// No description provided for @aiSetupCta.
  ///
  /// In en, this message translates to:
  /// **'Set up assistant'**
  String get aiSetupCta;

  /// No description provided for @allGoalsDone.
  ///
  /// In en, this message translates to:
  /// **'All goals done today — amazing!'**
  String get allGoalsDone;

  /// No description provided for @offlineAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline answer · on-device model'**
  String get offlineAnswerLabel;

  /// No description provided for @offlineModeChip.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get offlineModeChip;

  /// No description provided for @localModelsInfo.
  ///
  /// In en, this message translates to:
  /// **'Expense and shopping categories are recognised by small models that run on your device.'**
  String get localModelsInfo;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
