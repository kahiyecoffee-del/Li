import 'dart:async';

import 'package:home_widget/home_widget.dart';

import '../../core/utils/dates.dart';
import '../../domain/models/task_item.dart';

/// What the home-screen widget shows: today's program at a glance.
class TodayWidgetData {
  const TodayWidgetData({
    required this.day,
    required this.title,
    required this.lines,
    required this.summary,
    required this.staleHint,
    required this.route,
  });

  /// `yyyy-MM-dd`; the widget hides [lines] once this is not today.
  final String day;
  final String title;
  final List<String> lines;
  final String summary;

  /// Shown when the data is from an earlier day (app not opened yet today).
  final String staleHint;

  /// Where a tap opens the app.
  final String route;
}

/// Today's unfinished tasks (and overdue ones), timed tasks first by time,
/// then the rest by priority.
List<TaskItem> todaysProgram(List<TaskItem> tasks, DateTime now) {
  final today = Dates.dateOnly(now);
  final out = tasks.where((t) {
    if (t.deleted || t.isCompleted) return false;
    final a = t.anchorDate;
    return a != null && !Dates.dateOnly(a).isAfter(today);
  }).toList();
  bool timedToday(TaskItem t) => t.scheduledAt != null && Dates.dayKey(t.scheduledAt!) == Dates.dayKey(today);
  out.sort((a, b) {
    final ta = timedToday(a), tb = timedToday(b);
    if (ta && tb) return a.scheduledAt!.compareTo(b.scheduledAt!);
    if (ta != tb) return ta ? -1 : 1;
    return b.priority.index.compareTo(a.priority.index);
  });
  return out;
}

/// One line per task: "09:30  Dentist" or "•  Call mom".
List<String> programLines(List<TaskItem> program, DateTime now, {int max = 4}) {
  String two(int v) => v.toString().padLeft(2, '0');
  final today = Dates.dayKey(now);
  return [
    for (final t in program.take(max))
      t.scheduledAt != null && Dates.dayKey(t.scheduledAt!) == today
          ? '${two(t.scheduledAt!.hour)}:${two(t.scheduledAt!.minute)}  ${t.title}'
          : '•  ${t.title}',
  ];
}

abstract class HomeWidgetService {
  Future<void> update(TodayWidgetData data);

  /// Routes from widget taps (including the tap that launched the app).
  Stream<String> get taps;
}

/// iOS WidgetKit (App Group) and Android AppWidget through `home_widget`.
class DeviceHomeWidget implements HomeWidgetService {
  DeviceHomeWidget() {
    unawaited(HomeWidget.setAppGroupId(appGroup));
  }

  static const appGroup = 'group.com.dayly.app';
  static const iOSKind = 'DaylyWidget';
  static const androidProvider = 'com.dayly.app.DaylyWidgetProvider';

  @override
  Future<void> update(TodayWidgetData d) async {
    try {
      await HomeWidget.saveWidgetData<String>('day', d.day);
      await HomeWidget.saveWidgetData<String>('title', d.title);
      await HomeWidget.saveWidgetData<String>('lines', d.lines.join('\n'));
      await HomeWidget.saveWidgetData<String>('summary', d.summary);
      await HomeWidget.saveWidgetData<String>('staleHint', d.staleHint);
      await HomeWidget.saveWidgetData<String>('route', d.route);
      await HomeWidget.updateWidget(iOSName: iOSKind, qualifiedAndroidName: androidProvider);
    } catch (_) {
      // No widget support (or none added): nothing to update.
    }
  }

  @override
  Stream<String> get taps async* {
    final first = await HomeWidget.initiallyLaunchedFromHomeWidget().catchError((_) => null);
    if (first != null) yield routeOf(first);
    yield* HomeWidget.widgetClicked.where((u) => u != null).map((u) => routeOf(u!));
  }

  /// `dayly://open?homeWidget&r=/plan` → `/plan`.
  static String routeOf(Uri u) {
    final r = u.queryParameters['r'];
    return r != null && r.startsWith('/') ? r : '/plan';
  }
}

class NoHomeWidget implements HomeWidgetService {
  const NoHomeWidget();

  @override
  Future<void> update(TodayWidgetData data) async {}

  @override
  Stream<String> get taps => const Stream.empty();
}
