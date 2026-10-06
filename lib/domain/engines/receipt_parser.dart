import '../../core/utils/money.dart';

class ReceiptLine {
  const ReceiptLine(this.name, this.amountMinor);

  final String name;
  final int amountMinor;
}

class ParsedReceipt {
  const ParsedReceipt({this.merchant, this.totalMinor, this.date, this.items = const []});

  final String? merchant;
  final int? totalMinor;
  final DateTime? date;
  final List<ReceiptLine> items;

  bool get isEmpty => merchant == null && totalMinor == null && items.isEmpty;
}

/// Heuristic parser for OCR text of a receipt. Results are always shown to the
/// user for confirmation before anything is saved.
class ReceiptParser {
  const ReceiptParser();

  static final _totalWords = RegExp(
    r'\b(total|toplam|genel toplam|grand total|amount due|tutar|summe|totale|importe)\b',
    caseSensitive: false,
  );
  static final _skipWords = RegExp(
    r'\b(subtotal|ara toplam|tax|kdv|vat|change|para üstü|nakit|cash|card|kart|visa|mastercard|tel|fax|www)\b',
    caseSensitive: false,
  );
  static final _amount = RegExp(r'(\d{1,3}(?:[.,\s]\d{3})*[.,]\d{2}|\d+[.,]\d{2})(?!\d)');
  static final _date = RegExp(r'\b(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})\b');
  static final _isoDate = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b');

  ParsedReceipt parse(String text, {DateTime? now}) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return const ParsedReceipt();

    String? merchant;
    for (final l in lines.take(4)) {
      final letters = l.replaceAll(RegExp(r'[^A-Za-zÀ-ÿĞğİıŞşÇçÖöÜü ]'), '').trim();
      if (letters.length >= 3 && !_amount.hasMatch(l) && !_date.hasMatch(l)) {
        merchant = letters;
        break;
      }
    }

    int? total;
    int largest = 0;
    final items = <ReceiptLine>[];
    for (final raw in lines) {
      // Dates such as 12.06.2026 would otherwise read as the amount 12.06.
      final l = raw.replaceAll(_date, ' ').replaceAll(_isoDate, ' ').replaceAll(RegExp(r'\b\d{1,2}:\d{2}\b'), ' ');
      final matches = _amount.allMatches(l).toList();
      if (matches.isEmpty) continue;
      final value = Money.parseMinor(matches.last.group(0)!.replaceAll(' ', ''));
      if (value == null || value <= 0) continue;
      if (value > largest) largest = value;
      if (_totalWords.hasMatch(l) && !RegExp('sub|ara', caseSensitive: false).hasMatch(l)) {
        total = value;
        continue;
      }
      if (_skipWords.hasMatch(l)) continue;
      final name = l.substring(0, matches.last.start).replaceAll(RegExp(r'[*x×]\s*\d+\s*$'), '').trim();
      if (name.length >= 2 && RegExp(r'[A-Za-zÀ-ÿĞğİıŞşÇçÖöÜü]').hasMatch(name)) {
        items.add(ReceiptLine(name, value));
      }
    }
    // Fall back to the largest amount, which is usually the total.
    total ??= largest > 0 ? largest : null;

    DateTime? date;
    for (final l in lines) {
      final iso = _isoDate.firstMatch(l);
      if (iso != null) {
        date = _safeDate(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!));
      } else {
        final m = _date.firstMatch(l);
        if (m != null) {
          var y = int.parse(m.group(3)!);
          if (y < 100) y += 2000;
          // Day-first (most of the world, including TR); US-style dates whose
          // "month" exceeds 12 are swapped.
          var d = int.parse(m.group(1)!);
          var mo = int.parse(m.group(2)!);
          if (mo > 12 && d <= 12) (d, mo) = (mo, d);
          date = _safeDate(y, mo, d);
        }
      }
      if (date != null) break;
    }
    if (date != null && now != null && date.isAfter(now)) date = null;

    return ParsedReceipt(merchant: merchant, totalMinor: total, date: date, items: items.take(30).toList());
  }

  static DateTime? _safeDate(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31 || y < 2000 || y > 2100) return null;
    final dt = DateTime(y, m, d);
    return dt.month == m ? dt : null;
  }
}
