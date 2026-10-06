import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/widgets/common.dart';
import '../../services/ads/ads_service.dart';
import '../../services/analytics/analytics_service.dart';

/// Shows a rewarded ad on explicit user request. Returns true if the reward
/// was earned. For AI credits the reward is granted by the backend (capped
/// per day), never by the client alone.
Future<bool> watchRewardedAd(BuildContext context, WidgetRef ref, RewardPlacement placement) async {
  final services = ref.read(servicesProvider);
  final uid = ref.read(sessionProvider).value?.user.uid;
  if (uid == null) return false;
  final l = context.l10n;
  unawaited(services.analytics.log(AnalyticsEvent.rewardedAdStarted, {'placement': placement.name}));
  final outcome = await services.ads.showRewarded(placement, userId: uid);
  if (!context.mounted) return false;
  switch (outcome) {
    case RewardOutcome.unavailable:
      showSnack(context, l.aiRewardUnavailable);
      return false;
    case RewardOutcome.dismissed:
      return false;
    case RewardOutcome.earned:
      unawaited(services.analytics.log(AnalyticsEvent.rewardedAdCompleted, {'placement': placement.name}));
      if (placement == RewardPlacement.aiCredits) {
        try {
          ref.read(creditsProvider.notifier).set(await services.ai.grantAdReward(placement.name));
        } catch (e) {
          if (context.mounted) showSnack(context, l.failure(e));
          return false;
        }
      }
      if (context.mounted) showSnack(context, l.aiRewardEarned);
      return true;
  }
}

/// Per-day unlocks earned through rewarded ads (e.g. today's detailed score).
class RewardUnlocks {
  RewardUnlocks(this._ref);

  final Ref _ref;

  String _key(RewardPlacement p) {
    final d = _ref.read(todayProvider);
    return 'unlock_${p.name}_${d.year}${d.month}${d.day}';
  }

  bool isUnlocked(RewardPlacement p) => _ref.read(servicesProvider).prefs.getBool(_key(p)) ?? false;

  Future<void> unlock(RewardPlacement p) => _ref.read(servicesProvider).prefs.setBool(_key(p), true);
}

final rewardUnlocksProvider = Provider<RewardUnlocks>(RewardUnlocks.new);
