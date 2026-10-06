/// Reads numbers with their units out of everyday Turkish/English text:
/// "3.000 TL", "1,5 L", "%30", "yüzde 20", "4 kişi", "20 gün", "3 bin".
library;

enum Dim { money, days, people, months, percent, volume, mass, length, temperature, count, plain }

/// A unit the user can type. [factor] converts to the dimension's base unit
/// (litre, kilogram, metre); temperature is handled separately.
enum QUnit {
  // money (factor unused)
  tryLira(Dim.money, 1, 'TRY'),
  usd(Dim.money, 1, 'USD'),
  eur(Dim.money, 1, 'EUR'),
  gbp(Dim.money, 1, 'GBP'),
  day(Dim.days, 1, 'day'),
  person(Dim.people, 1, 'person'),
  month(Dim.months, 1, 'month'),
  percent(Dim.percent, 1, '%'),
  litre(Dim.volume, 1, 'L'),
  millilitre(Dim.volume, 0.001, 'ml'),
  gallon(Dim.volume, 3.785411784, 'gal'),
  kilogram(Dim.mass, 1, 'kg'),
  gram(Dim.mass, 0.001, 'g'),
  pound(Dim.mass, 0.45359237, 'lb'),
  ounce(Dim.mass, 0.028349523125, 'oz'),
  kilometre(Dim.length, 1000, 'km'),
  metre(Dim.length, 1, 'm'),
  centimetre(Dim.length, 0.01, 'cm'),
  millimetre(Dim.length, 0.001, 'mm'),
  inch(Dim.length, 0.0254, 'in'),
  foot(Dim.length, 0.3048, 'ft'),
  mile(Dim.length, 1609.344, 'mi'),
  celsius(Dim.temperature, 1, '°C'),
  fahrenheit(Dim.temperature, 1, '°F'),
  piece(Dim.count, 1, 'pcs');

  const QUnit(this.dim, this.factor, this.symbol);

  final Dim dim;
  final double factor;
  final String symbol;

  /// ISO currency code for money units.
  String? get currency => dim == Dim.money ? symbol : null;
}

class Quantity {
  const Quantity(this.value, this.unit, this.start, this.end);

  final double value;

  /// Null for a bare number.
  final QUnit? unit;
  final int start, end;

  Dim get dim => unit?.dim ?? Dim.plain;

  @override
  String toString() => '$value${unit == null ? '' : ' ${unit!.symbol}'}';
}

abstract final class Quantities {
  /// Lower-cases and folds Turkish letters so keyword checks are simple.
  static String fold(String s) {
    const from = 'çğıİöşüÇĞÖŞÜâîû';
    const to = 'cgiiosucgosuaiu';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch.toLowerCase());
    }
    return b.toString().replaceAll('’', "'");
  }

  /// True if any of [words] starts a word in the folded [text].
  static bool hasWord(String text, Iterable<String> words) {
    for (final w in words) {
      if (RegExp('(^|[^a-z0-9])${RegExp.escape(w)}').hasMatch(text)) return true;
    }
    return false;
  }

  static const _units = <String, QUnit>{
    'tl': QUnit.tryLira,
    'try': QUnit.tryLira,
    'lira': QUnit.tryLira,
    '₺': QUnit.tryLira,
    r'$': QUnit.usd,
    'usd': QUnit.usd,
    'dolar': QUnit.usd,
    'dollar': QUnit.usd,
    'dollars': QUnit.usd,
    'bucks': QUnit.usd,
    '€': QUnit.eur,
    'eur': QUnit.eur,
    'euro': QUnit.eur,
    'euros': QUnit.eur,
    '£': QUnit.gbp,
    'gbp': QUnit.gbp,
    'sterlin': QUnit.gbp,
    'pound sterling': QUnit.gbp,
    'gun': QUnit.day,
    'day': QUnit.day,
    'days': QUnit.day,
    'kisi': QUnit.person,
    'kisiyiz': QUnit.person,
    'people': QUnit.person,
    'person': QUnit.person,
    'persons': QUnit.person,
    'friends': QUnit.person,
    'ay': QUnit.month,
    'month': QUnit.month,
    'months': QUnit.month,
    'mo': QUnit.month,
    'taksit': QUnit.month,
    'installment': QUnit.month,
    'installments': QUnit.month,
    'payments': QUnit.month,
    '%': QUnit.percent,
    'percent': QUnit.percent,
    'l': QUnit.litre,
    'lt': QUnit.litre,
    'litre': QUnit.litre,
    'liter': QUnit.litre,
    'litres': QUnit.litre,
    'liters': QUnit.litre,
    'ml': QUnit.millilitre,
    'gal': QUnit.gallon,
    'gallon': QUnit.gallon,
    'gallons': QUnit.gallon,
    'kg': QUnit.kilogram,
    'kilo': QUnit.kilogram,
    'kilogram': QUnit.kilogram,
    'g': QUnit.gram,
    'gr': QUnit.gram,
    'gram': QUnit.gram,
    'grams': QUnit.gram,
    'lb': QUnit.pound,
    'lbs': QUnit.pound,
    'pound': QUnit.pound,
    'pounds': QUnit.pound,
    'oz': QUnit.ounce,
    'ounce': QUnit.ounce,
    'ounces': QUnit.ounce,
    'km': QUnit.kilometre,
    'kilometre': QUnit.kilometre,
    'kilometer': QUnit.kilometre,
    'm': QUnit.metre,
    'metre': QUnit.metre,
    'meter': QUnit.metre,
    'cm': QUnit.centimetre,
    'mm': QUnit.millimetre,
    'inch': QUnit.inch,
    'inches': QUnit.inch,
    'inc': QUnit.inch,
    'in': QUnit.inch,
    '"': QUnit.inch,
    'ft': QUnit.foot,
    'feet': QUnit.foot,
    'foot': QUnit.foot,
    'mile': QUnit.mile,
    'miles': QUnit.mile,
    'mil': QUnit.mile,
    'c': QUnit.celsius,
    '°c': QUnit.celsius,
    'celsius': QUnit.celsius,
    'santigrat': QUnit.celsius,
    'f': QUnit.fahrenheit,
    '°f': QUnit.fahrenheit,
    'fahrenheit': QUnit.fahrenheit,
    'adet': QUnit.piece,
    'tane': QUnit.piece,
    'pcs': QUnit.piece,
    'pieces': QUnit.piece,
    'pack': QUnit.piece,
    'paket': QUnit.piece,
  };

  /// Unit words that may follow a number, longest first so "kg" wins over "k".
  static final _unitPattern = () {
    final keys = _units.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
    return keys.map(RegExp.escape).join('|');
  }();

  static final _number = RegExp(r'(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d+)?|\d+(?:[.,]\d+)?)');

  /// A bare unit word anywhere in [folded] (used for conversion targets).
  static QUnit? unitWord(String folded) => _units[folded];

  /// All quantities in [text], in order of appearance.
  static List<Quantity> parse(String text) {
    final s = fold(text);
    final out = <Quantity>[];
    for (final m in _number.allMatches(s)) {
      var value = parseNumber(m.group(0)!);
      if (value == null) continue;
      // Skip digits glued to letters ("mp3", "iphone15") unless a currency sign.
      if (m.start > 0 && RegExp(r'[a-z]').hasMatch(s[m.start - 1])) continue;
      var end = m.end;
      QUnit? unit;

      // Prefix: "%30", "yüzde 30", "₺500", "$20".
      final before = s.substring(0, m.start);
      if (RegExp(r'%\s*$').hasMatch(before) || RegExp(r'(^|[^a-z])yuzde\s+$').hasMatch(before)) {
        unit = QUnit.percent;
      } else if (RegExp(r'₺\s*$').hasMatch(before)) {
        unit = QUnit.tryLira;
      } else if (RegExp(r'\$\s*$').hasMatch(before)) {
        unit = QUnit.usd;
      } else if (RegExp(r'€\s*$').hasMatch(before)) {
        unit = QUnit.eur;
      } else if (RegExp(r'£\s*$').hasMatch(before)) {
        unit = QUnit.gbp;
      }

      var rest = s.substring(end);
      // Turkish suffix after an apostrophe: 1500'ün, 100 km'de.
      final suffix = RegExp(r"^'[a-z]+").firstMatch(rest);
      if (suffix != null && unit == null) {
        end += suffix.end;
        rest = s.substring(end);
      }
      // Multipliers: "3 bin", "1,5 milyon", "3k".
      final mult = RegExp(r'^\s*(bin|k|thousand|milyon|million|m(?=\s*(tl|₺|\$|€|lira|dolar|euro)))(?![a-z])')
          .firstMatch(rest);
      if (mult != null) {
        final w = mult.group(1)!;
        value *= (w == 'bin' || w == 'k' || w == 'thousand') ? 1000 : 1000000;
        end += mult.end;
        rest = s.substring(end);
      }
      if (unit == null) {
        final um = RegExp('^\\s*($_unitPattern)(?![a-z])').firstMatch(rest);
        if (um != null) {
          final word = um.group(1)!;
          // "ay sonu" is a deadline, not a month count.
          final monthEnd = word == 'ay' && RegExp(r'^\s*ay\s*(sonu|sonuna|basi)').hasMatch(rest);
          if (!monthEnd) {
            unit = _units[word];
            end += um.end;
            final suffix2 = RegExp(r"^'?[a-z]*").firstMatch(s.substring(end));
            if (suffix2 != null && word.length > 1) end += suffix2.end;
          }
        }
      }
      out.add(Quantity(value, unit, m.start, end));
    }
    return out;
  }

  /// "3.000" → 3000, "1.299,90" → 1299.9, "1,5" → 1.5, "45.99" → 45.99.
  static double? parseNumber(String raw) {
    var s = raw;
    final hasDot = s.contains('.');
    final hasComma = s.contains(',');
    if (hasDot && hasComma) {
      final dec = s.lastIndexOf('.') > s.lastIndexOf(',') ? '.' : ',';
      final thou = dec == '.' ? ',' : '.';
      s = s.replaceAll(thou, '').replaceAll(dec, '.');
    } else if (hasDot || hasComma) {
      final sep = hasDot ? '.' : ',';
      final parts = s.split(sep);
      final thousands = parts.length > 2 || (parts.last.length == 3 && parts.first != '0');
      s = thousands ? parts.join() : parts.join('.');
    }
    return double.tryParse(s);
  }
}
