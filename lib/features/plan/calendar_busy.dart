import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/dates.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/task_item.dart';
import '../../domain/plan/day_timeline.dart';
import '../../services/calendar/calendar_service.dart';

/// The phone's calendar events on [day] (empty unless the person turned the
/// calendar on and allowed access).
final calendarDayProvider = FutureProvider.autoDispose.family<List<CalendarEvent>, DateTime>((ref, day) async {
  if (!ref.watch(settingsProvider.select((s) => s.showCalendar))) return const [];
  final calendar = ref.watch(servicesProvider).calendar;
  final from = Dates.dateOnly(day);
  return calendar.events(from, Dates.addDays(from, 1));
});

/// Timed events as fixed, read-only blocks the planner works around.
List<TaskItem> calendarBusy(List<CalendarEvent> events) => [
  for (final e in events)
    if (!e.allDay && e.minutes > 0)
      TaskItem(
        id: '$calendarIdPrefix${e.id}',
        updatedAt: e.start,
        title: e.title,
        priority: TaskPriority.high,
        category: TaskCategory.other,
        scheduledAt: e.start,
        estimatedMinutes: e.minutes,
        createdAt: e.start,
        remindBefore: -1,
      ),
];

/// Busy calendar time on [day], from what is already loaded.
List<TaskItem> busyOn(WidgetRef ref, DateTime day) =>
    calendarBusy(ref.read(calendarDayProvider(Dates.dateOnly(day))).value ?? const []);
