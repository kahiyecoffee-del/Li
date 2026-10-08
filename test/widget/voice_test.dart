import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/services/analytics/analytics_service.dart';
import 'package:lifeos/services/assistant/assistant_service.dart';

import 'harness.dart';

void main() {
  testWidgets('Voice: the mic writes what was said into the capture box', (tester) async {
    usePhoneViewport(tester);
    final voice = FakeVoice('tomorrow 15:00 dentist 30 min');
    final app = (await tester.runAsync(() => TestApp.onboarded(voice: voice)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));

    await tester.ensureVisible(find.byKey(const Key('capture-field')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('voice-mic')).first);
    await pumpUntil(tester, find.byKey(const Key('capture-preview')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Tomorrow'), findsWidgets);
    expect(voice.localeId, startsWith('en_'));
    expect(app.analytics.events.map((e) => e.$1), contains(AnalyticsEvent.voiceInputUsed));
    await tearDownApp(tester);
  });

  testWidgets('Siri / Assistant: "add" saves to the right place, "open" opens the screen', (tester) async {
    usePhoneViewport(tester);
    final commands = StreamController<AssistantCommand>();
    final app = (await tester.runAsync(() => TestApp.onboarded(assistant: NoAssistant(commands.stream))))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));

    commands.add(const AssistantCommand.add('tomorrow 15:00 dentist 30 min'));
    await pumpUntil(tester, find.textContaining('Planned: Dentist'));
    final task = (await tester.runAsync(() => app.seededRepos.tasks.getAll()))!.single;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(task.scheduledAt, DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 15));

    commands.add(const AssistantCommand.add('250 TL market'));
    await pumpUntil(tester, find.textContaining('Saved: '));
    final tx = (await tester.runAsync(() => app.seededRepos.transactions.getAll()))!;
    expect(tx.single.amountMinor, 25000);

    commands.add(const AssistantCommand.open('/plan'));
    await pumpUntil(tester, find.byKey(const Key('plan-composer')));
    await commands.close();
    await tearDownApp(tester);
  });
}
