import '../../core/utils/money.dart';
import '../ml/text_classifier.dart';
import '../models/enums.dart';

class ParsedExpense {
  const ParsedExpense({
    required this.amountMinor,
    required this.category,
    required this.description,
    required this.confident,
    this.type = TransactionType.expense,
  });

  final int amountMinor;
  final ExpenseCategory category;
  final String description;
  final TransactionType type;

  /// False when the category was not recognized; the UI can then ask the AI
  /// (if credits allow) or let the user pick.
  final bool confident;
}

/// Offline parser for quick entries such as "250 lunch", "lunch 250",
/// "₺1.250,50 market" or "taxi 85 tl". English and Turkish keywords.
class ExpenseParser {
  const ExpenseParser({this.model});

  /// Optional on-device classifier used when no keyword matches (typos,
  /// missing Turkish letters, merchant names).
  final TextClassifier? model;

  static const Map<ExpenseCategory, List<String>> keywords = {
    ExpenseCategory.food: [
      'lunch',
      'dinner',
      'breakfast',
      'coffee',
      'cafe',
      'restaurant',
      'food',
      'grocer',
      'groceries',
      'market',
      'supermarket',
      'snack',
      'pizza',
      'burger',
      'meal',
      'bakery',
      'takeaway',
      'delivery',
      'öğle',
      'ogle',
      'akşam yemeği',
      'kahvaltı',
      'kahvalti',
      'kahve',
      'yemek',
      'restoran',
      'market',
      'bakkal',
      'manav',
      'fırın',
      'firin',
      'migros',
      'bim',
      'a101',
      'şok',
      'getir',
      'yemeksepeti',
      'çay',
    ],
    ExpenseCategory.transport: [
      'taxi',
      'uber',
      'bus',
      'metro',
      'train',
      'fuel',
      'gas station',
      'petrol',
      'parking',
      'toll',
      'ticket',
      'taksi',
      'otobüs',
      'otobus',
      'benzin',
      'yakıt',
      'yakit',
      'otopark',
      'köprü',
      'istanbulkart',
      'marmaray',
    ],
    ExpenseCategory.shopping: [
      'shopping',
      'clothes',
      'shoes',
      'amazon',
      'store',
      'gift',
      'electronics',
      'alışveriş',
      'alisveris',
      'kıyafet',
      'kiyafet',
      'ayakkabı',
      'hediye',
      'trendyol',
      'hepsiburada',
    ],
    ExpenseCategory.bills: [
      'bill',
      'electric',
      'electricity',
      'water bill',
      'internet',
      'phone',
      'gas bill',
      'utility',
      'fatura',
      'elektrik',
      'su faturası',
      'doğalgaz',
      'dogalgaz',
      'telefon',
      'aidat',
    ],
    ExpenseCategory.housing: ['rent', 'mortgage', 'kira', 'konut'],
    ExpenseCategory.entertainment: [
      'movie',
      'cinema',
      'concert',
      'game',
      'bar',
      'party',
      'netflix night',
      'theatre',
      'sinema',
      'konser',
      'oyun',
      'eğlence',
      'eglence',
      'tiyatro',
    ],
    ExpenseCategory.health: [
      'pharmacy',
      'doctor',
      'medicine',
      'gym',
      'dentist',
      'hospital',
      'eczane',
      'doktor',
      'ilaç',
      'ilac',
      'spor salonu',
      'diş',
      'hastane',
    ],
    ExpenseCategory.subscriptions: [
      'subscription',
      'netflix',
      'spotify',
      'youtube premium',
      'icloud',
      'disney',
      'prime',
      'abonelik',
      'üyelik',
      'uyelik',
    ],
  };

  static const _incomeWords = ['salary', 'income', 'bonus', 'refund', 'maaş', 'maas', 'gelir', 'prim', 'iade'];

  ParsedExpense? parse(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;
    // With several numbers ("2 coffees 90") the largest is the amount.
    RegExpMatch? amountMatch;
    var minor = 0;
    for (final m in RegExp(r'[-+]?\d[\d.,]*').allMatches(text)) {
      final v = Money.parseMinor(m.group(0)!) ?? 0;
      if (v > minor) {
        minor = v;
        amountMatch = m;
      }
    }
    if (amountMatch == null || minor <= 0) return null;

    var desc = '${text.substring(0, amountMatch.start)} ${text.substring(amountMatch.end)}'
        .replaceAll(RegExp(r'[₺$€£¥]|\b(tl|try|usd|eur|gbp|lira|dollars?|euros?)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final lower = desc.toLowerCase();

    final isIncome = _incomeWords.any(lower.contains) || amountMatch.group(0)!.startsWith('+');
    final category = categorize(lower) ?? _modelCategory(desc);
    if (desc.isNotEmpty) desc = desc[0].toUpperCase() + desc.substring(1);
    return ParsedExpense(
      amountMinor: minor,
      category: category ?? ExpenseCategory.other,
      description: desc,
      confident: category != null || isIncome || desc.isEmpty,
      type: isIncome ? TransactionType.income : TransactionType.expense,
    );
  }

  /// Keyword match first, then the on-device model (if confident).
  ExpenseCategory? categorizeText(String text) => categorize(text.toLowerCase()) ?? _modelCategory(text);

  ExpenseCategory? _modelCategory(String text) {
    final p = model?.confident(text);
    if (p == null) return null;
    return ExpenseCategory.values.where((c) => c.name == p.label).firstOrNull;
  }

  /// Exact category name or keyword match; longest keyword wins.
  static ExpenseCategory? categorize(String lowerText) {
    for (final c in ExpenseCategory.values) {
      if (RegExp('\\b${c.name}\\b').hasMatch(lowerText)) return c;
    }
    ExpenseCategory? best;
    var bestLen = 0;
    keywords.forEach((cat, words) {
      for (final w in words) {
        if (w.length > bestLen && lowerText.contains(w)) {
          best = cat;
          bestLen = w.length;
        }
      }
    });
    return best;
  }
}
