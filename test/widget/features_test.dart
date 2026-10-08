import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/models/user_profile.dart';
import 'package:lifeos/services/share/share_service.dart';
import 'package:flutter/services.dart';
import 'package:lifeos/services/notifications/notification_service.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/core/utils/dates.dart';
import 'package:lifeos/services/calendar/calendar_service.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/money_models.dart';
import 'package:lifeos/domain/models/task_item.dart';
import 'package:lifeos/services/analytics/analytics_service.dart';

import 'harness.dart';

void main() {
  testWidgets('Money: smart input "250 lunch" saves a Food expense', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded()))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));

    await tester.tap(find.text('Explore').last);
    await pumpUntil(tester, find.text('Money'));
    await tester.tap(find.text('Money').last);
    await pumpUntil(tester, find.text('Add expense'));
    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('Type an amount and what it was for. We’ll fill in the rest.'));

    await tester.enterText(find.byType(TextField).first, '250 lunch');
    await tester.pump();
    expect(find.text('Lunch'), findsWidgets); // description auto-filled
    await tester.tap(find.text('Save'));
    await pumpUntil(tester, find.text('Expense saved'));
    await pumpUntil(tester, find.textContaining('250'));
    expect(app.analytics.logged(AnalyticsEvent.expenseAdded), isTrue);
    expect(app.analytics.events.firstWhere((e) => e.$1 == AnalyticsEvent.expenseAdded).$2['category'], 'food');
    await tearDownApp(tester);
  });

  testWidgets('Money plan: add a bill and pay it, fill a savings jar', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded()))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await openExploreTile(tester, 'Money');
    await pumpUntil(tester, find.text('Plan'));
    await tester.tap(find.text('Plan'));
    await pumpUntil(tester, find.text('Bills & subscriptions'));

    await tester.tap(find.text('Add bill'));
    await pumpUntil(tester, find.text('Name (e.g. Electricity, Netflix)'));
    await tester.enterText(find.byType(TextField).at(0), 'Electricity');
    await tester.enterText(find.byType(TextField).at(1), '450');
    await tester.tap(find.text('Save'));
    await pumpUntil(tester, find.text('Electricity'));
    await tester.tap(find.textContaining('Mark paid'));
    await pumpUntil(tester, find.text('Logged as an expense'));
    final tx = await tester.runAsync(() => app.seededRepos.transactions.getAll());
    expect(tx!.single.amountMinor, 45000);
    expect(tx.single.description, 'Electricity');
    final bills = await tester.runAsync(() => app.seededRepos.bills.getAll());
    expect(bills!.single.lastPaidMonth, isNotNull);

    await scrollAndTap(tester, find.text('New jar'));
    await pumpUntil(tester, find.text('What for? (e.g. Holiday)'));
    await tester.enterText(find.byType(TextField).at(0), 'Holiday');
    await tester.enterText(find.byType(TextField).at(1), '1000');
    await tester.tap(find.text('Save'));
    await pumpUntil(tester, find.text('Holiday'));
    await scrollAndTap(tester, find.text('Add money'));
    await pumpUntil(tester, find.byType(AlertDialog));
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), '250');
    await tester.tap(find.text('OK'));
    await pumpUntil(tester, find.text('25%'));
    await tearDownApp(tester);
  });

  testWidgets('Planner: one-line add, auto-schedule, swipe to tomorrow', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded()))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await openPlan(tester);
    expect(find.textContaining('Nothing planned for this day yet'), findsOneWidget);

    // No time given: lands in "Anytime" and can be scheduled into a free slot.
    await tester.enterText(find.byType(TextField).last, 'read 20 min');
    await tester.tap(find.byTooltip('Add').last);
    await pumpUntil(tester, find.text('Read'));
    expect(find.text('Anytime'), findsOneWidget);
    await scrollAndTap(tester, find.text('Schedule'));
    // Late at night there is no free slot left today.
    await pumpUntil(
      tester,
      find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains(RegExp('Scheduled for|No free slot'))),
    );
    var tasks = await tester.runAsync(() => app.seededRepos.tasks.getAll());
    final read = tasks!.single;
    expect(read.estimatedMinutes, 20);

    // Pick the time and length with the chip, then just type what.
    await tester.tap(find.byKey(const Key('composer-time')));
    await pumpUntil(tester, find.text('When, and for how long?'));
    await tester.tap(find.text('45 min').last);
    await tester.pump();
    await tester.tap(find.text('OK').last);
    await pumpUntil(tester, find.textContaining('· 45 min'));
    await tester.enterText(find.byType(TextField).last, 'gym');
    await tester.tap(find.byTooltip('Add').last);
    // The timeline may put it below the fold: check what was saved.
    for (var i = 0; i < 40; i++) {
      final all = (await tester.runAsync(() => app.seededRepos.tasks.getAll()))!;
      if (all.any((t) => t.title == 'Gym')) break;
      await tester.pump(const Duration(milliseconds: 100));
    }
    final gym = (await tester.runAsync(() => app.seededRepos.tasks.getAll()))!.firstWhere((t) => t.title == 'Gym');
    expect(gym.estimatedMinutes, 45);
    expect(gym.scheduledAt, isNotNull);

    // Swipe left: moves to tomorrow.
    tasks = await tester.runAsync(() => app.seededRepos.tasks.getAll());
    final card = find.ancestor(of: find.text('Read'), matching: find.byType(Dismissible));
    final hasSlot = read.scheduledAt != null;
    if (hasSlot) {
      // The list builds lazily: bring the card into the built range first.
      final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;
      for (var i = 0; i < 12 && card.evaluate().isEmpty; i++) {
        await tester.drag(list, Offset(0, i < 6 ? -250 : 250));
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.runAsync(() => Scrollable.ensureVisible(tester.element(card.first), alignment: 0.3));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.drag(card.first, const Offset(-600, 0));
      await pumpUntil(tester, find.text('Moved to tomorrow'));
      tasks = await tester.runAsync(() => app.seededRepos.tasks.getAll());
      expect(tasks!.firstWhere((t) => t.title == 'Read').scheduledAt!.difference(read.scheduledAt!).inHours, 24);
    }
    await tearDownApp(tester);
  });

  testWidgets('Quick capture: one line becomes an expense, a task, shopping or a journal note', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded()))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    final field = find.byKey(const Key('capture-field'));
    Future<void> capture(String text, String preview) async {
      await tester.ensureVisible(field);
      await tester.enterText(field, text);
      await tester.pump();
      expect(find.textContaining(preview), findsWidgets, reason: text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 400));
    }

    await capture('250 TL market', 'Food');
    await pumpUntil(tester, find.textContaining('Saved: '));
    await capture('tomorrow 15:00 dentist 30 min', 'Tomorrow');
    await pumpUntil(tester, find.textContaining('Planned: Dentist'));
    await capture('buy milk, eggs', 'milk, eggs');
    await capture('I feel calm after the walk', 'A note for your journal');
    await pumpUntil(tester, find.text('Saved to your journal'));

    final repos = app.seededRepos;
    final tx = (await tester.runAsync(() => repos.transactions.getAll()))!;
    expect(tx.single.amountMinor, 25000);
    final task = (await tester.runAsync(() => repos.tasks.getAll()))!.single;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(task.scheduledAt, DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 15));
    expect(task.estimatedMinutes, 30);
    final shop = (await tester.runAsync(() => repos.shopping.getAll()))!;
    expect(shop.map((x) => x.name), containsAll(['milk', 'eggs']));
    await tearDownApp(tester);
  });

  testWidgets('Routines, goals and the weekly review all feed the plan', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded()))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    final repos = app.seededRepos;

    // Routine: use a ready-made one, add it to today at its usual time.
    await openExploreTile(tester, 'Routines');
    await pumpUntil(tester, find.text('Morning routine'));
    await tester.tap(find.text('Use').first);
    await pumpUntil(tester, find.text('Add to a day'));
    await tester.tap(find.text('Add to a day').first);
    await pumpUntil(tester, find.text('When, and for how long?'));
    await tester.tap(find.text('OK').last);
    await pumpUntil(tester, find.textContaining('steps added to your plan'));
    var tasks = (await tester.runAsync(() => repos.tasks.getAll()))!;
    expect(tasks.map((t) => t.title), contains('Drink a glass of water'));
    expect(tasks.length, 5);
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.text('Explore'));

    // Goal: steps from lines, then plan one step.
    await openExploreTile(tester, 'Goals');
    await pumpUntil(tester, find.text('New goal'));
    await tester.tap(find.text('New goal').last);
    await pumpUntil(tester, find.text('Why it matters to you'));
    await tester.enterText(find.byType(TextField).at(0), 'English B1');
    await tester.enterText(find.byType(TextField).at(2), 'Placement test\nBook a course');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await pumpUntil(tester, find.text('English B1'));
    await tester.tap(find.text('English B1'));
    await pumpUntil(tester, find.text('Placement test'));
    await tester.tap(find.text('Plan').first);
    await pumpUntil(tester, find.text('Added to today’s plan'));
    tasks = (await tester.runAsync(() => repos.tasks.getAll()))!;
    expect(tasks.map((t) => t.title), contains('Placement test'));
    final goal = (await tester.runAsync(() => repos.lifeGoals.getAll()))!.single;
    expect(goal.steps.first.taskId, isNotNull);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.text('Explore'));

    // Weekly review: one focus, placed on a day of next week.
    await openExploreTile(tester, 'Weekly review');
    await pumpUntil(tester, find.text('Three focuses for next week'));
    await tester.scrollUntilVisible(find.byKey(const Key('focus-0')), 300, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byKey(const Key('focus-0')), 'finish the report');
    await scrollAndTap(tester, find.text('Plan next week'));
    await pumpUntil(tester, find.text('1 focus planned'));
    tasks = (await tester.runAsync(() => repos.tasks.getAll()))!;
    final report = tasks.firstWhere((t) => t.title == 'Finish the report');
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(report.deadline, DateTime(tomorrow.year, tomorrow.month, tomorrow.day));
    await tearDownApp(tester);
  });

  testWidgets('AI: proposed action needs confirmation, then creates the task', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded()))!;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final date =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    app.ai.nextReply = {
      'reply': 'Sure — shall I add it?',
      'actions': [
        {
          'intent': 'create_task',
          'requires_confirmation': true,
          'data': {'title': 'Team meeting', 'date': date, 'time': '09:00', 'duration_minutes': 60},
        },
        {
          'intent': 'transfer_money',
          'data': {'amount': 500},
        },
      ],
      'credits': {'used': 1, 'limit': 5, 'bonus': 0, 'premium': false, 'rewardedRemaining': 3},
    };
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await tester.tap(find.text('Solve'));
    await pumpUntil(tester, find.text('How can I help today?'));

    await tester.enterText(find.byType(TextField).last, 'Add a meeting tomorrow at 9');
    await tester.tap(find.byTooltip('Send'));
    await pumpUntil(tester, find.text('Sure — shall I add it?'));

    // Only the valid action is shown; the money transfer was rejected.
    expect(find.textContaining('Team meeting'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    // Context sent to the backend respects consent: journal excluded by default.
    expect(app.ai.requests.single.context.containsKey('journal'), isFalse);
    expect(app.ai.requests.single.context['currency'], 'TRY');

    // Nothing is created before confirmation.
    final before = await tester.runAsync(() => app.seededRepos.tasks.getAll());
    expect(before!.where((t) => t.title == 'Team meeting'), isEmpty);

    await tester.tap(find.text('Confirm'));
    await pumpUntil(tester, find.textContaining('Done'));
    expect(app.analytics.logged(AnalyticsEvent.aiActionConfirmed), isTrue);

    // Lio is not a tab any more: back (chat, then Lio) to Home, then the plan.
    while (find.text('Explore').evaluate().isEmpty) {
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
    }
    await openPlan(tester);
    await pickPlanDay(tester, tomorrow);
    await pumpUntil(tester, find.text('Team meeting'));
    await tearDownApp(tester);
  });

  testWidgets('Planner: overlaps are flagged and fixed; every task has a menu', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await openPlan(tester);
    final tomorrow = Dates.addDays(Dates.dateOnly(DateTime.now()), 1);
    await pickPlanDay(tester, tomorrow);
    Future<void> add(String text) async {
      final field = find.descendant(of: find.byKey(const Key('plan-composer')), matching: find.byType(TextField));
      await tester.enterText(field, text);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 400));
    }

    await add('Meeting 10:00 1 hour');
    await add('Call mom 10:30 30 min');
    await pumpUntil(tester, find.byKey(const Key('plan-clashes')));
    expect(find.textContaining('Overlaps'), findsWidgets);
    await tester.tap(find.text('Fix overlaps'));
    await pumpUntil(tester, find.textContaining('nothing overlaps now'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('plan-clashes')), findsNothing);
    final tasks = (await tester.runAsync(() => app.seededRepos.tasks.getAll()))!;
    final call = tasks.firstWhere((t) => t.title == 'Call mom');
    expect(call.scheduledAt!.hour, 11);

    // The ⋯ menu: duplicate the call.
    // Up from under the composer at the bottom.
    await tester.runAsync(
      () => Scrollable.ensureVisible(tester.element(find.byKey(Key('task-menu-${call.id}'))), alignment: 0.3),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(Key('task-menu-${call.id}')));
    await pumpUntil(tester, find.text('Duplicate'));
    await tester.tap(find.text('Duplicate'));
    await pumpUntil(tester, find.text('Copied'));
    final after = (await tester.runAsync(() => app.seededRepos.tasks.getAll()))!;
    expect(after.where((t) => t.title == 'Call mom' && !t.deleted).length, 2);
    await tearDownApp(tester);
  });

  testWidgets('Planner: an overloaded day offers to lighten it', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    final tomorrow = Dates.addDays(Dates.dateOnly(DateTime.now()), 1);
    await tester.runAsync(() async {
      for (final (id, mins, p) in [
        ('Deep work', 420, TaskPriority.high),
        ('Paperwork', 300, TaskPriority.medium),
        ('Tidy up', 180, TaskPriority.low),
      ]) {
        await app.seededRepos.tasks.save(
          TaskItem(
            id: id,
            updatedAt: DateTime.now(),
            title: id,
            priority: p,
            estimatedMinutes: mins,
            deadline: tomorrow,
            createdAt: DateTime.now(),
          ),
        );
      }
    });
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await openPlan(tester);
    await pickPlanDay(tester, tomorrow);
    await pumpUntil(tester, find.byKey(const Key('plan-overload')));
    await tester.tap(find.text('Lighten my day'));
    await pumpUntil(tester, find.textContaining('to tomorrow'));
    final tasks = (await tester.runAsync(() => app.seededRepos.tasks.getAll()))!;
    final tidy = tasks.firstWhere((t) => t.id == 'Tidy up');
    expect(Dates.sameDay(tidy.anchorDate!, Dates.addDays(tomorrow, 1)), isTrue);
    expect(tidy.rolledOver, 1);
    expect(Dates.sameDay(tasks.firstWhere((t) => t.id == 'Deep work').anchorDate!, tomorrow), isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('plan-overload')), findsNothing);
    await tearDownApp(tester);
  });

  testWidgets('Planner: the phone calendar shows as busy time and tasks step around it', (tester) async {
    usePhoneViewport(tester);
    final tomorrow = Dates.addDays(Dates.dateOnly(DateTime.now()), 1);
    final app = (await tester.runAsync(
      () => TestApp.onboarded(
        online: false,
        calendar: [
          CalendarEvent(
            id: 'e1',
            title: 'Dentist',
            start: tomorrow.add(const Duration(hours: 10)),
            end: tomorrow.add(const Duration(hours: 11)),
          ),
          CalendarEvent(id: 'e2', title: 'Holiday', start: tomorrow, end: Dates.addDays(tomorrow, 1), allDay: true),
        ],
      ),
    ))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await openPlan(tester);
    await pickPlanDay(tester, tomorrow);
    await tester.tap(find.byKey(const Key('plan-calendar-connect')));
    await pumpUntil(tester, find.byKey(const Key('plan-event')));
    expect(find.text('Dentist'), findsOneWidget);
    expect(find.text('Holiday'), findsOneWidget);

    final field = find.descendant(of: find.byKey(const Key('plan-composer')), matching: find.byType(TextField));
    await tester.enterText(field, 'Call bank 10:30 30 min');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpUntil(tester, find.textContaining('Overlaps “Dentist”'));
    await pumpUntil(tester, find.byKey(const Key('plan-clashes')));
    await tester.tap(find.text('Fix overlaps'));
    await pumpUntil(tester, find.textContaining('nothing overlaps now'));
    final tasks = (await tester.runAsync(() => app.seededRepos.tasks.getAll()))!;
    expect(tasks.firstWhere((t) => t.title == 'Call bank').scheduledAt, tomorrow.add(const Duration(hours: 11)));
    await tearDownApp(tester);
  });

  testWidgets('Home offers to save a streak after a day off', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    final today = Dates.dateOnly(DateTime.now());
    await tester.runAsync(() async {
      for (final back in [2, 3, 4]) {
        final d = Dates.addDays(today, -back).add(const Duration(hours: 12));
        await app.seededRepos.transactions.save(
          MoneyTransaction(
            id: 'tx$back',
            updatedAt: d,
            type: TransactionType.expense,
            amountMinor: 5000,
            currency: 'TRY',
            category: ExpenseCategory.food,
            date: d,
          ),
        );
      }
    });
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.byKey(const Key('streak-saver')));
    expect(find.text('Save your 4-day streak'), findsOneWidget);
    expect(find.text('Watch and save'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Focus: a session runs, counts toward Lio and can be stopped', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    unawaited(GoRouter.of(tester.element(find.text('What should we solve today?'))).push('/focus'));
    await pumpUntil(tester, find.byKey(const Key('focus-start')));
    await tester.tap(find.text('5 min'));
    await tester.tap(find.byKey(const Key('focus-start')));
    await pumpUntil(tester, find.byKey(const Key('focus-stop')));
    final notifications = app.services.notifications as NoopNotificationService;
    expect(notifications.focusEndsAt, isNotNull);
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.byKey(const Key('focus-stop')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(notifications.focusEndsAt, isNull);
    await pumpUntil(tester, find.byKey(const Key('focus-start')));
    await tearDownApp(tester);
  });

  testWidgets('Lio goes exploring after three things and brings a postcard', (tester) async {
    usePhoneViewport(tester);
    final now = DateTime.now();
    if (now.hour < 3) return; // the trip would start yesterday
    final app = (await tester.runAsync(
      () => TestApp.onboarded(
        online: false,
        prefs: {'garden_trip': now.subtract(const Duration(hours: 2, minutes: 5)).millisecondsSinceEpoch},
      ),
    ))!;
    await tester.runAsync(() async {
      for (final id in ['a', 'b', 'c']) {
        await app.seededRepos.tasks.save(
          TaskItem(id: id, updatedAt: now, title: id, deadline: now, completedAt: now, createdAt: now),
        );
      }
    });
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await tester.scrollUntilVisible(
      find.byKey(const Key('garden-open')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpUntil(tester, find.byKey(const Key('garden-open')));
    expect(find.text('A postcard is waiting!'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('garden-open')));
    await tester.tap(find.byKey(const Key('garden-open')));
    await pumpUntil(tester, find.text('1 of 24 collected'));
    expect(find.textContaining('POSTCARD FROM'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('The widget\'s Done button ticks the next task off', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    final now = DateTime.now();
    await tester.runAsync(
      () => app.seededRepos.tasks.save(
        TaskItem(id: 'w1', updatedAt: now, title: 'Water plants', deadline: now, createdAt: now),
      ),
    );
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    GoRouter.of(tester.element(find.text('What should we solve today?'))).go('/plan?done=w1');
    await pumpUntil(tester, find.text('Done: Water plants'));
    final t = (await tester.runAsync(() => app.seededRepos.tasks.getAll()))!.firstWhere((t) => t.id == 'w1');
    expect(t.isCompleted, isTrue);
    await tearDownApp(tester);
  });

  testWidgets('Today page: rates, opt-in prayer times and nearby links', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.runAsync(() async {
      final p = (await app.seededRepos.profile.get(UserProfile.singletonId))!;
      await app.seededRepos.profile.save(p.copyWith(place: const Place(name: 'İstanbul', latitude: 41, longitude: 29)));
    });
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    unawaited(GoRouter.of(tester.element(find.text('What should we solve today?'))).push('/today-info'));
    await pumpUntil(tester, find.byKey(const Key('today-rates')));
    await pumpUntil(tester, find.textContaining('41.50'));
    expect(find.byKey(const Key('today-prayer')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('today-prayer-toggle')));
    await tester.tap(find.byKey(const Key('today-prayer-toggle')));
    await pumpUntil(tester, find.text('Maghrib'));
    expect(find.text('18:35'), findsOneWidget);
    await tester.ensureVisible(find.text('Pharmacy on duty'));
    expect(find.text('Fuel prices'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Shopping: share the list as a message and add one someone sent', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    String? clipboard = '🛒 Shopping list\n☐ Milk\n☐ Bread\n\nMade with Dayly';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') return {'text': clipboard};
      return null;
    });
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    unawaited(GoRouter.of(tester.element(find.text('What should we solve today?'))).push('/shopping'));
    await pumpUntil(tester, find.byKey(const Key('shopping-paste')));
    await tester.tap(find.byKey(const Key('shopping-paste')));
    await pumpUntil(tester, find.text('2 items added'));
    await pumpUntil(tester, find.text('Milk'));
    await tester.tap(find.byKey(const Key('shopping-share')));
    await tester.pump();
    final share = app.services.share as RecordingShareService;
    expect(share.texts.single, contains('☐ Milk'));
    expect(share.texts.single, contains('☐ Bread'));
    clipboard = null;
    await tearDownApp(tester);
  });

  testWidgets('Weekly review: the week card can be shared as a picture', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    unawaited(GoRouter.of(tester.element(find.text('What should we solve today?'))).push('/review'));
    await pumpUntil(tester, find.byKey(const Key('review-share')));
    expect(find.text('My week with Dayly'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('review-share')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    expect((app.services.share as RecordingShareService).images, ['dayly-week.png']);
    await tearDownApp(tester);
  });

  testWidgets('Turkish + dark mode render Home and My day', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(prefs: {'locale': 'tr', 'themeMode': 'dark'})))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Bugün neyi çözelim?'));
    final ctx = tester.element(find.text('Bugün neyi çözelim?'));
    expect(Theme.of(ctx).brightness, Brightness.dark);
    await scrollAndTap(tester, find.text('Günüm'));
    await pumpUntil(tester, find.text('Gününe hızlı bir bakış.'));
    expect(find.text('Yaşam Skoru'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Offline banner is shown and core features still work', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Offline — changes are saved and will sync later.'));
    await openPlan(tester);
    // One line: title, time and length.
    await tester.enterText(find.byType(TextField).last, 'gym 18:30 45 min');
    await tester.tap(find.byTooltip('Add').last);
    // The timeline may put it below the fold: check what was saved.
    for (var i = 0; i < 40; i++) {
      final all = (await tester.runAsync(() => app.seededRepos.tasks.getAll()))!;
      if (all.any((t) => t.title == 'Gym')) break;
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('18:30'), findsWidgets);
    expect(app.analytics.logged(AnalyticsEvent.taskCreated), isTrue);
    await tearDownApp(tester);
  });

  testWidgets('Habits: tapping + logs progress toward the daily target', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded()))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await tester.tap(find.text('Explore').last);
    await pumpUntil(tester, find.text('Habits'));
    await tester.tap(find.text('Habits'));
    await pumpUntil(tester, find.byType(FloatingActionButton));
    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('New habit'));
    await tester.tap(find.text('Water'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await pumpUntil(tester, find.textContaining('0/8'));
    await tester.tap(find.byTooltip('Add one to Water'));
    await pumpUntil(tester, find.textContaining('1/8'));
    expect(app.analytics.logged(AnalyticsEvent.habitCreated), isTrue);
    await tearDownApp(tester);
  });

  testWidgets('Lio walks every tab; a tap opens his help, which leads to the assistant', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(prefs: {'showLio': true})))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    // No assistant tab: Lio is the way in.
    expect(find.text('AI'), findsNothing);
    final lio = find.byKey(const Key('lio-companion'));
    await pumpUntil(tester, lio);
    await tester.tap(find.text('Explore').last);
    await pumpUntil(tester, lio);
    await tester.tap(lio);
    await pumpUntil(tester, find.text('How can I help?'));
    expect(find.text('Plan my day'), findsOneWidget);
    await tester.tap(find.text('Ask me anything'));
    await pumpUntil(tester, find.text('How can I help today?'));
    await tearDownApp(tester);
  });

  testWidgets('Lio answers with no cloud and no model (built-in brain)', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await tester.tap(find.text('Solve'));
    await pumpUntil(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField).last, 'How much can I spend today?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await pumpUntil(tester, find.textContaining('safe daily amount'));
    await tearDownApp(tester);
  });

  testWidgets('Home: Solve opens Lio; a typed problem is answered and can be saved', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await tester.tap(find.text('Solve'));
    await pumpUntil(tester, find.text('How can I help today?'));
    await tester.enterText(find.byType(TextField).last, 'I have 3,000 TL left for 20 days');
    await tester.tap(find.byTooltip('Send').last);
    await pumpUntil(tester, find.textContaining('a day.'));
    expect(find.textContaining('150'), findsWidgets);
    expect(app.analytics.logged(AnalyticsEvent.problemSolved), isTrue);
    await tester.tap(find.widgetWithText(ActionChip, 'Save'));
    await pumpUntil(tester, find.text('Saved'));
    await tester.tap(find.text('Saved').last);
    await pumpUntil(tester, find.textContaining('a day.'));
    await tearDownApp(tester);
  });

  testWidgets('Lio: "X or Y?" offers to compare in Decide', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await tester.tap(find.text('Solve'));
    await pumpUntil(tester, find.text('How can I help today?'));
    await tester.enterText(find.byType(TextField).last, 'Kindle or Kobo?');
    await tester.tap(find.byTooltip('Send').last);
    await pumpUntil(tester, find.widgetWithText(ActionChip, 'Compare them properly'));
    await tester.tap(find.widgetWithText(ActionChip, 'Compare them properly'));
    await pumpUntil(tester, find.text('Decide'));
    expect(find.text('Kindle'), findsWidgets);
    await scrollAndTap(tester, find.text('Show the best option'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.scrollUntilVisible(find.text('RECOMMENDED'), 300, scrollable: find.byType(Scrollable).first);
    expect(app.analytics.logged(AnalyticsEvent.decisionCompleted), isTrue);
    await tearDownApp(tester);
  });

  testWidgets('Lio: cooking from what is at home suggests recipes (tr)', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false, prefs: {'locale': 'tr'})))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Bugün neyi çözelim?'));
    await tester.tap(find.text('Çöz'));
    await pumpUntil(tester, find.text('Bugün nasıl yardımcı olabilirim?'));
    await tester.enterText(find.byType(TextField).last, 'Evde yumurta, domates ve peynir var');
    await tester.tap(find.byTooltip('Gönder').last);
    await pumpUntil(tester, find.text('Elindekilerle bunları yapabilirsin'));
    expect(find.textContaining('Menemen'), findsWidgets);
    expect(app.analytics.logged(AnalyticsEvent.recipeGenerated), isTrue);
    await tearDownApp(tester);
  });

  testWidgets('The assistant can be renamed; Turkish suffixes follow the new name', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(prefs: {'locale': 'tr', 'assistantName': 'Maya'})))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Bugün neyi çözelim?'));
    await tester.tap(find.text('Çöz'));
    await pumpUntil(tester, find.text('Maya'));
    expect(find.text('Lio'), findsNothing);
    await tearDownApp(tester);
  });

  testWidgets('Calculator works offline', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await scrollAndTap(tester, find.text('Calculate'));
    await pumpUntil(tester, find.text('Calculator'));
    for (final k in ['1', '2', '×', '1', '5', '=']) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
    expect(find.text('180'), findsWidgets);
    await tearDownApp(tester);
  });

  group('Lio guide (no AI model)', () {
    Future<TestApp> openLio(WidgetTester tester) async {
      usePhoneViewport(tester);
      final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
      await tester.pumpWidget(app.widget());
      await pumpUntil(tester, find.text('What should we solve today?'));
      await tester.tap(find.text('Solve'));
      await pumpUntil(tester, find.text('How can I help today?'));
      return app;
    }

    Future<void> chip(WidgetTester tester, String label) async {
      await pumpUntil(tester, find.widgetWithText(ActionChip, label));
      await tester.tap(find.widgetWithText(ActionChip, label).last);
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> answer(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField).last, text);
      await tester.tap(find.byTooltip('Send').last);
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('money: will my money last, by tapping and typing', (tester) async {
      final app = await openLio(tester);
      await chip(tester, 'Money');
      await chip(tester, 'Will my money last?');
      await pumpUntil(tester, find.text('How much money do you have left?'));
      await answer(tester, '3000');
      await pumpUntil(tester, find.text('How many days does it need to last?'));
      await answer(tester, '20');
      await pumpUntil(tester, find.textContaining('a day.'));
      expect(find.textContaining('150'), findsWidgets);
      expect(app.analytics.logged(AnalyticsEvent.problemSolved), isTrue);
      await tearDownApp(tester);
    });

    testWidgets('write: a birthday message from a template, ready to copy', (tester) async {
      await openLio(tester);
      await chip(tester, 'Write');
      await chip(tester, 'Birthday wishes');
      await chip(tester, 'Warm');
      await pumpUntil(tester, find.text('Who is it for? (a name, or skip)'));
      await answer(tester, 'Ayşe');
      await pumpUntil(tester, find.textContaining('Happy birthday Ayşe!'));
      expect(find.text('Copy'), findsWidgets);
      await tearDownApp(tester);
    });

    testWidgets('decide: let Lio pick between options', (tester) async {
      await openLio(tester);
      await chip(tester, 'Decide');
      await pumpUntil(tester, find.textContaining('pizza sushi'));
      await answer(tester, 'pizza sushi');
      await chip(tester, 'Pick one for me');
      await pumpUntil(tester, find.textContaining('I pick'));
      await tearDownApp(tester);
    });

    testWidgets('plan my day: Lio asks, schedules and adds the tasks', (tester) async {
      usePhoneViewport(tester);
      final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
      await tester.pumpWidget(app.widget());
      await pumpUntil(tester, find.text('What should we solve today?'));
      await tester.tap(find.text('Plan').first);
      await pumpUntil(tester, find.textContaining('plan your day'));
      await answer(tester, 'write the report go to the gym');
      await chip(tester, 'Write the report');
      await chip(tester, '1 h');
      await chip(tester, '09:00');
      await pumpUntil(tester, find.text('Here’s your plan for today:'));
      expect(find.textContaining('09:00'), findsWidgets);
      await chip(tester, 'Add to my day');
      await pumpUntil(tester, find.textContaining('Your plan is in Plan'));
      final tasks = await tester.runAsync(() => app.seededRepos.tasks.getAll());
      expect(tasks!.map((t) => t.title), containsAll(['Write the report', 'Go to the gym']));
      expect(tasks.firstWhere((t) => t.title == 'Write the report').scheduledAt!.hour, 9);
      await tearDownApp(tester);
    });

    testWidgets('keyboard open: the chat still fits', (tester) async {
      await openLio(tester);
      await chip(tester, 'Money');
      tester.view.viewInsets = const FakeViewPadding(bottom: 1000);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tearDownApp(tester);
    });

    testWidgets('mood: feeling really bad shows where to get help', (tester) async {
      await openLio(tester);
      await chip(tester, 'Mood boost');
      await chip(tester, 'Really bad');
      await pumpUntil(tester, find.textContaining('112'));
      await tearDownApp(tester);
    });
  });

  testWidgets('Home: Lio speaks first about what he noticed (overdue task)', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.runAsync(() async {
      final now = DateTime.now();
      await app.seededRepos.tasks.save(
        TaskItem(
          id: 'late',
          updatedAt: now,
          createdAt: now,
          title: 'Pay rent',
          deadline: now.subtract(const Duration(days: 2)),
        ),
      );
    });
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.textContaining('1 task is overdue'));
    await tester.tap(find.text('Plan my day').first);
    await pumpUntil(tester, find.textContaining('plan your day'));
    await tearDownApp(tester);
  });

  testWidgets('Journal: write with a mood and a question, then see the streak', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await tester.tap(find.text('Journal').first);
    await pumpUntil(tester, find.text('How do you feel?'));
    await tester.tap(find.text('🙂'));
    await tester.tap(find.byTooltip('Add'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'A calm walk and good coffee.');
    await tester.tap(find.text('Save').first);
    await pumpUntil(tester, find.text('Saved to your journal'));
    expect(app.analytics.logged(AnalyticsEvent.journalEntryAdded), isTrue);
    expect(app.analytics.logged(AnalyticsEvent.moodLogged), isTrue);

    await tester.binding.handlePopRoute();
    await openExploreTile(tester, 'Journal');
    await pumpUntil(tester, find.text('1-day streak'));
    expect(find.text('What Lio has learned'), findsOneWidget);
    await tester.tap(find.textContaining('A calm walk'));
    await pumpUntil(tester, find.textContaining('words'));
    expect(find.text('🙂'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Food: filter recipes, scale servings, plan the week and make one shopping list', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await openExploreTile(tester, 'Food');
    await pumpUntil(tester, find.text('Recipes'));

    // Pick breakfast by hand instead of the suggestion.
    await tester.tap(find.text('Change').first);
    await pumpUntil(tester, find.text('Choose Breakfast'));
    await tester.enterText(find.byType(TextField).last, 'pancake');
    await pumpUntil(tester, find.text('Fluffy Pancakes'));
    await tester.tap(find.text('Fluffy Pancakes'));
    await pumpUntil(tester, find.text('Fluffy Pancakes'));
    final plans = await tester.runAsync(() => app.seededRepos.mealPlans.getAll());
    expect(plans!.single.meals.firstWhere((m) => m.mealType == MealType.breakfast).id, 'pancakes');
    expect(plans.single.meals.length, 3); // the other suggestions were kept

    await tester.tap(find.text('Recipes'));
    await pumpUntil(tester, find.text('Search a dish or an ingredient'));
    await tester.enterText(find.byType(TextField), 'menemen');
    await pumpUntil(tester, find.text('1 recipe'));
    await tester.tap(find.text('Menemen (Turkish Eggs)'));
    await pumpUntil(tester, find.text('2 servings'));
    expect(find.text('4'), findsOneWidget); // eggs for two
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.text('3 servings'), findsOneWidget);
    expect(find.text('6'), findsOneWidget); // eggs for three
    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.text('Recipes'));

    await tester.tap(find.text('Week'));
    await pumpUntil(tester, find.text('Plan the week'));
    await tester.tap(find.text('Plan the week'));
    await pumpUntil(tester, find.text('Your week is planned.'));
    expect(find.text('Not planned yet'), findsNothing);
    await tester.tap(find.text('Make the shopping list'));
    await pumpUntil(tester, find.textContaining('Added'));
    final shopping = await tester.runAsync(() => app.seededRepos.shopping.getAll());
    expect(shopping!.length, greaterThan(3));
    await tearDownApp(tester);
  });
}

/// Opens a tile from Explore.
Future<void> openExploreTile(WidgetTester tester, String label) async {
  await tester.tap(find.text('Explore').last);
  await pumpUntil(tester, find.text(label));
  await tester.scrollUntilVisible(find.text(label).last, 200, scrollable: find.byType(Scrollable).first);
  // Bring it to the top: the floating tab bar covers the bottom edge.
  await tester.ensureVisible(find.text(label).last);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(label).last);
}

/// Plan is a tool inside Explore now.
Future<void> openPlan(WidgetTester tester) async {
  await tester.tap(find.text('Explore').last);
  await pumpUntil(tester, find.text('Plan'));
  await tester.tap(find.text('Plan').last);
  await pumpUntil(tester, find.byKey(const Key('plan-composer')));
}

/// Taps a day on the planner's date strip.
Future<void> pickPlanDay(WidgetTester tester, DateTime d) async {
  final key = ValueKey(
    'day-${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
  );
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pump(const Duration(milliseconds: 500));
}
