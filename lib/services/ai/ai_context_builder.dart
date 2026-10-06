import '../../core/utils/dates.dart';
import '../../domain/engines/budget_engine.dart';
import '../../domain/engines/life_score_engine.dart';
import '../../domain/models/food.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/task_item.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/wellbeing.dart';
import '../settings/app_settings.dart';

/// Builds the compact, consented context sent with AI requests.
///
/// Only scopes the user enabled in Settings → Privacy → AI data are
/// included; amounts are sent in major units with the currency code. The
/// exact payload categories are listed to the user on the privacy screen.
class AiContextBuilder {
  const AiContextBuilder();

  Map<String, dynamic> build({
    required DateTime now,
    required String locale,
    required String? timeZone,
    required UserProfile profile,
    required Set<AiDataScope> scopes,
    LifeScore? score,
    BudgetSnapshot? budget,
    List<TaskItem> tasks = const [],
    List<Habit> habits = const [],
    List<HabitLog> habitLogs = const [],
    List<MoodLog> moods = const [],
    List<SleepLog> sleeps = const [],
    List<PantryItem> pantry = const [],
    List<JournalEntry> journal = const [],
  }) {
    double major(int minor) => minor / 100;
    final today = Dates.dayKey(now);
    final ctx = <String, dynamic>{
      'now': now.toIso8601String(),
      'weekday': now.weekday,
      'locale': locale,
      'timeZone': ?timeZone,
      'currency': profile.currency,
      if (profile.name.isNotEmpty) 'name': profile.name,
      'focusAreas': profile.focusAreas.map((f) => f.name).toList(),
      if (profile.wakeTime != null) 'wakeTime': profile.wakeTime.toString(),
      if (profile.sleepTime != null) 'sleepTime': profile.sleepTime.toString(),
      if (score?.total != null)
        'lifeScore': {'total': score!.total, for (final e in score.components.entries) e.key.name: e.value},
    };

    if (scopes.contains(AiDataScope.money) && budget != null) {
      ctx['money'] = {
        'monthlyIncome': major(profile.monthlyIncomeMinor ?? 0),
        'savingsGoal': major(profile.savingsGoalMinor ?? 0),
        'spentThisMonth': major(budget.spentMinor),
        'spentToday': major(budget.spentTodayMinor),
        'safeDailySpending': major(budget.safeDailyMinor),
        'remainingThisMonth': major(budget.remainingMinor),
        'daysLeftInMonth': budget.daysLeftInMonth,
        'byCategory': {for (final c in budget.byCategory.take(6)) c.category.name: major(c.amountMinor)},
      };
    }

    if (scopes.contains(AiDataScope.tasks)) {
      final horizon = Dates.addDays(Dates.dateOnly(now), 8);
      final open = tasks
          .where((t) => !t.isCompleted && (t.anchorDate == null || t.anchorDate!.isBefore(horizon)))
          .take(25)
          .map(
            (t) => {
              'title': t.title,
              'priority': t.priority.name,
              'minutes': t.estimatedMinutes,
              if (t.scheduledAt != null) 'at': t.scheduledAt!.toIso8601String(),
              if (t.deadline != null) 'due': Dates.dayKey(t.deadline!),
            },
          )
          .toList();
      ctx['tasks'] = open;
    }

    if (scopes.contains(AiDataScope.habits) && habits.isNotEmpty) {
      final todayLogs = {
        for (final l in habitLogs)
          if (l.day == today) l.habitId: l.count,
      };
      ctx['habits'] = habits
          .take(15)
          .map((h) => {'name': h.name, 'type': h.type.name, 'target': h.targetPerDay, 'today': todayLogs[h.id] ?? 0})
          .toList();
    }

    if (scopes.contains(AiDataScope.mood)) {
      final since = Dates.dayKey(Dates.addDays(now, -7));
      ctx['wellbeing'] = {
        'moods': {
          for (final m in moods)
            if (m.day.compareTo(since) >= 0) m.day: m.mood,
        },
        'sleepHours': {
          for (final s in sleeps)
            if (s.day.compareTo(since) >= 0) s.day: (s.minutes / 60).toStringAsFixed(1),
        },
      };
    }

    if (scopes.contains(AiDataScope.food)) {
      ctx['food'] = {...profile.food.toJson(), 'pantry': pantry.take(40).map((p) => p.name).toList()};
    }

    if (scopes.contains(AiDataScope.journal) && journal.isNotEmpty) {
      ctx['journal'] = journal.take(5).map((j) {
        final t = j.text.length > 500 ? '${j.text.substring(0, 500)}…' : j.text;
        return {'date': Dates.dayKey(j.createdAt), 'text': t};
      }).toList();
    }
    return ctx;
  }
}
