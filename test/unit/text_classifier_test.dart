import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/engines/expense_parser.dart';
import 'package:lifeos/domain/engines/shopping_categorizer.dart';
import 'package:lifeos/domain/ml/text_classifier.dart';
import 'package:lifeos/domain/models/enums.dart';

void main() {
  final expense = TextClassifier.fromJson(File('assets/models/expense_classifier.json').readAsStringSync());
  final shopping = TextClassifier.fromJson(File('assets/models/shopping_classifier.json').readAsStringSync());
  final parity = jsonDecode(File('test/fixtures/classifier_parity.json').readAsStringSync()) as Map<String, dynamic>;

  test('Dart inference matches the Python trainer exactly', () {
    for (final (name, model) in [('expense', expense), ('shopping', shopping)]) {
      final cases = parity[name] as Map<String, dynamic>;
      for (final e in cases.entries) {
        final want = e.value as Map<String, dynamic>;
        final got = model.predict(e.key)!;
        expect(got.label, want['label'], reason: '$name "${e.key}"');
        expect(got.probability, closeTo((want['p'] as num).toDouble(), 1e-9), reason: '$name "${e.key}"');
      }
    }
  });

  test('Turkish-aware normalization and hashing', () {
    expect(TextClassifier.normalize('İSTANBULKART 50₺!'), 'istanbulkart');
    expect(TextClassifier.normalize('KIRA'), 'kira');
    expect(TextClassifier.normalize('NETFLIX'), 'netflix');
    expect(TextClassifier.fnv1a('a'), 0xE40C292C); // FNV-1a 32 reference value
  });

  test('handles typos that keywords miss, and abstains when unsure', () {
    expect(ExpenseParser.categorize('elektirk faturs'), isNull); // keywords miss it
    expect(expense.confident('elektirk faturs')?.label, 'bills');
    expect(expense.confident('otoprk')?.label, 'transport');
    expect(shopping.confident('sampuan')?.label, 'personalCare');
    // Low-confidence guesses are not used (caller falls back to AI / user).
    expect(expense.confident('dogalgz'), isNull);
    expect(expense.confident('zzqxv'), isNull);
  });

  test('parsers use the model only when keywords fail', () {
    final parser = ExpenseParser(model: expense);
    expect(parser.parse('300 elektrik')!.category, ExpenseCategory.bills); // keyword path
    final typo = parser.parse('300 elektirk faturs')!;
    expect(typo.category, ExpenseCategory.bills);
    expect(typo.confident, isTrue);
    expect(const ExpenseParser().parse('300 elektirk faturs')!.confident, isFalse);

    final cat = ShoppingCategorizer(model: shopping);
    expect(cat.categorize('sampuan'), ShoppingCategory.personalCare);
    expect(const ShoppingCategorizer().categorize('sampuan'), isNull);
  });

  test('model files are small enough to bundle', () {
    expect(File('assets/models/expense_classifier.json').lengthSync(), lessThan(200 * 1024));
    expect(File('assets/models/shopping_classifier.json').lengthSync(), lessThan(200 * 1024));
  });
}
