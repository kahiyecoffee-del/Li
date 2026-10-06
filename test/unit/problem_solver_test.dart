import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/problem/calculator.dart';
import 'package:lifeos/domain/problem/decision_engine.dart';
import 'package:lifeos/domain/problem/problem_solver.dart';
import 'package:lifeos/domain/problem/quantities.dart';

void main() {
  final solver = ProblemSolver(clock: () => DateTime(2026, 10, 11, 10));
  T as<T>(String q) {
    final r = solver.solve(q);
    expect(r, isA<T>(), reason: '"$q" gave $r');
    return r as T;
  }

  group('numbers', () {
    test('Turkish and English separators', () {
      expect(Quantities.parseNumber('3.000'), 3000);
      expect(Quantities.parseNumber('1.299,90'), 1299.9);
      expect(Quantities.parseNumber('1,299.90'), 1299.9);
      expect(Quantities.parseNumber('1,5'), 1.5);
      expect(Quantities.parseNumber('45.99'), 45.99);
      expect(Quantities.parseNumber('1.250.000'), 1250000);
      expect(Quantities.parseNumber('0.125'), 0.125);
    });

    test('units, prefixes and multipliers', () {
      final q = Quantities.parse("₺500, %30, yüzde 20, 3 bin TL, 1,5 L, 4 kişi, 100 km'de, 20 gün");
      expect(q.map((e) => (e.value, e.unit)).toList(), [
        (500.0, QUnit.tryLira),
        (30.0, QUnit.percent),
        (20.0, QUnit.percent),
        (3000.0, QUnit.tryLira),
        (1.5, QUnit.litre),
        (4.0, QUnit.person),
        (100.0, QUnit.kilometre),
        (20.0, QUnit.day),
      ]);
    });

    test('"ay sonu" is not a month count', () {
      expect(Quantities.parse('3000 TL ay sonuna kadar').where((q) => q.unit == QUnit.month), isEmpty);
    });
  });

  group('calculator', () {
    test('precedence, parentheses, percent, power', () {
      expect(Calculator.evaluate('2+3*4'), 14);
      expect(Calculator.evaluate('(450+380)/2'), 415);
      expect(Calculator.evaluate('-3^2'), -9);
      expect(Calculator.evaluate('2^3^2'), 512);
      expect(Calculator.evaluate('200*15%'), 30);
      expect(Calculator.evaluate('1.250,50 x 2'), 2501);
    });

    test('only pure arithmetic is evaluated', () {
      expect(Calculator.tryEvaluate('1250*12 kaç'), 15000);
      expect(Calculator.tryEvaluate('12 / 0'), isNull);
      expect(Calculator.tryEvaluate('iphone 15'), isNull);
      expect(Calculator.tryEvaluate('2026'), isNull);
    });
  });

  group('money', () {
    test('will my money last (days given)', () {
      final s = as<RunwaySolution>('3.000 TL param kaldı ve ay sonuna 20 gün var');
      expect(s.perDay, 150);
      expect(s.currency, 'TRY');
      expect(s.monthEnd, isFalse);
    });

    test('will my money last (end of month)', () {
      final s = as<RunwaySolution>('2100 TL ile ay sonuna yeter mi?');
      expect(s.days, 21); // Oct 11 → Oct 31 inclusive
      expect(s.perDay, 100);
      expect(s.monthEnd, isTrue);
    });

    test('English runway', () {
      expect(as<RunwaySolution>(r'I have $600 left for 12 days').perDay, 50);
    });

    test('discount, VAT and raise', () {
      final d = as<PriceChangeSolution>('1.299 TL ürüne %30 indirim');
      expect(d.mode, PercentChange.discount);
      expect(d.result, closeTo(909.3, 1e-9));
      expect(as<PriceChangeSolution>('1000 TL + %20 KDV').result, 1200);
      expect(as<PriceChangeSolution>('maaşım 40.000 TL, %25 zam').result, 50000);
    });

    test('percent of a number', () {
      expect(as<PercentOfSolution>("1500'ün yüzde 20'si kaç?").result, 300);
      expect(as<PercentOfSolution>('20% of 1500').result, 300);
    });

    test('split the bill with a tip', () {
      final s = as<SplitSolution>('Hesap 1.840 TL, 4 kişiyiz, %10 bahşiş');
      expect(s.people, 4);
      expect(s.perPerson, closeTo(506, 1e-9));
    });

    test('instalments vs cash', () {
      final s = as<InstallmentSolution>('Peşini 9.000 TL, 12 taksit aylık 850 TL');
      expect(s.total, 10200);
      expect(s.cashPrice, 9000);
      expect(s.extra, 1200);
      expect(s.extraPercent, closeTo(13.33, 0.01));
    });

    test('which pack is cheaper', () {
      final s = as<UnitPriceSolution>('1 L 45 TL mi yoksa 1,5 L 60 TL mi daha ucuz?');
      expect(s.best, 1);
      expect(s.items[1].perBase, 40);
      expect(s.savingPercent, closeTo(11.1, 0.1));
    });

    test('unit price across units (g vs kg)', () {
      final s = as<UnitPriceSolution>('500 g 90 TL, 1 kg 170 TL');
      expect(s.best, 1);
    });

    test('trip fuel cost', () {
      final s = as<FuelSolution>("300 km yol, araba 100 km'de 7 litre yakıyor, benzin 45 TL");
      expect(s.litres, 21);
      expect(s.cost, 945);
    });

    test('yearly cost of subscriptions', () {
      final s = as<YearlySolution>('Netflix 230 TL ve Spotify 100 TL, yılda ne kadar?');
      expect(s.yearly, 3960);
    });
  });

  group('everyday', () {
    test('conversions', () {
      expect(as<ConvertSolution>('5 kg kaç lb').result, closeTo(11.023, 0.001));
      expect(as<ConvertSolution>('100 F to C').result, closeTo(37.78, 0.01));
      expect(as<ConvertSolution>('12 inch kaç cm').result, closeTo(30.48, 1e-9));
    });

    test('days until a date', () {
      final s = as<DaysUntilSolution>("31 Aralık'a kaç gün var?");
      expect(s.days, 81);
      expect(as<DaysUntilSolution>('how many days until March 1').date, DateTime(2027, 3, 1));
    });

    test('plain arithmetic', () {
      expect(as<CalcSolution>('(450+380)/2').value, 415);
    });
  });

  group('routing', () {
    test('decisions keep the options', () {
      final r = as<ToolRoute>('iPhone 15 mi yoksa Galaxy S24 mü almalıyım?');
      expect(r.tool, ProblemTool.decide);
      expect(r.options, ['iPhone 15', 'Galaxy S24']);
      expect(as<ToolRoute>('Which is better: Kindle vs Kobo').options, ['Kindle', 'Kobo']);
      expect(as<ToolRoute>('Kindle or Kobo?').options, ['Kindle', 'Kobo']);
      expect(as<ToolRoute>('iPhone mu Samsung mu?').options, ['iPhone', 'Samsung']);
    });

    test('cooking from what is at home', () {
      final r = as<ToolRoute>('Evde yumurta, domates, peynir ve ekmek var');
      expect(r.tool, ProblemTool.recipe);
      expect(r.options, ['yumurta', 'domates', 'peynir', 'ekmek']);
      expect(as<ToolRoute>('Evde yumurta domates peynir var').options, ['yumurta', 'domates', 'peynir']);
    });

    test('writing and reminders', () {
      expect(as<ToolRoute>('Patronuma izin için mesaj yaz').tool, ProblemTool.write);
      expect(as<ToolRoute>('Yarın annemi aramayı hatırlat').tool, ProblemTool.reminder);
    });

    test('everything else goes to Lio', () {
      expect(as<AskLio>('Bugün çok yorgunum').text, 'Bugün çok yorgunum');
    });
  });

  group('decide', () {
    const engine = DecisionEngine();
    const criteria = [
      Criterion(kind: CriterionKind.price, weight: 3),
      Criterion(kind: CriterionKind.quality),
      Criterion(kind: CriterionKind.longTerm, weight: 1),
    ];

    test('prices score the price criterion; winner and reasons', () {
      final o = engine.decide(
        options: 2,
        criteria: criteria,
        ratings: [
          [3, 5, 5],
          [3, 3, 4],
        ],
        prices: [52000, 38000],
      );
      // A: price 1, quality 5, long 5 → (3+10+5)/6 = 3 → 50. B: price 5, 3, 4 → (15+6+4)/6 = 4.17 → 79.
      expect(o.winner, 1);
      expect(o.totals[0], closeTo(50, 0.01));
      expect(o.totals[1], closeTo(79.17, 0.01));
      expect(o.confidence, Confidence.clear);
      expect(o.strengths.first.criterion.kind, CriterionKind.price);
      expect(o.weaknesses.first.criterion.kind, CriterionKind.quality);
    });

    test('a near tie is reported as too close to call', () {
      final o = engine.decide(
        options: 2,
        criteria: criteria,
        ratings: [
          [4, 4, 4],
          [4, 4, 3],
        ],
      );
      expect(o.confidence, Confidence.tooClose);
    });
  });
}
