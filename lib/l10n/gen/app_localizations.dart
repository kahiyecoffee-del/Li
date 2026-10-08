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
  /// **'Leave the hard part of life to us.'**
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

  /// No description provided for @navExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @profileAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile and settings'**
  String get profileAndSettings;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the hard part of life to us.'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Money, decisions, food, writing: type an everyday problem and Dayly solves it in seconds, right on your phone.'**
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
  /// **'Solve my first problem'**
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

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free · {time}'**
  String planFree(String time);

  /// No description provided for @planNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get planNow;

  /// No description provided for @routinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get routinesTitle;

  /// No description provided for @routinesIntro.
  ///
  /// In en, this message translates to:
  /// **'Save the things you do the same way, then add them to a day in one tap.'**
  String get routinesIntro;

  /// No description provided for @routinesMine.
  ///
  /// In en, this message translates to:
  /// **'Your routines'**
  String get routinesMine;

  /// No description provided for @routinesReady.
  ///
  /// In en, this message translates to:
  /// **'Ready-made'**
  String get routinesReady;

  /// No description provided for @routineAddToDay.
  ///
  /// In en, this message translates to:
  /// **'Add to a day'**
  String get routineAddToDay;

  /// No description provided for @routineAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step added to your plan} other{{count} steps added to your plan}}'**
  String routineAdded(int count);

  /// No description provided for @routineUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get routineUse;

  /// No description provided for @routineNew.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get routineNew;

  /// No description provided for @routineName.
  ///
  /// In en, this message translates to:
  /// **'Routine name'**
  String get routineName;

  /// No description provided for @routineAddStep.
  ///
  /// In en, this message translates to:
  /// **'Add a step'**
  String get routineAddStep;

  /// No description provided for @routineStepHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Stretch 10 min'**
  String get routineStepHint;

  /// No description provided for @routineSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} steps · {duration}'**
  String routineSummary(int count, String duration);

  /// No description provided for @routineStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts {time}'**
  String routineStartsAt(String time);

  /// No description provided for @planAddRoutine.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get planAddRoutine;

  /// No description provided for @goalsLife.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsLife;

  /// No description provided for @goalsLifeIntro.
  ///
  /// In en, this message translates to:
  /// **'A big goal gets easier in small steps. Plan one step at a time.'**
  String get goalsLifeIntro;

  /// No description provided for @goalNew.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalNew;

  /// No description provided for @goalTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What do you want to achieve? e.g. English B1'**
  String get goalTitleHint;

  /// No description provided for @goalWhy.
  ///
  /// In en, this message translates to:
  /// **'Why it matters to you'**
  String get goalWhy;

  /// No description provided for @goalStepsHint.
  ///
  /// In en, this message translates to:
  /// **'Steps, one per line'**
  String get goalStepsHint;

  /// No description provided for @goalStepsCount.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} steps'**
  String goalStepsCount(int done, int total);

  /// No description provided for @goalPlanStep.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get goalPlanStep;

  /// No description provided for @goalStepPlanned.
  ///
  /// In en, this message translates to:
  /// **'Added to today’s plan'**
  String get goalStepPlanned;

  /// No description provided for @goalDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day left} other{{count} days left}}'**
  String goalDaysLeft(int count);

  /// No description provided for @goalNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get goalNextStep;

  /// No description provided for @goalArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get goalArchive;

  /// No description provided for @goalAllDone.
  ///
  /// In en, this message translates to:
  /// **'Every step done. Well done! 🎉'**
  String get goalAllDone;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly review'**
  String get reviewTitle;

  /// No description provided for @reviewIntro.
  ///
  /// In en, this message translates to:
  /// **'A calm look back, then three focuses for next week.'**
  String get reviewIntro;

  /// No description provided for @reviewTasks.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} tasks done'**
  String reviewTasks(int done, int total);

  /// No description provided for @reviewHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits kept {p}%'**
  String reviewHabits(int p);

  /// No description provided for @reviewSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent {amount}'**
  String reviewSpent(String amount);

  /// No description provided for @reviewMood.
  ///
  /// In en, this message translates to:
  /// **'Average mood'**
  String get reviewMood;

  /// No description provided for @reviewMoreThanLast.
  ///
  /// In en, this message translates to:
  /// **'{p}% more than the week before'**
  String reviewMoreThanLast(int p);

  /// No description provided for @reviewLessThanLast.
  ///
  /// In en, this message translates to:
  /// **'{p}% less than the week before'**
  String reviewLessThanLast(int p);

  /// No description provided for @reviewJournal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 journal entry} other{{count} journal entries}}'**
  String reviewJournal(int count);

  /// No description provided for @reviewWins.
  ///
  /// In en, this message translates to:
  /// **'Wins of the week'**
  String get reviewWins;

  /// No description provided for @reviewNoWins.
  ///
  /// In en, this message translates to:
  /// **'Small steps count too. Next week starts fresh.'**
  String get reviewNoWins;

  /// No description provided for @reviewFocus.
  ///
  /// In en, this message translates to:
  /// **'Three focuses for next week'**
  String get reviewFocus;

  /// No description provided for @reviewFocusHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Finish the report'**
  String get reviewFocusHint;

  /// No description provided for @reviewPlanWeek.
  ///
  /// In en, this message translates to:
  /// **'Plan next week'**
  String get reviewPlanWeek;

  /// No description provided for @reviewPlanned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 focus planned} other{{count} focuses planned}}'**
  String reviewPlanned(int count);

  /// No description provided for @planAlso.
  ///
  /// In en, this message translates to:
  /// **'Also on this day'**
  String get planAlso;

  /// No description provided for @planHabitsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 habit} other{{count} habits}}'**
  String planHabitsCount(int count);

  /// No description provided for @captureHint.
  ///
  /// In en, this message translates to:
  /// **'Write anything… “250 TL market”, “tomorrow 15:00 dentist”'**
  String get captureHint;

  /// No description provided for @captureTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get captureTask;

  /// No description provided for @captureExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get captureExpense;

  /// No description provided for @captureShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get captureShopping;

  /// No description provided for @captureJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get captureJournal;

  /// No description provided for @captureSavedTask.
  ///
  /// In en, this message translates to:
  /// **'Planned: {title} · {when}'**
  String captureSavedTask(String title, String when);

  /// No description provided for @captureSavedExpense.
  ///
  /// In en, this message translates to:
  /// **'Saved: {amount} · {category}'**
  String captureSavedExpense(String amount, String category);

  /// No description provided for @captureNeedAmount.
  ///
  /// In en, this message translates to:
  /// **'Add an amount, e.g. 250'**
  String get captureNeedAmount;

  /// No description provided for @captureJournalNote.
  ///
  /// In en, this message translates to:
  /// **'A note for your journal'**
  String get captureJournalNote;

  /// No description provided for @todayFlow.
  ///
  /// In en, this message translates to:
  /// **'Today’s flow'**
  String get todayFlow;

  /// No description provided for @nextUp.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get nextUp;

  /// No description provided for @startsIn.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String startsIn(String time);

  /// No description provided for @noNextTask.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled next. Add it in one line above.'**
  String get noNextTask;

  /// No description provided for @openPlan.
  ///
  /// In en, this message translates to:
  /// **'Open plan'**
  String get openPlan;

  /// No description provided for @timeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'When, and for how long?'**
  String get timeSheetTitle;

  /// No description provided for @timeStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timeStart;

  /// No description provided for @presetMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get presetMorning;

  /// No description provided for @presetNoon.
  ///
  /// In en, this message translates to:
  /// **'Noon'**
  String get presetNoon;

  /// No description provided for @presetAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get presetAfternoon;

  /// No description provided for @presetEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get presetEvening;

  /// No description provided for @presetInHour.
  ///
  /// In en, this message translates to:
  /// **'In 1 hour'**
  String get presetInHour;

  /// No description provided for @timeNoTime.
  ///
  /// In en, this message translates to:
  /// **'No set time'**
  String get timeNoTime;

  /// No description provided for @timeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get timeCustom;

  /// No description provided for @timeChip.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeChip;

  /// No description provided for @timeWhenDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get timeWhenDay;

  /// No description provided for @timeAnytime.
  ///
  /// In en, this message translates to:
  /// **'Any time · {duration}'**
  String timeAnytime(String duration);

  /// No description provided for @planEmptyShort.
  ///
  /// In en, this message translates to:
  /// **'A free day'**
  String get planEmptyShort;

  /// No description provided for @planQuickHint.
  ///
  /// In en, this message translates to:
  /// **'Add a task… e.g. 15:00 dentist 30 min'**
  String get planQuickHint;

  /// No description provided for @planQuickAdded.
  ///
  /// In en, this message translates to:
  /// **'Added: {title}'**
  String planQuickAdded(String title);

  /// No description provided for @planDetails.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get planDetails;

  /// No description provided for @planScheduleIt.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get planScheduleIt;

  /// No description provided for @planScheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {time}'**
  String planScheduledAt(String time);

  /// No description provided for @planNoSlot.
  ///
  /// In en, this message translates to:
  /// **'No free slot left on this day'**
  String get planNoSlot;

  /// No description provided for @planPostpone.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get planPostpone;

  /// No description provided for @planPostponed.
  ///
  /// In en, this message translates to:
  /// **'Moved to tomorrow'**
  String get planPostponed;

  /// No description provided for @planToToday.
  ///
  /// In en, this message translates to:
  /// **'Do today'**
  String get planToToday;

  /// No description provided for @planProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String planProgress(int done, int total);

  /// No description provided for @planPlannedTime.
  ///
  /// In en, this message translates to:
  /// **'{time} planned'**
  String planPlannedTime(String time);

  /// No description provided for @planFreeTime.
  ///
  /// In en, this message translates to:
  /// **'{time} free'**
  String planFreeTime(String time);

  /// No description provided for @planDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned for this day yet. Write a task below or let Lio plan it with you.'**
  String get planDayEmpty;

  /// No description provided for @planWithLio.
  ///
  /// In en, this message translates to:
  /// **'Plan with Lio'**
  String get planWithLio;

  /// No description provided for @planTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get planTimeline;

  /// No description provided for @planPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get planPickDate;

  /// No description provided for @planClashes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task overlaps another} other{{count} tasks overlap}}'**
  String planClashes(int count);

  /// No description provided for @planFixClashes.
  ///
  /// In en, this message translates to:
  /// **'Fix overlaps'**
  String get planFixClashes;

  /// No description provided for @planClashesFixed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing overlaps.} =1{Moved 1 task, nothing overlaps now.} other{Moved {count} tasks, nothing overlaps now.}}'**
  String planClashesFixed(int count);

  /// No description provided for @planClashWith.
  ///
  /// In en, this message translates to:
  /// **'Overlaps “{title}”'**
  String planClashWith(String title);

  /// No description provided for @planMoveAfter.
  ///
  /// In en, this message translates to:
  /// **'Move after it'**
  String get planMoveAfter;

  /// No description provided for @planUseFreeTime.
  ///
  /// In en, this message translates to:
  /// **'Move to {time}'**
  String planUseFreeTime(String time);

  /// No description provided for @planDayHours.
  ///
  /// In en, this message translates to:
  /// **'Day {start} – {end}'**
  String planDayHours(String start, String end);

  /// No description provided for @planDayHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'When does your day start and end?'**
  String get planDayHoursTitle;

  /// No description provided for @planDayStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get planDayStart;

  /// No description provided for @planDayEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get planDayEnd;

  /// No description provided for @planHowTo.
  ///
  /// In en, this message translates to:
  /// **'Tap a task to change anything · swipe right: done · left: tomorrow'**
  String get planHowTo;

  /// No description provided for @taskMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get taskMore;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate Dayly'**
  String get rateApp;

  /// No description provided for @rateAppBody.
  ///
  /// In en, this message translates to:
  /// **'A few seconds that help us a lot.'**
  String get rateAppBody;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Tasks, recipes, spending, lists…'**
  String get searchHint;

  /// No description provided for @searchStart.
  ///
  /// In en, this message translates to:
  /// **'Search everything in Dayly. The search runs on your phone.'**
  String get searchStart;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing found for “{q}”.'**
  String searchEmpty(String q);

  /// No description provided for @searchGoTo.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get searchGoTo;

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get searchTasks;

  /// No description provided for @searchRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get searchRecipes;

  /// No description provided for @searchSpending.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get searchSpending;

  /// No description provided for @searchShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get searchShopping;

  /// No description provided for @searchSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get searchSaved;

  /// No description provided for @searchJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get searchJournal;

  /// No description provided for @cleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get cleared;

  /// No description provided for @gardenShortCharging.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more to go} other{{count} more to go}}'**
  String gardenShortCharging(int count);

  /// No description provided for @gardenShortExploring.
  ///
  /// In en, this message translates to:
  /// **'Exploring · back {time}'**
  String gardenShortExploring(String time);

  /// No description provided for @gardenShortGift.
  ///
  /// In en, this message translates to:
  /// **'A postcard is waiting!'**
  String get gardenShortGift;

  /// No description provided for @gardenShortOpened.
  ///
  /// In en, this message translates to:
  /// **'New trip tomorrow'**
  String get gardenShortOpened;

  /// No description provided for @todayStripHint.
  ///
  /// In en, this message translates to:
  /// **'Weather, rates, prayer times'**
  String get todayStripHint;

  /// No description provided for @shoppingShare.
  ///
  /// In en, this message translates to:
  /// **'Share list'**
  String get shoppingShare;

  /// No description provided for @shoppingShareHeader.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get shoppingShareHeader;

  /// No description provided for @shoppingShareFooter.
  ///
  /// In en, this message translates to:
  /// **'Made with Dayly'**
  String get shoppingShareFooter;

  /// No description provided for @shoppingPaste.
  ///
  /// In en, this message translates to:
  /// **'Add a list someone sent'**
  String get shoppingPaste;

  /// No description provided for @shoppingPasted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item added} other{{count} items added}}'**
  String shoppingPasted(int count);

  /// No description provided for @shoppingPasteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Copy the list first, then tap here.'**
  String get shoppingPasteEmpty;

  /// No description provided for @reviewShare.
  ///
  /// In en, this message translates to:
  /// **'Share my week'**
  String get reviewShare;

  /// No description provided for @reviewShareText.
  ///
  /// In en, this message translates to:
  /// **'My week with Dayly'**
  String get reviewShareText;

  /// No description provided for @reviewCardTasks.
  ///
  /// In en, this message translates to:
  /// **'things done'**
  String get reviewCardTasks;

  /// No description provided for @reviewCardHabits.
  ///
  /// In en, this message translates to:
  /// **'habits kept'**
  String get reviewCardHabits;

  /// No description provided for @reviewCardStreak.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get reviewCardStreak;

  /// No description provided for @todayInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Today at a glance'**
  String get todayInfoTitle;

  /// No description provided for @todayInfoTile.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayInfoTile;

  /// No description provided for @todayRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get todayRates;

  /// No description provided for @todayRatesNote.
  ///
  /// In en, this message translates to:
  /// **'European Central Bank reference rates, updated on working days. Banks and exchange offices differ.'**
  String get todayRatesNote;

  /// No description provided for @todayRatesUpdated.
  ///
  /// In en, this message translates to:
  /// **'As of {date}'**
  String todayRatesUpdated(String date);

  /// No description provided for @todayRatesOff.
  ///
  /// In en, this message translates to:
  /// **'Show exchange rates'**
  String get todayRatesOff;

  /// No description provided for @todayPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get todayPrayer;

  /// No description provided for @todayPrayerOn.
  ///
  /// In en, this message translates to:
  /// **'Show prayer times'**
  String get todayPrayerOn;

  /// No description provided for @todayPrayerNote.
  ///
  /// In en, this message translates to:
  /// **'Diyanet method. Times can differ by a minute or two from your mosque.'**
  String get todayPrayerNote;

  /// No description provided for @todayNeedsCity.
  ///
  /// In en, this message translates to:
  /// **'Pick your city to see this.'**
  String get todayNeedsCity;

  /// No description provided for @todayPickCity.
  ///
  /// In en, this message translates to:
  /// **'Pick city'**
  String get todayPickCity;

  /// No description provided for @todayNext.
  ///
  /// In en, this message translates to:
  /// **'{name} in {time}'**
  String todayNext(String name, String time);

  /// No description provided for @prayerImsak.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerImsak;

  /// No description provided for @prayerGunes.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerGunes;

  /// No description provided for @prayerOgle.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerOgle;

  /// No description provided for @prayerIkindi.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerIkindi;

  /// No description provided for @prayerAksam.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerAksam;

  /// No description provided for @prayerYatsi.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerYatsi;

  /// No description provided for @todayNearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get todayNearby;

  /// No description provided for @todayPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy on duty'**
  String get todayPharmacy;

  /// No description provided for @todayFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel prices'**
  String get todayFuel;

  /// No description provided for @todayOpensOutside.
  ///
  /// In en, this message translates to:
  /// **'Opens in your maps or browser.'**
  String get todayOpensOutside;

  /// No description provided for @todayUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load right now. Pull down to try again.'**
  String get todayUnavailable;

  /// No description provided for @todayWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get todayWeather;

  /// No description provided for @widgetDone.
  ///
  /// In en, this message translates to:
  /// **'✓ Done: {title}'**
  String widgetDone(String title);

  /// No description provided for @taskDoneFromWidget.
  ///
  /// In en, this message translates to:
  /// **'Done: {title}'**
  String taskDoneFromWidget(String title);

  /// No description provided for @taskFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus on it'**
  String get taskFocus;

  /// No description provided for @lioHelpFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get lioHelpFocus;

  /// No description provided for @focusTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusTitle;

  /// No description provided for @focusStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get focusStart;

  /// No description provided for @focusPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get focusPause;

  /// No description provided for @focusResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get focusResume;

  /// No description provided for @focusStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get focusStop;

  /// No description provided for @focusOn.
  ///
  /// In en, this message translates to:
  /// **'Focusing on'**
  String get focusOn;

  /// No description provided for @focusFree.
  ///
  /// In en, this message translates to:
  /// **'Free focus'**
  String get focusFree;

  /// No description provided for @focusHowLong.
  ///
  /// In en, this message translates to:
  /// **'How long?'**
  String get focusHowLong;

  /// No description provided for @focusPhoneDown.
  ///
  /// In en, this message translates to:
  /// **'Put the phone down. Dayly will tell you when time is up.'**
  String get focusPhoneDown;

  /// No description provided for @focusDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Nice! {minutes} minutes of focus'**
  String focusDoneTitle(int minutes);

  /// No description provided for @focusDoneTask.
  ///
  /// In en, this message translates to:
  /// **'Mark the task done'**
  String get focusDoneTask;

  /// No description provided for @focusBreak.
  ///
  /// In en, this message translates to:
  /// **'Take 5'**
  String get focusBreak;

  /// No description provided for @focusToday.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 focus session today · {minutes} min} other{{count} focus sessions today · {minutes} min}}'**
  String focusToday(int count, int minutes);

  /// No description provided for @focusNotifDone.
  ///
  /// In en, this message translates to:
  /// **'Time is up. Take a short break.'**
  String get focusNotifDone;

  /// No description provided for @gardenTitle.
  ///
  /// In en, this message translates to:
  /// **'Lio’s day'**
  String get gardenTitle;

  /// No description provided for @gardenCharging.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more and Lio goes exploring} other{{count} more and Lio goes exploring}}'**
  String gardenCharging(int count);

  /// No description provided for @gardenChargingHint.
  ///
  /// In en, this message translates to:
  /// **'Finish a task, log a habit or your mood, or focus for a while.'**
  String get gardenChargingHint;

  /// No description provided for @gardenExploring.
  ///
  /// In en, this message translates to:
  /// **'Lio is exploring. Back around {time}.'**
  String gardenExploring(String time);

  /// No description provided for @gardenGift.
  ///
  /// In en, this message translates to:
  /// **'Lio is back with a postcard!'**
  String get gardenGift;

  /// No description provided for @gardenOpen.
  ///
  /// In en, this message translates to:
  /// **'Open it'**
  String get gardenOpen;

  /// No description provided for @gardenOpened.
  ///
  /// In en, this message translates to:
  /// **'Today’s postcard is in your collection. See you tomorrow!'**
  String get gardenOpened;

  /// No description provided for @gardenFrom.
  ///
  /// In en, this message translates to:
  /// **'A postcard from {place}'**
  String gardenFrom(String place);

  /// No description provided for @gardenCollected.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} collected'**
  String gardenCollected(int count, int total);

  /// No description provided for @gardenAnother.
  ///
  /// In en, this message translates to:
  /// **'One more (watch an ad)'**
  String get gardenAnother;

  /// No description provided for @gardenCollection.
  ///
  /// In en, this message translates to:
  /// **'Postcards'**
  String get gardenCollection;

  /// No description provided for @gardenLocked.
  ///
  /// In en, this message translates to:
  /// **'Not found yet'**
  String get gardenLocked;

  /// No description provided for @notifGardenTitle.
  ///
  /// In en, this message translates to:
  /// **'Lio is back'**
  String get notifGardenTitle;

  /// No description provided for @notifGardenBody.
  ///
  /// In en, this message translates to:
  /// **'He brought you a postcard from his trip.'**
  String get notifGardenBody;

  /// No description provided for @adLabel.
  ///
  /// In en, this message translates to:
  /// **'Ad'**
  String get adLabel;

  /// No description provided for @planCalendarConnect.
  ///
  /// In en, this message translates to:
  /// **'Show my calendar'**
  String get planCalendarConnect;

  /// No description provided for @planCalendarDenied.
  ///
  /// In en, this message translates to:
  /// **'Calendar access was not allowed. You can allow it in Settings.'**
  String get planCalendarDenied;

  /// No description provided for @planCalendarShown.
  ///
  /// In en, this message translates to:
  /// **'Your calendar events now show on the plan.'**
  String get planCalendarShown;

  /// No description provided for @planCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'From your calendar'**
  String get planCalendarEvent;

  /// No description provided for @planCalendarToggle.
  ///
  /// In en, this message translates to:
  /// **'Show phone calendar'**
  String get planCalendarToggle;

  /// No description provided for @planCalendarToggleHint.
  ///
  /// In en, this message translates to:
  /// **'Read-only. Tasks will not overlap your events.'**
  String get planCalendarToggleHint;

  /// No description provided for @planOverloaded.
  ///
  /// In en, this message translates to:
  /// **'{work} of work, {left} left today'**
  String planOverloaded(String work, String left);

  /// No description provided for @planOverloadedHint.
  ///
  /// In en, this message translates to:
  /// **'Things usually take longer than planned. Keep some room.'**
  String get planOverloadedHint;

  /// No description provided for @planLighten.
  ///
  /// In en, this message translates to:
  /// **'Lighten my day'**
  String get planLighten;

  /// No description provided for @planLightened.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing to move: what is left is important.} =1{Moved 1 task to tomorrow.} other{Moved {count} tasks to tomorrow.}}'**
  String planLightened(int count);

  /// No description provided for @planUpNext.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get planUpNext;

  /// No description provided for @planTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String planTimeLeft(String time);

  /// No description provided for @planStartsIn.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String planStartsIn(String time);

  /// No description provided for @planShutdown.
  ///
  /// In en, this message translates to:
  /// **'Close the day'**
  String get planShutdown;

  /// No description provided for @planShutdownBody.
  ///
  /// In en, this message translates to:
  /// **'{done} done today. {left} still open: decide where each one goes.'**
  String planShutdownBody(int done, int left);

  /// No description provided for @planShutdownReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get planShutdownReview;

  /// No description provided for @planShutdownGood.
  ///
  /// In en, this message translates to:
  /// **'Everything is done. Good day!'**
  String get planShutdownGood;

  /// No description provided for @planAllTomorrow.
  ///
  /// In en, this message translates to:
  /// **'All to tomorrow'**
  String get planAllTomorrow;

  /// No description provided for @planAllToday.
  ///
  /// In en, this message translates to:
  /// **'All to today'**
  String get planAllToday;

  /// No description provided for @planDrop.
  ///
  /// In en, this message translates to:
  /// **'Let it go'**
  String get planDrop;

  /// No description provided for @planShrink.
  ///
  /// In en, this message translates to:
  /// **'Halve it'**
  String get planShrink;

  /// No description provided for @planRolled.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{moved once} other{moved {count} times}}'**
  String planRolled(int count);

  /// No description provided for @planRolledHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps moving? Make it smaller or let it go.'**
  String get planRolledHint;

  /// No description provided for @planBreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Break between tasks'**
  String get planBreakLabel;

  /// No description provided for @planBreakNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get planBreakNone;

  /// No description provided for @taskChangeTime.
  ///
  /// In en, this message translates to:
  /// **'Change time'**
  String get taskChangeTime;

  /// No description provided for @taskOtherDay.
  ///
  /// In en, this message translates to:
  /// **'Move to another day'**
  String get taskOtherDay;

  /// No description provided for @taskDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get taskDuplicate;

  /// No description provided for @taskClearTime.
  ///
  /// In en, this message translates to:
  /// **'Remove time'**
  String get taskClearTime;

  /// No description provided for @taskDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get taskDuplicated;

  /// No description provided for @taskMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get taskMoved;

  /// No description provided for @lioHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How can I help?'**
  String get lioHelpTitle;

  /// No description provided for @lioHelpPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan my day'**
  String get lioHelpPlan;

  /// No description provided for @lioHelpTask.
  ///
  /// In en, this message translates to:
  /// **'Add a task'**
  String get lioHelpTask;

  /// No description provided for @lioHelpMoney.
  ///
  /// In en, this message translates to:
  /// **'My budget'**
  String get lioHelpMoney;

  /// No description provided for @lioHelpWrite.
  ///
  /// In en, this message translates to:
  /// **'Write in my journal'**
  String get lioHelpWrite;

  /// No description provided for @lioHelpMood.
  ///
  /// In en, this message translates to:
  /// **'How I feel'**
  String get lioHelpMood;

  /// No description provided for @lioHelpAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything'**
  String get lioHelpAsk;

  /// No description provided for @lioHelpHide.
  ///
  /// In en, this message translates to:
  /// **'Hide Lio'**
  String get lioHelpHide;

  /// No description provided for @lioHelpTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: drag me anywhere along the bottom.'**
  String get lioHelpTip;

  /// No description provided for @durHM.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String durHM(int h, int m);

  /// No description provided for @durH.
  ///
  /// In en, this message translates to:
  /// **'{h} h'**
  String durH(int h);

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

  /// No description provided for @moneyTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get moneyTabOverview;

  /// No description provided for @moneyTabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get moneyTabActivity;

  /// No description provided for @moneyTabPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get moneyTabPlan;

  /// No description provided for @moneyMoreThanLast.
  ///
  /// In en, this message translates to:
  /// **'{p}% more than last month'**
  String moneyMoreThanLast(int p);

  /// No description provided for @moneyLessThanLast.
  ///
  /// In en, this message translates to:
  /// **'{p}% less than last month'**
  String moneyLessThanLast(int p);

  /// No description provided for @moneyMonthTotal.
  ///
  /// In en, this message translates to:
  /// **'Spent {amount}'**
  String moneyMonthTotal(String amount);

  /// No description provided for @moneyDailyAvg.
  ///
  /// In en, this message translates to:
  /// **'Daily average {amount}'**
  String moneyDailyAvg(String amount);

  /// No description provided for @moneyBiggest.
  ///
  /// In en, this message translates to:
  /// **'Biggest: {what} · {amount}'**
  String moneyBiggest(String what, String amount);

  /// No description provided for @moneySearch.
  ///
  /// In en, this message translates to:
  /// **'Search expenses'**
  String get moneySearch;

  /// No description provided for @moneyNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing here for this month.'**
  String get moneyNoMatch;

  /// No description provided for @moneyAddIncome.
  ///
  /// In en, this message translates to:
  /// **'Add income'**
  String get moneyAddIncome;

  /// No description provided for @moneyChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Where the money went'**
  String get moneyChartTitle;

  /// No description provided for @moneyPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get moneyPrevMonth;

  /// No description provided for @moneyNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get moneyNextMonth;

  /// No description provided for @advBillsDue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{name} is due ({amount}). Pay it and mark it here so your budget stays right.} other{{count} bills are due soon, {amount} in total. {name} is first.}}'**
  String advBillsDue(int count, String name, String amount);

  /// No description provided for @billsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bills & subscriptions'**
  String get billsTitle;

  /// No description provided for @billsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add rent, bills and subscriptions once. Dayly reminds you the day before and keeps that money aside in your daily budget.'**
  String get billsEmpty;

  /// No description provided for @billAdd.
  ///
  /// In en, this message translates to:
  /// **'Add bill'**
  String get billAdd;

  /// No description provided for @billName.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Electricity, Netflix)'**
  String get billName;

  /// No description provided for @billDay.
  ///
  /// In en, this message translates to:
  /// **'Day of the month'**
  String get billDay;

  /// No description provided for @billRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind me the day before'**
  String get billRemind;

  /// No description provided for @billPay.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get billPay;

  /// No description provided for @billPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billPaid;

  /// No description provided for @billOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day late} other{{count} days late}}'**
  String billOverdue(int count);

  /// No description provided for @billDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get billDueToday;

  /// No description provided for @billDueIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Tomorrow} other{In {count} days}}'**
  String billDueIn(int count);

  /// No description provided for @billsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month: {amount}'**
  String billsMonthly(String amount);

  /// No description provided for @billsLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} still to pay this month'**
  String billsLeft(String amount);

  /// No description provided for @billPaidSnack.
  ///
  /// In en, this message translates to:
  /// **'Logged as an expense'**
  String get billPaidSnack;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings jars'**
  String get goalsTitle;

  /// No description provided for @goalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Saving for something? Make a jar and watch it fill up.'**
  String get goalsEmpty;

  /// No description provided for @goalAdd.
  ///
  /// In en, this message translates to:
  /// **'New jar'**
  String get goalAdd;

  /// No description provided for @goalName.
  ///
  /// In en, this message translates to:
  /// **'What for? (e.g. Holiday)'**
  String get goalName;

  /// No description provided for @goalTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get goalTarget;

  /// No description provided for @goalDeadline.
  ///
  /// In en, this message translates to:
  /// **'By when (optional)'**
  String get goalDeadline;

  /// No description provided for @goalNoDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get goalNoDeadline;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'{saved} of {target}'**
  String goalProgress(String saved, String target);

  /// No description provided for @goalMonthly.
  ///
  /// In en, this message translates to:
  /// **'Put aside {amount} a month to make it'**
  String goalMonthly(String amount);

  /// No description provided for @goalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! 🎉'**
  String get goalReached;

  /// No description provided for @goalDeposit.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get goalDeposit;

  /// No description provided for @goalWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Take out'**
  String get goalWithdraw;

  /// No description provided for @goalAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get goalAmount;

  /// No description provided for @limitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending limits'**
  String get limitsTitle;

  /// No description provided for @limitsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Set a weekly limit, a monthly limit or one per category. They repeat every week or month by themselves.'**
  String get limitsEmpty;

  /// No description provided for @limitWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly total'**
  String get limitWeekly;

  /// No description provided for @limitMonthlyAll.
  ///
  /// In en, this message translates to:
  /// **'Monthly total'**
  String get limitMonthlyAll;

  /// No description provided for @notifBillTitle.
  ///
  /// In en, this message translates to:
  /// **'Bill reminder'**
  String get notifBillTitle;

  /// No description provided for @notifBillBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is due. Tap to mark it paid.'**
  String notifBillBody(String name);

  /// No description provided for @foodChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get foodChange;

  /// No description provided for @foodPick.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get foodPick;

  /// No description provided for @foodPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose {meal}'**
  String foodPickTitle(String meal);

  /// No description provided for @foodAddMeal.
  ///
  /// In en, this message translates to:
  /// **'Add a meal'**
  String get foodAddMeal;

  /// No description provided for @foodRemoveMeal.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get foodRemoveMeal;

  /// No description provided for @foodShowAllTypes.
  ///
  /// In en, this message translates to:
  /// **'Show every recipe'**
  String get foodShowAllTypes;

  /// No description provided for @foodTabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get foodTabToday;

  /// No description provided for @widgetToday.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String widgetToday(String date);

  /// No description provided for @widgetLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 thing left today} other{{count} things left today}}'**
  String widgetLeft(int count);

  /// No description provided for @widgetAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done for today 🎉'**
  String get widgetAllDone;

  /// No description provided for @widgetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plan yet. Tap to plan your day.'**
  String get widgetEmpty;

  /// No description provided for @widgetStale.
  ///
  /// In en, this message translates to:
  /// **'Open Dayly to see today\'s plan'**
  String get widgetStale;

  /// No description provided for @foodTabRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get foodTabRecipes;

  /// No description provided for @foodTabWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get foodTabWeek;

  /// No description provided for @foodSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a dish or an ingredient'**
  String get foodSearchHint;

  /// No description provided for @foodFilterFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get foodFilterFavorites;

  /// No description provided for @foodFilterCanMake.
  ///
  /// In en, this message translates to:
  /// **'Can make now'**
  String get foodFilterCanMake;

  /// No description provided for @foodFilterQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick (≤20 min)'**
  String get foodFilterQuick;

  /// No description provided for @foodFilterVeg.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get foodFilterVeg;

  /// No description provided for @foodFilterProtein.
  ///
  /// In en, this message translates to:
  /// **'High protein'**
  String get foodFilterProtein;

  /// No description provided for @foodFilterBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get foodFilterBudget;

  /// No description provided for @foodAllMeals.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get foodAllMeals;

  /// No description provided for @foodNoRecipes.
  ///
  /// In en, this message translates to:
  /// **'No recipe matches. Try removing a filter.'**
  String get foodNoRecipes;

  /// No description provided for @foodRecipeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recipe} other{{count} recipes}}'**
  String foodRecipeCount(int count);

  /// No description provided for @foodMissingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} missing'**
  String foodMissingCount(int count);

  /// No description provided for @foodHaveAll.
  ///
  /// In en, this message translates to:
  /// **'You have it all'**
  String get foodHaveAll;

  /// No description provided for @foodServings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 serving} other{{count} servings}}'**
  String foodServings(int count);

  /// No description provided for @foodAddToToday.
  ///
  /// In en, this message translates to:
  /// **'Add to today\'s menu'**
  String get foodAddToToday;

  /// No description provided for @foodAddedToToday.
  ///
  /// In en, this message translates to:
  /// **'Added to today\'s menu'**
  String get foodAddedToToday;

  /// No description provided for @foodFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get foodFavoriteAdd;

  /// No description provided for @foodFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get foodFavoriteRemove;

  /// No description provided for @foodCopyRecipe.
  ///
  /// In en, this message translates to:
  /// **'Copy recipe'**
  String get foodCopyRecipe;

  /// No description provided for @foodStepsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a step when it is done.'**
  String get foodStepsHint;

  /// No description provided for @foodCanMakeNow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You can cook 1 recipe with what you have} other{You can cook {count} recipes with what you have}}'**
  String foodCanMakeNow(int count);

  /// No description provided for @foodWeekIntro.
  ///
  /// In en, this message translates to:
  /// **'Lio picks varied meals for 7 days, using what you have at home first. Then make one shopping list for the whole week.'**
  String get foodWeekIntro;

  /// No description provided for @foodWeekPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan the week'**
  String get foodWeekPlan;

  /// No description provided for @foodWeekReplan.
  ///
  /// In en, this message translates to:
  /// **'Re-plan the week'**
  String get foodWeekReplan;

  /// No description provided for @foodWeekPlanned.
  ///
  /// In en, this message translates to:
  /// **'Your week is planned.'**
  String get foodWeekPlanned;

  /// No description provided for @foodWeekShopping.
  ///
  /// In en, this message translates to:
  /// **'Make the shopping list'**
  String get foodWeekShopping;

  /// No description provided for @foodWeekNothingMissing.
  ///
  /// In en, this message translates to:
  /// **'You already have everything for this week.'**
  String get foodWeekNothingMissing;

  /// No description provided for @foodNotPlanned.
  ///
  /// In en, this message translates to:
  /// **'Not planned yet'**
  String get foodNotPlanned;

  /// No description provided for @foodWeekCalories.
  ///
  /// In en, this message translates to:
  /// **'~{value} kcal a day'**
  String foodWeekCalories(int value);

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
  /// **'This permanently deletes your account and all data in the cloud and on this device. Active subscriptions must be cancelled in your app store (Google Play or the App Store).'**
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

  /// No description provided for @premiumFeatureStreak.
  ///
  /// In en, this message translates to:
  /// **'Save your streak without ads'**
  String get premiumFeatureStreak;

  /// No description provided for @premiumFeaturePostcards.
  ///
  /// In en, this message translates to:
  /// **'Two postcards from Lio every day'**
  String get premiumFeaturePostcards;

  /// No description provided for @premiumTrial.
  ///
  /// In en, this message translates to:
  /// **'{days}-day free trial, cancel anytime'**
  String premiumTrial(int days);

  /// No description provided for @premiumTry.
  ///
  /// In en, this message translates to:
  /// **'Start free trial'**
  String get premiumTry;

  /// No description provided for @premiumManageIos.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription in the App Store'**
  String get premiumManageIos;

  /// No description provided for @premiumDisclosureIos.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions renew automatically at the price shown until cancelled. Cancel anytime in your Apple Account settings at least 24 hours before renewal. Payment is charged to your Apple Account.'**
  String get premiumDisclosureIos;

  /// No description provided for @gardenAnotherFree.
  ///
  /// In en, this message translates to:
  /// **'One more'**
  String get gardenAnotherFree;

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
  /// **'{minutes, plural, =1{“{title}” starts in 1 minute.} other{“{title}” starts in {minutes} minutes.}}'**
  String notifTaskBody(String title, int minutes);

  /// No description provided for @notifTaskNow.
  ///
  /// In en, this message translates to:
  /// **'“{title}” starts now.'**
  String notifTaskNow(String title);

  /// No description provided for @remindLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get remindLabel;

  /// No description provided for @remindOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get remindOff;

  /// No description provided for @remindAtStart.
  ///
  /// In en, this message translates to:
  /// **'At start'**
  String get remindAtStart;

  /// No description provided for @remindBefore.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before'**
  String remindBefore(int minutes);

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

  /// No description provided for @notifPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Good morning ☀️'**
  String get notifPlanTitle;

  /// No description provided for @notifPlanBody.
  ///
  /// In en, this message translates to:
  /// **'Two minutes with Lio and your day has a plan.'**
  String get notifPlanBody;

  /// No description provided for @notifBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Good morning! 1 thing today} other{Good morning! {count} things today}}'**
  String notifBriefTitle(int count);

  /// No description provided for @notifBriefFirst.
  ///
  /// In en, this message translates to:
  /// **'First: {task}'**
  String notifBriefFirst(String task);

  /// No description provided for @notifBriefSpend.
  ///
  /// In en, this message translates to:
  /// **'you can spend {amount}'**
  String notifBriefSpend(String amount);

  /// No description provided for @notifCloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close the day'**
  String get notifCloseTitle;

  /// No description provided for @notifCloseBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task is still open. One minute and tomorrow is ready.} other{{count} tasks are still open. One minute and tomorrow is ready.}}'**
  String notifCloseBody(int count);

  /// No description provided for @streakSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your {count}-day streak'**
  String streakSaveTitle(int count);

  /// No description provided for @streakSaveBody.
  ///
  /// In en, this message translates to:
  /// **'You took yesterday off. Watch a short ad and Lio freezes that day for you (once a week).'**
  String get streakSaveBody;

  /// No description provided for @streakSaveBodyPremium.
  ///
  /// In en, this message translates to:
  /// **'You took yesterday off. Lio can freeze that day for you (once a week).'**
  String get streakSaveBodyPremium;

  /// No description provided for @streakSaveWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch and save'**
  String get streakSaveWatch;

  /// No description provided for @streakSaveFree.
  ///
  /// In en, this message translates to:
  /// **'Save it'**
  String get streakSaveFree;

  /// No description provided for @streakSaved.
  ///
  /// In en, this message translates to:
  /// **'Streak saved: {count} days'**
  String streakSaved(int count);

  /// No description provided for @notifJournalTitle.
  ///
  /// In en, this message translates to:
  /// **'Your journal'**
  String get notifJournalTitle;

  /// No description provided for @notifJournalBody.
  ///
  /// In en, this message translates to:
  /// **'How was today? A few lines are enough.'**
  String get notifJournalBody;

  /// No description provided for @journalReminderSetting.
  ///
  /// In en, this message translates to:
  /// **'Evening journal reminder'**
  String get journalReminderSetting;

  /// No description provided for @planReminderSetting.
  ///
  /// In en, this message translates to:
  /// **'Morning plan reminder'**
  String get planReminderSetting;

  /// No description provided for @assistantNameSetting.
  ///
  /// In en, this message translates to:
  /// **'Assistant’s name'**
  String get assistantNameSetting;

  /// No description provided for @assistantNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Call your helper whatever you like.'**
  String get assistantNameHelp;

  /// No description provided for @lioLearnsSetting.
  ///
  /// In en, this message translates to:
  /// **'Let Lio learn from my journal'**
  String get lioLearnsSetting;

  /// No description provided for @lioLearnsHelp.
  ///
  /// In en, this message translates to:
  /// **'Lio finds patterns in your entries (what lifts or lowers your mood) on this phone only. Nothing leaves your device.'**
  String get lioLearnsHelp;

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

  /// No description provided for @mascotTip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing urgent today — enjoy it.} =1{I have 1 idea for your day.} other{I have {count} ideas for your day.}}'**
  String mascotTip(int count);

  /// No description provided for @mascotAsk.
  ///
  /// In en, this message translates to:
  /// **'Tap to ask Lio anything'**
  String get mascotAsk;

  /// No description provided for @allGoalsDone.
  ///
  /// In en, this message translates to:
  /// **'All goals done today — amazing!'**
  String get allGoalsDone;

  /// No description provided for @lioName.
  ///
  /// In en, this message translates to:
  /// **'Lio, your companion'**
  String get lioName;

  /// No description provided for @lioAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask Lio'**
  String get lioAsk;

  /// No description provided for @lioAnother.
  ///
  /// In en, this message translates to:
  /// **'Another one'**
  String get lioAnother;

  /// No description provided for @lioHide.
  ///
  /// In en, this message translates to:
  /// **'Hide Lio'**
  String get lioHide;

  /// No description provided for @lioHidden.
  ///
  /// In en, this message translates to:
  /// **'Lio is resting. Bring him back in Settings.'**
  String get lioHidden;

  /// No description provided for @lioSetting.
  ///
  /// In en, this message translates to:
  /// **'Lio companion'**
  String get lioSetting;

  /// No description provided for @lioSettingHelp.
  ///
  /// In en, this message translates to:
  /// **'Lio walks around the app with tips and a little inspiration.'**
  String get lioSettingHelp;

  /// No description provided for @lioGoalsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One goal left today. You’ve got this!} other{{count} goals left today. One at a time.}}'**
  String lioGoalsLeft(int count);

  /// No description provided for @lioAllDone.
  ///
  /// In en, this message translates to:
  /// **'Every goal done today. I’m so proud of you!'**
  String get lioAllDone;

  /// No description provided for @lioOverBudget.
  ///
  /// In en, this message translates to:
  /// **'We went a bit over today. Tomorrow we take it slow — no stress.'**
  String get lioOverBudget;

  /// No description provided for @lioUnderBudget.
  ///
  /// In en, this message translates to:
  /// **'You still have {amount} for today. Nicely balanced!'**
  String lioUnderBudget(String amount);

  /// No description provided for @lioStreak.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak! Let’s keep the fire going.'**
  String lioStreak(int days);

  /// No description provided for @lioMoodCheck.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling? A quick mood check helps me help you.'**
  String get lioMoodCheck;

  /// No description provided for @lioNight.
  ///
  /// In en, this message translates to:
  /// **'It’s getting late. A good night’s sleep is the best plan for tomorrow.'**
  String get lioNight;

  /// No description provided for @lioTipHome1.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to log anything in two seconds.'**
  String get lioTipHome1;

  /// No description provided for @lioTipHome2.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh your day.'**
  String get lioTipHome2;

  /// No description provided for @lioTipPlan1.
  ///
  /// In en, this message translates to:
  /// **'Put your hardest task first — your energy is highest early.'**
  String get lioTipPlan1;

  /// No description provided for @lioTipPlan2.
  ///
  /// In en, this message translates to:
  /// **'Small tasks under 15 minutes? Batch them together.'**
  String get lioTipPlan2;

  /// No description provided for @lioTipPlan3.
  ///
  /// In en, this message translates to:
  /// **'Ask me to plan your day and I’ll arrange everything for you.'**
  String get lioTipPlan3;

  /// No description provided for @lioTipMoney1.
  ///
  /// In en, this message translates to:
  /// **'Just type “250 lunch” — I’ll figure out the rest.'**
  String get lioTipMoney1;

  /// No description provided for @lioTipMoney2.
  ///
  /// In en, this message translates to:
  /// **'Small daily savings add up to big months.'**
  String get lioTipMoney2;

  /// No description provided for @lioTipMoney3.
  ///
  /// In en, this message translates to:
  /// **'Snap a receipt and I’ll read the total for you.'**
  String get lioTipMoney3;

  /// No description provided for @lioTipLife1.
  ///
  /// In en, this message translates to:
  /// **'Two minutes of journaling can clear a whole day’s noise.'**
  String get lioTipLife1;

  /// No description provided for @lioTipLife2.
  ///
  /// In en, this message translates to:
  /// **'Tell me what’s in your fridge and I’ll suggest a meal.'**
  String get lioTipLife2;

  /// No description provided for @lioTipLife3.
  ///
  /// In en, this message translates to:
  /// **'Habits stick best when they’re tiny. Start with one glass of water.'**
  String get lioTipLife3;

  /// No description provided for @lioInspire1.
  ///
  /// In en, this message translates to:
  /// **'Small steps every day beat big plans someday.'**
  String get lioInspire1;

  /// No description provided for @lioInspire2.
  ///
  /// In en, this message translates to:
  /// **'You don’t have to do everything. Just the next right thing.'**
  String get lioInspire2;

  /// No description provided for @lioInspire3.
  ///
  /// In en, this message translates to:
  /// **'Rest is part of the plan, not a break from it.'**
  String get lioInspire3;

  /// No description provided for @lioInspire4.
  ///
  /// In en, this message translates to:
  /// **'Progress, not perfection.'**
  String get lioInspire4;

  /// No description provided for @lioInspire5.
  ///
  /// In en, this message translates to:
  /// **'A calm morning makes a kind day.'**
  String get lioInspire5;

  /// No description provided for @lioInspire6.
  ///
  /// In en, this message translates to:
  /// **'Be proud of how far you’ve come today.'**
  String get lioInspire6;

  /// No description provided for @lioInspire7.
  ///
  /// In en, this message translates to:
  /// **'Drink some water. Future you says thanks.'**
  String get lioInspire7;

  /// No description provided for @lioInspire8.
  ///
  /// In en, this message translates to:
  /// **'Every “no” to a small expense is a “yes” to a bigger dream.'**
  String get lioInspire8;

  /// No description provided for @lioInspire9.
  ///
  /// In en, this message translates to:
  /// **'Done is a beautiful word.'**
  String get lioInspire9;

  /// No description provided for @lioInspire10.
  ///
  /// In en, this message translates to:
  /// **'Take a deep breath. You’re doing better than you think.'**
  String get lioInspire10;

  /// No description provided for @lioInspire11.
  ///
  /// In en, this message translates to:
  /// **'Today is a good day to start something small.'**
  String get lioInspire11;

  /// No description provided for @lioInspire12.
  ///
  /// In en, this message translates to:
  /// **'Kindness to yourself counts too.'**
  String get lioInspire12;

  /// No description provided for @brainGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}! I’m Lio. Ask me about your plan, money, food or how you’re doing.'**
  String brainGreeting(String name);

  /// No description provided for @brainGreetingNoName.
  ///
  /// In en, this message translates to:
  /// **'Hi! I’m Lio. Ask me about your plan, money, food or how you’re doing.'**
  String get brainGreetingNoName;

  /// No description provided for @brainThanks.
  ///
  /// In en, this message translates to:
  /// **'Anytime! I’m right here whenever you need me.'**
  String get brainThanks;

  /// No description provided for @brainPlanNone.
  ///
  /// In en, this message translates to:
  /// **'Your plan for today is empty. Start by adding the one task that matters most — tap + on the Plan tab.'**
  String get brainPlanNone;

  /// No description provided for @brainPlanList.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have 1 thing on your list today:} other{You have {count} things on your list today:}}'**
  String brainPlanList(int count);

  /// No description provided for @brainPlanNext.
  ///
  /// In en, this message translates to:
  /// **'Start with “{title}” — once it’s done, the rest feels lighter.'**
  String brainPlanNext(String title);

  /// No description provided for @brainPlanAllDone.
  ///
  /// In en, this message translates to:
  /// **'Everything on today’s list is done. Rest, or get a head start on tomorrow.'**
  String get brainPlanAllDone;

  /// No description provided for @brainMoneyNoBudget.
  ///
  /// In en, this message translates to:
  /// **'You haven’t set a budget yet. Add your monthly income in Money and I’ll work out a safe daily amount.'**
  String get brainMoneyNoBudget;

  /// No description provided for @brainMoneySafe.
  ///
  /// In en, this message translates to:
  /// **'You can still spend {left} today. Your safe daily amount is {safe}.'**
  String brainMoneySafe(String left, String safe);

  /// No description provided for @brainMoneyOver.
  ///
  /// In en, this message translates to:
  /// **'You’re {over} over today’s safe amount. Let’s go easy for the rest of the day.'**
  String brainMoneyOver(String over);

  /// No description provided for @brainMoneyTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: log expenses right away — just type “250 lunch”.'**
  String get brainMoneyTip;

  /// No description provided for @brainFood.
  ///
  /// In en, this message translates to:
  /// **'How about {meal}? It takes about {minutes} minutes. You’ll find more ideas in Food.'**
  String brainFood(String meal, int minutes);

  /// No description provided for @brainFoodNone.
  ///
  /// In en, this message translates to:
  /// **'Add what’s in your pantry and I’ll suggest meals that use it.'**
  String get brainFoodNone;

  /// No description provided for @brainScore.
  ///
  /// In en, this message translates to:
  /// **'Your Life Score today is {score}/100.'**
  String brainScore(int score);

  /// No description provided for @brainScoreNone.
  ///
  /// In en, this message translates to:
  /// **'No score yet today — log your mood or finish a goal and it will appear.'**
  String get brainScoreNone;

  /// No description provided for @brainFeelLow.
  ///
  /// In en, this message translates to:
  /// **'I’m sorry today feels heavy. Try one tiny thing: a glass of water, a short walk or three slow breaths. Logging your mood can help too.'**
  String get brainFeelLow;

  /// No description provided for @brainSleep.
  ///
  /// In en, this message translates to:
  /// **'Keep a steady bedtime and put screens away 30 minutes before. You can log your sleep from Home.'**
  String get brainSleep;

  /// No description provided for @brainHabit.
  ///
  /// In en, this message translates to:
  /// **'Small habits win. Pick something that takes under two minutes and track it in Habits.'**
  String get brainHabit;

  /// No description provided for @brainHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick a topic below — money, decisions, food, messages or a quick calculation — and I’ll walk you through it.'**
  String get brainHelp;

  /// No description provided for @brainFallback.
  ///
  /// In en, this message translates to:
  /// **'I’m still learning that one. Try asking about your plan, money, food or how your day is going.'**
  String get brainFallback;

  /// No description provided for @brainAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Lio · on your phone'**
  String get brainAnswerLabel;

  /// No description provided for @homeHello.
  ///
  /// In en, this message translates to:
  /// **'Hi {name} 👋'**
  String homeHello(String name);

  /// No description provided for @homeHelloNoName.
  ///
  /// In en, this message translates to:
  /// **'Hi there 👋'**
  String get homeHelloNoName;

  /// No description provided for @homeQuestion.
  ///
  /// In en, this message translates to:
  /// **'What should we solve today?'**
  String get homeQuestion;

  /// No description provided for @problemHint.
  ///
  /// In en, this message translates to:
  /// **'Type a problem…'**
  String get problemHint;

  /// No description provided for @problemEx1.
  ///
  /// In en, this message translates to:
  /// **'I have 3,000 left and 20 days to go'**
  String get problemEx1;

  /// No description provided for @problemEx2.
  ///
  /// In en, this message translates to:
  /// **'1 L for 45 or 1.5 L for 60 — which is cheaper?'**
  String get problemEx2;

  /// No description provided for @problemEx3.
  ///
  /// In en, this message translates to:
  /// **'I have eggs, tomatoes and cheese at home'**
  String get problemEx3;

  /// No description provided for @problemEx4.
  ///
  /// In en, this message translates to:
  /// **'iPhone or Samsung?'**
  String get problemEx4;

  /// No description provided for @problemEx5.
  ///
  /// In en, this message translates to:
  /// **'Split a 1,840 bill between 4 people'**
  String get problemEx5;

  /// No description provided for @problemEx6.
  ///
  /// In en, this message translates to:
  /// **'30% off 1,299 — what do I pay?'**
  String get problemEx6;

  /// No description provided for @problemEx7.
  ///
  /// In en, this message translates to:
  /// **'How many days until December 31?'**
  String get problemEx7;

  /// No description provided for @solve.
  ///
  /// In en, this message translates to:
  /// **'Solve'**
  String get solve;

  /// No description provided for @voiceInput.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get voiceInput;

  /// No description provided for @photoInput.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photoInput;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get listening;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input isn’t available on this device.'**
  String get voiceUnavailable;

  /// No description provided for @photoNoText.
  ///
  /// In en, this message translates to:
  /// **'I couldn’t read any text in that photo.'**
  String get photoNoText;

  /// No description provided for @quickMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get quickMoney;

  /// No description provided for @quickDecide.
  ///
  /// In en, this message translates to:
  /// **'Decide'**
  String get quickDecide;

  /// No description provided for @quickFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get quickFood;

  /// No description provided for @quickCalc.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get quickCalc;

  /// No description provided for @quickWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get quickWrite;

  /// No description provided for @quickPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get quickPlan;

  /// No description provided for @recentlySolved.
  ///
  /// In en, this message translates to:
  /// **'Recently solved'**
  String get recentlySolved;

  /// No description provided for @solutionTitle.
  ///
  /// In en, this message translates to:
  /// **'Solution'**
  String get solutionTitle;

  /// No description provided for @solvedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Calculated on your phone'**
  String get solvedOnDevice;

  /// No description provided for @savedToast.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedToast;

  /// No description provided for @askLioAbout.
  ///
  /// In en, this message translates to:
  /// **'Ask Lio about this'**
  String get askLioAbout;

  /// No description provided for @solveAnother.
  ///
  /// In en, this message translates to:
  /// **'Solve something else'**
  String get solveAnother;

  /// No description provided for @rowPerDay.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get rowPerDay;

  /// No description provided for @rowPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get rowPerWeek;

  /// No description provided for @rowDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get rowDays;

  /// No description provided for @rowTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get rowTotal;

  /// No description provided for @rowYouSave.
  ///
  /// In en, this message translates to:
  /// **'You save'**
  String get rowYouSave;

  /// No description provided for @rowTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get rowTax;

  /// No description provided for @rowIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get rowIncrease;

  /// No description provided for @rowPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get rowPrice;

  /// No description provided for @rowPerPerson.
  ///
  /// In en, this message translates to:
  /// **'Per person'**
  String get rowPerPerson;

  /// No description provided for @rowPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get rowPeople;

  /// No description provided for @rowTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get rowTip;

  /// No description provided for @rowMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get rowMonthly;

  /// No description provided for @rowMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get rowMonths;

  /// No description provided for @rowCash.
  ///
  /// In en, this message translates to:
  /// **'Cash price'**
  String get rowCash;

  /// No description provided for @rowExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra you pay'**
  String get rowExtra;

  /// No description provided for @rowDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get rowDistance;

  /// No description provided for @rowFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get rowFuel;

  /// No description provided for @rowYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get rowYearly;

  /// No description provided for @rowDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get rowDate;

  /// No description provided for @runwayHeadline.
  ///
  /// In en, this message translates to:
  /// **'You can spend {amount} a day.'**
  String runwayHeadline(String amount);

  /// No description provided for @runwayMonthEnd.
  ///
  /// In en, this message translates to:
  /// **'Counted to the end of the month ({days} days, today included).'**
  String runwayMonthEnd(int days);

  /// No description provided for @discountHeadline.
  ///
  /// In en, this message translates to:
  /// **'You pay {amount}.'**
  String discountHeadline(String amount);

  /// No description provided for @vatHeadline.
  ///
  /// In en, this message translates to:
  /// **'Total with VAT: {amount}.'**
  String vatHeadline(String amount);

  /// No description provided for @raiseHeadline.
  ///
  /// In en, this message translates to:
  /// **'New amount: {amount}.'**
  String raiseHeadline(String amount);

  /// No description provided for @percentOfHeadline.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of {base} is {result}.'**
  String percentOfHeadline(String percent, String base, String result);

  /// No description provided for @splitHeadline.
  ///
  /// In en, this message translates to:
  /// **'Each person pays {amount}.'**
  String splitHeadline(String amount);

  /// No description provided for @installmentMore.
  ///
  /// In en, this message translates to:
  /// **'Instalments cost {amount} more than paying cash ({percent}%).'**
  String installmentMore(String amount, String percent);

  /// No description provided for @installmentNoMore.
  ///
  /// In en, this message translates to:
  /// **'Instalments cost no more than cash — spreading it out is fine.'**
  String get installmentNoMore;

  /// No description provided for @installmentTotal.
  ///
  /// In en, this message translates to:
  /// **'You will pay {amount} in total.'**
  String installmentTotal(String amount);

  /// No description provided for @unitPriceHeadline.
  ///
  /// In en, this message translates to:
  /// **'Option {n} is cheaper: {price} per {unit}.'**
  String unitPriceHeadline(int n, String price, String unit);

  /// No description provided for @unitPriceSaving.
  ///
  /// In en, this message translates to:
  /// **'About {percent}% cheaper per unit.'**
  String unitPriceSaving(String percent);

  /// No description provided for @unitPriceSame.
  ///
  /// In en, this message translates to:
  /// **'They cost the same per unit — pick the size you’ll actually use.'**
  String get unitPriceSame;

  /// No description provided for @unitPieceLabel.
  ///
  /// In en, this message translates to:
  /// **'piece'**
  String get unitPieceLabel;

  /// No description provided for @fuelHeadline.
  ///
  /// In en, this message translates to:
  /// **'The trip costs about {amount} in fuel.'**
  String fuelHeadline(String amount);

  /// No description provided for @yearlyHeadline.
  ///
  /// In en, this message translates to:
  /// **'That is {amount} a year.'**
  String yearlyHeadline(String amount);

  /// No description provided for @daysUntilHeadline.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{It’s today!} =1{1 day to go.} other{{days} days to go.}}'**
  String daysUntilHeadline(int days);

  /// No description provided for @optionN.
  ///
  /// In en, this message translates to:
  /// **'Option {n}'**
  String optionN(int n);

  /// No description provided for @decideTitle.
  ///
  /// In en, this message translates to:
  /// **'Decide'**
  String get decideTitle;

  /// No description provided for @decideIntro.
  ///
  /// In en, this message translates to:
  /// **'Add your options and what matters to you. I’ll weigh them up.'**
  String get decideIntro;

  /// No description provided for @decideAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get decideAddOption;

  /// No description provided for @decidePrice.
  ///
  /// In en, this message translates to:
  /// **'Price (optional)'**
  String get decidePrice;

  /// No description provided for @decideWhatMatters.
  ///
  /// In en, this message translates to:
  /// **'What matters?'**
  String get decideWhatMatters;

  /// No description provided for @critPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get critPrice;

  /// No description provided for @critQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get critQuality;

  /// No description provided for @critFit.
  ///
  /// In en, this message translates to:
  /// **'Fits my needs'**
  String get critFit;

  /// No description provided for @critLongTerm.
  ///
  /// In en, this message translates to:
  /// **'Long-term value'**
  String get critLongTerm;

  /// No description provided for @critRisk.
  ///
  /// In en, this message translates to:
  /// **'Low risk'**
  String get critRisk;

  /// No description provided for @critCustomHint.
  ///
  /// In en, this message translates to:
  /// **'Something else that matters'**
  String get critCustomHint;

  /// No description provided for @weight1.
  ///
  /// In en, this message translates to:
  /// **'Nice to have'**
  String get weight1;

  /// No description provided for @weight2.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get weight2;

  /// No description provided for @weight3.
  ///
  /// In en, this message translates to:
  /// **'Must'**
  String get weight3;

  /// No description provided for @decideRate.
  ///
  /// In en, this message translates to:
  /// **'Rate each option'**
  String get decideRate;

  /// No description provided for @decideRateHelp.
  ///
  /// In en, this message translates to:
  /// **'1 = poor, 5 = great. Price is scored from the prices you entered.'**
  String get decideRateHelp;

  /// No description provided for @decideShow.
  ///
  /// In en, this message translates to:
  /// **'Show the best option'**
  String get decideShow;

  /// No description provided for @decideRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get decideRecommended;

  /// No description provided for @decideWhy.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get decideWhy;

  /// No description provided for @decideStrength.
  ///
  /// In en, this message translates to:
  /// **'Better on {criterion}'**
  String decideStrength(String criterion);

  /// No description provided for @decideWeakness.
  ///
  /// In en, this message translates to:
  /// **'Weaker on {criterion}'**
  String decideWeakness(String criterion);

  /// No description provided for @decideTooClose.
  ///
  /// In en, this message translates to:
  /// **'It’s very close — both are reasonable. Let what you value most decide.'**
  String get decideTooClose;

  /// No description provided for @decideSlight.
  ///
  /// In en, this message translates to:
  /// **'A slight edge, not a big one.'**
  String get decideSlight;

  /// No description provided for @decideClear.
  ///
  /// In en, this message translates to:
  /// **'A clear winner for your priorities.'**
  String get decideClear;

  /// No description provided for @decideDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Based on your own ratings. Check current prices and details before you buy.'**
  String get decideDisclaimer;

  /// No description provided for @decideNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'Add at least two options.'**
  String get decideNeedTwo;

  /// No description provided for @decideScore.
  ///
  /// In en, this message translates to:
  /// **'{score}/100'**
  String decideScore(int score);

  /// No description provided for @calcTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get calcTitle;

  /// No description provided for @calcError.
  ///
  /// In en, this message translates to:
  /// **'Check the expression'**
  String get calcError;

  /// No description provided for @exploreTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get exploreTitle;

  /// No description provided for @exploreSolve.
  ///
  /// In en, this message translates to:
  /// **'Solve'**
  String get exploreSolve;

  /// No description provided for @exploreLife.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get exploreLife;

  /// No description provided for @exploreMyDay.
  ///
  /// In en, this message translates to:
  /// **'My day'**
  String get exploreMyDay;

  /// No description provided for @exploreMyDayBody.
  ///
  /// In en, this message translates to:
  /// **'Plan, budget and goals for today'**
  String get exploreMyDayBody;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// No description provided for @savedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get savedEmptyTitle;

  /// No description provided for @savedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Solve a problem and tap Save to keep it here.'**
  String get savedEmptyBody;

  /// No description provided for @removed.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get removed;

  /// No description provided for @recipeHeadline.
  ///
  /// In en, this message translates to:
  /// **'You can make these with what you have'**
  String get recipeHeadline;

  /// No description provided for @recipeMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing: {items}'**
  String recipeMissing(String items);

  /// No description provided for @recipeHaveAll.
  ///
  /// In en, this message translates to:
  /// **'You have everything'**
  String get recipeHaveAll;

  /// No description provided for @recipeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String recipeMinutes(int minutes);

  /// No description provided for @addMissingToList.
  ///
  /// In en, this message translates to:
  /// **'Add missing to shopping list'**
  String get addMissingToList;

  /// No description provided for @addedToList.
  ///
  /// In en, this message translates to:
  /// **'Added to your shopping list'**
  String get addedToList;

  /// No description provided for @recipeNoMatch.
  ///
  /// In en, this message translates to:
  /// **'I couldn’t match those ingredients to a recipe yet. Ask Lio for ideas.'**
  String get recipeNoMatch;

  /// No description provided for @gTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Or type your problem…'**
  String get gTypeHint;

  /// No description provided for @gAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer…'**
  String get gAnswerHint;

  /// No description provided for @gRestart.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get gRestart;

  /// No description provided for @gMainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get gMainMenu;

  /// No description provided for @gSomethingElse.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get gSomethingElse;

  /// No description provided for @gNotUnderstood.
  ///
  /// In en, this message translates to:
  /// **'I can’t do that one yet. Pick a topic and I’ll help step by step.'**
  String get gNotUnderstood;

  /// No description provided for @gInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'That doesn’t look like a number. Try again?'**
  String get gInvalidNumber;

  /// No description provided for @gMood.
  ///
  /// In en, this message translates to:
  /// **'Mood boost'**
  String get gMood;

  /// No description provided for @gRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get gRemind;

  /// No description provided for @gRemindPrompt.
  ///
  /// In en, this message translates to:
  /// **'What should I remind you about?'**
  String get gRemindPrompt;

  /// No description provided for @gMoneyPrompt.
  ///
  /// In en, this message translates to:
  /// **'What should we figure out?'**
  String get gMoneyPrompt;

  /// No description provided for @gRunway.
  ///
  /// In en, this message translates to:
  /// **'Will my money last?'**
  String get gRunway;

  /// No description provided for @gDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get gDiscount;

  /// No description provided for @gSplit.
  ///
  /// In en, this message translates to:
  /// **'Split the bill'**
  String get gSplit;

  /// No description provided for @gInstallment.
  ///
  /// In en, this message translates to:
  /// **'Instalments or cash?'**
  String get gInstallment;

  /// No description provided for @gUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Which is cheaper?'**
  String get gUnitPrice;

  /// No description provided for @gVat.
  ///
  /// In en, this message translates to:
  /// **'Add VAT'**
  String get gVat;

  /// No description provided for @gRaise.
  ///
  /// In en, this message translates to:
  /// **'Salary raise'**
  String get gRaise;

  /// No description provided for @gYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly cost of subscriptions'**
  String get gYearly;

  /// No description provided for @gCalcPrompt.
  ///
  /// In en, this message translates to:
  /// **'What should we calculate?'**
  String get gCalcPrompt;

  /// No description provided for @gPercentOf.
  ///
  /// In en, this message translates to:
  /// **'Percent of a number'**
  String get gPercentOf;

  /// No description provided for @gConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert units'**
  String get gConvert;

  /// No description provided for @gDaysUntil.
  ///
  /// In en, this message translates to:
  /// **'Days until a date'**
  String get gDaysUntil;

  /// No description provided for @gFuel.
  ///
  /// In en, this message translates to:
  /// **'Trip fuel cost'**
  String get gFuel;

  /// No description provided for @gOpenCalculator.
  ///
  /// In en, this message translates to:
  /// **'Open the calculator'**
  String get gOpenCalculator;

  /// No description provided for @qAmountLeft.
  ///
  /// In en, this message translates to:
  /// **'How much money do you have left?'**
  String get qAmountLeft;

  /// No description provided for @qDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'How many days does it need to last?'**
  String get qDaysLeft;

  /// No description provided for @qMonthEnd.
  ///
  /// In en, this message translates to:
  /// **'Until month end'**
  String get qMonthEnd;

  /// No description provided for @qPrice.
  ///
  /// In en, this message translates to:
  /// **'What’s the price?'**
  String get qPrice;

  /// No description provided for @qDiscountPct.
  ///
  /// In en, this message translates to:
  /// **'How many percent off?'**
  String get qDiscountPct;

  /// No description provided for @qTotal.
  ///
  /// In en, this message translates to:
  /// **'What’s the total bill?'**
  String get qTotal;

  /// No description provided for @qPeople.
  ///
  /// In en, this message translates to:
  /// **'How many people?'**
  String get qPeople;

  /// No description provided for @qTip.
  ///
  /// In en, this message translates to:
  /// **'Any tip?'**
  String get qTip;

  /// No description provided for @qNoTip.
  ///
  /// In en, this message translates to:
  /// **'No tip'**
  String get qNoTip;

  /// No description provided for @qMonthly.
  ///
  /// In en, this message translates to:
  /// **'How much is each instalment?'**
  String get qMonthly;

  /// No description provided for @qMonths.
  ///
  /// In en, this message translates to:
  /// **'How many months?'**
  String get qMonths;

  /// No description provided for @qCash.
  ///
  /// In en, this message translates to:
  /// **'What’s the cash price? (skip if you don’t know)'**
  String get qCash;

  /// No description provided for @qSize1.
  ///
  /// In en, this message translates to:
  /// **'First option: how much is in it? (e.g. 1 L, 500 g, 6 pcs)'**
  String get qSize1;

  /// No description provided for @qPrice1.
  ///
  /// In en, this message translates to:
  /// **'And its price?'**
  String get qPrice1;

  /// No description provided for @qSize2.
  ///
  /// In en, this message translates to:
  /// **'Second option: how much is in it?'**
  String get qSize2;

  /// No description provided for @qPrice2.
  ///
  /// In en, this message translates to:
  /// **'And its price?'**
  String get qPrice2;

  /// No description provided for @qNeedUnit.
  ///
  /// In en, this message translates to:
  /// **'Add a unit, like 1 L, 500 g or 6 pcs.'**
  String get qNeedUnit;

  /// No description provided for @qVatRate.
  ///
  /// In en, this message translates to:
  /// **'Which VAT rate?'**
  String get qVatRate;

  /// No description provided for @qSalary.
  ///
  /// In en, this message translates to:
  /// **'What’s the current amount?'**
  String get qSalary;

  /// No description provided for @qRaisePct.
  ///
  /// In en, this message translates to:
  /// **'How many percent is the raise?'**
  String get qRaisePct;

  /// No description provided for @qSubs.
  ///
  /// In en, this message translates to:
  /// **'Monthly amounts, separated by commas (e.g. 99, 149)'**
  String get qSubs;

  /// No description provided for @qNumber.
  ///
  /// In en, this message translates to:
  /// **'Which number?'**
  String get qNumber;

  /// No description provided for @qPercent.
  ///
  /// In en, this message translates to:
  /// **'What percent?'**
  String get qPercent;

  /// No description provided for @qConvert.
  ///
  /// In en, this message translates to:
  /// **'What should I convert? (e.g. 5 kg to lb)'**
  String get qConvert;

  /// No description provided for @qDate.
  ///
  /// In en, this message translates to:
  /// **'Which date? (e.g. 31 December)'**
  String get qDate;

  /// No description provided for @qKm.
  ///
  /// In en, this message translates to:
  /// **'How many km is the trip?'**
  String get qKm;

  /// No description provided for @qConsumption.
  ///
  /// In en, this message translates to:
  /// **'How many litres per 100 km?'**
  String get qConsumption;

  /// No description provided for @qFuelPrice.
  ///
  /// In en, this message translates to:
  /// **'Fuel price per litre?'**
  String get qFuelPrice;

  /// No description provided for @gConvertFail.
  ///
  /// In en, this message translates to:
  /// **'I couldn’t read that. Try “5 kg to lb” or “30 C to F”.'**
  String get gConvertFail;

  /// No description provided for @gDateFail.
  ///
  /// In en, this message translates to:
  /// **'I couldn’t read that date. Try “31 December”.'**
  String get gDateFail;

  /// No description provided for @gDecidePrompt.
  ///
  /// In en, this message translates to:
  /// **'Let’s decide. What are your options?'**
  String get gDecidePrompt;

  /// No description provided for @qOptions.
  ///
  /// In en, this message translates to:
  /// **'Write your options (e.g. pizza sushi)'**
  String get qOptions;

  /// No description provided for @gDecideCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare them properly'**
  String get gDecideCompare;

  /// No description provided for @gCoin.
  ///
  /// In en, this message translates to:
  /// **'Flip a coin'**
  String get gCoin;

  /// No description provided for @gRandomPick.
  ///
  /// In en, this message translates to:
  /// **'Pick one for me'**
  String get gRandomPick;

  /// No description provided for @coinHeads.
  ///
  /// In en, this message translates to:
  /// **'Heads! 🪙'**
  String get coinHeads;

  /// No description provided for @coinTails.
  ///
  /// In en, this message translates to:
  /// **'Tails! 🪙'**
  String get coinTails;

  /// No description provided for @randomPicked.
  ///
  /// In en, this message translates to:
  /// **'I pick {option}! 🎲'**
  String randomPicked(String option);

  /// No description provided for @gFoodPrompt.
  ///
  /// In en, this message translates to:
  /// **'Food time! What do you need?'**
  String get gFoodPrompt;

  /// No description provided for @gCookWithWhatIHave.
  ///
  /// In en, this message translates to:
  /// **'Cook with what I have'**
  String get gCookWithWhatIHave;

  /// No description provided for @qIngredients.
  ///
  /// In en, this message translates to:
  /// **'What do you have? (e.g. eggs tomatoes cheese)'**
  String get qIngredients;

  /// No description provided for @gWhatToEat.
  ///
  /// In en, this message translates to:
  /// **'What should I eat?'**
  String get gWhatToEat;

  /// No description provided for @gShoppingList.
  ///
  /// In en, this message translates to:
  /// **'My shopping list'**
  String get gShoppingList;

  /// No description provided for @gRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get gRecipes;

  /// No description provided for @mealIdea.
  ///
  /// In en, this message translates to:
  /// **'How about {meal}? Ready in about {minutes} min.'**
  String mealIdea(String meal, int minutes);

  /// No description provided for @gAnotherIdea.
  ///
  /// In en, this message translates to:
  /// **'Another idea'**
  String get gAnotherIdea;

  /// No description provided for @gWritePrompt.
  ///
  /// In en, this message translates to:
  /// **'What kind of message should we write?'**
  String get gWritePrompt;

  /// No description provided for @tplBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday wishes'**
  String get tplBirthday;

  /// No description provided for @tplThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get tplThanks;

  /// No description provided for @tplApology.
  ///
  /// In en, this message translates to:
  /// **'Apology'**
  String get tplApology;

  /// No description provided for @tplLate.
  ///
  /// In en, this message translates to:
  /// **'Running late'**
  String get tplLate;

  /// No description provided for @tplLeave.
  ///
  /// In en, this message translates to:
  /// **'Asking for time off'**
  String get tplLeave;

  /// No description provided for @tplDecline.
  ///
  /// In en, this message translates to:
  /// **'Saying no politely'**
  String get tplDecline;

  /// No description provided for @tplCongrats.
  ///
  /// In en, this message translates to:
  /// **'Congratulations'**
  String get tplCongrats;

  /// No description provided for @tplCondolence.
  ///
  /// In en, this message translates to:
  /// **'Condolences'**
  String get tplCondolence;

  /// No description provided for @tplPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment reminder'**
  String get tplPayment;

  /// No description provided for @tplComplaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint to a company'**
  String get tplComplaint;

  /// No description provided for @tplJob.
  ///
  /// In en, this message translates to:
  /// **'Job application'**
  String get tplJob;

  /// No description provided for @tplLandlord.
  ///
  /// In en, this message translates to:
  /// **'Message to the landlord'**
  String get tplLandlord;

  /// No description provided for @qTone.
  ///
  /// In en, this message translates to:
  /// **'Which tone?'**
  String get qTone;

  /// No description provided for @toneWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get toneWarm;

  /// No description provided for @toneFormal.
  ///
  /// In en, this message translates to:
  /// **'Formal'**
  String get toneFormal;

  /// No description provided for @toneShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get toneShort;

  /// No description provided for @fName.
  ///
  /// In en, this message translates to:
  /// **'Who is it for? (a name, or skip)'**
  String get fName;

  /// No description provided for @fCompany.
  ///
  /// In en, this message translates to:
  /// **'Which company?'**
  String get fCompany;

  /// No description provided for @fWhatThanks.
  ///
  /// In en, this message translates to:
  /// **'What are you thanking them for?'**
  String get fWhatThanks;

  /// No description provided for @fWhatApology.
  ///
  /// In en, this message translates to:
  /// **'What are you apologising for?'**
  String get fWhatApology;

  /// No description provided for @fWhatLeave.
  ///
  /// In en, this message translates to:
  /// **'What’s the reason?'**
  String get fWhatLeave;

  /// No description provided for @fWhatDecline.
  ///
  /// In en, this message translates to:
  /// **'What are you saying no to?'**
  String get fWhatDecline;

  /// No description provided for @fWhatCongrats.
  ///
  /// In en, this message translates to:
  /// **'What are you congratulating them on?'**
  String get fWhatCongrats;

  /// No description provided for @fWhatPayment.
  ///
  /// In en, this message translates to:
  /// **'Which payment? (e.g. the 500 rent)'**
  String get fWhatPayment;

  /// No description provided for @fWhatComplaint.
  ///
  /// In en, this message translates to:
  /// **'What’s the problem?'**
  String get fWhatComplaint;

  /// No description provided for @fWhatJob.
  ///
  /// In en, this message translates to:
  /// **'Which position?'**
  String get fWhatJob;

  /// No description provided for @fWhatLandlord.
  ///
  /// In en, this message translates to:
  /// **'What needs fixing? (e.g. the boiler)'**
  String get fWhatLandlord;

  /// No description provided for @fWhenLate.
  ///
  /// In en, this message translates to:
  /// **'When will you get there? (e.g. in 15 minutes)'**
  String get fWhenLate;

  /// No description provided for @fWhenLeave.
  ///
  /// In en, this message translates to:
  /// **'Which day(s)? (e.g. on Friday)'**
  String get fWhenLeave;

  /// No description provided for @writeResult.
  ///
  /// In en, this message translates to:
  /// **'Here are a few versions. Copy the one you like.'**
  String get writeResult;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @gOtherTone.
  ///
  /// In en, this message translates to:
  /// **'Another tone'**
  String get gOtherTone;

  /// No description provided for @gOtherMessage.
  ///
  /// In en, this message translates to:
  /// **'Another message'**
  String get gOtherMessage;

  /// No description provided for @gMoodPrompt.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling right now?'**
  String get gMoodPrompt;

  /// No description provided for @mTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get mTired;

  /// No description provided for @mStressed.
  ///
  /// In en, this message translates to:
  /// **'Stressed'**
  String get mStressed;

  /// No description provided for @mUnmotivated.
  ///
  /// In en, this message translates to:
  /// **'No motivation'**
  String get mUnmotivated;

  /// No description provided for @mCantSleep.
  ///
  /// In en, this message translates to:
  /// **'Can’t sleep'**
  String get mCantSleep;

  /// No description provided for @mLonely.
  ///
  /// In en, this message translates to:
  /// **'Lonely'**
  String get mLonely;

  /// No description provided for @mVeryBad.
  ///
  /// In en, this message translates to:
  /// **'Really bad'**
  String get mVeryBad;

  /// No description provided for @mTiredReply.
  ///
  /// In en, this message translates to:
  /// **'That happens. Try this:\n• a glass of water and a 10-minute walk\n• one small task, then a real break\n• an early night tonight'**
  String get mTiredReply;

  /// No description provided for @mStressedReply.
  ///
  /// In en, this message translates to:
  /// **'Let’s slow down for a minute:\n• breathe in for 4, hold for 4, out for 6 — five times\n• write down the one thing that matters most today\n• everything else can wait a little'**
  String get mStressedReply;

  /// No description provided for @mUnmotivatedReply.
  ///
  /// In en, this message translates to:
  /// **'Motivation often comes after starting, not before:\n• pick a 2-minute version of the task\n• set a 10-minute timer and just begin\n• reward yourself when it rings'**
  String get mUnmotivatedReply;

  /// No description provided for @mCantSleepReply.
  ///
  /// In en, this message translates to:
  /// **'For tonight:\n• put the screen away and dim the lights\n• keep the room cool\n• if you’re still awake after 20 minutes, get up, read something calm, then try again'**
  String get mCantSleepReply;

  /// No description provided for @mLonelyReply.
  ///
  /// In en, this message translates to:
  /// **'Feeling lonely is hard, and you’re not the only one. A small step can help: message one person you miss, or go somewhere with people around for a bit — a café, a park, a class.'**
  String get mLonelyReply;

  /// No description provided for @mVeryBadReply.
  ///
  /// In en, this message translates to:
  /// **'I’m really sorry you’re feeling this way. You don’t have to carry it alone — please talk to someone you trust today. If you are in danger or thinking about hurting yourself, call your local emergency number now (112 in Türkiye and Europe, 911 in the US).'**
  String get mVeryBadReply;

  /// No description provided for @gInspire.
  ///
  /// In en, this message translates to:
  /// **'Inspire me'**
  String get gInspire;

  /// No description provided for @gMyDayPrompt.
  ///
  /// In en, this message translates to:
  /// **'What would you like to know about today?'**
  String get gMyDayPrompt;

  /// No description provided for @gTodayPlan.
  ///
  /// In en, this message translates to:
  /// **'Today’s plan'**
  String get gTodayPlan;

  /// No description provided for @gSpendToday.
  ///
  /// In en, this message translates to:
  /// **'How much can I spend today?'**
  String get gSpendToday;

  /// No description provided for @gMyScore.
  ///
  /// In en, this message translates to:
  /// **'My Life Score'**
  String get gMyScore;

  /// No description provided for @gOpenMyDay.
  ///
  /// In en, this message translates to:
  /// **'Open My day'**
  String get gOpenMyDay;

  /// No description provided for @pPrompt.
  ///
  /// In en, this message translates to:
  /// **'Let’s plan your day! What do you need to get done today? (e.g. write the report, call mom, gym)'**
  String get pPrompt;

  /// No description provided for @pAlready.
  ///
  /// In en, this message translates to:
  /// **'You already have these today: {tasks}. Add them to the plan?'**
  String pAlready(String tasks);

  /// No description provided for @pYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get pYes;

  /// No description provided for @pNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get pNo;

  /// No description provided for @pImportant.
  ///
  /// In en, this message translates to:
  /// **'Which one matters most?'**
  String get pImportant;

  /// No description provided for @pAllSame.
  ///
  /// In en, this message translates to:
  /// **'All equal'**
  String get pAllSame;

  /// No description provided for @pDuration.
  ///
  /// In en, this message translates to:
  /// **'Roughly how long does each one take?'**
  String get pDuration;

  /// No description provided for @pHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String pHours(int hours);

  /// No description provided for @pStart.
  ///
  /// In en, this message translates to:
  /// **'When should we start?'**
  String get pStart;

  /// No description provided for @pNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get pNow;

  /// No description provided for @pTimeFail.
  ///
  /// In en, this message translates to:
  /// **'Write a time like 09:30.'**
  String get pTimeFail;

  /// No description provided for @pResult.
  ///
  /// In en, this message translates to:
  /// **'Here’s your plan for today:'**
  String get pResult;

  /// No description provided for @pFixed.
  ///
  /// In en, this message translates to:
  /// **'already scheduled'**
  String get pFixed;

  /// No description provided for @pBreaks.
  ///
  /// In en, this message translates to:
  /// **'I left 10 minutes between tasks so you can breathe.'**
  String get pBreaks;

  /// No description provided for @pDidntFit.
  ///
  /// In en, this message translates to:
  /// **'These didn’t fit today: {tasks}'**
  String pDidntFit(String tasks);

  /// No description provided for @pAddToDay.
  ///
  /// In en, this message translates to:
  /// **'Add to my day'**
  String get pAddToDay;

  /// No description provided for @pAdded.
  ///
  /// In en, this message translates to:
  /// **'Done! Your plan is in Plan, with reminders.'**
  String get pAdded;

  /// No description provided for @pRedo.
  ///
  /// In en, this message translates to:
  /// **'Plan again'**
  String get pRedo;

  /// No description provided for @pOpenPlan.
  ///
  /// In en, this message translates to:
  /// **'Open Plan'**
  String get pOpenPlan;

  /// No description provided for @pNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to plan yet. Tell me at least one thing to do.'**
  String get pNothing;

  /// No description provided for @lioSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Lio’s suggestions'**
  String get lioSuggestions;

  /// No description provided for @lioAllGood.
  ///
  /// In en, this message translates to:
  /// **'All looks good today. I’ll tell you when something needs attention.'**
  String get lioAllGood;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get insightsTitle;

  /// No description provided for @insightsIntro.
  ///
  /// In en, this message translates to:
  /// **'I looked at your money, plans, habits, mood and journal. Here’s what stood out.'**
  String get insightsIntro;

  /// No description provided for @insightsMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more suggestion} other{{count} more suggestions}}'**
  String insightsMore(int count);

  /// No description provided for @insightsUnlock.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to see them all today'**
  String get insightsUnlock;

  /// No description provided for @gMySuggestions.
  ///
  /// In en, this message translates to:
  /// **'My suggestions'**
  String get gMySuggestions;

  /// No description provided for @advOverBudget.
  ///
  /// In en, this message translates to:
  /// **'You’re {amount} over today’s budget. Let’s keep tomorrow light.'**
  String advOverBudget(String amount);

  /// No description provided for @advBudgetTight.
  ///
  /// In en, this message translates to:
  /// **'Only {amount} left for today. A no-spend evening would help.'**
  String advBudgetTight(String amount);

  /// No description provided for @advSavingsOff.
  ///
  /// In en, this message translates to:
  /// **'At this pace you’ll miss your savings goal by about {amount} this month.'**
  String advSavingsOff(String amount);

  /// No description provided for @advSetUpBudget.
  ///
  /// In en, this message translates to:
  /// **'You’ve logged several expenses. Add your monthly income and I’ll work out a safe daily limit.'**
  String get advSetUpBudget;

  /// No description provided for @advWeeklyUp.
  ///
  /// In en, this message translates to:
  /// **'You spent {percent}% more this week than usual.'**
  String advWeeklyUp(int percent);

  /// No description provided for @advWeeklyDown.
  ///
  /// In en, this message translates to:
  /// **'Nice! You spent {percent}% less this week than usual.'**
  String advWeeklyDown(int percent);

  /// No description provided for @advCategorySpike.
  ///
  /// In en, this message translates to:
  /// **'{category} spending is up {percent}% compared with last month.'**
  String advCategorySpike(String category, int percent);

  /// No description provided for @advSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Looks like {count} subscriptions ({names}), about {amount} a year. Still using them all?'**
  String advSubscriptions(int count, String names, String amount);

  /// No description provided for @advTopCategory.
  ///
  /// In en, this message translates to:
  /// **'{category} is {percent}% of your spending this month.'**
  String advTopCategory(String category, int percent);

  /// No description provided for @advOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task is overdue.} other{{count} tasks are overdue.}} Shall we fit them into today?'**
  String advOverdue(int count);

  /// No description provided for @advNoPlan.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned for today yet. Two minutes with me and your day has a shape.'**
  String get advNoPlan;

  /// No description provided for @advUnscheduled.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks today have no time yet. Want me to schedule them?'**
  String advUnscheduled(int count);

  /// No description provided for @advTasksGood.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks done this week. Great rhythm!'**
  String advTasksGood(int count);

  /// No description provided for @advHabitRisk.
  ///
  /// In en, this message translates to:
  /// **'Your {count}-day {name} streak is waiting for today.'**
  String advHabitRisk(int count, String name);

  /// No description provided for @advHabitDown.
  ///
  /// In en, this message translates to:
  /// **'Habits slipped {percent} points this week. Pick one small win for today.'**
  String advHabitDown(int percent);

  /// No description provided for @advHabitUp.
  ///
  /// In en, this message translates to:
  /// **'Habits are up {percent} points this week. Keep going!'**
  String advHabitUp(int percent);

  /// No description provided for @advMoodDown.
  ///
  /// In en, this message translates to:
  /// **'Your mood has been lower this week. Want to talk it through or write a few lines?'**
  String get advMoodDown;

  /// No description provided for @advMoodSleep.
  ///
  /// In en, this message translates to:
  /// **'On short-sleep days your mood tends to be lower. An earlier night might help.'**
  String get advMoodSleep;

  /// No description provided for @advJournalNudge.
  ///
  /// In en, this message translates to:
  /// **'How was today? Two lines in your journal is enough.'**
  String get advJournalNudge;

  /// No description provided for @advJournalStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} days of journaling in a row. Lovely habit.'**
  String advJournalStreak(int count);

  /// No description provided for @advShopping.
  ///
  /// In en, this message translates to:
  /// **'{count} items are waiting on your shopping list.'**
  String advShopping(int count);

  /// No description provided for @advCook.
  ///
  /// In en, this message translates to:
  /// **'You have everything for {name} ({minutes} min).'**
  String advCook(String name, int minutes);

  /// No description provided for @actOpenMoney.
  ///
  /// In en, this message translates to:
  /// **'Open Money'**
  String get actOpenMoney;

  /// No description provided for @actPlanDay.
  ///
  /// In en, this message translates to:
  /// **'Plan my day'**
  String get actPlanDay;

  /// No description provided for @actOpenPlan.
  ///
  /// In en, this message translates to:
  /// **'Open Plan'**
  String get actOpenPlan;

  /// No description provided for @actOpenHabits.
  ///
  /// In en, this message translates to:
  /// **'Open Habits'**
  String get actOpenHabits;

  /// No description provided for @actTalk.
  ///
  /// In en, this message translates to:
  /// **'Talk to Lio'**
  String get actTalk;

  /// No description provided for @actLogMood.
  ///
  /// In en, this message translates to:
  /// **'Log sleep & mood'**
  String get actLogMood;

  /// No description provided for @actWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get actWrite;

  /// No description provided for @actShopping.
  ///
  /// In en, this message translates to:
  /// **'Open list'**
  String get actShopping;

  /// No description provided for @actRecipe.
  ///
  /// In en, this message translates to:
  /// **'See recipe'**
  String get actRecipe;

  /// No description provided for @quickJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get quickJournal;

  /// No description provided for @advJournalLift.
  ///
  /// In en, this message translates to:
  /// **'On days you write about “{word}”, your mood is usually better. Make some room for it today?'**
  String advJournalLift(String word);

  /// No description provided for @advJournalDrain.
  ///
  /// In en, this message translates to:
  /// **'Days with “{word}” in your journal tend to be harder. Anything you can plan around it?'**
  String advJournalDrain(String word);

  /// No description provided for @journalKnowsTitle.
  ///
  /// In en, this message translates to:
  /// **'What Lio has learned'**
  String get journalKnowsTitle;

  /// No description provided for @journalThemes.
  ///
  /// In en, this message translates to:
  /// **'You write most about'**
  String get journalThemes;

  /// No description provided for @journalLifts.
  ///
  /// In en, this message translates to:
  /// **'Lifts your mood'**
  String get journalLifts;

  /// No description provided for @journalDrains.
  ///
  /// In en, this message translates to:
  /// **'Makes days harder'**
  String get journalDrains;

  /// No description provided for @journalLearnHint.
  ///
  /// In en, this message translates to:
  /// **'Keep writing and logging how you feel; I’ll spot patterns after about a week.'**
  String get journalLearnHint;

  /// No description provided for @journalOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Learned on this phone only.'**
  String get journalOnDevice;

  /// No description provided for @journalStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak'**
  String journalStreakLabel(int count);

  /// No description provided for @journalThisMonth.
  ///
  /// In en, this message translates to:
  /// **'{count} this month'**
  String journalThisMonth(int count);

  /// No description provided for @journalMoodWeek.
  ///
  /// In en, this message translates to:
  /// **'Mood this week'**
  String get journalMoodWeek;

  /// No description provided for @journalSearch.
  ///
  /// In en, this message translates to:
  /// **'Search your journal'**
  String get journalSearch;

  /// No description provided for @journalTodayPrompt.
  ///
  /// In en, this message translates to:
  /// **'Today’s question'**
  String get journalTodayPrompt;

  /// No description provided for @journalHowFeel.
  ///
  /// In en, this message translates to:
  /// **'How do you feel?'**
  String get journalHowFeel;

  /// No description provided for @journalWords.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String journalWords(int count);

  /// No description provided for @journalNoResults.
  ///
  /// In en, this message translates to:
  /// **'No entries match.'**
  String get journalNoResults;

  /// No description provided for @journalWriteToday.
  ///
  /// In en, this message translates to:
  /// **'Write today’s entry'**
  String get journalWriteToday;

  /// No description provided for @journalSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your journal'**
  String get journalSaved;

  /// No description provided for @jp1.
  ///
  /// In en, this message translates to:
  /// **'What made you smile today?'**
  String get jp1;

  /// No description provided for @jp2.
  ///
  /// In en, this message translates to:
  /// **'What are you grateful for?'**
  String get jp2;

  /// No description provided for @jp3.
  ///
  /// In en, this message translates to:
  /// **'What drained your energy today?'**
  String get jp3;

  /// No description provided for @jp4.
  ///
  /// In en, this message translates to:
  /// **'What will you do differently tomorrow?'**
  String get jp4;

  /// No description provided for @jp5.
  ///
  /// In en, this message translates to:
  /// **'One thing you learned today'**
  String get jp5;

  /// No description provided for @jp6.
  ///
  /// In en, this message translates to:
  /// **'Who made your day better?'**
  String get jp6;

  /// No description provided for @jp7.
  ///
  /// In en, this message translates to:
  /// **'What are you looking forward to?'**
  String get jp7;
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
