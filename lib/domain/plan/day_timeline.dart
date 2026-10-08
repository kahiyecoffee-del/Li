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

/// Parses a one-line task in Turkish or English, forgiving about how times
/// are typed: "15:00", "15.30", "15 30", "1530", "saat 3", "3'te",
/// "3 buçuk", "akşam 7", "sabah 9:30", "bu akşam", "3pm", "at 9".
/// Durations: "30 dk", "1 saat", "1,5 saat", "1 saat 30 dk", "yarım saat",
/// "çeyrek saat", "2h", "90 min", "half an hour".
QuickTask parseQuickTask(String input) {
  var s = ' ${input.trim()} ';
  int? hour, minutes;
  var minute = 0;

  // Matching runs on a lower-case copy of the same length.
  String low() => s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
  void cut(RegExpMatch m) => s = s.replaceRange(m.start, m.end, ' ' * (m.end - m.start));
  const l = r'a-zçğıöşü';

  // ---- durations (first, so "1 saat" is not read as a time)
  final words = <(String, int)>[
    ('bir buçuk saat', 90),
    ('yarım saat', 30),
    ('çeyrek saat', 15),
    ('bir saat', 60),
    ('iki saat', 120),
    ('half an hour', 30),
    ('an hour', 60),
    ('one hour', 60),
  ];
  for (final (w, v) in words) {
    final m = RegExp('(?<![$l])$w(?![$l])').firstMatch(low());
    if (m != null) {
      minutes = v;
      cut(m);
      break;
    }
  }
  if (minutes == null) {
    final hm = RegExp(
      r'(?<![\d:.])(\d+)\s*(saat|sa|h|hr|hour|hours)\s*(\d+)\s*(dk|dakika|min|mins|minutes|m)(?![a-zçğıöşü])',
    ).firstMatch(low());
    if (hm != null) {
      minutes = int.parse(hm.group(1)!) * 60 + int.parse(hm.group(3)!);
      cut(hm);
    }
  }
  if (minutes == null) {
    final dm = RegExp(
      r'(?<![\d:.])(\d+(?:[.,]\d+)?|\d+ buçuk)\s*(dk|dakika|dakikalık|min|mins|minute|minutes|m|saat|saatlik|sa|h|hr|hrs|hour|hours)(?![a-zçğıöşü])',
    ).firstMatch(low());
    if (dm != null) {
      final raw = dm.group(1)!;
      final n = raw.contains('buçuk') ? int.parse(raw.split(' ').first) + 0.5 : double.parse(raw.replaceAll(',', '.'));
      final unit = dm.group(2)!;
      final isHours = const {'saat', 'saatlik', 'sa', 'h', 'hr', 'hrs', 'hour', 'hours'}.contains(unit);
      final value = (isHours ? n * 60 : n).round();
      if (value > 0 && value <= 16 * 60) {
        minutes = value;
        cut(dm);
      }
    }
  }

  // ---- times
  // Part of the day, which moves 1–11 into the afternoon or evening.
  const parts = <String, int>{
    'öğleden sonra': 12,
    'ögleden sonra': 12,
    'sabah': 0,
    'öğlen': 12,
    'öğle': 12,
    'akşam': 12,
    'aksam': 12,
    'gece': 12,
    'morning': 0,
    'afternoon': 12,
    'evening': 12,
    'tonight': 12,
    'night': 12,
  };
  int adjust(int h, String? part, {bool colloquial = false}) {
    if (part != null) {
      final add = parts[part]!;
      if (part.startsWith('gece') || part == 'night') return h <= 5 ? h : (h < 12 ? h + 12 : h);
      if (part.startsWith('öğle') && h == 12) return 12;
      return h < 12 ? h + add : h;
    }
    // "saat 3", "3'te", "3 buçuk": people mean the afternoon.
    return colloquial && h >= 1 && h <= 6 ? h + 12 : h;
  }

  final partRe = '(?:(${parts.keys.join('|')})\\s+(?:saat\\s+)?)?';
  const sfx = r"(?:['’]?(?:te|ta|de|da|e|a|ye|ya))?";
  final patterns = <(RegExp, void Function(RegExpMatch))>[
    // [akşam] 7:30 / 19.30 / 15:30'da
    (
      RegExp('$partRe(?<![\\d,])([01]?\\d|2[0-3])[:.]([0-5]\\d)(?!\\d)(?:\\s*(am|pm)(?![a-z]))?$sfx'),
      (m) {
        final h = int.parse(m.group(2)!);
        final ampm = m.group(4);
        hour = ampm == null ? adjust(h, m.group(1)) : (h % 12) + (ampm == 'pm' ? 12 : 0);
        minute = int.parse(m.group(3)!);
      },
    ),
    // 3:30 pm / 3pm / 11 am
    (
      RegExp(r'(?<![\d:])(1[0-2]|0?[1-9])(?::([0-5]\d))?\s*(am|pm)(?![a-z])'),
      (m) {
        final h = int.parse(m.group(1)!) % 12;
        hour = m.group(3) == 'pm' ? h + 12 : h;
        minute = int.tryParse(m.group(2) ?? '') ?? 0;
      },
    ),
    // [akşam] [saat] 7 buçuk
    (
      RegExp('$partRe(?:saat\\s+)?(?<![\\d,])([01]?\\d|2[0-3])\\s*buçuk$sfx'),
      (m) {
        hour = adjust(int.parse(m.group(2)!), m.group(1), colloquial: true);
        minute = 30;
      },
    ),
    // 15 30 (a space instead of ":"), not "15 30 tl"
    (
      RegExp(
        r'(?<![\d.,])([01]?\d|2[0-3])\s([0-5]\d)(?!\d)(?!\s*(?:tl|₺|lira|try|usd|eur|dk|dakika|min|saat|sa)\b)' + sfx,
      ),
      (m) {
        hour = int.parse(m.group(1)!);
        minute = int.parse(m.group(2)!);
      },
    ),
    // 1530 / 0930, not "1530 tl"
    (
      RegExp(r'(?<![\d.,₺$€£])([01]\d|2[0-3])([0-5]\d)(?!\d)(?!\s*(?:tl|₺|lira|try|usd|eur|dk|min)\b)' + sfx),
      (m) {
        hour = int.parse(m.group(1)!);
        minute = int.parse(m.group(2)!);
      },
    ),
    // akşam 7 / sabah 9 / evening 7
    (
      RegExp('(${parts.keys.join('|')})\\s+(?:saat\\s+)?([01]?\\d|2[0-3])(?!\\d)$sfx'),
      (m) => hour = adjust(int.parse(m.group(2)!), m.group(1)),
    ),
    // saat 15 / at 9
    (
      RegExp(r'(?<![a-zçğıöşü])(saat|at)\s+([01]?\d|2[0-3])(?!\d)' + sfx),
      (m) => hour = adjust(int.parse(m.group(2)!), null, colloquial: m.group(1) == 'saat'),
    ),
    // 15'te, 9'da, 15te
    (
      RegExp(r"(?<![\d])([01]?\d|2[0-3])['’]?(te|ta|de|da)(?![a-zçğıöşü])"),
      (m) => hour = adjust(int.parse(m.group(1)!), null, colloquial: true),
    ),
    // bu sabah / bu akşam / bu gece / this evening / tonight → a sensible hour
    (
      RegExp(
        r'(?<![a-zçğıöşü])(bu sabah|bu öğlen|bu akşam|bu gece|this morning|this afternoon|this evening|tonight)(?![a-zçğıöşü])',
      ),
      (m) => hour = switch (m.group(1)!) {
        'bu sabah' || 'this morning' => 9,
        'bu öğlen' => 12,
        'this afternoon' => 15,
        'bu gece' => 22,
        'tonight' => 20,
        _ => 19,
      },
    ),
  ];
  for (final (re, apply) in patterns) {
    final m = re.firstMatch(low());
    if (m != null) {
      apply(m);
      cut(m);
      break;
    }
  }

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
  const TaskBlock(this.task, super.start, super.end, {this.clash});
  final TaskItem task;

  /// An earlier task this one starts inside of (they overlap).
  final TaskItem? clash;
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
  TaskItem? longest; // the timed task that ends last so far
  DateTime? longestEnd;
  for (final t in timed) {
    final start = t.scheduledAt!;
    final end = start.add(Duration(minutes: t.estimatedMinutes));
    if (start.difference(cursor).inMinutes >= minGap) out.add(FreeGap(cursor, start));
    final clash = longestEnd != null && start.isBefore(longestEnd) ? longest : null;
    out.add(TaskBlock(t, start, end, clash: clash));
    if (longestEnd == null || end.isAfter(longestEnd)) {
      longest = t;
      longestEnd = end;
    }
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

DateTime _end(TaskItem t) => t.scheduledAt!.add(Duration(minutes: t.estimatedMinutes));

List<TaskItem> _timedOn(List<TaskItem> tasks, DateTime day, {String? exceptId}) =>
    tasks
        .where(
          (t) =>
              !t.deleted &&
              !t.isCompleted &&
              t.id != exceptId &&
              t.scheduledAt != null &&
              Dates.sameDay(t.scheduledAt!, day),
        )
        .toList()
      ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

/// The first open task that [start]–[start]+[minutes] would overlap, if any.
TaskItem? clashFor(List<TaskItem> tasks, DateTime start, int minutes, {String? exceptId}) {
  final end = start.add(Duration(minutes: minutes));
  for (final t in _timedOn(tasks, start, exceptId: exceptId)) {
    if (t.scheduledAt!.isBefore(end) && _end(t).isAfter(start)) return t;
  }
  return null;
}

/// The earliest start at or after [from] where [minutes] fit without
/// touching another open task that day, or null when nothing fits before
/// [dayEnd].
DateTime? nextFreeStart(
  List<TaskItem> tasks,
  DateTime from,
  int minutes, {
  required DateTime dayEnd,
  String? exceptId,
}) {
  var at = from;
  for (final t in _timedOn(tasks, from, exceptId: exceptId)) {
    if (!_end(t).isAfter(at)) continue;
    if (!t.scheduledAt!.isBefore(at.add(Duration(minutes: minutes)))) break;
    at = _end(t);
  }
  return at.add(Duration(minutes: minutes)).isAfter(dayEnd) ? null : at;
}

/// How many open timed tasks on [day] overlap one before them.
int countClashes(List<TaskItem> tasks, DateTime day) {
  var n = 0;
  DateTime? lastEnd;
  for (final t in _timedOn(tasks, day)) {
    if (lastEnd != null && t.scheduledAt!.isBefore(lastEnd)) n++;
    final e = _end(t);
    if (lastEnd == null || e.isAfter(lastEnd)) lastEnd = e;
  }
  return n;
}

/// Untangles [day]: keeps the order people chose and slides each task that
/// overlaps the one before it to right after it. Returns task id → new start
/// (only the ones that move).
Map<String, DateTime> resolveClashes(List<TaskItem> tasks, DateTime day) {
  final out = <String, DateTime>{};
  DateTime? cursor;
  for (final t in _timedOn(tasks, day)) {
    var start = t.scheduledAt!;
    if (cursor != null && start.isBefore(cursor)) {
      start = cursor;
      out[t.id] = start;
    }
    final e = start.add(Duration(minutes: t.estimatedMinutes));
    if (cursor == null || e.isAfter(cursor)) cursor = e;
  }
  return out;
}
