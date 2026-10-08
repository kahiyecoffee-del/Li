import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/utils/dates.dart';
import 'package:lifeos/data/local/database_opener.dart';
import 'package:lifeos/data/repositories/journal_repository.dart';
import 'package:lifeos/data/repositories/user_repos.dart';
import 'package:lifeos/domain/ai/ai_action.dart';
import 'package:lifeos/domain/ai/ai_action_validator.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/task_item.dart';
import 'package:lifeos/domain/models/user_profile.dart';
import 'package:lifeos/domain/models/wellbeing.dart';
import 'package:lifeos/services/ads/ad_policy.dart';
import 'package:lifeos/services/ai/ai_action_executor.dart';
import 'package:lifeos/services/ai/ai_context_builder.dart';
import 'package:lifeos/services/ai/ai_service.dart';
import 'package:lifeos/services/ai/memory_manager.dart';
import 'package:lifeos/services/notifications/notification_planner.dart';
import 'package:lifeos/services/notifications/notification_service.dart';
import 'package:lifeos/services/settings/app_settings.dart';

void main() {
  final now = DateTime(2026, 6, 10, 9); // Wednesday
  var n = 0;

  Future<UserRepos> repos() async =>
      UserRepos(await DatabaseOpener.inMemory('svc${n++}'), journalKeys: MemoryJournalKeyStore(), clock: () => now);

  group('AiActionExecutor', () {
    late UserRepos r;
    late AiActionExecutor exec;
    final profile = UserProfile(
      updatedAt: now,
      currency: 'TRY',
      wakeTime: const DayTime(7 * 60),
      sleepTime: const DayTime(23 * 60),
    );

    setUp(() async {
      r = await repos();
      exec = AiActionExecutor(
        repos: r,
        profile: profile,
        memory: MemoryManager(r.memories, limit: 2, enabled: true, clock: () => now),
        languageCode: 'en',
        clock: () => now,
      );
    });

    test('create task', () async {
      final o = await exec.execute(CreateTaskAction(title: 'Meeting', scheduledAt: DateTime(2026, 6, 11, 9)));
      expect(o.success, isTrue);
      final t = (await r.tasks.getAll()).single;
      expect(t.title, 'Meeting');
      expect(t.scheduledAt, DateTime(2026, 6, 11, 9));
    });

    test('weekly budget starts on Monday, in profile currency', () async {
      await exec.execute(const CreateBudgetAction(period: BudgetPeriod.week, amountMinor: 1000000));
      final b = (await r.budgets.getAll()).single;
      expect(b.periodStart, DateTime(2026, 6, 8));
      expect(b.currency, 'TRY');
    });

    test('shopping items dedupe and categorize', () async {
      await exec.execute(const AddShoppingItemsAction(['Milk', 'Chicken']));
      final o = await exec.execute(const AddShoppingItemsAction(['milk', 'Rice']));
      expect(o.count, 1);
      final items = await r.shopping.getAll();
      expect(items.length, 3);
      expect(items.firstWhere((i) => i.name == 'Milk').category, ShoppingCategory.dairy);
    });

    test('meal plan from local library', () async {
      final o = await exec.execute(GenerateMealPlanAction(date: now));
      expect(o.count, 3);
      expect((await r.mealPlans.get(Dates.dayKey(now)))!.meals.length, 3);
    });

    test('optimize plan schedules open tasks inside the day', () async {
      await r.tasks.save(TaskItem(id: 'a', updatedAt: now, title: 'Report', estimatedMinutes: 60, createdAt: now));
      final o = await exec.execute(const OptimizePlanAction());
      expect(o.count, 1);
      final t = await r.tasks.get('a');
      expect(t!.scheduledAt, DateTime(2026, 6, 10, 9));
    });

    test('memory respects limit', () async {
      await exec.execute(const SaveMemoryAction(category: MemoryCategory.food, content: 'Vegetarian'));
      await exec.execute(const SaveMemoryAction(category: MemoryCategory.goals, content: 'Save 10k'));
      final o = await exec.execute(const SaveMemoryAction(category: MemoryCategory.habits, content: 'Runs daily'));
      expect(o.success, isFalse);
      expect(o.detail, 'limitReached');
    });
  });

  group('AiResponseParser', () {
    final p = AiResponseParser(AiActionValidator(clock: () => now));
    test('keeps valid actions, drops invalid, parses credits', () {
      final r = p.parseChat({
        'reply': 'Done',
        'actions': [
          {
            'intent': 'create_task',
            'data': {'title': 'Gym'},
          },
          {
            'intent': 'transfer_money',
            'data': {'amount': 100},
          },
        ],
        'memorySuggestions': [
          {'category': 'food', 'content': 'Likes spicy food'},
          {'category': 'bogus', 'content': 'x'},
        ],
        'credits': {'used': 2, 'limit': 5, 'bonus': 2, 'premium': false, 'rewardedRemaining': 1},
      });
      expect(r.actions.length, 1);
      expect(r.rejectedActions, 1);
      expect(r.memorySuggestions.single.category, MemoryCategory.food);
      expect(r.credits.remaining, 5);
      expect(r.credits.canEarnMore, isTrue);
    });
  });

  group('NotificationPlanner', () {
    const planner = NotificationPlanner();
    test('morning plan and evening journal reminders, skipped when done', () {
      final morning = DateTime(2026, 6, 10, 7);
      final p = planner.plan(NotificationState(now: morning, frequency: NotificationFrequency.normal, dailyCap: 5));
      final today = p.where((x) => Dates.sameDay(x.at, morning)).map((x) => (x.kind, x.at.hour, x.at.minute));
      expect(today, containsAll([(NotificationKind.planDay, 8, 45), (NotificationKind.journal, 21, 15)]));
      expect(NotificationKind.planDay.route, '/ai?topic=plan');
      final done = planner.plan(
        NotificationState(
          now: morning,
          frequency: NotificationFrequency.normal,
          dailyCap: 5,
          hasPlanToday: true,
          journaledToday: true,
        ),
      );
      expect(
        done.where((x) => Dates.sameDay(x.at, morning)).map((x) => x.kind),
        isNot(contains(NotificationKind.planDay)),
      );
      expect(
        done.where((x) => Dates.sameDay(x.at, morning)).map((x) => x.kind),
        isNot(contains(NotificationKind.journal)),
      );
    });

    test('off schedules nothing', () {
      expect(planner.plan(NotificationState(now: now, frequency: NotificationFrequency.off, dailyCap: 3)), isEmpty);
    });

    test('task reminder 30 minutes before; low only allows reminders', () {
      final s = NotificationState(
        now: now,
        frequency: NotificationFrequency.low,
        dailyCap: 3,
        hasBudget: true,
        upcomingTasks: [
          TaskItem(id: 'm', updatedAt: now, title: 'Standup', scheduledAt: DateTime(2026, 6, 10, 11), createdAt: now),
        ],
      );
      final p = planner.plan(s);
      expect(p.single.kind, NotificationKind.taskReminder);
      expect(p.single.at, DateTime(2026, 6, 10, 10, 30));
      // The reminder knows its task (for the Done button) and carries what a
      // background snooze needs.
      expect(p.single.taskId, 'm');
      final payload = jsonDecode(taskPayload(route: '/plan', taskId: 'm', title: 'Standup', body: 'in 30 min'));
      expect(payload, {'r': '/plan', 'k': 'm', 't': 'Standup', 'b': 'in 30 min'});
    });

    test('a day with tasks gets a morning brief and an evening close-the-day', () {
      final s = NotificationState(
        now: now,
        frequency: NotificationFrequency.normal,
        dailyCap: 3,
        spendToday: '₺320',
        quietEnd: const DayTime(7 * 60),
        quietStart: const DayTime(23 * 60),
        upcomingTasks: [
          TaskItem(
            id: 'a',
            updatedAt: now,
            title: 'Gym',
            scheduledAt: DateTime(2026, 6, 11, 18),
            remindBefore: -1,
            createdAt: now,
          ),
          TaskItem(id: 'b', updatedAt: now, title: 'Call bank', deadline: DateTime(2026, 6, 11), createdAt: now),
        ],
      );
      final p = planner.plan(s);
      final brief = p.firstWhere((n) => n.kind == NotificationKind.morningBrief);
      expect(brief.at, DateTime(2026, 6, 11, 7, 15));
      expect(brief.count, 2);
      expect(brief.title, '18:00 Gym');
      expect(brief.extra, isNull); // tomorrow's budget is not known yet
      final close = p.firstWhere((n) => n.kind == NotificationKind.closeDay);
      expect(close.at, DateTime(2026, 6, 11, 21));
      expect(close.kind.route, '/plan?close=1');
    });

    test('nudges are capped per day and skipped when satisfied', () {
      final p = planner.plan(
        NotificationState(
          now: now,
          frequency: NotificationFrequency.normal,
          dailyCap: 1,
          hasBudget: true,
          loggedSpendingToday: true,
          moodLoggedToday: false,
          currentStreak: 3,
          activeToday: true,
        ),
      );
      final today = p.where((x) => Dates.sameDay(x.at, now)).toList();
      expect(today.length, 1);
      // The evening journal reminder doubles as the mood check-in.
      expect(today.single.kind, NotificationKind.journal);
      final tomorrow = p.where((x) => Dates.sameDay(x.at, Dates.addDays(now, 1))).toList();
      expect(tomorrow.length, 1);
      expect(tomorrow.single.kind, NotificationKind.streakAtRisk);
    });

    test('quiet hours respected', () {
      final p = planner.plan(
        NotificationState(
          now: now,
          frequency: NotificationFrequency.normal,
          dailyCap: 5,
          quietStart: const DayTime(19 * 60),
          quietEnd: const DayTime(8 * 60),
        ),
      );
      expect(p.every((x) => x.at.hour < 19 && x.at.hour >= 8), isTrue);
    });
  });

  group('AdPolicy', () {
    const policy = AdPolicy(isPremium: false, minMinutesBetween: 30, maxPerDay: 2);

    test('app-open: measured — not for premium, new users, before onboarding or too often', () {
      final now = DateTime(2026, 5, 10, 12);
      final old = now.subtract(const Duration(days: 5));
      bool can(AdPolicy p, {DateTime? last, DateTime? installed, bool onboarded = true, bool rc = true}) =>
          p.canShowAppOpen(
            remoteEnabled: rc,
            now: now,
            lastShownAt: last,
            installedAt: installed ?? old,
            onboarded: onboarded,
          );
      expect(can(policy), isTrue);
      expect(can(const AdPolicy(isPremium: true, minMinutesBetween: 30, maxPerDay: 2)), isFalse);
      expect(can(policy, rc: false), isFalse);
      expect(can(policy, onboarded: false), isFalse);
      expect(can(policy, installed: now.subtract(const Duration(days: 1))), isFalse);
      expect(can(policy, last: now.subtract(const Duration(hours: 2))), isFalse);
      expect(can(policy, last: now.subtract(const Duration(hours: 5))), isTrue);
    });
    final installed = now.subtract(const Duration(days: 10));
    test('never during critical flows, AI, onboarding; never for premium', () {
      for (final m in [AdMoment.criticalFlow, AdMoment.aiConversation, AdMoment.onboarding]) {
        expect(
          policy.canShowInterstitial(moment: m, now: now, lastShownAt: null, shownToday: 0, installedAt: installed),
          isFalse,
        );
      }
      expect(
        const AdPolicy(isPremium: true, minMinutesBetween: 30, maxPerDay: 2).canShowInterstitial(
          moment: AdMoment.naturalBreak,
          now: now,
          lastShownAt: null,
          shownToday: 0,
          installedAt: installed,
        ),
        isFalse,
      );
    });

    test('frequency caps, new-user grace period, remote disable', () {
      expect(
        policy.canShowInterstitial(
          moment: AdMoment.naturalBreak,
          now: now,
          lastShownAt: null,
          shownToday: 0,
          installedAt: installed,
        ),
        isTrue,
      );
      expect(
        policy.canShowInterstitial(
          moment: AdMoment.naturalBreak,
          now: now,
          lastShownAt: now.subtract(const Duration(minutes: 10)),
          shownToday: 1,
          installedAt: installed,
        ),
        isFalse,
      );
      expect(
        policy.canShowInterstitial(
          moment: AdMoment.naturalBreak,
          now: now,
          lastShownAt: null,
          shownToday: 2,
          installedAt: installed,
        ),
        isFalse,
      );
      expect(
        policy.canShowInterstitial(
          moment: AdMoment.naturalBreak,
          now: now,
          lastShownAt: null,
          shownToday: 0,
          installedAt: now,
        ),
        isFalse,
      );
      expect(
        const AdPolicy(isPremium: false, minMinutesBetween: 0, maxPerDay: 2).canShowInterstitial(
          moment: AdMoment.naturalBreak,
          now: now,
          lastShownAt: null,
          shownToday: 0,
          installedAt: installed,
        ),
        isFalse,
      );
    });
  });

  group('AiContextBuilder', () {
    test('only consented scopes are included', () {
      final profile = UserProfile(updatedAt: now, name: 'Eray', currency: 'TRY');
      final journal = [JournalEntry(id: 'j', updatedAt: now, createdAt: now, text: 'secret')];
      final ctx = const AiContextBuilder().build(
        now: now,
        locale: 'tr',
        timeZone: 'Europe/Istanbul',
        profile: profile,
        scopes: {AiDataScope.tasks},
        journal: journal,
        moods: [MoodLog(id: Dates.dayKey(now), updatedAt: now, mood: 4)],
      );
      expect(ctx.containsKey('tasks'), isTrue);
      expect(ctx.containsKey('journal'), isFalse);
      expect(ctx.containsKey('wellbeing'), isFalse);
      expect(ctx.containsKey('money'), isFalse);
      expect(ctx['name'], 'Eray');
      final withJournal = const AiContextBuilder().build(
        now: now,
        locale: 'tr',
        timeZone: null,
        profile: profile,
        scopes: {AiDataScope.journal},
        journal: journal,
      );
      expect(withJournal['journal'], isNotEmpty);
    });
  });
}
