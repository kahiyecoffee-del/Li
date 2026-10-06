import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/lio/lio_brain.dart';
import 'package:lifeos/l10n/gen/app_localizations_en.dart';
import 'package:lifeos/l10n/gen/app_localizations_tr.dart';

void main() {
  final en = AppLocalizationsEn();
  final tr = AppLocalizationsTr();

  test('understands everyday questions in Turkish and English', () {
    expect(LioBrain.intentOf('Bugün planım ne?'), LioIntent.plan);
    expect(LioBrain.intentOf('Günümü planla'), LioIntent.plan);
    expect(LioBrain.intentOf('Bugün ne kadar harcayabilirim'), LioIntent.money);
    expect(LioBrain.intentOf('Akşam yemeği için ne pişireyim?'), LioIntent.food);
    expect(LioBrain.intentOf('Çok yorgunum ve stresliyim'), LioIntent.feelLow);
    expect(LioBrain.intentOf('Merhaba Lio'), LioIntent.greeting);
    expect(LioBrain.intentOf('Teşekkürler'), LioIntent.thanks);
    expect(LioBrain.intentOf('What should I cook for dinner?'), LioIntent.food);
    expect(LioBrain.intentOf('How am I doing?'), LioIntent.score);
    expect(LioBrain.intentOf('asdfgh'), LioIntent.unknown);
  });

  test('plan answers list open tasks and suggest the first', () {
    final r = LioBrain.reply(
      'plan my day',
      const LioFacts(todayTasks: [('Gym', '08:00', false), ('Email', null, true), ('Call mom', '18:00', false)]),
      en,
      inspirations: const ['x'],
    );
    expect(r.text, contains('2 things'));
    expect(r.text, contains('08:00 Gym'));
    expect(r.text, isNot(contains('Email')));
    expect(r.text, contains('Start with “Gym”'));
  });

  test('money answers use the real budget, in Turkish too', () {
    final r = LioBrain.reply(
      'bütçem',
      const LioFacts(safeDaily: '₺500', leftToday: '₺320'),
      tr,
      inspirations: const [],
    );
    expect(r.text, contains('₺320'));
    expect(r.text, contains('₺500'));
    final over = LioBrain.reply(
      'money',
      const LioFacts(safeDaily: '₺500', overToday: '₺80'),
      en,
      inspirations: const [],
    );
    expect(over.text, contains('₺80 over'));
    expect(LioBrain.reply('money', const LioFacts(), en, inspirations: const []).text, en.brainMoneyNoBudget);
  });

  test('unknown questions get a friendly pointer, never an invented answer', () {
    expect(
      LioBrain.reply('what is quantum gravity', const LioFacts(), en, inspirations: const []).text,
      en.brainFallback,
    );
  });
}
