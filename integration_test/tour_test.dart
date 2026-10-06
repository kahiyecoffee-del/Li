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
    await pumpUntil(tester, find.text('Gününe hızlı bir bakış.'));
    await shot(tester, '01-ana-sayfa');

    await tester.tap(find.text('Plan').last);
    await pumpUntil(tester, find.text('Annemi ara'));
    await shot(tester, '02-plan');

    await tester.tap(find.text('Yaşam').last);
    await pumpUntil(tester, find.text('Para'));
    await shot(tester, '03-yasam');

    await tester.tap(find.text('Para').last);
    await pumpUntil(tester, find.text('Harcama ekle'));
    await shot(tester, '04-para');
    await tester.binding.handlePopRoute();
    await pumpUntil(tester, find.text('YZ'));

    await tester.tap(find.text('YZ').last);
    await pumpUntil(tester, find.text('Bugün nasıl yardımcı olabilirim?'));
    await shot(tester, '05-lio-sohbet');

    for (final q in ['Bugün ne kadar harcayabilirim?', 'Günümü planla']) {
      await tester.enterText(find.byType(TextField).last, q);
      await tester.tap(find.byTooltip('Gönder'));
      await pumpUntil(tester, find.text(q));
      // Let Lio finish answering before the next question (slow emulators).
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
        await tester.pump(const Duration(milliseconds: 200));
      }
    }
    await shot(tester, '06-lio-cevaplar');
  });
}
