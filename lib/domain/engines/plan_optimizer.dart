import '../../core/utils/dates.dart';
import '../models/task_item.dart';

class PlannedSlot {
  const PlannedSlot(this.task, this.start);

  final TaskItem task;
  final DateTime start;
  DateTime get end => start.add(Duration(minutes: task.estimatedMinutes));
}

/// Deterministic day planner used by "Optimize my plan".
///
/// Ordering: overdue → deadline today → priority (high first) → earliest
/// deadline → shorter first. Tasks with a fixed scheduled time (meetings) are
/// kept in place; flexible tasks fill the gaps between [dayStart] and
/// [dayEnd] with a 10-minute buffer between blocks.
class PlanOptimizer {
  const PlanOptimizer({this.bufferMinutes = 10});

  final int bufferMinutes;

  List<TaskItem> prioritize(List<TaskItem> tasks, DateTime now) {
    final today = Dates.dateOnly(now);
    int rank(TaskItem t) {
      final d = t.deadline;
      if (d != null && Dates.dateOnly(d).isBefore(today)) return 0;
      if (d != null && Dates.sameDay(d, today)) return 1;
      return 2;
    }

    final open = tasks.where((t) => !t.deleted && !t.isCompleted).toList();
    open.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      final p = b.priority.index.compareTo(a.priority.index);
      if (p != 0) return p;
      final ad = a.deadline ?? DateTime(9999);
      final bd = b.deadline ?? DateTime(9999);
      final d = ad.compareTo(bd);
      if (d != 0) return d;
      final m = a.estimatedMinutes.compareTo(b.estimatedMinutes);
      return m != 0 ? m : a.createdAt.compareTo(b.createdAt);
    });
    return open;
  }

  /// [fixed] are tasks that must keep their `scheduledAt` (e.g. meetings).
  /// Returns slots for flexible tasks that fit today; others stay unscheduled.
  List<PlannedSlot> schedule({
    required List<TaskItem> flexible,
    required List<TaskItem> fixed,
    required DateTime now,
    required DateTime dayStart,
    required DateTime dayEnd,
  }) {
    final busy =
        fixed
            .where((t) => t.scheduledAt != null && !t.deleted)
            .map((t) => (t.scheduledAt!, t.scheduledAt!.add(Duration(minutes: t.estimatedMinutes))))
            .toList()
          ..sort((a, b) => a.$1.compareTo(b.$1));

    var cursor = now.isAfter(dayStart) ? _roundUp(now) : dayStart;
    final slots = <PlannedSlot>[];
    for (final t in prioritize(flexible, now)) {
      final dur = Duration(minutes: t.estimatedMinutes);
      var placed = false;
      var candidate = cursor;
      while (!placed) {
        final end = candidate.add(dur);
        if (end.isAfter(dayEnd)) break;
        final clash = busy.where((b) => candidate.isBefore(b.$2) && end.isAfter(b.$1)).toList();
        if (clash.isEmpty) {
          slots.add(PlannedSlot(t, candidate));
          busy.add((candidate, end));
          busy.sort((a, b) => a.$1.compareTo(b.$1));
          placed = true;
        } else {
          candidate = clash
              .map((b) => b.$2)
              .reduce((a, b) => a.isAfter(b) ? a : b)
              .add(Duration(minutes: bufferMinutes));
        }
      }
      if (placed) cursor = slots.last.end.add(Duration(minutes: bufferMinutes));
    }
    return slots;
  }

  static DateTime _roundUp(DateTime t) {
    final m = (t.minute / 15).ceil() * 15;
    return DateTime(t.year, t.month, t.day, t.hour).add(Duration(minutes: m));
  }
}
