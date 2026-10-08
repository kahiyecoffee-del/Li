import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/config/app_config.dart';

/// Where a rewarded ad was offered (for analytics and A/B tests).
enum RewardPlacement {
  aiCredits,
  detailedScore,
  extraMeals,
  extraInsights,
  premiumPreview,
  streakRecovery,
  advancedAnalysis,
}

enum RewardOutcome { earned, dismissed, unavailable }

abstract class AdsService {
  Future<void> initialize({required bool personalized});
  bool get rewardedReady;
  Future<void> preloadRewarded();

  /// Shows a rewarded ad. [userId] is attached for AdMob server-side
  /// verification (SSV) so the backend can trust the reward.
  Future<RewardOutcome> showRewarded(RewardPlacement placement, {required String userId});
  Future<bool> showInterstitial();

  /// App-open ad (shown on launch/return, see [AdPolicy.canShowAppOpen]).
  Future<bool> showAppOpen();
}

/// AdMob implementation, with Google UMP consent (GDPR/CCPA) collected before
/// any ad request.
class AdMobAdsService implements AdsService {
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  AppOpenAd? _appOpen;
  DateTime? _appOpenLoadedAt;
  bool _canRequest = false;
  bool _personalized = true;
  bool _loadingRewarded = false;

  static String get _rewardedId => Platform.isIOS ? AppConfig.admobRewardedIos : AppConfig.admobRewardedAndroid;
  static String get _interstitialId =>
      Platform.isIOS ? AppConfig.admobInterstitialIos : AppConfig.admobInterstitialAndroid;
  static String get _appOpenId => Platform.isIOS ? AppConfig.admobAppOpenIos : AppConfig.admobAppOpenAndroid;
  static String get bannerId => Platform.isIOS ? AppConfig.admobBannerIos : AppConfig.admobBannerAndroid;
  static String get nativeId => Platform.isIOS ? AppConfig.admobNativeIos : AppConfig.admobNativeAndroid;

  AdRequest get _request => AdRequest(nonPersonalizedAds: !_personalized);

  @override
  Future<void> initialize({required bool personalized}) async {
    _personalized = personalized;
    await _gatherConsent();
    _canRequest = await ConsentInformation.instance.canRequestAds();
    if (!_canRequest) return;
    await MobileAds.instance.initialize();
    unawaited(preloadRewarded());
    unawaited(_loadInterstitial());
    unawaited(_loadAppOpen());
  }

  Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        if (!done.isCompleted) done.complete();
      },
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future.timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  @override
  bool get rewardedReady => _rewarded != null;

  @override
  Future<void> preloadRewarded() async {
    if (!_canRequest || _rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    final c = Completer<void>();
    await RewardedAd.load(
      adUnitId: _rewardedId,
      request: _request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
          c.complete();
        },
        onAdFailedToLoad: (e) {
          debugPrint('rewarded load failed: $e');
          _loadingRewarded = false;
          c.complete();
        },
      ),
    );
    return c.future;
  }

  @override
  Future<RewardOutcome> showRewarded(RewardPlacement placement, {required String userId}) async {
    if (_rewarded == null) await preloadRewarded();
    final ad = _rewarded;
    if (ad == null) return RewardOutcome.unavailable;
    _rewarded = null;
    await ad.setServerSideOptions(ServerSideVerificationOptions(userId: userId, customData: placement.name));
    var earned = false;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        if (!closed.isCompleted) closed.complete();
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    await closed.future;
    unawaited(preloadRewarded());
    return earned ? RewardOutcome.earned : RewardOutcome.dismissed;
  }

  @override
  Future<bool> showInterstitial() async {
    if (!_canRequest) return false;
    final ad = _interstitial;
    if (ad == null) {
      unawaited(_loadInterstitial());
      return false;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) => a.dispose(),
      onAdFailedToShowFullScreenContent: (a, _) => a.dispose(),
    );
    await ad.show();
    unawaited(_loadInterstitial());
    return true;
  }

  Future<void> _loadAppOpen() => AppOpenAd.load(
    adUnitId: _appOpenId,
    request: _request,
    adLoadCallback: AppOpenAdLoadCallback(
      onAdLoaded: (ad) {
        _appOpen = ad;
        _appOpenLoadedAt = DateTime.now();
      },
      onAdFailedToLoad: (_) {},
    ),
  );

  @override
  Future<bool> showAppOpen() async {
    if (!_canRequest) return false;
    final ad = _appOpen;
    // App-open ads expire after 4 hours.
    final fresh = _appOpenLoadedAt != null && DateTime.now().difference(_appOpenLoadedAt!) < const Duration(hours: 4);
    if (ad == null || !fresh) {
      if (ad != null) unawaited(ad.dispose());
      _appOpen = null;
      unawaited(_loadAppOpen());
      return false;
    }
    _appOpen = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        unawaited(_loadAppOpen());
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        unawaited(_loadAppOpen());
      },
    );
    await ad.show();
    return true;
  }

  Future<void> _loadInterstitial() => InterstitialAd.load(
    adUnitId: _interstitialId,
    request: _request,
    adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (ad) => _interstitial = ad, onAdFailedToLoad: (_) {}),
  );
}

/// No ads (premium users, unsupported platforms, tests).
class NoAdsService implements AdsService {
  const NoAdsService();

  @override
  Future<void> initialize({required bool personalized}) async {}

  @override
  bool get rewardedReady => false;

  @override
  Future<void> preloadRewarded() async {}

  @override
  Future<RewardOutcome> showRewarded(RewardPlacement placement, {required String userId}) async =>
      RewardOutcome.unavailable;

  @override
  Future<bool> showInterstitial() async => false;

  @override
  Future<bool> showAppOpen() async => false;
}
