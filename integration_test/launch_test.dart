// Starts the real app (real plugins, no Firebase config) and checks it gets
// to the welcome screen without crashing. Run with test_driver to save the
// screenshot:
//   flutter drive --driver test_driver/integration_test.dart --target integration_test/launch_test.dart
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lifeos/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real app launches to the welcome screen', (tester) async {
    await app.main();
    for (var i = 0; i < 100 && find.byType(FilledButton).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(FilledButton), findsWidgets);
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    await binding.takeScreenshot('00-launch');
  });
}
