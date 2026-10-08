import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/models/task_item.dart';
import 'package:lifeos/domain/plan/day_timeline.dart';

void main() {
  group('quick add', () {
    void check(String input, String title, {int? hour, int minute = 0, int? minutes}) {
      final q = parseQuickTask(input);
      expect(q.title, title, reason: input);
      expect(q.hour, hour, reason: input);
      if (hour != null) expect(q.minute, minute, reason: input);
      expect(q.minutes, minutes, reason: input);
    }

    test('Turkish', () {
      check('15:00 dişçi 30 dk', 'Dişçi', hour: 15, minutes: 30);
      check('saat 9 spor 1 saat', 'Spor', hour: 9, minutes: 60);
      check("annemi ara 18'de", 'Annemi ara', hour: 18);
      check('rapor yaz 1,5 saat', 'Rapor yaz', minutes: 90);
      check('ilaç 21.30', 'İlaç', hour: 21, minute: 30);
      check('market alışverişi', 'Market alışverişi');
    });

    test('forgiving: how people really type times', () {
      check('dişçi 15 30', 'Dişçi', hour: 15, minute: 30);
      check('dişçi 1530', 'Dişçi', hour: 15, minute: 30);
      check("toplantı 15:30'da", 'Toplantı', hour: 15, minute: 30);
      check('kahve 3 buçuk', 'Kahve', hour: 15, minute: 30);
      check('akşam 7 yemek', 'Yemek', hour: 19);
      check('akşam 7 buçuk sinema', 'Sinema', hour: 19, minute: 30);
      check('sabah 9:30 koşu', 'Koşu', hour: 9, minute: 30);
      check("saat 3'te annem", 'Annem', hour: 15);
      check('öğlen 1 yemek', 'Yemek', hour: 13);
      check('gece 11 kitap', 'Kitap', hour: 23);
      check('bu akşam sinema', 'Sinema', hour: 19);
      check('spor yarım saat', 'Spor', minutes: 30);
      check('ders 1 saat 30 dk', 'Ders', minutes: 90);
      check('ders 1 buçuk saat', 'Ders', minutes: 90);
      check('10 30 ders 45 dk', 'Ders', hour: 10, minute: 30, minutes: 45);
      check('sabah koşusu', 'Sabah koşusu'); // no hour: stays a title
    });

    test('English', () {
      check('dentist 3pm 45 min', 'Dentist', hour: 15, minutes: 45);
      check('call mom at 9', 'Call mom', hour: 9);
      check('gym 2h', 'Gym', minutes: 120);
      check('Team sync 10:15', 'Team sync', hour: 10, minute: 15);
      check('dinner 7:30 pm', 'Dinner', hour: 19, minute: 30);
      check('read half an hour', 'Read', minutes: 30);
      check('call evening 7', 'Call', hour: 19);
    });
  });

  group('timeline', () {
    final day = DateTime(2026, 6, 10);
    TaskItem t(String id, int h, int m, int mins, {bool done = false}) => TaskItem(
      id: id,
      updatedAt: day,
      title: id,
      scheduledAt: DateTime(2026, 6, 10, h, m),
      estimatedMinutes: mins,
      completedAt: done ? day : null,
      createdAt: day,
    );

    test('blocks with the free time between them; nothing before now', () {
      final entries = buildTimeline(
        tasks: [t('b', 13, 0, 60), t('a', 10, 0, 30)],
        day: day,
        dayStart: DateTime(2026, 6, 10, 8),
        dayEnd: DateTime(2026, 6, 10, 22),
        now: DateTime(2026, 6, 10, 9, 5),
      );
      expect(entries.map((e) => e.runtimeType), [FreeGap, TaskBlock, FreeGap, TaskBlock, FreeGap]);
      expect(entries.first.start, DateTime(2026, 6, 10, 9, 15)); // rounded up from now
      expect((entries[1] as TaskBlock).task.id, 'a');
      expect(entries[2].minutes, 150);
      final stats = dayStats([t('a', 10, 0, 30), t('b', 13, 0, 60, done: true)], entries);
      expect(stats.done, 1);
      expect(stats.plannedMinutes, 30);
      expect(stats.progress, 0.5);
    });

    test('short gaps are hidden and past days have no free time', () {
      final entries = buildTimeline(
        tasks: [t('a', 10, 0, 60), t('b', 11, 15, 30)],
        day: day,
        dayStart: DateTime(2026, 6, 10, 8),
        dayEnd: DateTime(2026, 6, 10, 22),
        now: DateTime(2026, 6, 12),
      );
      expect(entries.whereType<FreeGap>(), isEmpty);
      expect(entries.length, 2);
    });
  });
}
