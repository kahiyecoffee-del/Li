import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/journal_repository.dart';
import '../services/ads/ads_service.dart';
import '../services/ai/ai_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/auth/auth_service.dart';
import '../services/billing/billing_service.dart';
import '../services/config/feature_flags.dart';
import '../services/config/remote_config_service.dart';
import '../services/connectivity/connectivity_service.dart';
import '../services/crash/crash_reporter.dart';
import '../services/news/news_service.dart';
import '../services/notifications/notification_service.dart';
import '../services/notifications/push_service.dart';
import '../services/ocr/ocr_service.dart';
import '../services/voice/voice_input_service.dart';
import '../services/weather/weather_service.dart';
import '../services/widget/home_widget_service.dart';

/// App-wide service graph, built once in `bootstrap()` and injected through
/// Riverpod (`servicesProvider`). Tests build it with fakes.
class Services {
  Services({
    required this.prefs,
    required this.auth,
    required this.analytics,
    required this.crash,
    required this.remote,
    required this.connectivity,
    required this.ai,
    required this.ads,
    required this.billing,
    required this.notifications,
    required this.weather,
    required this.location,
    required this.news,
    required this.ocr,
    required this.journalKeys,
    this.firestore,
    this.functions,
    this.push,
    this.voice = const NoVoiceInput(),
    this.homeWidget = const NoHomeWidget(),
  }) : flags = FeatureFlags(remote);

  final SharedPreferences prefs;
  final AuthService auth;
  final AnalyticsService analytics;
  final CrashReporter crash;
  final RemoteValues remote;
  final FeatureFlags flags;
  final ConnectivityService connectivity;
  final AiService ai;
  final AdsService ads;
  final BillingService billing;
  final NotificationService notifications;
  final WeatherService weather;
  final LocationService location;
  final NewsService news;
  final OcrService ocr;
  final JournalKeyStore journalKeys;
  final VoiceInputService voice;

  /// Today's program on the home screen (iOS/Android only).
  final HomeWidgetService homeWidget;

  /// Null in local-only mode (Firebase not configured).
  final FirebaseFirestore? firestore;
  final FirebaseFunctions? functions;
  final PushService? push;

  bool get cloudEnabled => firestore != null;

  /// The assistant needs a configured backend (Cloud Functions).
  bool get aiEnabled => ai is! UnavailableAiService;
}
