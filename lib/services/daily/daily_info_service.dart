import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_failure.dart';
import '../../domain/models/user_profile.dart';

/// Today's prayer times (Diyanet method), as local wall-clock "HH:mm".
class PrayerTimes {
  const PrayerTimes({required this.day, required this.times});

  /// `dd-MM-yyyy` the times are for.
  final String day;

  /// imsak, sunrise, noon, afternoon, evening, night → "HH:mm".
  final Map<String, String> times;

  static const order = ['imsak', 'gunes', 'ogle', 'ikindi', 'aksam', 'yatsi'];

  /// The next time after [now] (name, time), or null after the last one.
  (String, DateTime)? next(DateTime now) {
    for (final k in order) {
      final v = times[k];
      if (v == null) continue;
      final p = v.split(':');
      final at = DateTime(now.year, now.month, now.day, int.parse(p[0]), int.parse(p[1].substring(0, 2)));
      if (at.isAfter(now)) return (k, at);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {'d': day, 't': times};
  static PrayerTimes fromJson(Map<String, dynamic> j) =>
      PrayerTimes(day: j['d'] as String, times: (j['t'] as Map).cast<String, String>());
}

/// What one unit of each currency costs in Turkish lira.
typedef LiraRates = Map<String, double>;

abstract class DailyInfoProvider {
  Future<LiraRates> rates();
  Future<PrayerTimes> prayerTimes(Place place, DateTime day);
}

/// Frankfurter (ECB reference rates) and AlAdhan (Diyanet method 13): both
/// free, no key; only coordinates are sent for prayer times.
class HttpDailyInfoProvider implements DailyInfoProvider {
  HttpDailyInfoProvider([http.Client? client]) : _http = client ?? http.Client();
  final http.Client _http;

  static const currencies = ['USD', 'EUR', 'GBP'];

  @override
  Future<LiraRates> rates() async {
    final query = {'base': 'TRY', 'symbols': currencies.join(',')};
    http.Response? res;
    for (final uri in [
      Uri.https('api.frankfurter.dev', '/v1/latest', query),
      Uri.https('api.frankfurter.app', '/latest', query),
    ]) {
      try {
        res = await _http.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) break;
      } catch (_) {
        res = null;
      }
    }
    if (res == null || res.statusCode != 200) throw const AppFailure(FailureKind.unavailable);
    return parseRates(res.body);
  }

  /// `{"base":"TRY","rates":{"USD":0.024}}` → {USD: 41.6} (lira per unit).
  static LiraRates parseRates(String body) {
    final j = (jsonDecode(body) as Map).cast<String, dynamic>();
    final r = (j['rates'] as Map).cast<String, dynamic>();
    return {
      for (final e in r.entries)
        if ((e.value as num) > 0) e.key: 1 / (e.value as num).toDouble(),
    };
  }

  @override
  Future<PrayerTimes> prayerTimes(Place place, DateTime day) async {
    String two(int v) => v.toString().padLeft(2, '0');
    final d = '${two(day.day)}-${two(day.month)}-${day.year}';
    final uri = Uri.https('api.aladhan.com', '/v1/timings/$d', {
      'latitude': place.latitude.toStringAsFixed(3),
      'longitude': place.longitude.toStringAsFixed(3),
      'method': '13',
    });
    final res = await _http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw AppFailure(FailureKind.unavailable, cause: res.statusCode);
    return parsePrayer(res.body, d);
  }

  static PrayerTimes parsePrayer(String body, String day) {
    final j = (jsonDecode(body) as Map).cast<String, dynamic>();
    final t = ((j['data'] as Map)['timings'] as Map).cast<String, dynamic>();
    String hm(String k) => (t[k] as String).split(' ').first;
    return PrayerTimes(
      day: day,
      times: {
        'imsak': hm('Fajr'),
        'gunes': hm('Sunrise'),
        'ogle': hm('Dhuhr'),
        'ikindi': hm('Asr'),
        'aksam': hm('Maghrib'),
        'yatsi': hm('Isha'),
      },
    );
  }
}

/// No network (tests, or nothing configured).
class NoDailyInfoProvider implements DailyInfoProvider {
  const NoDailyInfoProvider({this.fakeRates, this.fakePrayer});
  final LiraRates? fakeRates;
  final PrayerTimes? fakePrayer;

  @override
  Future<LiraRates> rates() async => fakeRates ?? (throw const AppFailure(FailureKind.unavailable));

  @override
  Future<PrayerTimes> prayerTimes(Place place, DateTime day) async =>
      fakePrayer ?? (throw const AppFailure(FailureKind.unavailable));
}

/// Caches rates for 6 hours and prayer times per day and place; shows the
/// last known values offline.
class DailyInfoService {
  DailyInfoService(this._provider, this._prefs);
  final DailyInfoProvider _provider;
  final SharedPreferences _prefs;

  Future<(LiraRates, DateTime)?> rates() async {
    final raw = _prefs.getString('rates_cache');
    (LiraRates, DateTime)? cached;
    if (raw != null) {
      try {
        final j = (jsonDecode(raw) as Map).cast<String, dynamic>();
        cached = (
          (j['r'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
          DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
        );
      } catch (_) {}
    }
    if (cached != null && DateTime.now().difference(cached.$2) < const Duration(hours: 6)) return cached;
    try {
      final r = await _provider.rates();
      final now = DateTime.now();
      await _prefs.setString('rates_cache', jsonEncode({'r': r, 'at': now.millisecondsSinceEpoch}));
      return (r, now);
    } catch (_) {
      return cached;
    }
  }

  Future<PrayerTimes?> prayerTimes(Place place, DateTime day) async {
    final key = 'prayer_${place.latitude.toStringAsFixed(2)}_${place.longitude.toStringAsFixed(2)}';
    String two(int v) => v.toString().padLeft(2, '0');
    final d = '${two(day.day)}-${two(day.month)}-${day.year}';
    final raw = _prefs.getString(key);
    if (raw != null) {
      try {
        final p = PrayerTimes.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
        if (p.day == d) return p;
      } catch (_) {}
    }
    try {
      final p = await _provider.prayerTimes(place, day);
      await _prefs.setString(key, jsonEncode(p.toJson()));
      return p;
    } catch (_) {
      return null;
    }
  }
}
