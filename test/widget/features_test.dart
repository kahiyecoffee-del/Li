import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/services/analytics/analytics_service.dart';

import 'harness.dart';

void main() {
  testWidgets('Money: smart input "250 lunch" saves a Food expense', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded()))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Your day at a glance.'));

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
    await pumpUntil(tester, find.text('Your day at a glance.'));
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
    await tester.tap(find.text('Plan').last);
    await pumpUntil(tester, find.byType(FloatingActionButton));
    await tester.tap(find.text('This week'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Team meeting'), findsNothing);

    await tester.tap(find.text('AI').last);
    await pumpUntil(tester, find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await pumpUntil(tester, find.textContaining('Done'));
    expect(app.analytics.logged(AnalyticsEvent.aiActionConfirmed), isTrue);

    await tester.tap(find.text('Plan').last);
    await pumpUntil(tester, find.text('Team meeting'));
    await tearDownApp(tester);
  });

  testWidgets('Turkish + dark mode render the Daily Brief', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(prefs: {'locale': 'tr', 'themeMode': 'dark'})))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Gününe hızlı bir bakış.'));
    final ctx = tester.element(find.text('Gününe hızlı bir bakış.'));
    expect(Theme.of(ctx).brightness, Brightness.dark);
    expect(find.text('Yaşam Skoru'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Offline banner is shown and core features still work', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Offline — changes are saved and will sync later.'));
    await tester.tap(find.text('Plan').last);
    await pumpUntil(tester, find.byType(FloatingActionButton));
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
    await pumpUntil(tester, find.text('Your day at a glance.'));
    await tester.tap(find.text('Life').last);
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

  testWidgets('Offline: with the on-device model installed the assistant answers locally', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(online: false, offlineModelReady: true)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Your day at a glance.'));
    await tester.tap(find.text('AI').last);
    await pumpUntil(tester, find.text('Offline mode'));
    await tester.enterText(find.byType(TextField).last, 'Any tip for today?');
    await tester.tap(find.byTooltip('Send'));
    await pumpUntil(tester, find.text('Offline tip: drink water.'));
    expect(find.text('Offline answer · on-device model'), findsOneWidget);
    expect(app.ai.requests, isEmpty, reason: 'no cloud call, no credits used');
    await tearDownApp(tester);
  });

  testWidgets('Lio: tap for a tip, then jump to the assistant', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(prefs: {'showLio': true})))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Your day at a glance.'));
    final lio = find.bySemanticsLabel('Lio, your companion');
    await pumpUntil(tester, lio);
    await tester.tap(lio);
    await pumpUntil(tester, find.text('Ask Lio'));
    expect(find.text('Another one'), findsOneWidget);
    await tester.tap(find.text('Ask Lio'));
    await pumpUntil(tester, find.text('How can I help today?'));
    await tearDownApp(tester);
  });
}
