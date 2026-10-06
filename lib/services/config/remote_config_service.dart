import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Remote Config keys. Every monetization and limit value is remote-controlled
/// so it can change without an app update. The same keys and defaults are
/// read by Cloud Functions (functions/src/config/serverConfig.ts) so client
/// display and server enforcement agree.
abstract final class RcKeys {
  static const dailyFreeAiLimit = 'daily_free_ai_limit';
  static const rewardedAiLimit = 'rewarded_ai_limit';
  static const rewardedCreditsPerAd = 'rewarded_credits_per_ad';
  static const interstitialFrequency = 'interstitial_frequency';
  static const interstitialMaxPerDay = 'interstitial_max_per_day';
  static const bannerEnabled = 'banner_enabled';
  static const premiumPrice = 'premium_price';
  static const notificationFrequency = 'notification_frequency';
  static const notificationDailyCap = 'notification_daily_cap';
  static const freeMemoryLimit = 'free_memory_limit';
  static const featureFlags = 'feature_flags';
  static const premiumFeatures = 'premium_features';
  static const experiments = 'experiments';
}

/// Typed defaults (also used offline and when Firebase is not configured).
const Map<String, Object> remoteDefaults = {
  RcKeys.dailyFreeAiLimit: 5,
  RcKeys.rewardedAiLimit: 3,
  RcKeys.rewardedCreditsPerAd: 2,
  // Minimum minutes between interstitials; 0 disables interstitials.
  RcKeys.interstitialFrequency: 0,
  RcKeys.interstitialMaxPerDay: 2,
  RcKeys.bannerEnabled: false,
  // Which paywall price point / product set to show: "default" | "discount".
  RcKeys.premiumPrice: 'default',
  RcKeys.notificationFrequency: 'normal',
  RcKeys.notificationDailyCap: 3,
  RcKeys.freeMemoryLimit: 10,
  RcKeys.featureFlags: '{"news":true,"receipt_ocr":true,"weekly_report":true,"monthly_report":true,"pantry":true}',
  RcKeys.premiumFeatures: '["unlimited_ai","advanced_score","advanced_analytics","no_ads","advanced_planning","advanced_finance","unlimited_meals","ai_memory_unlimited","monthly_report"]',
  RcKeys.experiments: '{}',
};

/// Read-only view of remote values.
abstract class RemoteValues {
  int getInt(String key);
  bool getBool(String key);
  String getString(String key);

  /// Emits whenever values change (after fetch/activate or realtime update).
  Stream<void> get changes;

  Map<String, Object?> json(String key) {
    try {
      final v = jsonDecode(getString(key));
      return v is Map ? v.map((k, v) => MapEntry('$k', v)) : const {};
    } on FormatException {
      return const {};
    }
  }

  List<String> stringList(String key) {
    try {
      final v = jsonDecode(getString(key));
      return v is List ? v.whereType<String>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }
}

/// Defaults-only implementation (offline / no Firebase / tests).
class DefaultRemoteValues extends RemoteValues {
  DefaultRemoteValues([Map<String, Object> overrides = const {}]) : _values = {...remoteDefaults, ...overrides};

  final Map<String, Object> _values;

  @override
  int getInt(String key) => (_values[key] as num?)?.toInt() ?? 0;

  @override
  bool getBool(String key) => _values[key] == true;

  @override
  String getString(String key) => '${_values[key] ?? ''}';

  @override
  Stream<void> get changes => const Stream.empty();
}

class FirebaseRemoteValues extends RemoteValues {
  FirebaseRemoteValues(this._rc);

  final FirebaseRemoteConfig _rc;
  final _changes = StreamController<void>.broadcast();
  StreamSubscription<RemoteConfigUpdate>? _sub;

  Future<void> init({bool debug = false}) async {
    await _rc.setDefaults(remoteDefaults);
    await _rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: debug ? const Duration(minutes: 1) : const Duration(hours: 6),
      ),
    );
    // Activate cached values immediately; fetch in the background so app
    // start is never blocked on the network.
    await _rc.activate();
    unawaited(_rc.fetchAndActivate().then((_) => _changes.add(null)).catchError((Object _) {}));
    _sub = _rc.onConfigUpdated.listen((_) async {
      await _rc.activate();
      _changes.add(null);
    }, onError: (Object _) {});
  }

  @override
  int getInt(String key) => _rc.getInt(key);

  @override
  bool getBool(String key) => _rc.getBool(key);

  @override
  String getString(String key) => _rc.getString(key);

  @override
  Stream<void> get changes => _changes.stream;

  Future<void> dispose() async {
    await _sub?.cancel();
    await _changes.close();
  }
}
