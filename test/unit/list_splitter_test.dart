import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/problem/list_splitter.dart';

void main() {
  test('separators always win', () {
    expect(ListSplitter.split('rapor yaz, spor', ListKind.tasks), ['rapor yaz', 'spor']);
    expect(ListSplitter.split('yumurta ve domates', ListKind.ingredients), ['yumurta', 'domates']);
    expect(ListSplitter.split('pizza\nsushi', ListKind.options), ['pizza', 'sushi']);
  });

  test('ingredients without commas, multi-word names kept', () {
    expect(ListSplitter.split('yumurta domates peynir ekmek', ListKind.ingredients), [
      'yumurta',
      'domates',
      'peynir',
      'ekmek',
    ]);
    expect(ListSplitter.split('makarna zeytin yağı sarımsak', ListKind.ingredients), [
      'makarna',
      'zeytin yağı',
      'sarımsak',
    ]);
    expect(ListSplitter.split('eggs tomato olive oil', ListKind.ingredients), ['eggs', 'tomato', 'olive oil']);
  });

  test('options without commas keep model numbers', () {
    expect(ListSplitter.split('pizza sushi burger', ListKind.options), ['pizza', 'sushi', 'burger']);
    expect(ListSplitter.split('iPhone 15 Pro Galaxy S24', ListKind.options), ['iPhone 15 Pro', 'Galaxy S24']);
  });

  test('Turkish tasks end with a verb; compounds stay together', () {
    expect(ListSplitter.split('rapor yaz annemi ara spor', ListKind.tasks), ['rapor yaz', 'annemi ara', 'spor']);
    expect(ListSplitter.split('fatura öde market alışverişi', ListKind.tasks), ['fatura öde', 'market alışverişi']);
    expect(ListSplitter.split('spor market alışverişi yap', ListKind.tasks), ['spor', 'market alışverişi yap']);
    expect(ListSplitter.split('spor salonu kitap oku', ListKind.tasks), ['spor salonu', 'kitap oku']);
  });

  test('English tasks start with a verb', () {
    expect(ListSplitter.split('write the report call mom buy milk', ListKind.tasks), [
      'write the report',
      'call mom',
      'buy milk',
    ]);
  });
}
