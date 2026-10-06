import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/models/enums.dart';
import 'package:lifeos/domain/models/task_item.dart';
import 'package:lifeos/services/widget/home_widget_service.dart';

void main() {
  final now = DateTime(2026, 6, 10, 8);
  TaskItem t(String id, {DateTime? at, DateTime? due, TaskPriority p = TaskPriority.medium, DateTime? done}) =>
      TaskItem(
        id: id,
        updatedAt: now,
        title: id,
        priority: p,
        scheduledAt: at,
        deadline: due,
        completedAt: done,
        createdAt: now,
      );

  test('today\'s program: timed first by time, then overdue/undated by priority; done and future left out', () {
    final program = todaysProgram([
      t('later', at: DateTime(2026, 6, 10, 15)),
      t('early', at: DateTime(2026, 6, 10, 9, 5)),
      t('low', due: DateTime(2026, 6, 10), p: TaskPriority.low),
      t('overdue-high', due: DateTime(2026, 6, 8), p: TaskPriority.high),
      t('tomorrow', at: DateTime(2026, 6, 11, 9)),
      t('done', at: DateTime(2026, 6, 10, 10), done: now),
    ], now);
    expect(program.map((x) => x.id), ['early', 'later', 'overdue-high', 'low']);
    expect(programLines(program, now, max: 3), ['09:05  early', '15:00  later', '•  overdue-high']);
  });

  test('widget link opens the route it carries, plan otherwise', () {
    expect(DeviceHomeWidget.routeOf(Uri.parse('dayly://open?homeWidget&r=%2Fai%3Ftopic%3Dplan')), '/ai?topic=plan');
    expect(DeviceHomeWidget.routeOf(Uri.parse('dayly://open?homeWidget')), '/plan');
    expect(DeviceHomeWidget.routeOf(Uri.parse('dayly://open?homeWidget&r=https://evil')), '/plan');
  });

  test('Lio\'s pose follows the day', () {
    expect(widgetMood(left: 2, doneToday: false, now: DateTime(2026, 6, 10, 9)), 'happy');
    expect(widgetMood(left: 0, doneToday: true, now: DateTime(2026, 6, 10, 18)), 'excited');
    expect(widgetMood(left: 0, doneToday: false, now: DateTime(2026, 6, 10, 9)), 'curious');
    expect(widgetMood(left: 6, doneToday: false, now: DateTime(2026, 6, 10, 9)), 'thoughtful');
    expect(widgetMood(left: 2, doneToday: false, now: DateTime(2026, 6, 10, 23)), 'sleepy');
  });
}
