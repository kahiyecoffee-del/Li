// Renders real screenshots (real fonts) for design review:
//   flutter test test_tools/screens_test.dart --update-goldens
// Output: test_tools/out/*.png. Not part of the regular test suite.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/habit.dart';
import 'package:lifeos/domain/models/money_models.dart';
import 'package:lifeos/domain/models/task_item.dart';

import '../test/widget/harness.dart';

Future<void> _loadFonts() async {
  Future<ByteData> file(String p) async => ByteData.sublistView(await File(p).readAsBytes());
  final jakarta = FontLoader('Jakarta');
  for (final w in ['400Regular', '500Medium', '600SemiBold', '700Bold']) {
    jakarta.addFont(file('assets/fonts/PlusJakartaSans_$w.ttf'));
  }
  await jakarta.load();
  final fraunces = FontLoader('Fraunces')
    ..addFont(file('assets/fonts/Fraunces_500Medium.ttf'))
    ..addFont(file('assets/fonts/Fraunces_600SemiBold.ttf'));
  await fraunces.load();
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter-sdk/flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(file('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> _shot(WidgetTester tester, String name) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('out/$name.png'));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await tester0();
  });

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('screens $mode', (tester) async {
      usePhoneViewport(tester);
      final app = (await tester.runAsync(
        () => TestApp.onboarded(prefs: {'locale': 'tr', 'showLio': true, if (dark) 'themeMode': 'dark'}),
      ))!;
      final now = DateTime.now();
      final d = DateTime(now.year, now.month, now.day);
      TaskItem t(
        String id,
        String title,
        int h,
        int m,
        int mins,
        TaskCategory c, {
        bool done = false,
        bool timed = true,
      }) => TaskItem(
        id: id,
        updatedAt: now,
        title: title,
        category: c,
        estimatedMinutes: mins,
        scheduledAt: timed ? DateTime(d.year, d.month, d.day, h, m) : null,
        deadline: timed ? null : d,
        completedAt: done ? now : null,
        createdAt: now,
      );
      await tester.runAsync(() async {
        final repos = app.seededRepos;
        for (final x in [
          t('1', 'Sabah koşusu', 7, 30, 40, TaskCategory.health, done: true),
          t('2', 'Ekip toplantısı', 10, 0, 60, TaskCategory.work),
          t('3', 'Annemi ara', 13, 30, 20, TaskCategory.social),
          t('4', 'Market alışverişi', 18, 0, 45, TaskCategory.errands),
          t('5', 'Kitap oku', 0, 0, 30, TaskCategory.learning, timed: false),
          t('6', 'Kahve molası', 10, 30, 20, TaskCategory.personal),
        ]) {
          await repos.tasks.save(x);
        }
        await repos.habits.save(
          Habit(id: 'h1', updatedAt: now, name: 'Su iç', type: HabitType.water, targetPerDay: 8, createdAt: now),
        );
        await repos.habits.save(
          Habit(id: 'h2', updatedAt: now, name: 'Kitap', type: HabitType.reading, createdAt: now),
        );
        await repos.bills.save(
          RecurringBill(
            id: 'b1',
            updatedAt: now,
            name: 'Elektrik',
            amountMinor: 45000,
            category: ExpenseCategory.bills,
            dayOfMonth: now.day,
          ),
        );
      });
      await tester.pumpWidget(app.widget());
      await pumpUntil(tester, find.text('Bugün neyi çözelim?'));
      await _shot(tester, '$mode-home');
      await tester.tap(find.byKey(const Key('lio-companion')), warnIfMissed: false);
      await pumpUntil(tester, find.text('Nasıl yardım edeyim?'));
      await tester.pump(const Duration(milliseconds: 600));
      await _shot(tester, '$mode-lio-help');
      await tester.binding
          .handlePopRoute(); // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(find.byKey(const Key('capture-field')), 'yarın 15:00 dişçi 30 dk');
      await tester.pump();
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await _shot(tester, '$mode-home-capture');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Keşfet').last);
      await pumpUntil(tester, find.text('Planla'));
      await tester.tap(find.text('Planla').last);
      await pumpUntil(tester, find.byKey(const Key('plan-composer')));
      await _shot(tester, '$mode-plan');
      await tester.tap(find.byKey(const Key('composer-time')));
      await pumpUntil(tester, find.text('Ne zaman, ne kadar süre?'));
      await tester.tap(find.text('45 dk').last);
      await _shot(tester, '$mode-time-sheet');
      await tester.tap(find.text('Tamam').last);
      await pumpUntil(tester, find.textContaining('· 45 dk'));
      await _shot(tester, '$mode-plan-chosen');
      await tester.runAsync(
        () => Scrollable.ensureVisible(tester.element(find.text('Ekip toplantısı').last), alignment: 0.3),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Ekip toplantısı').last);
      await pumpUntil(tester, find.byKey(const Key('editor-time')));
      await _shot(tester, '$mode-editor');
      await tester.binding
          .handlePopRoute(); // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      await tester.pump(const Duration(milliseconds: 600));
      await tester.drag(find.byType(ListView).last, const Offset(0, -600));
      await _shot(tester, '$mode-plan-2');
      await tester.binding
          .handlePopRoute(); // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      await pumpUntil(tester, find.text('Para'));
      await tester.tap(find.text('Para').last);
      await pumpUntil(tester, find.text('Özet'));
      await _shot(tester, '$mode-money');
      await tester.binding
          .handlePopRoute(); // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      await pumpUntil(tester, find.text('Yemek'));
      await _shot(tester, '$mode-explore');
      await tester.ensureVisible(find.text('Yemek').last);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Yemek').last);
      await pumpUntil(tester, find.text('Tarifler'));
      await _shot(tester, '$mode-food');
      await tester.binding
          .handlePopRoute(); // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      await pumpUntil(tester, find.text('Keşfet'));
      await tester.scrollUntilVisible(find.text('Rutinler'), -300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.text('Rutinler'));
      await tester.tap(find.text('Rutinler'));
      await pumpUntil(tester, find.text('Hazır rutinler'));
      await _shot(tester, '$mode-routines');
      await tester.binding
          .handlePopRoute(); // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      await pumpUntil(tester, find.text('Haftalık değerlendirme'));
      await tester.ensureVisible(find.text('Haftalık değerlendirme'));
      await tester.tap(find.text('Haftalık değerlendirme'));
      await pumpUntil(tester, find.text('Gelecek hafta için üç odak'));
      await _shot(tester, '$mode-review');
      await tester.binding
          .handlePopRoute(); // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      await pumpUntil(tester, find.text('Bugün'));
      await tester.scrollUntilVisible(find.text('Bugün'), -300, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Bugün').last);
      await pumpUntil(tester, find.byKey(const Key('today-rates')));
      await tester.tap(find.byKey(const Key('today-prayer-toggle')));
      await tester.pump(const Duration(milliseconds: 600));
      await _shot(tester, '$mode-today');
      await tearDownApp(tester);
    });
  }
}

Future<void> tester0() => _loadFonts();
