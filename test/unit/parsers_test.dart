import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/engines/expense_parser.dart';
import 'package:lifeos/domain/engines/receipt_parser.dart';
import 'package:lifeos/domain/engines/shopping_categorizer.dart';
import 'package:lifeos/domain/models/enums.dart';

void main() {
  group('ExpenseParser', () {
    const p = ExpenseParser();

    test('"250 lunch"', () {
      final r = p.parse('250 lunch')!;
      expect(r.amountMinor, 25000);
      expect(r.category, ExpenseCategory.food);
      expect(r.description, 'Lunch');
      expect(r.confident, isTrue);
    });

    test('turkish and currency symbols', () {
      final r = p.parse('taksi 85,50 TL')!;
      expect(r.amountMinor, 8550);
      expect(r.category, ExpenseCategory.transport);
      expect(p.parse('₺1.250 kira')!.category, ExpenseCategory.housing);
    });

    test('largest number is the amount', () {
      expect(p.parse('2 coffee 90')!.amountMinor, 9000);
    });

    test('income detection', () {
      expect(p.parse('maaş 45000')!.type, TransactionType.income);
      expect(p.parse('salary 3000')!.type, TransactionType.income);
    });

    test('unknown category is not confident; no amount → null', () {
      final r = p.parse('300 zxqw')!;
      expect(r.category, ExpenseCategory.other);
      expect(r.confident, isFalse);
      expect(p.parse('lunch'), isNull);
      expect(p.parse(''), isNull);
    });
  });

  group('ReceiptParser', () {
    const p = ReceiptParser();
    const text = '''
MIGROS TICARET
Kadikoy Istanbul
12.06.2026 14:22
SUT 1L          34,90
EKMEK            12,50
DOMATES KG       45,00
ARA TOPLAM       92,40
KDV               8,40
TOPLAM           92,40
KART             92,40
''';

    test('extracts merchant, total, date and items', () {
      final r = p.parse(text, now: DateTime(2026, 6, 13));
      expect(r.merchant, 'MIGROS TICARET');
      expect(r.totalMinor, 9240);
      expect(r.date, DateTime(2026, 6, 12));
      expect(r.items.map((i) => i.name), ['SUT 1L', 'EKMEK', 'DOMATES KG']);
    });

    test('future dates are dropped; empty text is empty', () {
      expect(p.parse(text, now: DateTime(2026, 1, 1)).date, isNull);
      expect(p.parse('').isEmpty, isTrue);
    });

    test('falls back to the largest amount', () {
      expect(p.parse('Shop\nItem A 3.50\nItem B 10.00').totalMinor, 1000);
    });
  });

  group('ShoppingCategorizer', () {
    const c = ShoppingCategorizer();
    test('en + tr keywords', () {
      expect(c.categorize('Milk'), ShoppingCategory.dairy);
      expect(c.categorize('yumurta'), ShoppingCategory.dairy);
      expect(c.categorize('Chicken breast'), ShoppingCategory.meat);
      expect(c.categorize('dish detergent'), ShoppingCategory.household);
      expect(c.categorize('Rice'), ShoppingCategory.pantry);
      expect(c.categorize('qwerty'), isNull);
    });

    test('short words match whole words only', () {
      expect(c.categorize('et'), ShoppingCategory.meat);
      expect(c.categorize('peterson'), isNull);
    });
  });
}
