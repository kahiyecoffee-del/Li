import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/l10n/labels.dart';
import '../core/utils/dates.dart';
import '../core/widgets/formatters.dart';
import '../domain/models/progress.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/ads/ad_policy.dart';
import '../services/analytics/analytics_service.dart';
import '../services/config/feature_flags.dart';
import '../services/config/remote_config_service.dart';
import '../services/notifications/notification_planner.dart';
import '../services/widget/home_widget_service.dart';
import '../features/lio/garden.dart';
import 'actions.dart';
import 'derived_providers.dart';
import 'providers.dart';
import 'router.dart';

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
  Timer? _widgetDebounce;
  StreamSubscription<String>? _widgetTaps;
  StreamSubscription<String>? _doneTasks;
  String? _sessionUid;
  bool _adsInitialized = false;
  StreamSubscription<String>? _taps;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final s = ref.read(servicesProvider);
    unawaited(s.analytics.log(AnalyticsEvent.appOpen));
    unawaited(s.notifications.initialize());
    // Tapping a reminder opens the right screen (plan with Lio, journal…).
    _taps = s.notifications.taps.listen((route) {
      final r = route.contains('topic=') ? '$route&n=${DateTime.now().microsecondsSinceEpoch}' : route;
      ref.read(routerProvider).go(r);
    });
    // "Done" on a task reminder ticks the task off.
    _doneTasks = s.notifications.doneTasks.listen((id) async {
      final t = ref.read(tasksProvider).list.where((t) => t.id == id && !t.isCompleted).firstOrNull;
      if (t != null) await ref.read(actionsProvider).toggleTask(t);
    });
    // Tapping the home-screen widget opens the plan (or Lio to make one).
    _widgetTaps = s.homeWidget.taps.listen((route) {
      final r = route.contains('topic=') ? '$route&n=${DateTime.now().microsecondsSinceEpoch}' : route;
      ref.read(routerProvider).go(r);
    });
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
    _widgetDebounce?.cancel();
    unawaited(_taps?.cancel());
    unawaited(_widgetTaps?.cancel());
    unawaited(_doneTasks?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _pausedAt = DateTime.now();
    if (state == AppLifecycleState.resumed) {
      ref.read(sessionProvider).value?.sync?.scheduleSync(const Duration(seconds: 1));
      _scheduleNotifications();
      _updateHomeWidget();
      // Coming back after a real break (not a quick app switch).
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      if (away > const Duration(seconds: 30)) unawaited(_maybeAppOpenAd());
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
    unawaited(() async {
      await ref.read(servicesProvider).ads.initialize(personalized: ref.read(settingsProvider).personalizedAds);
      // Give the first app-open ad a moment to load on a cold start.
      await Future<void>.delayed(const Duration(seconds: 3));
      if (mounted) await _maybeAppOpenAd();
    }());
  }

  /// App-open ad, measured: see [AdPolicy.canShowAppOpen].
  Future<void> _maybeAppOpenAd() async {
    final s = ref.read(servicesProvider);
    final profile = ref.read(profileProvider).value;
    final last = s.prefs.getInt('ad_ao_last');
    final ok =
        AdPolicy(
          isPremium: ref.read(isPremiumProvider),
          minMinutesBetween: s.remote.getInt(RcKeys.interstitialFrequency),
          maxPerDay: s.remote.getInt(RcKeys.interstitialMaxPerDay),
        ).canShowAppOpen(
          remoteEnabled: s.remote.getBool(RcKeys.appOpenEnabled),
          now: DateTime.now(),
          lastShownAt: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
          installedAt: profile?.installedAt,
          onboarded: profile?.onboardingCompleted ?? false,
          minHours: s.remote.getInt(RcKeys.appOpenMinHours),
        );
    if (!ok) return;
    if (await s.ads.showAppOpen()) {
      await s.prefs.setInt('ad_ao_last', DateTime.now().millisecondsSinceEpoch);
      unawaited(s.analytics.log(AnalyticsEvent.interstitialShown, {'format': 'app_open'}));
    }
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
          bills: ref.read(billsProvider).list,
          hasBudget: budget != null,
          loggedSpendingToday: (ref.read(transactionsProvider).list).any((t) => Dates.dayKey(t.date) == today),
          budgetTight: budget?.isTight ?? false,
          currentStreak: streak.current,
          activeToday: ref.read(activeDaysProvider).contains(today),
          moodLoggedToday: (ref.read(moodsProvider).list).any((m) => m.day == today),
          weeklyReportEnabled: services.flags.isEnabled(Feature.weeklyReport),
          hasPlanToday: ref
              .read(tasksProvider)
              .list
              .any((t) => !t.deleted && t.anchorDate != null && Dates.dayKey(t.anchorDate!) == today),
          journaledToday: ref.read(journalProvider).list.any((e) => Dates.dayKey(e.createdAt) == today),
          journalReminder: settings.journalReminder,
          planReminder: settings.planReminder,
          gardenBackAt: ref.read(gardenProvider.notifier).backAt,
          spendToday: budget == null || budget.overToday
              ? null
              : ref
                    .read(fmtProvider(Localizations.localeOf(context).toLanguageTag()))
                    .money(budget.remainingTodayMinor),
          quietEnd: profile?.wakeTime ?? defaultQuietEnd,
          quietStart: profile?.sleepTime ?? defaultQuietStart,
        ),
      );
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      await services.notifications.apply(plan, (n) => l.notification(n, streak: streak.current));
    });
  }

  /// Pushes today's program to the home-screen widget.
  void _updateHomeWidget() {
    _widgetDebounce?.cancel();
    _widgetDebounce = Timer(const Duration(seconds: 1), () async {
      if (!mounted || ref.read(sessionProvider).value == null) return;
      final now = DateTime.now();
      final tasks = ref.read(tasksProvider).list;
      final program = todaysProgram(tasks, now);
      final doneToday = tasks.any(
        (t) => !t.deleted && t.completedAt != null && Dates.dayKey(t.completedAt!) == Dates.dayKey(now),
      );
      final l = AppLocalizations.of(context);
      final locale = Localizations.localeOf(context).toString();
      await ref
          .read(servicesProvider)
          .homeWidget
          .update(
            TodayWidgetData(
              day: Dates.dayKey(now),
              title: l.widgetToday(DateFormat.MMMd(locale).format(now)),
              lines: programLines(program, now),
              summary: program.isNotEmpty
                  ? l.widgetLeft(program.length)
                  : (doneToday ? l.widgetAllDone : l.widgetEmpty),
              staleHint: l.widgetStale,
              route: program.isEmpty && !doneToday ? '/ai?topic=plan' : Routes.plan,
              mood: widgetMood(left: program.length, doneToday: doneToday, now: now),
              nextId: program.isEmpty ? null : program.first.id,
              doneLabel: program.isEmpty ? null : l.widgetDone(program.first.title),
            ),
          );
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
      ref.listen(tasksProvider, (_, _) {
        _scheduleNotifications();
        _updateHomeWidget();
      });
      ref.listen(moodsProvider, (_, _) => _scheduleNotifications());
      ref.listen(transactionsProvider, (_, _) => _scheduleNotifications());
      ref.listen(settingsProvider.select((s) => s.notificationFrequency), (_, _) => _scheduleNotifications());
      ref.listen(journalProvider, (_, _) => _scheduleNotifications());
      ref.listen(billsProvider, (_, _) => _scheduleNotifications());
      ref.listen(
        settingsProvider.select((s) => (s.journalReminder, s.planReminder)),
        (_, _) => _scheduleNotifications(),
      );
    }
    return widget.child;
  }
}
