import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/services.dart';
import 'core/config/app_config.dart';
import 'data/repositories/journal_repository.dart';
import 'services/ads/ads_service.dart';
import 'services/ai/ai_service.dart';
import 'services/analytics/analytics_service.dart';
import 'services/auth/auth_service.dart';
import 'services/billing/billing_service.dart';
import 'services/config/remote_config_service.dart';
import 'services/connectivity/connectivity_service.dart';
import 'services/crash/crash_reporter.dart';
import 'services/news/news_service.dart';
import 'services/notifications/notification_service.dart';
import 'services/notifications/push_service.dart';
import 'services/ocr/ocr_mlkit.dart';
import 'services/voice/voice_input_service.dart';
import 'services/widget/home_widget_service.dart';
import 'services/weather/weather_service.dart';

/// FCM background handler must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification messages are displayed by the OS; nothing else to do.
}

/// Builds the service graph. If Firebase is not configured (no
/// google-services.json), the app runs in on-device mode: all core features
/// work locally; sync, AI, news and purchases report "unavailable".
Future<Services> buildServices() async {
  final prefs = await SharedPreferences.getInstance();
  // Local notifications are mobile-only; the web preview runs without them.
  final NotificationService notifications = kIsWeb ? NoopNotificationService() : LocalNotificationService();
  final connectivity = PlatformConnectivityService();
  final weather = WeatherService(OpenMeteoProvider(), prefs);
  final mobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  final ads = mobile ? AdMobAdsService() : const NoAdsService();

  var firebaseReady = false;
  // The web build is a preview without Firebase web config: skip it so the
  // page never waits on Firebase scripts.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      firebaseReady = true;
    } catch (e) {
      debugPrint('Firebase not configured, running on-device only: $e');
    }
  }

  if (!firebaseReady) {
    return Services(
      prefs: prefs,
      auth: LocalAuthService(prefs),
      analytics: MemoryAnalyticsService(),
      crash: DebugCrashReporter(),
      remote: DefaultRemoteValues(),
      connectivity: connectivity,
      ai: const UnavailableAiService(),
      ads: ads,
      billing: UnavailableBillingService(),
      notifications: notifications,
      weather: weather,
      location: LocationService(),
      news: NewsService(UnavailableNewsProvider(), prefs),
      ocr: MlKitOcrService(),
      voice: mobile ? DeviceVoiceInput() : const NoVoiceInput(),
      homeWidget: mobile ? DeviceHomeWidget() : const NoHomeWidget(),
      journalKeys: SecureJournalKeyStore(),
    );
  }

  // App Check: Play Integrity in release, debug provider in debug builds
  // (register the printed debug token in the Firebase console).
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode ? const AppleDebugProvider() : const AppleAppAttestProvider(),
  );

  final firestore = FirebaseFirestore.instance;
  // The app has its own offline store; Firestore's cache would duplicate it.
  firestore.settings = const Settings(persistenceEnabled: false);
  final functions = FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);
  final auth = FirebaseAuth.instance;

  if (AppConfig.useEmulators && kDebugMode) {
    firestore.useFirestoreEmulator(AppConfig.emulatorHost, 8080);
    functions.useFunctionsEmulator(AppConfig.emulatorHost, 5001);
    await auth.useAuthEmulator(AppConfig.emulatorHost, 9099);
  }

  final remote = FirebaseRemoteValues(FirebaseRemoteConfig.instance);
  await remote.init(debug: kDebugMode);

  final crash = CrashlyticsReporter(FirebaseCrashlytics.instance);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  return Services(
    prefs: prefs,
    auth: FirebaseAuthService(auth),
    analytics: FirebaseAnalyticsService(FirebaseAnalytics.instance),
    crash: crash,
    remote: remote,
    connectivity: connectivity,
    ai: CloudAiService(functions, timeZone: notifications.timeZoneName),
    ads: ads,
    billing: mobile ? PlayBillingService(InAppPurchase.instance, functions) : UnavailableBillingService(),
    notifications: notifications,
    weather: weather,
    location: LocationService(),
    news: NewsService(BackendNewsProvider(functions), prefs),
    ocr: MlKitOcrService(),
    voice: mobile ? DeviceVoiceInput() : const NoVoiceInput(),
    homeWidget: mobile ? DeviceHomeWidget() : const NoHomeWidget(),
    journalKeys: SecureJournalKeyStore(),
    firestore: firestore,
    functions: functions,
    push: PushService(
      FirebaseMessaging.instance,
      firestore,
      onForegroundMessage: (m) async {
        if (notifications is LocalNotificationService) await notifications.showRemote(m);
      },
    ),
  );
}

/// Routes uncaught errors to the crash reporter. UI never shows raw errors.
void installErrorHandlers(CrashReporter crash) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(crash.recordError(details.exception, details.stack, fatal: true, reason: 'flutter'));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(crash.recordError(error, stack, fatal: true, reason: 'platform'));
    return true;
  };
}
