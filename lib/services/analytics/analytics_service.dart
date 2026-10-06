import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Canonical analytics events. Names are stable API for dashboards and
/// funnels: never rename, only add.
enum AnalyticsEvent {
  appOpen('app_open'),
  problemCreated('problem_created'),
  problemSolved('problem_solved'),
  decisionStarted('decision_started'),
  decisionCompleted('decision_completed'),
  recipeGenerated('recipe_generated'),
  savingCalculated('saving_calculated'),
  itemSaved('item_saved'),
  voiceInputUsed('voice_input_used'),
  photoInputUsed('photo_input_used'),
  onboardingStarted('onboarding_started'),
  onboardingStepCompleted('onboarding_step_completed'),
  onboardingCompleted('onboarding_completed'),
  dailyBriefViewed('daily_brief_viewed'),
  lifeScoreViewed('life_score_viewed'),
  lifeScoreCompleted('life_score_completed'),
  dailyGoalCompleted('daily_goal_completed'),
  aiMessageSent('ai_message_sent'),
  aiActionStarted('ai_action_started'),
  aiActionConfirmed('ai_action_confirmed'),
  aiActionDismissed('ai_action_dismissed'),
  aiLimitReached('ai_limit_reached'),
  expenseAdded('expense_added'),
  budgetCreated('budget_created'),
  taskCreated('task_created'),
  taskCompleted('task_completed'),
  planOptimized('plan_optimized'),
  habitCreated('habit_created'),
  habitCompleted('habit_completed'),
  moodLogged('mood_logged'),
  journalEntryAdded('journal_entry_added'),
  mealGenerated('meal_generated'),
  shoppingItemAdded('shopping_item_added'),
  receiptScanned('receipt_scanned'),
  weeklyReportViewed('weekly_report_viewed'),
  monthlyReportViewed('monthly_report_viewed'),
  rewardedAdStarted('rewarded_ad_started'),
  rewardedAdCompleted('rewarded_ad_completed'),
  interstitialShown('interstitial_shown'),
  paywallViewed('paywall_viewed'),
  subscriptionStarted('subscription_started'),
  subscriptionCancelled('subscription_cancelled'),
  experimentExposure('experiment_exposure'),
  retentionDay('retention_day'),
  dataExported('data_exported'),
  accountDeleted('account_deleted');

  const AnalyticsEvent(this.wire);

  final String wire;
}

/// User properties used to segment funnels and cohorts.
abstract final class UserProps {
  static const isPremium = 'is_premium';
  static const focusAreas = 'focus_areas';
  static const installWeek = 'install_week';
  static const authType = 'auth_type';
}

abstract class AnalyticsService {
  Future<void> log(AnalyticsEvent event, [Map<String, Object> params = const {}]);
  Future<void> setUserProperty(String name, String? value);
  Future<void> setUserId(String? id);

  /// Respects the user's analytics opt-out (Settings → Privacy).
  Future<void> setEnabled(bool enabled);
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._fa);

  final FirebaseAnalytics _fa;
  bool _enabled = true;

  @override
  Future<void> log(AnalyticsEvent event, [Map<String, Object> params = const {}]) async {
    if (!_enabled) return;
    try {
      await _fa.logEvent(name: event.wire, parameters: params.isEmpty ? null : params);
    } catch (e) {
      debugPrint('analytics: $e');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    if (!_enabled) return;
    await _fa.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> setUserId(String? id) => _fa.setUserId(id: id);

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _fa.setAnalyticsCollectionEnabled(enabled);
  }
}

/// Records events in memory (tests, and builds without Firebase).
class MemoryAnalyticsService implements AnalyticsService {
  final events = <(AnalyticsEvent, Map<String, Object>)>[];
  final props = <String, String?>{};
  bool enabled = true;

  @override
  Future<void> log(AnalyticsEvent event, [Map<String, Object> params = const {}]) async {
    if (enabled) events.add((event, params));
  }

  @override
  Future<void> setUserProperty(String name, String? value) async => props[name] = value;

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setEnabled(bool e) async => enabled = e;

  bool logged(AnalyticsEvent e) => events.any((x) => x.$1 == e);
}
