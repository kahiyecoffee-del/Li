import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../../services/ads/ad_policy.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/config/remote_config_service.dart';

/// Shows an interstitial only at a natural break and only if [AdPolicy]
/// allows it (frequency caps from Remote Config, never for Premium, never
/// in the first days). Disabled by default (`interstitial_frequency` = 0).
Future<void> maybeShowInterstitial(WidgetRef ref) async {
  final s = ref.read(servicesProvider);
  final prefs = s.prefs;
  final now = DateTime.now();
  final today = Dates.dayKey(now);
  final last = prefs.getInt('ad_i_last');
  final shownToday = prefs.getString('ad_i_day') == today ? (prefs.getInt('ad_i_count') ?? 0) : 0;
  final policy = AdPolicy(
    isPremium: ref.read(isPremiumProvider),
    minMinutesBetween: s.remote.getInt(RcKeys.interstitialFrequency),
    maxPerDay: s.remote.getInt(RcKeys.interstitialMaxPerDay),
  );
  final ok = policy.canShowInterstitial(
    moment: AdMoment.naturalBreak,
    now: now,
    lastShownAt: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
    shownToday: shownToday,
    installedAt: ref.read(profileProvider).value?.installedAt,
  );
  if (!ok) return;
  if (await s.ads.showInterstitial()) {
    await prefs.setInt('ad_i_last', now.millisecondsSinceEpoch);
    await prefs.setString('ad_i_day', today);
    await prefs.setInt('ad_i_count', shownToday + 1);
    unawaited(s.analytics.log(AnalyticsEvent.interstitialShown));
  }
}
