import '../../core/utils/dates.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/money_models.dart';
import '../../domain/models/task_item.dart';

enum NotificationKind {
  taskReminder,
  logSpending,
  budgetTight,
  streakAtRisk,
  moodCheckIn,
  weeklyReview,
  planDay,
  journal,
  billDue;

  /// Where tapping the notification takes the user.
  String get route => switch (this) {
    taskReminder => '/plan',
    logSpending || budgetTight => '/money',
    streakAtRisk => '/home',
    moodCheckIn => '/mood',
    weeklyReview => '/review',
    planDay => '/ai?topic=plan',
    journal => '/journal/new',
    billDue => '/money?tab=plan',
  };
}

class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.at,
    this.title = '',
    this.leadMinutes = 30,
  });

  /// Stable id so re-planning replaces instead of duplicating.
  final int id;
  final NotificationKind kind;
  final DateTime at;

  /// Task title for reminders.
  final String title;

  /// How long before the start a task reminder fires.
  final int leadMinutes;
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
    this.bills = const [],
    this.hasBudget = false,
    this.loggedSpendingToday = false,
    this.budgetTight = false,
    this.currentStreak = 0,
    this.activeToday = false,
    this.moodLoggedToday = false,
    this.weeklyReportEnabled = true,
    this.hasPlanToday = false,
    this.journaledToday = false,
    this.journalReminder = true,
    this.planReminder = true,
    this.quietStart = defaultQuietStart,
    this.quietEnd = defaultQuietEnd,
  });

  final DateTime now;
  final NotificationFrequency frequency;
  final int dailyCap;
  final List<TaskItem> upcomingTasks;

  /// Monthly bills; unpaid ones are reminded the day before and on the day.
  final List<RecurringBill> bills;
  final bool hasBudget;
  final bool loggedSpendingToday;
  final bool budgetTight;
  final int currentStreak;
  final bool activeToday;
  final bool moodLoggedToday;
  final bool weeklyReportEnabled;

  /// Something is already planned for today (no morning nudge then).
  final bool hasPlanToday;
  final bool journaledToday;

  /// User settings for the daily journal and morning plan reminders.
  final bool journalReminder;
  final bool planReminder;

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
      final lead = t.reminderLead;
      if (t.deleted || t.isCompleted || at == null || lead == null) continue;
      final fire = at.subtract(lead);
      if (fire.isAfter(s.now) && fire.isBefore(horizon)) {
        out.add(
          PlannedNotification(
            id: 1000 + (t.id.hashCode & 0xFFFFF),
            kind: NotificationKind.taskReminder,
            at: fire,
            title: t.title,
            leadMinutes: lead.inMinutes,
          ),
        );
      }
    }

    // Bill reminders (user-created, like task reminders): 10:00 the day
    // before and on the due day, until marked paid this month.
    final month = Dates.monthKey(s.now);
    for (final b in s.bills) {
      if (b.deleted || !b.remind || b.lastPaidMonth == month) continue;
      final due = b.dueIn(s.now);
      for (final (i, d) in [Dates.addDays(due, -1), due].indexed) {
        final at = _at(d, 10, 0);
        if (at.isAfter(s.now) && at.isBefore(horizon)) {
          out.add(
            PlannedNotification(
              id: 3000 + ((b.id.hashCode & 0xFFFF) << 1) + i,
              kind: NotificationKind.billDue,
              at: at,
              title: b.name,
            ),
          );
        }
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
      if (s.planReminder && (!isToday || !s.hasPlanToday)) {
        // 45 minutes after the user's wake time.
        final wake = s.quietEnd.minutes + 45;
        day.add(PlannedNotification(id: 60 + index, kind: NotificationKind.planDay, at: _at(d, wake ~/ 60, wake % 60)));
      }
      if (s.journalReminder && (!isToday || !s.journaledToday)) {
        day.add(PlannedNotification(id: 70 + index, kind: NotificationKind.journal, at: _at(d, 21, 15)));
      }
      if (s.hasBudget && (!isToday || !s.loggedSpendingToday)) {
        day.add(PlannedNotification(id: 30 + index, kind: NotificationKind.logSpending, at: _at(d, 20, 30)));
      }
      if (s.budgetTight && !isToday) {
        day.add(PlannedNotification(id: 40 + index, kind: NotificationKind.budgetTight, at: _at(d, 9, 0)));
      }
      // The evening journal also asks how you feel, so it replaces the
      // separate mood check-in when it is on (one evening nudge, not two).
      if (!s.journalReminder && (!isToday || !s.moodLoggedToday)) {
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
