/// Screens / moments in which an ad could appear.
enum AdMoment {
  /// Natural break points after a finished flow (e.g. leaving a report).
  naturalBreak,

  /// The user is entering money, filling a form, or confirming an action.
  criticalFlow,

  /// While an AI answer is streaming or awaiting confirmation.
  aiConversation,
  onboarding,
}

/// Pure decision logic for non-rewarded (interstitial) ads. Rewarded ads are
/// always user-initiated and never governed by frequency caps here.
class AdPolicy {
  const AdPolicy({required this.isPremium, required this.minMinutesBetween, required this.maxPerDay});

  final bool isPremium;

  /// From Remote Config `interstitial_frequency`; 0 disables interstitials.
  final int minMinutesBetween;
  final int maxPerDay;

  bool canShowInterstitial({
    required AdMoment moment,
    required DateTime now,
    required DateTime? lastShownAt,
    required int shownToday,
    required DateTime? installedAt,
  }) {
    if (isPremium || minMinutesBetween <= 0) return false;
    if (moment != AdMoment.naturalBreak) return false;
    if (shownToday >= maxPerDay) return false;
    // No interstitials in the first 3 days: let users find value first.
    if (installedAt == null || now.difference(installedAt) < const Duration(days: 3)) return false;
    if (lastShownAt != null && now.difference(lastShownAt) < Duration(minutes: minMinutesBetween)) return false;
    return true;
  }

  /// App-open ads: never for Premium or in the first 2 days, never before
  /// onboarding is done, and at most once every [minHours].
  bool canShowAppOpen({
    required bool remoteEnabled,
    required DateTime now,
    required DateTime? lastShownAt,
    required DateTime? installedAt,
    required bool onboarded,
    int minHours = 4,
  }) {
    if (isPremium || !remoteEnabled || !onboarded) return false;
    if (installedAt == null || now.difference(installedAt) < const Duration(days: 2)) return false;
    if (lastShownAt != null && now.difference(lastShownAt) < Duration(hours: minHours)) return false;
    return true;
  }

  bool canShowBanner({required bool remoteEnabled, required AdMoment moment}) =>
      !isPremium && remoteEnabled && moment == AdMoment.naturalBreak;
}
