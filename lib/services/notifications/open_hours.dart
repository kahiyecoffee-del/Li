import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/dates.dart';

/// Remembers at which hours the app was opened over the last two weeks (on
/// the device only), so nudges can come when the person usually looks.
class OpenHours {
  OpenHours(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'open_log', _days = 14;

  Future<void> record(DateTime now) async {
    final entry = '${Dates.dayKey(now)}:${now.hour}';
    final cutoff = Dates.dayKey(Dates.addDays(Dates.dateOnly(now), -_days));
    final log = [
      for (final e in _prefs.getStringList(_key) ?? const <String>[])
        if (e.split(':').first.compareTo(cutoff) > 0) e,
    ];
    if (log.contains(entry)) return;
    await _prefs.setStringList(_key, [...log, entry]);
  }

  /// Hour → number of days the app was opened in that hour.
  Map<int, int> counts() {
    final out = <int, int>{};
    for (final e in _prefs.getStringList(_key) ?? const <String>[]) {
      final h = int.tryParse(e.split(':').last);
      if (h != null) out[h] = (out[h] ?? 0) + 1;
    }
    return out;
  }
}
