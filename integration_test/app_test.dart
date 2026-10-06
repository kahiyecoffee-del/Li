// On-device end-to-end test (run with an emulator or device attached):
//   flutter test integration_test/app_test.dart
//
// Uses the same fake service graph as the widget tests so it is
// deterministic and needs no Firebase project or network.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/widget/harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch to Home', (tester) async {
    final app = await TestApp.create();
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await pumpUntil(tester, find.text("What's your name?"));
    await tester.enterText(find.byType(TextField), 'Eray');
    await tester.tap(find.text('Next'));
    await pumpUntil(tester, find.text('What do you want to improve?'));
    await tester.tap(find.text('Money'));
    await tester.tap(find.text('Next'));
    await pumpUntil(tester, find.text('Typical monthly income'));
    await tester.enterText(find.byType(TextField).first, '30000');
    await tester.tap(find.text('Next'));
    for (var i = 0; i < 8 && find.text('Skip').evaluate().isNotEmpty; i++) {
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await pumpUntil(tester, find.text('Solve my first problem'));
    await tester.tap(find.text('Solve my first problem'));
    await pumpUntil(tester, find.text('What should we solve today?'));
    await tearDownApp(tester);
  });
}
