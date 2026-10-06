/// Defensive JSON readers. Data may come from older app versions, Firestore
/// or AI output, so every read tolerates missing or mistyped values.
abstract final class J {
  static String str(Map<String, dynamic> j, String k, [String fallback = '']) {
    final v = j[k];
    return v is String ? v : fallback;
  }

  static String? strOrNull(Map<String, dynamic> j, String k) {
    final v = j[k];
    return v is String && v.isNotEmpty ? v : null;
  }

  static int integer(Map<String, dynamic> j, String k, [int fallback = 0]) {
    final v = j[k];
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static int? intOrNull(Map<String, dynamic> j, String k) {
    final v = j[k];
    if (v is int) return v;
    if (v is num) return v.round();
    return null;
  }

  static double dbl(Map<String, dynamic> j, String k, [double fallback = 0]) {
    final v = j[k];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool boolean(Map<String, dynamic> j, String k, [bool fallback = false]) {
    final v = j[k];
    return v is bool ? v : fallback;
  }

  static DateTime? date(Map<String, dynamic> j, String k) {
    final v = j[k];
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static List<String> strList(Map<String, dynamic> j, String k) {
    final v = j[k];
    if (v is List) return v.whereType<String>().toList();
    return const [];
  }

  static Map<String, dynamic> map(Map<String, dynamic> j, String k) {
    final v = j[k];
    if (v is Map) return v.map((key, value) => MapEntry('$key', value));
    return const {};
  }

  static List<Map<String, dynamic>> mapList(Map<String, dynamic> j, String k) {
    final v = j[k];
    if (v is! List) return const [];
    return v.whereType<Map<Object?, Object?>>().map((m) => m.map((key, value) => MapEntry('$key', value))).toList();
  }

  static T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
