import 'package:intl/intl.dart';

/// Monetary amount stored in integer minor units (e.g. kuruş / cents).
///
/// All financial arithmetic in Dayly is integer based to avoid floating point
/// rounding drift. AI is never used to compute money values.
class Money implements Comparable<Money> {
  const Money(this.minor, this.currency);

  const Money.zero(this.currency) : minor = 0;

  /// Parses a user-entered major-unit amount like "250", "250.5" or "1.250,75".
  static Money? tryParse(String input, String currency) {
    final minor = parseMinor(input);
    return minor == null ? null : Money(minor, currency);
  }

  /// Converts a free-form amount string to minor units.
  ///
  /// Handles both `1,250.75` and `1.250,75` styles: the right-most separator
  /// followed by exactly 1–2 digits is treated as the decimal separator.
  static int? parseMinor(String input) {
    var s = input.trim().replaceAll(RegExp(r'[^\d.,-]'), '');
    if (s.isEmpty || s == '-') return null;
    final negative = s.startsWith('-');
    s = s.replaceAll('-', '');
    final decimalMatch = RegExp(r'[.,](\d{1,2})$').firstMatch(s);
    String whole;
    String frac = '';
    if (decimalMatch != null) {
      whole = s.substring(0, decimalMatch.start);
      frac = decimalMatch.group(1)!;
    } else {
      whole = s;
    }
    whole = whole.replaceAll(RegExp(r'[.,]'), '');
    if (whole.isEmpty) whole = '0';
    final w = int.tryParse(whole);
    if (w == null) return null;
    final f = int.parse(frac.padRight(2, '0'));
    final v = w * 100 + f;
    return negative ? -v : v;
  }

  final int minor;
  final String currency;

  double get major => minor / 100;
  bool get isNegative => minor < 0;
  bool get isZero => minor == 0;

  Money operator +(Money other) => Money(minor + other.minor, currency);
  Money operator -(Money other) => Money(minor - other.minor, currency);
  Money operator -() => Money(-minor, currency);

  @override
  int compareTo(Money other) => minor.compareTo(other.minor);

  @override
  bool operator ==(Object other) => other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => '$currency ${major.toStringAsFixed(2)}';
}

/// Formats minor-unit amounts for display in the user's locale.
class MoneyFormatter {
  MoneyFormatter(this.locale);

  final String locale;
  final Map<String, NumberFormat> _cache = {};
  final Map<String, NumberFormat> _compactCache = {};

  String format(int minor, String currency, {bool showCents = false}) {
    final f = _cache.putIfAbsent(
      '$currency$showCents',
      () => NumberFormat.simpleCurrency(locale: locale, name: currency, decimalDigits: showCents ? 2 : 0),
    );
    return f.format(minor / 100);
  }

  String compact(int minor, String currency) {
    final f = _compactCache.putIfAbsent(
      currency,
      () => NumberFormat.compactSimpleCurrency(locale: locale, name: currency),
    );
    return f.format(minor / 100);
  }
}

/// Guesses a sensible default currency from a locale tag.
String defaultCurrencyForLocale(String localeTag) {
  final lower = localeTag.toLowerCase().replaceAll('-', '_');
  const byCountry = {
    'tr': 'TRY',
    'us': 'USD',
    'gb': 'GBP',
    'de': 'EUR',
    'fr': 'EUR',
    'es': 'EUR',
    'it': 'EUR',
    'pt': 'EUR',
    'br': 'BRL',
    'mx': 'MXN',
    'jp': 'JPY',
    'kr': 'KRW',
    'in': 'INR',
    'sa': 'SAR',
    'ae': 'AED',
    'eg': 'EGP',
    'ca': 'CAD',
    'au': 'AUD',
    'ar': 'ARS',
  };
  final parts = lower.split('_');
  if (parts.length > 1 && byCountry.containsKey(parts.last)) {
    return byCountry[parts.last]!;
  }
  const byLanguage = {
    'tr': 'TRY',
    'de': 'EUR',
    'fr': 'EUR',
    'es': 'EUR',
    'it': 'EUR',
    'pt': 'BRL',
    'ja': 'JPY',
    'ko': 'KRW',
    'hi': 'INR',
    'ar': 'SAR',
  };
  return byLanguage[parts.first] ?? 'USD';
}
