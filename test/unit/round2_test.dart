import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/search/search_text.dart';
import 'package:lifeos/services/review/review_service.dart';

void main() {
  test('search ignores case and Turkish accents, needs every word', () {
    expect(searchMatches('Çay demle', 'cay'), isTrue);
    expect(searchMatches('İstanbul gezisi', 'ISTANBUL'), isTrue);
    expect(searchMatches('Market alışverişi', 'alisveris market'), isTrue);
    expect(searchMatches('Market alışverişi', 'market süt'), isFalse);
    expect(searchMatches('anything', '   '), isFalse);
  });

  test('a rating is asked only after real use, rarely', () {
    final now = DateTime(2026, 10, 8);
    bool ask({int installedDaysAgo = 30, int active = 10, List<DateTime> asked = const []}) => ReviewPolicy.shouldAsk(
      now: now,
      installedAt: now.subtract(Duration(days: installedDaysAgo)),
      activeDays: active,
      asked: asked,
    );
    expect(ask(), isTrue);
    expect(ask(installedDaysAgo: 2), isFalse);
    expect(ask(active: 2), isFalse);
    expect(ask(asked: [now.subtract(const Duration(days: 30))]), isFalse);
    expect(ask(asked: [now.subtract(const Duration(days: 150))]), isTrue);
    expect(
      ask(
        asked: [
          now.subtract(const Duration(days: 130)),
          now.subtract(const Duration(days: 260)),
          now.subtract(const Duration(days: 300)),
        ],
      ),
      isFalse,
    );
  });
}
