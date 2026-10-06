import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database_opener.dart';
import '../data/local/local_store.dart';
import '../data/repositories/user_repos.dart';
import '../domain/models/ai_models.dart';
import '../domain/models/food.dart';
import '../domain/models/habit.dart';
import '../domain/models/money_models.dart';
import '../domain/models/progress.dart';
import '../domain/models/saved_item.dart';
import '../domain/models/task_item.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/wellbeing.dart';
import '../services/auth/auth_service.dart';
import '../services/billing/entitlement.dart';
import '../services/settings/app_settings.dart';
import 'services.dart';
import 'session.dart';

/// Typed empty-list fallback for list providers that are still loading.
extension AsyncListX<T> on AsyncValue<List<T>> {
  List<T> get list => value ?? List<T>.empty();
}

/// Injected in `main()` via `ProviderScope(overrides: …)`.
final servicesProvider = Provider<Services>((ref) => throw UnimplementedError('servicesProvider not overridden'));

/// Opens the per-user local DB (overridden in tests with in-memory stores).
final storeOpenerProvider = Provider<Future<LocalStore> Function(String uid)>((ref) => DatabaseOpener.openForUser);

/// Wall clock, overridable for tests and screenshots.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// "Now", ticking every minute so day-based views roll over at midnight.
final nowProvider = StreamProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final c = StreamController<DateTime>();
  c.add(clock());
  final t = Timer.periodic(const Duration(minutes: 1), (_) => c.add(clock()));
  ref.onDispose(() {
    t.cancel();
    unawaited(c.close());
  });
  return c.stream;
});

DateTime currentNow(Ref ref) => ref.watch(nowProvider).value ?? ref.watch(clockProvider)();

// ---------------------------------------------------------------------------
// Settings

class SettingsController extends Notifier<AppSettings> {
  late SettingsStore _store;

  @override
  AppSettings build() {
    _store = SettingsStore(ref.watch(servicesProvider).prefs);
    return _store.load();
  }

  Future<void> update(AppSettings Function(AppSettings) f) async {
    final next = f(state);
    state = next;
    await _store.save(next);
    final s = ref.read(servicesProvider);
    await s.analytics.setEnabled(next.analyticsEnabled);
    await s.crash.setEnabled(next.crashReportingEnabled);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

// ---------------------------------------------------------------------------
// Auth & session

final authUserProvider = StreamProvider<AppUser?>((ref) => ref.watch(servicesProvider).auth.userChanges);

/// The signed-in user's session; `null` while signed out.
final sessionProvider = FutureProvider<Session?>((ref) async {
  // Rebuild only when the uid changes: linking an anonymous account to
  // Google/email keeps the uid (and the local data).
  final uid = await ref.watch(authUserProvider.selectAsync((u) => u?.uid));
  final user = ref.read(authUserProvider).value;
  if (uid == null || user == null) return null;
  final services = ref.watch(servicesProvider);
  final session = await Session.open(user, services, ref.watch(storeOpenerProvider));
  ref.onDispose(() => unawaited(session.close()));
  unawaited(services.analytics.setUserId(user.uid));
  unawaited(services.crash.setUserId(user.uid));
  return session;
});

/// Repositories for the current session. Only read below the signed-in shell.
final reposProvider = Provider<UserRepos>((ref) {
  final s = ref.watch(sessionProvider).value;
  if (s == null) throw StateError('No active session');
  return s.repos;
});

final entitlementProvider = StreamProvider<Entitlement>((ref) {
  final s = ref.watch(sessionProvider).value;
  if (s == null) return Stream.value(Entitlement.free);
  return s.entitlements.watch();
});

final isPremiumProvider = Provider<bool>((ref) {
  final e = ref.watch(entitlementProvider).value ?? Entitlement.free;
  return e.activeAt(currentNow(ref));
});

// ---------------------------------------------------------------------------
// Live data streams (local-first; they work offline).

final profileProvider = StreamProvider<UserProfile>(
  (ref) => ref.watch(reposProvider).profile.watch(UserProfile.singletonId).map((p) => p ?? UserProfile.empty()),
);
final savedProvider = StreamProvider<List<SavedItem>>((ref) => ref.watch(reposProvider).saved.watchAll());
final savingsGoalsProvider = StreamProvider<List<SavingsGoal>>(
  (ref) => ref.watch(reposProvider).savingsGoals.watchAll(),
);
final billsProvider = StreamProvider<List<RecurringBill>>((ref) => ref.watch(reposProvider).bills.watchAll());
final tasksProvider = StreamProvider<List<TaskItem>>((ref) => ref.watch(reposProvider).tasks.watchAll());
final transactionsProvider = StreamProvider<List<MoneyTransaction>>(
  (ref) => ref.watch(reposProvider).transactions.watchAll(),
);
final budgetsProvider = StreamProvider<List<Budget>>((ref) => ref.watch(reposProvider).budgets.watchAll());
final habitsProvider = StreamProvider<List<Habit>>((ref) => ref.watch(reposProvider).habits.watchAll());
final habitLogsProvider = StreamProvider<List<HabitLog>>((ref) => ref.watch(reposProvider).habitLogs.watchAll());
final moodsProvider = StreamProvider<List<MoodLog>>((ref) => ref.watch(reposProvider).moods.watchAll());
final sleepsProvider = StreamProvider<List<SleepLog>>((ref) => ref.watch(reposProvider).sleeps.watchAll());
final scoresProvider = StreamProvider<List<DailyScoreRecord>>((ref) => ref.watch(reposProvider).scores.watchAll());
final goalsRecordsProvider = StreamProvider<List<DailyGoalsRecord>>((ref) => ref.watch(reposProvider).goals.watchAll());
final achievementsProvider = StreamProvider<List<AchievementRecord>>(
  (ref) => ref.watch(reposProvider).achievements.watchAll(),
);
final shoppingProvider = StreamProvider<List<ShoppingItem>>((ref) => ref.watch(reposProvider).shopping.watchAll());
final pantryProvider = StreamProvider<List<PantryItem>>((ref) => ref.watch(reposProvider).pantry.watchAll());
final mealPlansProvider = StreamProvider<List<MealPlan>>((ref) => ref.watch(reposProvider).mealPlans.watchAll());
final memoriesProvider = StreamProvider<List<AiMemory>>((ref) => ref.watch(reposProvider).memories.watchAll());
final journalProvider = StreamProvider<List<JournalEntry>>((ref) => ref.watch(reposProvider).journal.watchAll());

/// Pending uploads (shown as "syncing" in Settings).
final outboxCountProvider = StreamProvider<int>((ref) {
  final s = ref.watch(sessionProvider).value;
  return s == null ? Stream.value(0) : s.store.watchOutboxCount();
});

final onlineProvider = StreamProvider<bool>((ref) async* {
  final c = ref.watch(servicesProvider).connectivity;
  yield await c.isOnline();
  yield* c.onlineChanges;
});

/// Effective locale (settings override or device).
final localeProvider = Provider<Locale?>((ref) {
  final code = ref.watch(settingsProvider).localeCode;
  return code == null ? null : Locale(code);
});
