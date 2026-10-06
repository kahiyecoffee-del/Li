import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/widgets/mascot.dart';
import 'package:lifeos/features/lio/lio_companion.dart';
import 'package:lifeos/l10n/gen/app_localizations_en.dart';

void main() {
  final l = AppLocalizationsEn();

  List<LioLine> lines({
    int tab = 0,
    int hour = 10,
    int goalsLeft = 0,
    bool allDone = false,
    bool over = false,
    String? left,
    int streak = 0,
    bool mood = true,
  }) => LioScript.lines(
    l: l,
    tab: tab,
    hour: hour,
    goalsLeft: goalsLeft,
    allGoalsDone: allDone,
    overBudgetToday: over,
    budgetLeftToday: left,
    streak: streak,
    moodLogged: mood,
  );

  LioLine top(List<LioLine> x) => x.reduce((a, b) => b.priority > a.priority ? b : a);

  test('celebrates when every goal is done', () {
    final t = top(lines(allDone: true));
    expect(t.text, l.lioAllDone);
    expect(t.mood, MascotMood.excited);
  });

  test('gently warns about the budget on the Money tab', () {
    expect(top(lines(tab: 2, over: true)).text, l.lioOverBudget);
    expect(top(lines(tab: 2, left: '₺500')).text, l.lioUnderBudget('₺500'));
  });

  test('suggests rest late at night', () {
    expect(top(lines(hour: 23)).mood, MascotMood.sleepy);
  });

  test('always has tab tips and inspiration to fall back on', () {
    for (var tab = 0; tab < 4; tab++) {
      final x = lines(tab: tab);
      expect(x.where((e) => e.mood == MascotMood.curious), isNotEmpty);
      expect(x.where((e) => e.mood == MascotMood.loving).length, 12);
    }
  });
}
