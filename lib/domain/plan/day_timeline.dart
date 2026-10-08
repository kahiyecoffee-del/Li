import '../../core/utils/dates.dart';
import '../models/task_item.dart';

/// What the quick-add line understood: "15:00 dişçi 30 dk" → title
/// "Dişçi", at 15:00, 30 minutes.
class QuickTask {
  const QuickTask(this.title, {this.hour, this.minute = 0, this.minutes});
  final String title;
  final int? hour;
  final int minute;
  final int? minutes;

  bool get hasTime => hour != null;
}

/// Parses a one-line task in Turkish or English. Understands times
/// ("15:00", "9.30", "saat 15", "15'te", "3pm", "at 9") and durations
/// ("30 dk", "45 dakika", "1 saat", "1,5 saat", "2h", "90 min").
QuickTask parseQuickTask(String input) {
  var s = ' ${input.trim()} ';
  int? hour, minutes;
  var minute = 0;

  // Durations first so "1 saat" is not read as a time.
  final dur = RegExp(
    r'(?<![\d:.])(\d+(?:[.,]\d+)?)\s*(dk|dakika|dakikalık|min|mins|minute|minutes|m|saat|saatlik|sa|h|hr|hrs|hour|hours)(?=[\s,.!?]|$)',
    caseSensitive: false,
  );
  final dm = dur.firstMatch(s);
  // "saat 15" (time) has the number after "saat"; "1 saat" (duration) before.
  if (dm != null) {
    final n = double.parse(dm.group(1)!.replaceAll(',', '.'));
    final unit = dm.group(2)!.toLowerCase();
    final isHours = const {'saat', 'saatlik', 'sa', 'h', 'hr', 'hrs', 'hour', 'hours'}.contains(unit);
    final value = (isHours ? n * 60 : n).round();
    if (value > 0 && value <= 16 * 60) {
      minutes = value;
      s = s.replaceRange(dm.start, dm.end, ' ');
    }
  }

  RegExpMatch? m;
  // 15:00 / 9.30
  m = RegExp(r'(?<![\d,])([01]?\d|2[0-3])[:.]([0-5]\d)(?!\d)').firstMatch(s);
  if (m != null) {
    hour = int.parse(m.group(1)!);
    minute = int.parse(m.group(2)!);
  } else {
    // 3pm / 11 am
    m = RegExp(r'(?<!\d)(1[0-2]|0?[1-9])\s*(am|pm)\b', caseSensitive: false).firstMatch(s);
    if (m != null) {
      final h = int.parse(m.group(1)!) % 12;
      hour = m.group(2)!.toLowerCase() == 'pm' ? h + 12 : h;
    } else {
      // saat 15 / at 9
      m = RegExp(r'\b(saat|at)\s+([01]?\d|2[0-3])(?!\d)', caseSensitive: false).firstMatch(s);
      if (m != null) {
        hour = int.parse(m.group(2)!);
      } else {
        // 15'te, 9'da, 15te
        m = RegExp(r"(?<!\d)([01]?\d|2[0-3])['’]?(te|ta|de|da)\b", caseSensitive: false).firstMatch(s);
        if (m != null) hour = int.parse(m.group(1)!);
      }
    }
  }
  if (m != null && hour != null) s = s.replaceRange(m.start, m.end, ' ');

  var title = s.replaceAll(RegExp(r'\s+'), ' ').trim().replaceAll(RegExp(r'^[,.\-–:]+|[,.\-–:]+$'), '').trim();
  if (title.isNotEmpty) title = _capitalize(title);
  return QuickTask(title, hour: hour, minute: minute, minutes: minutes);
}

String _capitalize(String s) {
  final first = s[0];
  final upper = first == 'i' ? 'İ' : (first == 'ı' ? 'I' : first.toUpperCase());
  return '$upper${s.substring(1)}';
}

sealed class TimelineEntry {
  const TimelineEntry(this.start, this.end);
  final DateTime start;
  final DateTime end;
  int get minutes => end.difference(start).inMinutes;
}

class TaskBlock extends TimelineEntry {
  const TaskBlock(this.task, super.start, super.end);
  final TaskItem task;
}

class FreeGap extends TimelineEntry {
  const FreeGap(super.start, super.end);
}

/// The day as blocks of timed tasks with the free time between them.
/// Gaps shorter than [minGap] minutes are not shown. On [now]'s day, free
/// time in the past is not offered.
List<TimelineEntry> buildTimeline({
  required List<TaskItem> tasks,
  required DateTime day,
  required DateTime dayStart,
  required DateTime dayEnd,
  required DateTime now,
  int minGap = 30,
}) {
  final timed = tasks.where((t) => !t.deleted && t.scheduledAt != null && Dates.sameDay(t.scheduledAt!, day)).toList()
    ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
  final out = <TimelineEntry>[];
  final isToday = Dates.sameDay(day, now);
  var cursor = dayStart;
  if (isToday && now.isAfter(cursor)) {
    // Round up to the next quarter hour.
    final q = (now.minute / 15).ceil() * 15;
    cursor = DateTime(now.year, now.month, now.day, now.hour).add(Duration(minutes: q));
  }
  if (Dates.dateOnly(day).isBefore(Dates.dateOnly(now))) cursor = dayEnd; // no gaps in the past
  for (final t in timed) {
    final start = t.scheduledAt!;
    final end = start.add(Duration(minutes: t.estimatedMinutes));
    if (start.difference(cursor).inMinutes >= minGap) out.add(FreeGap(cursor, start));
    out.add(TaskBlock(t, start, end));
    if (end.isAfter(cursor)) cursor = end;
  }
  if (dayEnd.difference(cursor).inMinutes >= minGap) out.add(FreeGap(cursor, dayEnd));
  return out;
}

class DayStats {
  const DayStats({required this.total, required this.done, required this.plannedMinutes, required this.freeMinutes});
  final int total;
  final int done;
  final int plannedMinutes;
  final int freeMinutes;
  double get progress => total == 0 ? 0 : done / total;
}

DayStats dayStats(List<TaskItem> dayTasks, List<TimelineEntry> timeline) => DayStats(
  total: dayTasks.length,
  done: dayTasks.where((t) => t.isCompleted).length,
  plannedMinutes: dayTasks.where((t) => !t.isCompleted).fold(0, (s, t) => s + t.estimatedMinutes),
  freeMinutes: timeline.whereType<FreeGap>().fold(0, (s, g) => s + g.minutes),
);
