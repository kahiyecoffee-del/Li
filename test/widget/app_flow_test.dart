import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/services/analytics/analytics_service.dart';

import 'harness.dart';

void main() {
  testWidgets('first run: welcome → onboarding → personalized Home', (tester) async {
    usePhoneViewport(tester);
    final app = await TestApp.create();
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Get started'));

    await tester.tap(find.text('Get started'));
    await pumpUntil(tester, find.text("What's your name?"));

    await tester.enterText(find.byType(TextField), 'Eray');
    await tester.pump();
    await tester.tap(find.text('Next'));
    await pumpUntil(tester, find.text('What do you want to improve?'));

    await tester.tap(find.text('Money'));
    await tester.tap(find.text('Health'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await pumpUntil(tester, find.text('Typical monthly income'));

    await tester.enterText(find.byType(TextField).first, '45000');
    await tester.tap(find.text('Next'));
    await pumpUntil(tester, find.text('Monthly savings goal'));

    // Skip the remaining optional steps.
    for (var i = 0; i < 6 && find.text('Skip').evaluate().isNotEmpty; i++) {
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await pumpUntil(tester, find.text('Your LifeOS is ready.'));
    await tester.tap(find.text('Open my day'));
    await pumpUntil(tester, find.textContaining('Eray'));

    expect(find.text('Your day at a glance.'), findsOneWidget);
    // Money focus + income → safe spending card; Health focus → starter water habit goal.
    await tester.scrollUntilVisible(find.text("Today's safe spending"), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Water'), findsWidgets);
    expect(app.analytics.logged(AnalyticsEvent.onboardingStarted), isTrue);
    expect(app.analytics.logged(AnalyticsEvent.onboardingCompleted), isTrue);
    expect(app.analytics.logged(AnalyticsEvent.dailyBriefViewed), isTrue);

    await tearDownApp(tester);
  });
}
