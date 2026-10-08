import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/domain/lio/daily_question.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/money_models.dart';
import 'package:lifeos/services/share/share_service.dart';

import 'features_test.dart' show bringIntoView;
import 'harness.dart';

const _home = 'What should we solve today?';

Future<TestApp> _open(WidgetTester tester, [String? route]) async {
  usePhoneViewport(tester);
  final app = (await tester.runAsync(() => TestApp.onboarded()))!;
  await tester.pumpWidget(app.widget());
  await pumpUntil(tester, find.text(_home));
  if (route != null) unawaited(GoRouter.of(tester.element(find.text(_home))).push(route));
  return app;
}

void main() {
  testWidgets('Question of the day: answer once, see the result and the streak', (tester) async {
    await _open(tester);
    final q = DailyQuestion.forDay(DateTime.now());
    final right = find.byKey(Key('quiz-option-${q.correct}'));
    await bringIntoView(tester, right);
    expect(find.text(q.question('en')), findsOneWidget);
    await tester.tap(right);
    await pumpUntil(tester, find.byKey(const Key('quiz-result')));
    expect(find.text('Correct! Lio got +1 energy.'), findsOneWidget);
    expect(find.textContaining('1-day streak'), findsOneWidget);
    // Answered: the options are locked.
    await tester.tap(find.byKey(Key('quiz-option-${(q.correct + 1) % 4}')), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Correct! Lio got +1 energy.'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Debts: add, split a bill into debts, remind and settle with undo', (tester) async {
    final app = await _open(tester, '/debts');
    await pumpUntil(tester, find.text('Nobody owes anybody. Add a debt or split a bill.'));

    await tester.tap(find.byKey(const Key('debt-add')));
    await pumpUntil(tester, find.byKey(const Key('debt-person')));
    await tester.enterText(find.byKey(const Key('debt-person')), 'Ali');
    await tester.enterText(find.byKey(const Key('debt-amount')), '300');
    await tester.tap(find.byKey(const Key('debt-save')));
    await pumpUntil(tester, find.text('Owes you ₺300'));

    await tester.tap(find.byKey(const Key('split-open')));
    await pumpUntil(tester, find.byKey(const Key('split-amount')));
    await tester.enterText(find.byKey(const Key('split-amount')), '1200');
    await tester.enterText(find.byKey(const Key('split-names')), 'Ali, Ayşe');
    await tester.pump();
    expect(find.text('3'), findsWidgets);
    expect(find.textContaining('₺400'), findsWidgets);
    await tester.ensureVisible(find.byKey(const Key('split-save')));
    await tester.tap(find.byKey(const Key('split-save')));
    await pumpUntil(tester, find.text('Owes you ₺700'));
    expect(find.text('Owes you ₺400'), findsOneWidget); // Ayşe

    await tester.tap(find.text('Remind').first);
    await tester.pump();
    expect((app.services.share as RecordingShareService).texts.single, contains('₺700'));

    await tester.tap(find.byKey(const Key('debt-settle-ali')));
    await pumpUntil(tester, find.text('Settled with Ali'));
    expect(find.text('Owes you ₺700'), findsNothing);
    await tester.tap(find.text('Undo'));
    await pumpUntil(tester, find.text('Owes you ₺700'));
    await tearDownApp(tester);
  });

  testWidgets('Medicines: add with a stock, take a dose (stock counts down)', (tester) async {
    final app = await _open(tester, '/meds');
    await pumpUntil(tester, find.byKey(const Key('meds-add')));
    await tester.tap(find.byKey(const Key('meds-add')));
    await pumpUntil(tester, find.byKey(const Key('med-name')));
    await tester.enterText(find.byKey(const Key('med-name')), 'Vitamin D');
    await tester.enterText(find.widgetWithText(TextField, 'Pills left (optional)'), '30');
    await tester.tap(find.byKey(const Key('med-save')));
    await pumpUntil(tester, find.text('30 days left'));
    final take = find.byWidgetPredicate(
      (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('take-'),
    );
    await tester.tap(take.first);
    await pumpUntil(tester, find.text('Taken'));
    final med = (await tester.runAsync(() => app.seededRepos.medications.getAll()))!.single;
    expect(med.stock, 29);
    expect((await tester.runAsync(() => app.seededRepos.medDoses.getAll()))!, hasLength(1));
    await tearDownApp(tester);
  });

  testWidgets('Subscriptions: yearly total, "still using?" → cancel with undo', (tester) async {
    final app = await _open(tester);
    await tester.runAsync(
      () => app.seededRepos.bills.save(
        RecurringBill(
          id: 'n',
          updatedAt: DateTime.now(),
          name: 'Netflix',
          amountMinor: 20000,
          category: ExpenseCategory.entertainment,
          dayOfMonth: 3,
        ),
      ),
    );
    unawaited(GoRouter.of(tester.element(find.text(_home))).push('/subscriptions'));
    await pumpUntil(tester, find.byKey(const Key('subs-yearly')));
    expect(find.text('₺2,400 a year'), findsOneWidget);
    await tester.tap(find.text('Netflix'));
    await pumpUntil(tester, find.text('Still using Netflix?'));
    await tester.tap(find.byKey(const Key('subs-cancel')));
    await pumpUntil(tester, find.textContaining('Netflix removed'));
    expect(find.text('₺0 a year'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await pumpUntil(tester, find.text('₺2,400 a year'));
    await tearDownApp(tester);
  });
}
