/// Date helpers. Dayly keys daily data by local calendar day ("yyyy-MM-dd").
abstract final class Dates {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_pad2(d.month)}-${_pad2(d.day)}';

  static String monthKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_pad2(d.month)}';

  static DateTime parseDayKey(String key) {
    final p = key.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static int daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);

  static DateTime startOfNextMonth(DateTime d) => DateTime(d.year, d.month + 1);

  /// Monday-based start of week.
  static DateTime startOfWeek(DateTime d) {
    final day = dateOnly(d);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static DateTime addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days, d.hour, d.minute);

  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whole calendar days from [from] to [to]; DST-safe (computed in UTC).
  static int daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  /// Iterates calendar days in [from, to] inclusive.
  static Iterable<DateTime> range(DateTime from, DateTime to) sync* {
    var d = dateOnly(from);
    final end = dateOnly(to);
    while (!d.isAfter(end)) {
      yield d;
      d = DateTime(d.year, d.month, d.day + 1);
    }
  }

  static String _pad2(int v) => v.toString().padLeft(2, '0');
}

/// Time of day stored as minutes since midnight.
class DayTime {
  const DayTime(this.minutes) : assert(minutes >= 0 && minutes < 24 * 60);

  factory DayTime.hm(int h, int m) => DayTime(h * 60 + m);

  final int minutes;
  int get hour => minutes ~/ 60;
  int get minute => minutes % 60;

  @override
  bool operator ==(Object other) => other is DayTime && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
