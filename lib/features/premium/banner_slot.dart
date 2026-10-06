import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/providers.dart';
import '../../services/ads/ad_policy.dart';
import '../../services/ads/ads_service.dart';
import '../../services/config/remote_config_service.dart';

/// Optional banner for non-critical browsing screens only (Life hub,
/// reports). Hidden for Premium and unless Remote Config `banner_enabled`.
class BannerSlot extends ConsumerStatefulWidget {
  const BannerSlot({super.key});

  @override
  ConsumerState<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends ConsumerState<BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  bool get _allowed {
    final s = ref.read(servicesProvider);
    if (s.ads is! AdMobAdsService) return false;
    final policy = AdPolicy(
      isPremium: ref.read(isPremiumProvider),
      minMinutesBetween: s.remote.getInt(RcKeys.interstitialFrequency),
      maxPerDay: s.remote.getInt(RcKeys.interstitialMaxPerDay),
    );
    return policy.canShowBanner(remoteEnabled: s.remote.getBool(RcKeys.bannerEnabled), moment: AdMoment.naturalBreak);
  }

  @override
  void initState() {
    super.initState();
    if (!_allowed) return;
    _ad = BannerAd(
      adUnitId: AdMobAdsService.bannerId,
      size: AdSize.banner,
      request: AdRequest(nonPersonalizedAds: !ref.read(settingsProvider).personalizedAds),
      listener: BannerAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(isPremiumProvider);
    if (premium || !_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
