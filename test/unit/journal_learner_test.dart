import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/utils/dates.dart';
import 'package:lifeos/domain/lio/journal_learner.dart';

void main() {
  const learner = JournalLearner();
  final start = DateTime(2026, 10, 1);
  DateTime day(int i) => Dates.addDays(start, i);

  test('finds themes and what lifts or drains the mood', () {
    final notes = <JournalNote>[];
    final moods = <String, int>{};
    for (var i = 0; i < 12; i++) {
      final sport = i.isEven;
      final traffic = !sport && i < 6;
      notes.add(
        JournalNote(
          day(i),
          [
            if (sport) 'Sabah spora gittim, çok iyi geldi.',
            if (traffic) 'Trafikte iki saat kaldım.',
            'Annemle konuştum.',
          ].join(' '),
        ),
      );
      moods[Dates.dayKey(day(i))] = sport ? 5 : (traffic ? 2 : 3);
    }
    final p = learner.learn(notes, moods, Dates.dayKey);
    expect(p.themes.first.word, 'annemle');
    expect(p.themes.map((t) => t.word), contains('spora'));
    expect(p.lifts.first.word, 'spora');
    expect(p.lifts.first.withMood, 5);
    expect(p.drains.map((d) => d.word), contains('trafikte'));
  });

  test('too little data: no patterns claimed', () {
    final p = learner.learn(
      [JournalNote(day(0), 'Spor yaptım'), JournalNote(day(1), 'Spor yaptım')],
      {Dates.dayKey(day(0)): 5, Dates.dayKey(day(1)): 4},
      Dates.dayKey,
    );
    expect(p.isEmpty, isTrue);
  });
}
