// Walks the main screens in Turkish with sample data and saves a screenshot
// of each, so the app can be reviewed without a phone:
//   flutter drive --driver test_driver/integration_test.dart --target integration_test/tour_test.dart
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lifeos/data/repositories/journal_repository.dart';
import 'package:lifeos/data/repositories/user_repos.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/money_models.dart';
import 'package:lifeos/domain/models/task_item.dart';

import '../test/widget/harness.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await binding.takeScreenshot(name);
  }

  testWidgets('tour of the main screens (tr)', (tester) async {
    final app = (await tester.runAsync(() => TestApp.onboarded(prefs: {'locale': 'tr', 'showLio': true})))!;
    await tester.runAsync(() async {
      final repos = UserRepos(app.seeded!, journalKeys: MemoryJournalKeyStore());
      final now = DateTime.now();
      DateTime at(int h, [int m = 0]) => DateTime(now.year, now.month, now.day, h, m);
      var n = 0;
      TaskItem task(String title, DateTime? when, {bool done = false, TaskCategory c = TaskCategory.personal}) =>
          TaskItem(
            id: 'tour-task-${n++}',
            updatedAt: now,
            createdAt: now,
            title: title,
            category: c,
            scheduledAt: when,
            completedAt: done ? now : null,
          );
      await repos.tasks.saveAll([
        task('Spor salonu', at(8), done: true, c: TaskCategory.health),
        task("Ali'ye e-posta", null, c: TaskCategory.work),
        task('Market alışverişi', at(17, 30), c: TaskCategory.errands),
        task('Annemi ara', at(19), c: TaskCategory.social),
      ]);
      MoneyTransaction spend(int lira, ExpenseCategory c, String d) => MoneyTransaction(
        id: 'tour-tx-${n++}',
        updatedAt: now,
        type: TransactionType.expense,
        amountMinor: lira * 100,
        currency: 'TRY',
        category: c,
        date: now,
        description: d,
      );
      await repos.transactions.saveAll([
        spend(85, ExpenseCategory.food, 'Kahve ve simit'),
        spend(240, ExpenseCategory.food, 'Öğle yemeği'),
        spend(60, ExpenseCategory.transport, 'Metro'),
      ]);
    });

    await tester.pumpWidget(app.widget());
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    await pumpUntil(tester, find.text('Bugün neyi çözelim?'));
    await shot(tester, '01-ana-sayfa');

    await tester.tap(find.text('Çöz'));
    await pumpUntil(tester, find.text('Bugün nasıl yardımcı olabilirim?'));
    await shot(tester, '02-lio-menu');

    Future<void> ask(String q) async {
      await tester.enterText(find.byType(TextField).last, q);
      await tester.tap(find.byTooltip('Gönder').last);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    Future<void> chip(String label) async {
      await pumpUntil(tester, find.widgetWithText(ActionChip, label));
      // Screen sizes differ (iPhone vs Pixel): bring the chip on screen first.
      await tester.ensureVisible(find.widgetWithText(ActionChip, label).last);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.widgetWithText(ActionChip, label).last);
      await tester.pump(const Duration(milliseconds: 300));
    }

    await ask('3.000 TL param kaldı, ay sonuna 20 gün var');
    await pumpUntil(tester, find.textContaining('harcayabilirsin'));
    await shot(tester, '03-param-yeter-mi');

    await ask('1 L 45 TL mi yoksa 1,5 L 60 TL mi daha ucuz?');
    await pumpUntil(tester, find.textContaining('daha ucuz'));
    await shot(tester, '04-hangisi-ucuz');

    await chip('Ana menü');
    await chip('Yaz');
    await chip('İzin isteme');
    await chip('Resmi');
    await ask('Ahmet Bey');
    await ask('Cuma günü');
    await ask('ailevi bir durum');
    await pumpUntil(tester, find.textContaining('izin talep ediyorum'));
    await shot(tester, '05-mesaj-sablonu');

    await chip('Ana menü');
    await chip('Karar ver');
    await ask('pizza, sushi');
    await chip('Benim yerime seç');
    await pumpUntil(tester, find.textContaining('Seçimim'));
    await shot(tester, '06-karar');

    await ask('Evde yumurta, domates, peynir ve ekmek var');
    await pumpUntil(tester, find.text('Elindekilerle bunları yapabilirsin'));
    await shot(tester, '07-yemek');

    // Close the keyboard: the tab bar hides while typing.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await pumpUntil(tester, find.text('Keşfet'));
    await tester.tap(find.text('Keşfet').last);
    await pumpUntil(tester, find.text('Takip'));
    await shot(tester, '08-kesfet');

    await tester.tap(find.text('Ana sayfa').last);
    await pumpUntil(tester, find.text('Bugün neyi çözelim?'));
    await tester.tap(find.text('Günlük').first);
    await pumpUntil(tester, find.text('Nasıl hissediyorsun?'));
    await tester.tap(find.text('🙂'));
    await tester.tap(find.byTooltip('Ekle'));
    await shot(tester, '09-gunluk');

    // Day planner: one-line add.
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.text('Bugün neyi çözelim?'));
    await tester.tap(find.text('Keşfet').last);
    await pumpUntil(tester, find.text('Planla'));
    await tester.tap(find.text('Planla').last);
    await pumpUntil(tester, find.byKey(const Key('plan-composer')));
    await tester.enterText(find.byType(TextField).last, '18:30 spor 45 dk');
    await tester.tap(find.byTooltip('Ekle').last);
    await pumpUntil(tester, find.text('Spor'));
    FocusManager.instance.primaryFocus?.unfocus();
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await shot(tester, '10-plan');
  });
}
