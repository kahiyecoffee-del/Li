import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/lists/list_share.dart';
import 'package:lifeos/services/daily/daily_info_service.dart';
import 'package:lifeos/services/notifications/notification_planner.dart';
import 'package:lifeos/services/notifications/open_hours.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('rates are turned into lira per unit', () {
    final r = HttpDailyInfoProvider.parseRates('{"amount":1.0,"base":"TRY","rates":{"USD":0.025,"EUR":0.02}}');
    expect(r['USD'], closeTo(40, 0.001));
    expect(r['EUR'], closeTo(50, 0.001));
  });

  test('prayer times parse and tell the next one', () {
    final p = HttpDailyInfoProvider.parsePrayer(
      '{"code":200,"data":{"timings":{"Fajr":"05:41 (+03)","Sunrise":"07:06","Dhuhr":"12:56","Asr":"16:04","Maghrib":"18:33","Isha":"19:53"}}}',
      '08-10-2026',
    );
    expect(p.times['imsak'], '05:41');
    final next = p.next(DateTime(2026, 10, 8, 17));
    expect(next!.$1, 'aksam');
    expect(next.$2, DateTime(2026, 10, 8, 18, 33));
    expect(p.next(DateTime(2026, 10, 8, 23)), isNull);
  });

  test('a shared shopping list round-trips and other formats are understood', () {
    final text = shoppingShareText(['Süt', 'Ekmek'], header: 'Alışveriş listesi', footer: 'Dayly ile hazırlandı');
    expect(text, '🛒 Alışveriş listesi\n☐ Süt\n☐ Ekmek\n\nDayly ile hazırlandı');
    expect(parseSharedList(text, footer: 'Dayly ile hazırlandı'), ['Süt', 'Ekmek']);
    expect(parseSharedList('- yumurta\n• peynir\n1. domates\n[x] zeytin'), ['yumurta', 'peynir', 'domates', 'zeytin']);
    expect(parseSharedList('süt, ekmek; yumurta'), ['süt', 'ekmek', 'yumurta']);
    expect(parseSharedList(''), isEmpty);
  });

  test('nudges move to the hour the app is usually opened', () {
    expect(NotificationPlanner.bestHour({}, preferred: 21, min: 19, max: 22), 21);
    expect(NotificationPlanner.bestHour({20: 6, 21: 1, 9: 5}, preferred: 21, min: 19, max: 22), 20);
    // Outside the window does not count.
    expect(NotificationPlanner.bestHour({9: 20}, preferred: 21, min: 19, max: 22), 21);
  });

  test('open hours keep two weeks, one entry per day and hour', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    final o = OpenHours(p);
    await o.record(DateTime(2026, 10, 1, 20, 5));
    await o.record(DateTime(2026, 10, 1, 20, 40));
    await o.record(DateTime(2026, 10, 2, 20));
    await o.record(DateTime(2026, 10, 2, 8));
    expect(o.counts(), {20: 2, 8: 1});
    await o.record(DateTime(2026, 10, 20, 9));
    expect(o.counts(), {9: 1});
  });
}
