import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/json.dart';
import '../../domain/models/user_profile.dart';

enum WeatherCondition { clear, partlyCloudy, cloudy, fog, drizzle, rain, snow, thunderstorm }

class Weather {
  const Weather({
    required this.temperatureC,
    required this.condition,
    required this.rainProbability,
    required this.highC,
    required this.lowC,
    required this.fetchedAt,
    required this.placeName,
  });

  factory Weather.fromJson(Map<String, dynamic> j) => Weather(
    temperatureC: J.dbl(j, 't'),
    condition: J.enumByName(WeatherCondition.values, j['c'], WeatherCondition.clear),
    rainProbability: J.integer(j, 'p'),
    highC: J.dbl(j, 'hi'),
    lowC: J.dbl(j, 'lo'),
    fetchedAt: J.date(j, 'at') ?? DateTime(2000),
    placeName: J.str(j, 'n'),
  );

  final double temperatureC;
  final WeatherCondition condition;
  final int rainProbability;
  final double highC;
  final double lowC;
  final DateTime fetchedAt;
  final String placeName;

  Map<String, dynamic> toJson() => {
    't': temperatureC,
    'c': condition.name,
    'p': rainProbability,
    'hi': highC,
    'lo': lowC,
    'at': fetchedAt.millisecondsSinceEpoch,
    'n': placeName,
  };
}

/// Weather provider abstraction (swap Open-Meteo for another API here).
abstract class WeatherProvider {
  Future<Weather> current(Place place);
  Future<List<Place>> searchPlaces(String query, String language);
}

/// Open-Meteo: free, no API key, no personal data sent beyond coordinates.
class OpenMeteoProvider implements WeatherProvider {
  OpenMeteoProvider([http.Client? client]) : _http = client ?? http.Client();

  final http.Client _http;

  @override
  Future<Weather> current(Place place) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': place.latitude.toStringAsFixed(3),
      'longitude': place.longitude.toStringAsFixed(3),
      'current': 'temperature_2m,weather_code',
      'daily': 'temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'forecast_days': '1',
      'timezone': 'auto',
    });
    final res = await _http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw AppFailure(FailureKind.unavailable, cause: res.statusCode);
    final j = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    final cur = J.map(j, 'current');
    final daily = J.map(j, 'daily');
    double first(String k) =>
        (daily[k] is List && (daily[k] as List).isNotEmpty) ? ((daily[k] as List).first as num? ?? 0).toDouble() : 0;
    return Weather(
      temperatureC: J.dbl(cur, 'temperature_2m'),
      condition: conditionFor(J.integer(cur, 'weather_code')),
      rainProbability: first('precipitation_probability_max').round(),
      highC: first('temperature_2m_max'),
      lowC: first('temperature_2m_min'),
      fetchedAt: DateTime.now(),
      placeName: place.name,
    );
  }

  @override
  Future<List<Place>> searchPlaces(String query, String language) async {
    if (query.trim().length < 2) return const [];
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query.trim(),
      'count': '8',
      'language': language,
      'format': 'json',
    });
    final res = await _http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw AppFailure(FailureKind.unavailable, cause: res.statusCode);
    final j = (jsonDecode(res.body) as Map).cast<String, dynamic>();
    return J.mapList(j, 'results').map((r) {
      final admin = J.str(r, 'admin1');
      final country = J.str(r, 'country');
      final label = [J.str(r, 'name'), if (admin.isNotEmpty) admin, if (country.isNotEmpty) country].join(', ');
      return Place(name: label, latitude: J.dbl(r, 'latitude'), longitude: J.dbl(r, 'longitude'));
    }).toList();
  }

  /// WMO weather interpretation codes.
  static WeatherCondition conditionFor(int code) => switch (code) {
    0 => WeatherCondition.clear,
    1 || 2 => WeatherCondition.partlyCloudy,
    3 => WeatherCondition.cloudy,
    45 || 48 => WeatherCondition.fog,
    >= 51 && <= 57 => WeatherCondition.drizzle,
    >= 61 && <= 67 || >= 80 && <= 82 => WeatherCondition.rain,
    >= 71 && <= 77 || 85 || 86 => WeatherCondition.snow,
    >= 95 => WeatherCondition.thunderstorm,
    _ => WeatherCondition.cloudy,
  };
}

/// Caches weather for 30 minutes to avoid unnecessary calls and to show the
/// last known value offline.
class WeatherService {
  WeatherService(this._provider, this._prefs);

  final WeatherProvider _provider;
  final SharedPreferences _prefs;
  static const ttl = Duration(minutes: 30);
  static const _key = 'weather_cache';

  Weather? cached() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Weather.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  Future<Weather?> get(Place place, {bool force = false}) async {
    final c = cached();
    if (!force && c != null && c.placeName == place.name && DateTime.now().difference(c.fetchedAt) < ttl) return c;
    try {
      final w = await _provider.current(place);
      await _prefs.setString(_key, jsonEncode(w.toJson()));
      return w;
    } catch (_) {
      return c; // stale is better than nothing when offline
    }
  }

  Future<List<Place>> search(String q, String lang) => _provider.searchPlaces(q, lang);
}

/// Optional device location (coarse). Never required: users can pick a city.
class LocationService {
  Future<Place?> currentPlace(String label) async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10)),
    );
    // Rounded to ~1 km: enough for weather, less precise for privacy.
    double r(double v) => (v * 100).round() / 100;
    return Place(name: label, latitude: r(pos.latitude), longitude: r(pos.longitude));
  }
}
