import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await tester.tap(find.text('AI').last);
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
    await openPlan(tester);
    await tester.tap(find.text('This week'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Team meeting'), findsNothing);
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.text('AI'));

    await tester.tap(find.text('AI').last);
    await pumpUntil(tester, find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await pumpUntil(tester, find.textContaining('Done'));
    expect(app.analytics.logged(AnalyticsEvent.aiActionConfirmed), isTrue);

    await openPlan(tester);
    await tester.tap(find.text('This week'));
    await pumpUntil(tester, find.text('Team meeting'));
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
    await tester.tap(find.byType(FloatingActionButton));
    await pumpUntil(tester, find.text('New task'));
    await tester.enterText(find.byType(TextField).first, 'Gym');
    await tester.ensureVisible(find.text('Save'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await pumpUntil(tester, find.text('Gym'));
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

  testWidgets('Lio: tap for a tip, then jump to the assistant', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(prefs: {'showLio': true})))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    // Home already shows Lio; the walking companion appears on other tabs.
    await tester.tap(find.text('Explore').last);
    final lio = find.bySemanticsLabel('Lio, your companion');
    await pumpUntil(tester, lio);
    await tester.tap(lio);
    await pumpUntil(tester, find.text('Ask Lio'));
    expect(find.text('Another one'), findsWidgets);
    await tester.tap(find.text('Ask Lio').last);
    await pumpUntil(tester, find.text('How can I help today?'));
    await tearDownApp(tester);
  });

  testWidgets('Lio answers with no cloud and no model (built-in brain)', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await tester.tap(find.text('AI').last);
    await pumpUntil(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField).last, 'How much can I spend today?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await pumpUntil(tester, find.textContaining('safe daily amount'));
    await tearDownApp(tester);
  });

  testWidgets('Home: a typed problem is solved on the phone and can be saved', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await tester.enterText(find.byType(TextField).first, 'I have 3,000 TL left for 20 days');
    await tester.tap(find.text('Solve'));
    await pumpUntil(tester, find.textContaining('a day.'));
    expect(find.textContaining('150'), findsWidgets);
    expect(find.text('Calculated on your phone'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await pumpUntil(tester, find.text('Saved'));
    expect(app.analytics.logged(AnalyticsEvent.problemSolved), isTrue);

    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.text('Saved'));
    await tester.tap(find.text('Saved').last);
    await pumpUntil(tester, find.text('I have 3,000 TL left for 20 days'));
    await tearDownApp(tester);
  });

  testWidgets('Home: "which one" opens Decide with the options filled in', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded()))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    await tester.enterText(find.byType(TextField).first, 'Kindle or Kobo?');
    await tester.tap(find.text('Solve'));
    await pumpUntil(tester, find.text('Decide'));
    expect(find.text('Kindle'), findsWidgets);
    expect(find.text('Kobo'), findsWidgets);
    await scrollAndTap(tester, find.text('Show the best option'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.scrollUntilVisible(find.text('RECOMMENDED'), 300, scrollable: find.byType(Scrollable).first);
    expect(app.analytics.logged(AnalyticsEvent.decisionCompleted), isTrue);
    await tearDownApp(tester);
  });

  testWidgets('Home: cooking from what is at home suggests recipes', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(prefs: {'locale': 'tr'})))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Bugün neyi çözelim?'));
    await tester.enterText(find.byType(TextField).first, 'Evde yumurta, domates ve peynir var');
    await tester.tap(find.text('Çöz'));
    await pumpUntil(tester, find.text('Elindekilerle bunları yapabilirsin'));
    expect(find.text('Menemen'), findsOneWidget);
    expect(app.analytics.logged(AnalyticsEvent.recipeGenerated), isTrue);
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
      await tester.tap(find.text('AI').last);
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
      await pumpUntil(tester, find.textContaining('separated by commas'));
      await answer(tester, 'pizza, sushi');
      await chip(tester, 'Pick one for me');
      await pumpUntil(tester, find.textContaining('I pick'));
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
}

/// Plan is a tool inside Explore now.
Future<void> openPlan(WidgetTester tester) async {
  await tester.tap(find.text('Explore').last);
  await pumpUntil(tester, find.text('Plan'));
  await tester.tap(find.text('Plan').last);
  await pumpUntil(tester, find.byType(FloatingActionButton));
}
