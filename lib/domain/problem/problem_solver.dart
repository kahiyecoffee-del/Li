import 'dart:math' as math;

import 'calculator.dart';
import 'quantities.dart';

/// What the user typed, understood well enough to answer on the phone with
/// exact arithmetic, or to hand to the right tool.
sealed class ProblemResult {
  const ProblemResult();
}

/// Answered on the device. Numbers come from code, never from a language
/// model, so they are always right for the given inputs.
sealed class Solution extends ProblemResult {
  const Solution();

  /// Stable id used for analytics and saved items.
  String get kind;
}

/// "3.000 TL, 20 days left" → per-day limit.
class RunwaySolution extends Solution {
  const RunwaySolution({required this.amount, required this.days, required this.currency, required this.monthEnd});
  final double amount;
  final int days;
  final String? currency;

  /// Days were derived from "end of month" rather than typed.
  final bool monthEnd;
  double get perDay => amount / days;
  double get perWeek => perDay * 7;
  @override
  String get kind => 'budget_runway';
}

/// Discount, VAT or a raise applied to a price.
enum PercentChange { discount, vat, raise }

class PriceChangeSolution extends Solution {
  const PriceChangeSolution({required this.price, required this.percent, required this.mode, this.currency});
  final double price, percent;
  final PercentChange mode;
  final String? currency;
  double get delta => price * percent / 100;
  double get result => mode == PercentChange.discount ? price - delta : price + delta;
  @override
  String get kind => 'price_change';
}

class PercentOfSolution extends Solution {
  const PercentOfSolution({required this.base, required this.percent});
  final double base, percent;
  double get result => base * percent / 100;
  @override
  String get kind => 'percent_of';
}

class SplitSolution extends Solution {
  const SplitSolution({required this.total, required this.people, this.tipPercent = 0, this.currency});
  final double total;
  final int people;
  final double tipPercent;
  final String? currency;
  double get totalWithTip => total * (1 + tipPercent / 100);
  double get perPerson => totalWithTip / people;
  @override
  String get kind => 'split_bill';
}

class InstallmentSolution extends Solution {
  const InstallmentSolution({required this.monthly, required this.months, this.cashPrice, this.currency});
  final double monthly;
  final int months;
  final double? cashPrice;
  final String? currency;
  double get total => monthly * months;
  double? get extra => cashPrice == null ? null : total - cashPrice!;
  double? get extraPercent => cashPrice == null || cashPrice == 0 ? null : extra! / cashPrice! * 100;
  @override
  String get kind => 'installment';
}

class UnitPriceItem {
  const UnitPriceItem(this.size, this.unit, this.price);
  final double size;
  final QUnit unit;
  final double price;

  /// Price per base unit (per litre, per kg, per metre, per piece).
  double get perBase => price / (size * unit.factor);
}

class UnitPriceSolution extends Solution {
  const UnitPriceSolution({required this.items, this.currency});
  final List<UnitPriceItem> items;
  final String? currency;
  int get best {
    var b = 0;
    for (var i = 1; i < items.length; i++) {
      if (items[i].perBase < items[b].perBase) b = i;
    }
    return b;
  }

  /// How much cheaper the best option is per unit than the priciest one.
  double get savingPercent {
    final worst = items.map((e) => e.perBase).reduce(math.max);
    return worst == 0 ? 0 : (worst - items[best].perBase) / worst * 100;
  }

  Dim get dim => items.first.unit.dim;
  @override
  String get kind => 'unit_price';
}

class FuelSolution extends Solution {
  const FuelSolution({required this.km, required this.litresPer100, required this.pricePerLitre, this.currency});
  final double km, litresPer100, pricePerLitre;
  final String? currency;
  double get litres => km / 100 * litresPer100;
  double get cost => litres * pricePerLitre;
  @override
  String get kind => 'fuel_cost';
}

class YearlySolution extends Solution {
  const YearlySolution({required this.monthlyAmounts, this.currency});
  final List<double> monthlyAmounts;
  final String? currency;
  double get monthly => monthlyAmounts.fold(0, (a, b) => a + b);
  double get yearly => monthly * 12;
  @override
  String get kind => 'yearly_cost';
}

class ConvertSolution extends Solution {
  const ConvertSolution({required this.value, required this.from, required this.to});
  final double value;
  final QUnit from, to;
  double get result {
    if (from.dim == Dim.temperature) {
      if (from == to) return value;
      return from == QUnit.celsius ? value * 9 / 5 + 32 : (value - 32) * 5 / 9;
    }
    return value * from.factor / to.factor;
  }

  @override
  String get kind => 'convert';
}

class CalcSolution extends Solution {
  const CalcSolution({required this.expression, required this.value});
  final String expression;
  final double value;
  @override
  String get kind => 'calculate';
}

class DaysUntilSolution extends Solution {
  const DaysUntilSolution({required this.date, required this.days});
  final DateTime date;
  final int days;
  @override
  String get kind => 'days_until';
}

/// Needs a tool screen rather than a one-line answer.
enum ProblemTool { decide, recipe, write, reminder }

class ToolRoute extends ProblemResult {
  const ToolRoute(this.tool, {this.options = const [], this.text = ''});
  final ProblemTool tool;

  /// Decide: the options the user named. Recipe: ingredients.
  final List<String> options;
  final String text;
}

/// Anything else goes to Lio (on-device brain / model, or cloud AI).
class AskLio extends ProblemResult {
  const AskLio(this.text);
  final String text;
}

/// Turns free text into a [ProblemResult]. Pure and synchronous.
class ProblemSolver {
  const ProblemSolver({this.clock});

  final DateTime Function()? clock;
  DateTime get _now => clock?.call() ?? DateTime.now();

  ProblemResult solve(String input) {
    final text = input.trim();
    if (text.isEmpty) return const AskLio('');
    final f = Quantities.fold(text);
    final qs = Quantities.parse(text);
    bool kw(List<String> w) => Quantities.hasWord(f, w);
    List<Quantity> of(Dim d) => qs.where((q) => q.dim == d).toList();
    final money = of(Dim.money);
    // Bare numbers next to a money word ("1500 lira" is parsed; "1500" alone is plain).
    final plain = of(Dim.plain);
    final pct = of(Dim.percent);
    String? cur() => money.isEmpty ? null : money.first.unit!.currency;
    List<double> amounts() => [...money.map((q) => q.value)];

    // 1. Plain arithmetic: "1250*12", "(450+380)/3".
    final calc = Calculator.tryEvaluate(text);
    if (calc != null) return CalcSolution(expression: text, value: calc);

    // 2. Unit conversion: "5 kg kaç lb", "70 F to C", "12 inch in cm".
    final conv = _conversion(f, qs);
    if (conv != null) return conv;

    // 3. Trip fuel cost: "300 km, 100 km'de 7 litre, litresi 45 TL".
    final kms = qs.where((q) => q.unit == QUnit.kilometre).toList();
    final litres = qs.where((q) => q.unit == QUnit.litre).toList();
    if (kms.isNotEmpty &&
        litres.isNotEmpty &&
        money.isNotEmpty &&
        kw([
          'yakit',
          'benzin',
          'mazot',
          'dizel',
          'fuel',
          'gas',
          'petrol',
          'yol',
          'trip',
          'drive',
          'arac',
          'araba',
          'car',
        ])) {
      final trip = kms.firstWhere((q) => q.value != 100, orElse: () => kms.first);
      return FuelSolution(
        km: trip.value,
        litresPer100: litres.first.value,
        pricePerLitre: money.first.value,
        currency: cur(),
      );
    }

    // 4. Unit price: two sizes with two prices of the same kind.
    final sizes = qs.where((q) => const {Dim.volume, Dim.mass, Dim.length, Dim.count}.contains(q.dim)).toList();
    if (sizes.length >= 2 && money.length >= 2) {
      final n = math.min(sizes.length, money.length);
      final items = [for (var i = 0; i < n; i++) UnitPriceItem(sizes[i].value, sizes[i].unit!, money[i].value)];
      if (items.every((e) => e.unit.dim == items.first.unit.dim) && items.every((e) => e.size > 0)) {
        return UnitPriceSolution(items: items, currency: cur());
      }
    }

    // 5. Split a bill: "1840 TL 4 kişi %10 bahşiş".
    final people = of(Dim.people);
    if (money.isNotEmpty && (people.isNotEmpty || kw(['bol', 'paylas', 'split']))) {
      final n = people.isNotEmpty ? people.first.value.round() : (plain.isNotEmpty ? plain.first.value.round() : 0);
      if (n >= 2) {
        final tip = kw(['bahsis', 'tip', 'servis']) && pct.isNotEmpty ? pct.first.value : 0.0;
        return SplitSolution(total: money.first.value, people: n, tipPercent: tip, currency: cur());
      }
    }

    // 6. Instalments: "12 taksit aylık 850 TL, peşini 9.000 TL".
    final months = of(Dim.months);
    if (money.isNotEmpty &&
        months.isNotEmpty &&
        kw(['taksit', 'install', 'aylik', 'monthly', 'kredi', 'loan', 'pesin', 'cash', 'month', 'ay '])) {
      final count = months.first.value.round();
      if (count >= 2) {
        double monthly;
        double? cash;
        if (money.length >= 2) {
          final cashQ = money.where((q) => _near(f, q, ['pesin', 'cash', 'nakit', 'fiyat', 'price']));
          final monthlyQ = money.where((q) => _near(f, q, ['aylik', 'monthly', 'ayda', 'per month', 'a month']));
          if (monthlyQ.isNotEmpty) {
            monthly = monthlyQ.first.value;
            cash = money.where((q) => q != monthlyQ.first).first.value;
          } else if (cashQ.isNotEmpty) {
            cash = cashQ.first.value;
            monthly = money.where((q) => q != cashQ.first).first.value;
          } else {
            monthly = money.map((q) => q.value).reduce(math.min);
            cash = money.map((q) => q.value).reduce(math.max);
          }
        } else {
          monthly = money.first.value;
        }
        return InstallmentSolution(monthly: monthly, months: count, cashPrice: cash, currency: cur());
      }
    }

    // 7. Discount / VAT / raise: "1.299 TL %30 indirim".
    if (pct.isNotEmpty && (money.isNotEmpty || plain.isNotEmpty)) {
      final price = money.isNotEmpty ? money.first.value : plain.first.value;
      PercentChange? mode;
      if (kw(['indirim', 'discount', 'off', 'sale', 'kampanya', 'ucuz'])) mode = PercentChange.discount;
      if (kw(['kdv', 'vat', 'tax', 'vergi'])) mode = PercentChange.vat;
      if (kw(['zam', 'raise', 'artis', 'increase', 'enflasyon', 'inflation'])) mode = PercentChange.raise;
      if (mode != null) return PriceChangeSolution(price: price, percent: pct.first.value, mode: mode, currency: cur());
    }

    // 8. Will my money last? "3.000 TL kaldı, ay sonuna 20 gün var".
    final days = of(Dim.days);
    final monthEnd = kw(['ay sonu', 'ay sonuna', 'end of the month', 'end of month', 'month end', 'maasa', 'payday']);
    if (money.isNotEmpty && (days.isNotEmpty || monthEnd)) {
      final d = days.isNotEmpty ? days.first.value.round() : _daysToMonthEnd();
      if (d >= 1) return RunwaySolution(amount: money.first.value, days: d, currency: cur(), monthEnd: days.isEmpty);
    }

    // 9. Yearly cost of monthly payments: "aylık 99 ve 149 TL, yılda ne eder".
    if (money.isNotEmpty && kw(['yilda', 'yillik', 'year', 'annual', 'senede'])) {
      return YearlySolution(monthlyAmounts: amounts(), currency: cur());
    }

    // 10. Percent of a number: "1500'ün yüzde 20'si", "20% of 1500".
    if (pct.isNotEmpty && (plain.isNotEmpty || money.isNotEmpty)) {
      final base = plain.isNotEmpty ? plain.first.value : money.first.value;
      return PercentOfSolution(base: base, percent: pct.first.value);
    }

    // 11. Days until a date: "31 Aralık'a kaç gün var".
    final until = _daysUntil(f);
    if (until != null) return until;

    // 12. Tools. "X mi Y mi?", "X or Y?" with two named options is a choice.
    final lower = text.toLowerCase();
    final choice =
        RegExp(r'(^|\s)(mı|mi|mu|mü)\s.*(mı|mi|mu|mü)(\s|\?|$)').hasMatch(lower) ||
        (RegExp(r'\s(or|veya|ya da)\s').hasMatch(lower) && lower.trim().endsWith('?'));
    if (choice && splitOptions(text).length >= 2) {
      return ToolRoute(ProblemTool.decide, options: splitOptions(text), text: text);
    }
    if (kw([
      'hangisi',
      'hangisini',
      'which',
      'versus',
      'vs',
      'karar',
      'decide',
      'choose',
      'secmeli',
      'secsem',
      'alsam',
      'almali',
      'yoksa',
      'should i',
      'better',
    ])) {
      return ToolRoute(ProblemTool.decide, options: splitOptions(text), text: text);
    }
    if (kw(['evde', 'elimde', 'dolapta', 'buzdolab', 'i have', 'at home', 'fridge']) &&
            kw(['var', 'have', 'yemek', 'pisir', 'cook', 'yapabilir', 'make']) ||
        kw(['ne pisir', 'ne yapsam', 'tarif', 'recipe', 'what can i cook', 'what to cook', 'yemek oner'])) {
      return ToolRoute(ProblemTool.recipe, options: _ingredients(text), text: text);
    }
    if (kw([
      'mesaj',
      'cevapla',
      'cevap yaz',
      'e posta',
      'eposta',
      'email',
      'e-mail',
      'mail',
      'yeniden yaz',
      'duzelt',
      'ozetle',
      'cevir',
      'translate',
      'reply',
      'rewrite',
      'write',
      'yaz ',
      'dilekce',
      'cv ',
    ])) {
      return ToolRoute(ProblemTool.write, text: text);
    }
    if (kw(['hatirlat', 'remind', 'unutma', "don't forget", 'dont forget'])) {
      return ToolRoute(ProblemTool.reminder, text: text);
    }
    return AskLio(text);
  }

  int _daysToMonthEnd() {
    final now = _now;
    final last = DateTime(now.year, now.month + 1, 0);
    return last.day - now.day + 1;
  }

  static bool _near(String f, Quantity q, List<String> words) {
    final from = math.max(0, q.start - 18);
    final to = math.min(f.length, q.end + 10);
    final window = f.substring(from, to);
    return words.any(window.contains);
  }

  static ConvertSolution? _conversion(String f, List<Quantity> qs) {
    final convertible = qs
        .where((q) => const {Dim.volume, Dim.mass, Dim.length, Dim.temperature}.contains(q.dim))
        .toList();
    if (convertible.length != 1) return null;
    final src = convertible.first;
    final after = f.substring(src.end);
    if (!RegExp(r'(kac|to|in|=|how many|into|cevir|convert|olur|eder|\?)').hasMatch(after)) return null;
    for (final m in RegExp(r'[°a-z\x22]+').allMatches(after)) {
      final u = Quantities.unitWord(m.group(0)!);
      if (u != null && u != src.unit && u.dim == src.unit!.dim) {
        return ConvertSolution(value: src.value, from: src.unit!, to: u);
      }
    }
    return null;
  }

  static const _months = {
    'ocak': 1,
    'subat': 2,
    'mart': 3,
    'nisan': 4,
    'mayis': 5,
    'haziran': 6,
    'temmuz': 7,
    'agustos': 8,
    'eylul': 9,
    'ekim': 10,
    'kasim': 11,
    'aralik': 12,
    'january': 1,
    'february': 2,
    'march': 3,
    'april': 4,
    'may': 5,
    'june': 6,
    'july': 7,
    'august': 8,
    'september': 9,
    'october': 10,
    'november': 11,
    'december': 12,
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  DaysUntilSolution? _daysUntil(String f) {
    const asks = ['kac gun', 'how many days', 'days until', 'days left', 'gun kaldi', 'gun var'];
    if (!Quantities.hasWord(f, asks)) return null;
    final m = RegExp(r'(\d{1,2})\s*([a-z]+)|([a-z]+)\s+(\d{1,2})(?!\d)').allMatches(f);
    for (final x in m) {
      final day = int.tryParse(x.group(1) ?? x.group(4) ?? '');
      final name = (x.group(2) ?? x.group(3) ?? '').replaceAll(RegExp(r"'.*"), '');
      final month =
          _months[name] ?? _months.entries.where((e) => e.key.length > 3 && name.startsWith(e.key)).firstOrNull?.value;
      if (day == null || month == null || day < 1 || day > 31) continue;
      final now = _now;
      final today = DateTime(now.year, now.month, now.day);
      var date = DateTime(now.year, month, day);
      if (date.isBefore(today)) date = DateTime(now.year + 1, month, day);
      return DaysUntilSolution(date: date, days: date.difference(today).inDays);
    }
    return null;
  }

  /// "iPhone 15 mi yoksa Galaxy S24 mü?" → ["iPhone 15", "Galaxy S24"].
  static List<String> splitOptions(String text) {
    var t = text.replaceAll(RegExp(r'[?!]'), ' ');
    t = t.replaceAll(
      RegExp(
        r'\b(hangisi|hangisini|which|should i|choose|karar|ver|alsam|almalıyım|seçmeliyim|daha iyi|better|is better)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    final parts = t
        .split(
          RegExp(
            r'\s+(?:(?:mı|mi|mu|mü)\s+)?(?:vs\.?|versus|veya|ya da|yoksa|or|mı|mi|mu|mü)\s+|\s*[,/]\s*',
            caseSensitive: false,
          ),
        )
        .map(
          (e) => e
              .replaceAll(RegExp(r'\s+(?:mı|mi|mu|mü)$', caseSensitive: false), '')
              .replaceAll(RegExp(r'^[\s:;\-–]+|[\s:;\-–]+$'), '')
              .trim(),
        )
        .where((e) => e.length > 1)
        .toList();
    return parts.length >= 2 ? parts.take(4).toList() : const [];
  }

  /// Keeps the user's own spelling (with Turkish letters) so ingredient
  /// aliases such as "salça" still match the recipe library.
  static List<String> _ingredients(String text) {
    const filler = {
      'evde',
      'elimde',
      'dolapta',
      'buzdolabında',
      'buzdolabinda',
      'var',
      'ne',
      'neler',
      'pişirebilirim',
      'pisirebilirim',
      'yapabilirim',
      'yapsam',
      'i',
      'have',
      'at',
      'home',
      'in',
      'the',
      'fridge',
      'what',
      'can',
      'cook',
      'make',
      'with',
      'got',
      'some',
    };
    final lower = text.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase().replaceAll(RegExp(r'[.?!;:]'), ' ');
    return lower
        .split(RegExp(r'\s*(?:,|\sve\s|\sand\s|\sile\s)\s*'))
        .map((e) => e.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && !filler.contains(w)).join(' '))
        .where((e) => e.length > 1)
        .toList();
  }
}
