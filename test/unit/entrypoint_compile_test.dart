import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/bootstrap.dart' as bootstrap;
import 'package:lifeos/main.dart' as app;

/// Compiles the real entry point and production service graph (Firebase,
/// AdMob, Billing, ML Kit, notifications) so type errors there fail CI even
/// though widget tests use fakes.
void main() {
  test('entry point and bootstrap compile', () {
    expect(app.main, isA<Function>());
    expect(bootstrap.buildServices, isA<Function>());
    expect(bootstrap.firebaseMessagingBackgroundHandler, isA<Function>());
  });
}
