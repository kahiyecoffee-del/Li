import '../../core/utils/dates.dart';
import '../models/enums.dart';
import '../models/routine_goal.dart';
import '../models/task_item.dart';

/// Ready-made routines the user can add and then change.
class RoutineTemplate {
  const RoutineTemplate(this.key, this.emoji, this.start, this.en, this.tr, this.steps);
  final String key;
  final String emoji;

  /// Minutes after midnight.
  final int start;
  final String en, tr;

  /// (English, Turkish, minutes, category)
  final List<(String, String, int, TaskCategory)> steps;

  Routine toRoutine(String id, String lang) => Routine(
    id: id,
    updatedAt: DateTime.now(),
    name: lang == 'tr' ? tr : en,
    emoji: emoji,
    startMinutes: start,
    steps: [for (final (e, t, m, c) in steps) RoutineStep(lang == 'tr' ? t : e, m, category: c)],
  );
}

const routineTemplates = <RoutineTemplate>[
  RoutineTemplate('morning', '🌅', 7 * 60, 'Morning routine', 'Sabah rutini', [
    ('Drink a glass of water', 'Bir bardak su iç', 5, TaskCategory.health),
    ('Stretch', 'Esneme', 10, TaskCategory.health),
    ('Shower', 'Duş', 15, TaskCategory.personal),
    ('Breakfast', 'Kahvaltı', 20, TaskCategory.health),
    ('Plan the day', 'Günü planla', 10, TaskCategory.personal),
  ]),
  RoutineTemplate('focus', '🎯', 9 * 60, 'Focus block', 'Odak bloğu', [
    ('Deep work', 'Derin çalışma', 50, TaskCategory.work),
    ('Break: walk, water', 'Mola: yürü, su iç', 10, TaskCategory.health),
    ('Deep work', 'Derin çalışma', 50, TaskCategory.work),
    ('Inbox and messages', 'E-posta ve mesajlar', 20, TaskCategory.work),
  ]),
  RoutineTemplate('workout', '💪', 18 * 60, 'Workout', 'Spor', [
    ('Warm up', 'Isınma', 10, TaskCategory.health),
    ('Training', 'Antrenman', 45, TaskCategory.health),
    ('Stretch', 'Esneme', 10, TaskCategory.health),
    ('Protein snack', 'Protein atıştırmalığı', 10, TaskCategory.health),
  ]),
  RoutineTemplate('evening', '🌙', 21 * 60 + 30, 'Evening wind-down', 'Akşam rutini', [
    ('Plan tomorrow', 'Yarını planla', 10, TaskCategory.personal),
    ('Write in your journal', 'Günlük yaz', 10, TaskCategory.personal),
    ('Screen-free time', 'Ekransız zaman', 30, TaskCategory.health),
    ('Read', 'Kitap oku', 20, TaskCategory.learning),
  ]),
  RoutineTemplate('cleaning', '🧺', 10 * 60, 'Home reset', 'Ev toparlama', [
    ('Laundry', 'Çamaşır', 30, TaskCategory.errands),
    ('Kitchen', 'Mutfak', 30, TaskCategory.errands),
    ('Dusting', 'Toz alma', 20, TaskCategory.errands),
    ('Groceries list', 'Market listesi', 10, TaskCategory.errands),
  ]),
];

/// The routine's steps as back-to-back tasks on [day] from [startMinutes].
List<TaskItem> routineTasks(
  Routine r,
  DateTime day,
  int startMinutes, {
  required DateTime now,
  required String Function() newId,
}) {
  var at = Dates.dateOnly(day).add(Duration(minutes: startMinutes));
  return [
    for (final (i, s) in r.steps.indexed)
      () {
        final t = TaskItem(
          id: newId(),
          updatedAt: now,
          title: s.title,
          estimatedMinutes: s.minutes,
          category: s.category,
          scheduledAt: at,
          createdAt: now,
          // One reminder for the routine (its first step), not one per step.
          remindBefore: i == 0 ? null : -1,
        );
        at = at.add(Duration(minutes: s.minutes));
        return t;
      }(),
  ];
}
