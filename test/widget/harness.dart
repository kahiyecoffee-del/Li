import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/app.dart';
import 'package:lifeos/app/providers.dart';
import 'package:lifeos/app/services.dart';
import 'package:lifeos/data/local/database_opener.dart';
import 'package:lifeos/data/local/local_store.dart';
import 'package:lifeos/data/repositories/user_repos.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/data/repositories/journal_repository.dart';
import 'package:lifeos/domain/ai/ai_action_validator.dart';
import 'package:lifeos/domain/models/user_profile.dart';
import 'package:lifeos/services/ads/ads_service.dart';
import 'package:lifeos/services/ai/ai_models.dart';
import 'package:lifeos/services/ai/ai_service.dart';
import 'package:lifeos/services/analytics/analytics_service.dart';
import 'package:lifeos/services/auth/auth_service.dart';
import 'package:lifeos/services/billing/billing_service.dart';
import 'package:lifeos/services/config/remote_config_service.dart';
import 'package:lifeos/services/connectivity/connectivity_service.dart';
import 'package:lifeos/services/crash/crash_reporter.dart';
import 'package:lifeos/services/news/news_service.dart';
import 'package:lifeos/services/notifications/notification_service.dart';
import 'package:lifeos/services/ocr/ocr_service.dart';
import 'package:lifeos/services/weather/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeWeather implements WeatherProvider {
  @override
  Future<Weather> current(Place place) async => Weather(
    temperatureC: 21,
    condition: WeatherCondition.clear,
    rainProbability: 10,
    highC: 24,
    lowC: 14,
    fetchedAt: DateTime.now(),
    placeName: place.name,
  );

  @override
  Future<List<Place>> searchPlaces(String query, String language) async => [
    const Place(name: 'Istanbul, Türkiye', latitude: 41.01, longitude: 28.97),
  ];
}

class FakeOcr implements OcrService {
  @override
  Future<String> recognize(String imagePath) async => '';
}

/// Scripted assistant used by widget tests.
class FakeAi implements AiService {
  Map<String, dynamic> nextReply = {'reply': 'Hello!', 'credits': _credits};
  final requests = <AiChatRequest>[];

  static const _credits = {'used': 1, 'limit': 5, 'bonus': 0, 'premium': false, 'rewardedRemaining': 3};

  @override
  Future<AiChatResponse> chat(AiChatRequest request) async {
    requests.add(request);
    return const AiResponseParser(AiActionValidator()).parseChat(nextReply);
  }

  @override
  Future<AiTaskResponse> task(AiTaskType type, Map<String, dynamic> input) async =>
      AiTaskResponse(const {}, AiCredits.fromJson(_credits));

  @override
  Future<AiCredits> credits() async => AiCredits.fromJson(_credits);

  @override
  Future<AiCredits> grantAdReward(String placement) async => AiCredits.fromJson(_credits);
}

class FakeConnectivity implements ConnectivityService {
  FakeConnectivity(this.online);

  final bool online;

  @override
  Stream<bool> get onlineChanges => Stream.value(online);

  @override
  Future<bool> isOnline() async => online;
}

class TestApp {
  TestApp._(this.services, this.analytics, this.ai);

  final Services services;
  final MemoryAnalyticsService analytics;
  final FakeAi ai;
  LocalStore? seeded;

  /// A signed-in (local) user who already finished onboarding.
  static Future<TestApp> onboarded({
    Map<String, Object> prefs = const {},
    bool online = true,
  }) async {
    final app = await create(
      prefs: {'local_uid': 'local-test', ...prefs},
      online: online,
    );
    final store = await DatabaseOpener.inMemory('seed${DateTime.now().microsecondsSinceEpoch}');
    final repos = UserRepos(store, journalKeys: MemoryJournalKeyStore());
    await repos.profile.save(
      UserProfile(
        updatedAt: DateTime.now(),
        name: 'Eray',
        focusAreas: const {FocusArea.money, FocusArea.planning, FocusArea.health},
        currency: 'TRY',
        monthlyIncomeMinor: 4500000,
        fixedExpensesMinor: 1500000,
        savingsGoalMinor: 500000,
        onboardingCompleted: true,
        installedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    );
    app.seeded = store;
    return app;
  }

  static Future<TestApp> create({
    Map<String, Object> prefs = const {},
    bool online = true,
  }) async {
    SharedPreferences.setMockInitialValues({'showLio': false, ...prefs});
    final p = await SharedPreferences.getInstance();
    final analytics = MemoryAnalyticsService();
    final ai = FakeAi();
    final services = Services(
      prefs: p,
      auth: LocalAuthService(p),
      analytics: analytics,
      crash: DebugCrashReporter(),
      remote: DefaultRemoteValues(),
      connectivity: FakeConnectivity(online),
      ai: ai,
      ads: const NoAdsService(),
      billing: UnavailableBillingService(),
      notifications: NoopNotificationService(),
      weather: WeatherService(FakeWeather(), p),
      location: LocationService(),
      news: NewsService(UnavailableNewsProvider(), p),
      ocr: FakeOcr(),
      journalKeys: MemoryJournalKeyStore(),
    );
    return TestApp._(services, analytics, ai);
  }

  Widget widget() => ProviderScope(
    overrides: [
      servicesProvider.overrideWithValue(services),
      storeOpenerProvider.overrideWithValue((uid) async => seeded ?? await DatabaseOpener.inMemory(uid)),
    ],
    child: const LifeOsApp(),
  );
}

/// Pumps frames until [finder] matches or [maxSteps] × 100ms pass. Needed
/// because async DB work completes outside the fake-async frame clock.
Future<void> pumpUntil(WidgetTester tester, Finder finder, {int maxSteps = 60}) async {
  for (var i = 0; i < maxSteps; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      // Let page transitions/animations finish before interacting.
      await tester.pump(const Duration(milliseconds: 500));
      return;
    }
  }
  throw TestFailure('Timed out waiting for $finder');
}

/// Scrolls [finder] well clear of the floating tab bar, then taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
}

/// Phone-sized viewport (412×915 logical px).
void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1236, 2745);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Disposes the tree so debounce timers are cancelled before the test ends.
Future<void> tearDownApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}
