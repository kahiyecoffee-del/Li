import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../services/ads/ads_service.dart';
import '../../services/config/remote_config_service.dart';

/// A native ad styled like a list row, for browse lists only (recipes,
/// news). Never for Premium, never when Remote Config turns it off, and it
/// takes no space until an ad has loaded.
class NativeSlot extends ConsumerStatefulWidget {
  const NativeSlot({super.key});

  /// Whether list position [i] (0-based) should be followed by an ad.
  static bool after(WidgetRef ref, int i) {
    final every = ref.read(servicesProvider).remote.getInt(RcKeys.nativeEvery);
    return every > 0 && (i + 1) % every == 0;
  }

  @override
  ConsumerState<NativeSlot> createState() => _NativeSlotState();
}

class _NativeSlotState extends ConsumerState<NativeSlot> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(servicesProvider);
    if (s.ads is! AdMobAdsService || ref.read(isPremiumProvider) || !s.remote.getBool(RcKeys.nativeEnabled)) return;
    _ad = NativeAd(
      adUnitId: AdMobAdsService.nativeId,
      request: AdRequest(nonPersonalizedAds: !ref.read(settingsProvider).personalizedAds),
      listener: NativeAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
      nativeTemplateStyle: NativeTemplateStyle(templateType: TemplateType.small, cornerRadius: Radii.md),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(isPremiumProvider) || !_loaded || _ad == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 90, maxHeight: 120),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
