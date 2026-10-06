import '../../core/utils/dates.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/task_item.dart';

enum NotificationKind { taskReminder, logSpending, budgetTight, streakAtRisk, moodCheckIn, weeklyReview }

class PlannedNotification {
  const PlannedNotification({required this.id, required this.kind, required this.at, this.title = ''});

  /// Stable id so re-planning replaces instead of duplicating.
  final int id;
  final NotificationKind kind;
  final DateTime at;

  /// Task title for reminders.
  final String title;
}

/// Default quiet hours when the user has not set a routine.
const defaultQuietStart = DayTime(22 * 60);
const defaultQuietEnd = DayTime(8 * 60);

class NotificationState {
  const NotificationState({
    required this.now,
    required this.frequency,
    required this.dailyCap,
    this.upcomingTasks = const [],
    this.hasBudget = false,
    this.loggedSpendingToday = false,
    this.budgetTight = false,
    this.currentStreak = 0,
    this.activeToday = false,
    this.moodLoggedToday = false,
    this.weeklyReportEnabled = true,
    this.quietStart = defaultQuietStart,
    this.quietEnd = defaultQuietEnd,
  });

  final DateTime now;
  final NotificationFrequency frequency;
  final int dailyCap;
  final List<TaskItem> upcomingTasks;
  final bool hasBudget;
  final bool loggedSpendingToday;
  final bool budgetTight;
  final int currentStreak;
  final bool activeToday;
  final bool moodLoggedToday;
  final bool weeklyReportEnabled;

  /// Nothing is scheduled between [quietStart] and [quietEnd] (except
  /// reminders for tasks the user scheduled in that window themselves).
  final DayTime quietStart;
  final DayTime quietEnd;
}

/// Decides which local notifications to schedule for the next ~36 hours.
///
/// Anti-spam rules:
/// * `off` → nothing. `low` → task reminders + weekly review only.
/// * `normal` → nudges are capped per day by Remote Config
///   (`notification_daily_cap`) in priority order; task reminders the user
///   created are not counted against the cap.
/// * Nudges never fire in quiet hours and are skipped when already satisfied
///   (e.g. spending already logged today).
class NotificationPlanner {
  const NotificationPlanner();

  static const reminderLead = Duration(minutes: 30);

  List<PlannedNotification> plan(NotificationState s) {
    if (s.frequency == NotificationFrequency.off) return const [];
    final out = <PlannedNotification>[];
    final today = Dates.dateOnly(s.now);
    final tomorrow = Dates.addDays(today, 1);
    final horizon = s.now.add(const Duration(hours: 36));

    // 1. Task reminders (user-created, always allowed unless off).
    for (final t in s.upcomingTasks) {
      final at = t.scheduledAt;
      if (t.deleted || t.isCompleted || at == null) continue;
      final fire = at.subtract(reminderLead);
      if (fire.isAfter(s.now) && fire.isBefore(horizon)) {
        out.add(
          PlannedNotification(
            id: 1000 + (t.id.hashCode & 0xFFFFF),
            kind: NotificationKind.taskReminder,
            at: fire,
            title: t.title,
          ),
        );
      }
    }

    // 2. Weekly review: Sunday 18:00.
    if (s.weeklyReportEnabled) {
      for (final d in [today, tomorrow]) {
        if (d.weekday == DateTime.sunday) {
          final at = DateTime(d.year, d.month, d.day, 18);
          if (at.isAfter(s.now)) out.add(PlannedNotification(id: 10, kind: NotificationKind.weeklyReview, at: at));
        }
      }
    }
    if (s.frequency == NotificationFrequency.low) return out;

    // 3. Nudges in priority order, per day, capped.
    final nudges = <PlannedNotification>[];
    for (final (index, d) in [today, tomorrow].indexed) {
      final isToday = index == 0;
      final day = <PlannedNotification>[];
      if (s.currentStreak >= 2 && (!isToday || !s.activeToday)) {
        day.add(PlannedNotification(id: 20 + index, kind: NotificationKind.streakAtRisk, at: _at(d, 21, 0)));
      }
      if (s.hasBudget && (!isToday || !s.loggedSpendingToday)) {
        day.add(PlannedNotification(id: 30 + index, kind: NotificationKind.logSpending, at: _at(d, 20, 30)));
      }
      if (s.budgetTight && !isToday) {
        day.add(PlannedNotification(id: 40 + index, kind: NotificationKind.budgetTight, at: _at(d, 9, 0)));
      }
      if (!isToday || !s.moodLoggedToday) {
        day.add(PlannedNotification(id: 50 + index, kind: NotificationKind.moodCheckIn, at: _at(d, 19, 30)));
      }
      nudges.addAll(day.where((n) => n.at.isAfter(s.now) && !_quiet(n.at, s)).take(s.dailyCap));
    }
    return [...out, ...nudges]..sort((a, b) => a.at.compareTo(b.at));
  }

  static DateTime _at(DateTime d, int h, int m) => DateTime(d.year, d.month, d.day, h, m);

  static bool _quiet(DateTime t, NotificationState s) {
    final m = t.hour * 60 + t.minute;
    final start = s.quietStart.minutes;
    final end = s.quietEnd.minutes;
    return start > end ? (m >= start || m < end) : (m >= start && m < end);
  }
}
