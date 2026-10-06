import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/labels.dart';
import '../core/utils/dates.dart';
import '../domain/models/progress.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/analytics/analytics_service.dart';
import '../services/config/feature_flags.dart';
import '../services/config/remote_config_service.dart';
import '../services/notifications/notification_planner.dart';
import 'derived_providers.dart';
import 'providers.dart';

/// App-wide side effects that react to state:
/// * persist today's Life Score snapshot (history, reports, badges);
/// * record newly earned achievements;
/// * re-plan local notifications when relevant data changes;
/// * register for push, initialise ads, log app_open and retention days;
/// * trigger sync when the app returns to the foreground.
class AppEffects extends ConsumerStatefulWidget {
  const AppEffects({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppEffects> createState() => _AppEffectsState();
}

class _AppEffectsState extends ConsumerState<AppEffects> with WidgetsBindingObserver {
  Timer? _scoreDebounce;
  Timer? _notifDebounce;
  String? _sessionUid;
  bool _adsInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final s = ref.read(servicesProvider);
    unawaited(s.analytics.log(AnalyticsEvent.appOpen));
    unawaited(s.notifications.initialize());
    ref.listenManual(
      sessionProvider.select((s) => s.value?.user.uid),
      (_, uid) => _onSession(uid),
      fireImmediately: true,
    );
    ref.listenManual(isPremiumProvider, (_, premium) {
      _initAds(premium);
      unawaited(ref.read(servicesProvider).analytics.setUserProperty(UserProps.isPremium, '$premium'));
    }, fireImmediately: true);
    ref.listenManual(profileProvider.select((p) => p.value?.onboardingCompleted), (_, done) {
      if (done == true) _logRetention();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scoreDebounce?.cancel();
    _notifDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(sessionProvider).value?.sync?.scheduleSync(const Duration(seconds: 1));
      _scheduleNotifications();
    }
  }

  void _onSession(String? uid) {
    if (uid == _sessionUid) return;
    final services = ref.read(servicesProvider);
    final prev = _sessionUid;
    _sessionUid = uid;
    if (prev != null) unawaited(services.push?.unregister(prev));
    if (uid == null) return;
    final session = ref.read(sessionProvider).value;
    if (session != null && !session.user.isLocalOnly) {
      unawaited(() async {
        final locale = ref.read(settingsProvider).localeCode ?? PlatformDispatcher.instance.locale.languageCode;
        await services.push?.register(uid, locale: locale, timeZone: await services.notifications.timeZoneName());
      }());
    }
    unawaited(services.analytics.setUserProperty(UserProps.authType, session?.user.provider.name));
  }

  void _initAds(bool premium) {
    if (_adsInitialized || premium) return;
    _adsInitialized = true;
    unawaited(ref.read(servicesProvider).ads.initialize(personalized: ref.read(settingsProvider).personalizedAds));
  }

  Future<void> _persistScore(TodayScore s) async {
    try {
      final total = s.score.total;
      if (total == null || ref.read(sessionProvider).value == null) return;
      final repos = ref.read(reposProvider);
      final key = Dates.dayKey(ref.read(todayProvider));
      final components = {for (final e in s.score.components.entries) e.key.name: e.value};
      final existing = await repos.scores.get(key);
      if (existing != null && existing.total == total && _sameMap(existing.components, components)) return;
      await repos.scores.save(
        DailyScoreRecord(id: key, updatedAt: DateTime.now(), total: total, components: components),
      );
      if (existing == null) {
        unawaited(ref.read(servicesProvider).analytics.log(AnalyticsEvent.lifeScoreCompleted, {'score': total}));
      }
    } catch (_) {
      // Signed out (store closed) while saving: nothing left to update.
      if (mounted) rethrow;
    }
  }

  static bool _sameMap(Map<String, int> a, Map<String, int> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  Future<void> _recordBadges() async {
    if (ref.read(sessionProvider).value == null) return;
    final earned = ref.read(earnedBadgesProvider);
    final have = (ref.read(achievementsProvider).list).map((a) => a.id).toSet();
    if (!ref.read(achievementsProvider).hasValue) return;
    final repos = ref.read(reposProvider);
    for (final b in earned.where((b) => !have.contains(b.name))) {
      await repos.achievements.save(
        AchievementRecord(id: b.name, updatedAt: DateTime.now(), unlockedAt: DateTime.now()),
      );
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l.badgeUnlocked(l.badge(b).$1))));
    }
  }

  void _scheduleNotifications() {
    _notifDebounce?.cancel();
    _notifDebounce = Timer(const Duration(seconds: 3), () async {
      if (!mounted || ref.read(sessionProvider).value == null) return;
      final services = ref.read(servicesProvider);
      final settings = ref.read(settingsProvider);
      final profile = ref.read(profileProvider).value;
      final now = DateTime.now();
      final today = Dates.dayKey(now);
      final streak = ref.read(streakProvider);
      final budget = ref.read(budgetSnapshotProvider);
      final plan = const NotificationPlanner().plan(
        NotificationState(
          now: now,
          frequency: settings.notificationFrequency,
          dailyCap: services.remote.getInt(RcKeys.notificationDailyCap),
          upcomingTasks: ref.read(tasksProvider).list,
          hasBudget: budget != null,
          loggedSpendingToday: (ref.read(transactionsProvider).list).any((t) => Dates.dayKey(t.date) == today),
          budgetTight: budget?.isTight ?? false,
          currentStreak: streak.current,
          activeToday: ref.read(activeDaysProvider).contains(today),
          moodLoggedToday: (ref.read(moodsProvider).list).any((m) => m.day == today),
          weeklyReportEnabled: services.flags.isEnabled(Feature.weeklyReport),
          quietEnd: profile?.wakeTime ?? defaultQuietEnd,
          quietStart: profile?.sleepTime ?? defaultQuietStart,
        ),
      );
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      await services.notifications.apply(plan, (n) => l.notification(n, streak: streak.current));
    });
  }

  void _logRetention() {
    final profile = ref.read(profileProvider).value;
    final installed = profile?.installedAt;
    if (installed == null) return;
    final prefs = ref.read(servicesProvider).prefs;
    final today = Dates.dayKey(DateTime.now());
    if (prefs.getString('retention_logged') == today) return;
    unawaited(prefs.setString('retention_logged', today));
    final day = Dates.daysBetween(installed, DateTime.now());
    final analytics = ref.read(servicesProvider).analytics;
    unawaited(
      analytics.log(AnalyticsEvent.retentionDay, {
        'day': day,
        if (const {1, 3, 7, 14, 30}.contains(day)) 'milestone': 'd$day',
      }),
    );
    final week = Dates.dayKey(Dates.startOfWeek(installed));
    unawaited(analytics.setUserProperty(UserProps.installWeek, week));
    unawaited(analytics.setUserProperty(UserProps.focusAreas, profile!.focusAreas.map((f) => f.name).join(',')));
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(sessionProvider).value != null) {
      ref.listen(lifeScoreProvider, (_, s) {
        _scoreDebounce?.cancel();
        _scoreDebounce = Timer(const Duration(seconds: 2), () => unawaited(_persistScore(s)));
      });
      ref.listen(earnedBadgesProvider, (_, _) => unawaited(_recordBadges()));
      ref.listen(tasksProvider, (_, _) => _scheduleNotifications());
      ref.listen(moodsProvider, (_, _) => _scheduleNotifications());
      ref.listen(transactionsProvider, (_, _) => _scheduleNotifications());
      ref.listen(settingsProvider.select((s) => s.notificationFrequency), (_, _) => _scheduleNotifications());
    }
    return widget.child;
  }
}
