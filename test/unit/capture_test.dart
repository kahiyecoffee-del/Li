import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/capture/capture.dart';
import 'package:lifeos/domain/models/enums.dart';

void main() {
  final now = DateTime(2026, 6, 10, 9); // Wednesday

  test('day words', () {
    expect(parseDay('yarın dişçi', now)!.day, DateTime(2026, 6, 11));
    expect(parseDay('yarın dişçi', now)!.rest, 'dişçi');
    expect(parseDay('cuma toplantı', now)!.day, DateTime(2026, 6, 12));
    expect(parseDay('cumartesi piknik', now)!.day, DateTime(2026, 6, 13));
    expect(parseDay("pazartesi'ye rapor", now)!.day, DateTime(2026, 6, 15));
    expect(parseDay('call mom on friday', now)!.day, DateTime(2026, 6, 12));
    expect(parseDay('wednesday gym', now)!.day, DateTime(2026, 6, 10));
    expect(parseDay('market alışverişi', now), isNull);
  });

  test('tasks: time or day wins even with numbers', () {
    final c = classifyCapture('yarın 15:00 dişçi 30 dk', now);
    expect(c.kind, CaptureKind.task);
    expect(c.day, DateTime(2026, 6, 11));
    expect(c.task!.title, 'Dişçi');
    expect(c.task!.hour, 15);
    expect(c.task!.minutes, 30);
    expect(classifyCapture('annemi ara', now).kind, CaptureKind.task);
    expect(classifyCapture('dişçi 15 30', now).task!.hour, 15);
    expect(classifyCapture('1530 tl market', now).kind, CaptureKind.expense);
    expect(classifyCapture('bu akşam sinema', now).task!.hour, 19);
    expect(classifyCapture('annemi ara', now).day, DateTime(2026, 6, 10));
  });

  test('expenses', () {
    final c = classifyCapture('250 TL market', now);
    expect(c.kind, CaptureKind.expense);
    expect(c.expense!.amountMinor, 25000);
    expect(c.expense!.category, ExpenseCategory.food);
    expect(classifyCapture('taxi 85', now).kind, CaptureKind.expense);
    expect(classifyCapture('maaş 45000 tl', now).expense!.type, TransactionType.income);
  });

  test('shopping', () {
    final c = classifyCapture('süt yumurta ekmek al', now);
    expect(c.kind, CaptureKind.shopping);
    expect(c.items, containsAll(['süt', 'yumurta', 'ekmek']));
    expect(classifyCapture('buy milk, eggs', now).items, containsAll(['milk', 'eggs']));
  });

  test('journal', () {
    expect(classifyCapture('bugün çok yorgunum ama mutluyum', now).kind, CaptureKind.journal);
    expect(classifyCapture('I feel calm after the walk', now).kind, CaptureKind.journal);
  });
}
