import 'remote_config_service.dart';

/// Remotely togglable features.
enum Feature {
  news('news'),
  receiptOcr('receipt_ocr'),
  weeklyReport('weekly_report'),
  monthlyReport('monthly_report'),
  pantry('pantry');

  const Feature(this.key);

  final String key;
}

/// Capabilities that may be restricted to Premium. Which ones actually are is
/// controlled remotely by `premium_features`.
enum PremiumFeature {
  unlimitedAi('unlimited_ai'),
  advancedScore('advanced_score'),
  advancedAnalytics('advanced_analytics'),
  noAds('no_ads'),
  advancedPlanning('advanced_planning'),
  advancedFinance('advanced_finance'),
  unlimitedMeals('unlimited_meals'),
  aiMemoryUnlimited('ai_memory_unlimited'),
  monthlyReport('monthly_report');

  const PremiumFeature(this.key);

  final String key;
}

class FeatureFlags {
  const FeatureFlags(this._rc);

  final RemoteValues _rc;

  bool isEnabled(Feature f) {
    final v = _rc.json(RcKeys.featureFlags)[f.key];
    return v is bool ? v : true;
  }

  /// Whether [f] currently requires Premium.
  bool isPremiumOnly(PremiumFeature f) => _rc.stringList(RcKeys.premiumFeatures).contains(f.key);
}

/// Experiments run through Firebase A/B Testing, which assigns users to
/// Remote Config variants. The app only reads the assigned variant and logs an
/// exposure event — there is no client-side randomization.
enum Experiment {
  // Short by default: long set-up before any value is a top reason people
  // leave in the first minutes.
  onboarding('onboarding', ['control', 'short'], fallback: 'short'),
  homeLayout('home_layout', ['control', 'compact']),
  rewardedPlacement('rewarded_placement', ['control', 'inline']),
  paywall('paywall', ['control', 'annual_first']),
  notifications('notifications', ['control', 'evening']);

  const Experiment(this.key, this.variants, {this.fallback = 'control'});

  final String key;
  final List<String> variants;

  /// The variant when Remote Config assigns none.
  final String fallback;
}

class Experiments {
  Experiments(this._rc, this._onExposure);

  final RemoteValues _rc;
  final void Function(Experiment, String variant) _onExposure;
  final _exposed = <Experiment>{};

  /// Variant for [e]; unknown values fall back to [Experiment.fallback].
  String variant(Experiment e) {
    final raw = _rc.json(RcKeys.experiments)[e.key];
    final v = raw is String && e.variants.contains(raw) ? raw : e.fallback;
    if (_exposed.add(e)) _onExposure(e, v);
    return v;
  }
}
