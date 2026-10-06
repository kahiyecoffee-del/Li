/// Build-time configuration passed with `--dart-define` (or
/// `--dart-define-from-file=env/prod.json`). No secrets live here: AI and
/// news API keys are only stored server-side as Cloud Functions secrets.
abstract final class AppConfig {
  /// Region of the deployed Cloud Functions.
  static const functionsRegion = String.fromEnvironment('FUNCTIONS_REGION', defaultValue: 'us-central1');

  /// Use the local Firebase Emulator Suite (debug only).
  static const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static const emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');

  /// AdMob ad unit ids. Defaults are Google's official TEST ids, which never
  /// generate revenue — replace them for release builds.
  static const admobRewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const admobRewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );
  static const admobInterstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const admobInterstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );
  static const admobBannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/9214589741',
  );
  static const admobBannerIos = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/2435281174',
  );

  /// Google Play subscription product ids (created in Play Console).
  static const premiumMonthlyProductId = String.fromEnvironment(
    'PREMIUM_MONTHLY_ID',
    defaultValue: 'dayly_premium_monthly',
  );
  static const premiumYearlyProductId = String.fromEnvironment(
    'PREMIUM_YEARLY_ID',
    defaultValue: 'dayly_premium_yearly',
  );

  /// Web client id (OAuth) used by Google Sign-In to mint Firebase ID tokens.
  /// Found in Firebase console → Authentication → Google → Web SDK config.
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Shown in Settings → About (set from CI: --dart-define=APP_VERSION=…).
  static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  /// Android application id (used for the Play subscription management link).
  static const androidPackage = String.fromEnvironment('ANDROID_PACKAGE', defaultValue: 'com.dayly.app');

  /// Public URLs shown in Settings and the Play listing.
  static const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
  static const termsUrl = String.fromEnvironment('TERMS_URL');
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
}
