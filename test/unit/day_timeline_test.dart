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

    test('English', () {
      check('dentist 3pm 45 min', 'Dentist', hour: 15, minutes: 45);
      check('call mom at 9', 'Call mom', hour: 9);
      check('gym 2h', 'Gym', minutes: 120);
      check('Team sync 10:15', 'Team sync', hour: 10, minute: 15);
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
