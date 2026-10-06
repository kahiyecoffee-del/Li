import '../../core/utils/dates.dart';
import '../models/habit.dart';
import '../models/task_item.dart';
import 'budget_engine.dart';

enum ScoreComponent { money, health, productivity, habits, mood, sleep, planning }

/// Everything the Life Score needs for a single day. Built by
/// `LifeScoreInputBuilder` from repositories; kept plain so it is trivially
/// unit-testable.
class LifeScoreInput {
  const LifeScoreInput({
    required this.day,
    this.budget,
    this.habits = const [],
    this.habitLogs = const [],
    this.tasks = const [],
    this.mood,
    this.sleepMinutes,
    this.sleepTargetMinutes = 480,
    this.checkedInToday = false,
  });

  final DateTime day;

  /// `null` when the user has no budget configured.
  final BudgetSnapshot? budget;
  final List<Habit> habits;

  /// Logs for [day] only.
  final List<HabitLog> habitLogs;
  final List<TaskItem> tasks;

  /// 1–5, `null` when not logged.
  final int? mood;
  final int? sleepMinutes;
  final int sleepTargetMinutes;

  /// Whether the user logged anything (expense, mood, habit…) today.
  final bool checkedInToday;
}

class LifeScore {
  const LifeScore({required this.total, required this.components});

  /// 0–100, or `null` when there is not enough data for any component.
  final int? total;

  /// Only components with data are present.
  final Map<ScoreComponent, int> components;

  bool get hasData => total != null;
}

/// One reason the score moved compared with a previous day.
class ScoreFactor {
  const ScoreFactor(this.component, this.delta, this.weightedImpact);

  final ScoreComponent component;

  /// Change of the sub-score in points.
  final int delta;

  /// Contribution to the total change, in total-score points.
  final double weightedImpact;
}

class ScoreExplanation {
  const ScoreExplanation({required this.totalDelta, required this.topFactors});

  final int totalDelta;

  /// At most two factors that explain most of the change, largest first, all
  /// moving in the same direction as [totalDelta].
  final List<ScoreFactor> topFactors;
}

/// Deterministic, explainable 0–100 daily score.
///
/// Each component is computed from the user's own data with fixed formulas;
/// components without data are excluded and the remaining weights are
/// renormalized, so not using a feature never lowers the score. The AI may
/// *describe* the score but never decides it.
class LifeScoreEngine {
  const LifeScoreEngine({this.weights = defaultWeights});

  static const defaultWeights = <ScoreComponent, double>{
    ScoreComponent.money: 0.20,
    ScoreComponent.health: 0.15,
    ScoreComponent.productivity: 0.20,
    ScoreComponent.habits: 0.15,
    ScoreComponent.mood: 0.10,
    ScoreComponent.sleep: 0.10,
    ScoreComponent.planning: 0.10,
  };

  final Map<ScoreComponent, double> weights;

  LifeScore compute(LifeScoreInput input) {
    final c = <ScoreComponent, int>{};

    final money = moneyScore(input.budget);
    if (money != null) c[ScoreComponent.money] = money;

    final dayHabits = input.habits.where((h) => !h.deleted && h.isScheduledOn(input.day)).toList();
    final health = _habitCompletion(dayHabits.where((h) => h.type.isHealth).toList(), input.habitLogs);
    if (health != null) c[ScoreComponent.health] = health;

    final habits = _habitCompletion(dayHabits, input.habitLogs);
    if (habits != null) c[ScoreComponent.habits] = habits;

    final productivity = productivityScore(input.tasks, input.day);
    if (productivity != null) c[ScoreComponent.productivity] = productivity;

    if (input.mood != null) c[ScoreComponent.mood] = (input.mood!.clamp(1, 5) * 20);

    if (input.sleepMinutes != null) {
      c[ScoreComponent.sleep] = sleepScore(input.sleepMinutes!, input.sleepTargetMinutes);
    }

    c[ScoreComponent.planning] = planningScore(input);

    return LifeScore(total: _weighted(c), components: c);
  }

  int? _weighted(Map<ScoreComponent, int> c) {
    // Planning alone is not meaningful enough to produce a score.
    if (c.keys.every((k) => k == ScoreComponent.planning)) return null;
    var sum = 0.0;
    var w = 0.0;
    c.forEach((k, v) {
      final wk = weights[k] ?? 0;
      sum += v * wk;
      w += wk;
    });
    if (w == 0) return null;
    return (sum / w).round().clamp(0, 100);
  }

  /// 100 when today's variable spend is within the safe allowance, falling
  /// linearly to 0 at twice the allowance. A day with no allowance left scores
  /// 100 if nothing was spent, otherwise 0.
  static int? moneyScore(BudgetSnapshot? b) {
    if (b == null) return null;
    final allowance = b.safeDailyMinor;
    final spent = b.spentTodayMinor;
    if (allowance <= 0) return spent == 0 ? 100 : 0;
    if (spent <= allowance) return 100;
    final over = spent - allowance;
    return (100 - (over * 100) ~/ allowance).clamp(0, 100);
  }

  static int? _habitCompletion(List<Habit> habits, List<HabitLog> logs) {
    if (habits.isEmpty) return null;
    final counts = {
      for (final l in logs)
        if (!l.deleted) l.habitId: l.count,
    };
    var ratioSum = 0.0;
    for (final h in habits) {
      final done = counts[h.id] ?? 0;
      ratioSum += (done / h.targetPerDay).clamp(0.0, 1.0);
    }
    return (ratioSum / habits.length * 100).round();
  }

  /// Share of tasks planned for [day] (scheduled or due) that are completed.
  /// Overdue open tasks count against the day too.
  static int? productivityScore(List<TaskItem> tasks, DateTime day) {
    final d = Dates.dateOnly(day);
    var planned = 0;
    var done = 0;
    for (final t in tasks) {
      if (t.deleted) continue;
      final anchor = t.anchorDate;
      if (anchor == null) {
        if (t.completedAt != null && Dates.sameDay(t.completedAt!, d)) {
          planned++;
          done++;
        }
        continue;
      }
      final anchorDay = Dates.dateOnly(anchor);
      final isToday = anchorDay == d;
      final overdue = anchorDay.isBefore(d) && t.completedAt == null;
      final completedToday = t.completedAt != null && Dates.sameDay(t.completedAt!, d);
      if (isToday || overdue || completedToday) {
        planned++;
        if (t.completedAt != null && !Dates.dateOnly(t.completedAt!).isAfter(d)) done++;
      }
    }
    if (planned == 0) return null;
    return (done * 100 / planned).round();
  }

  /// 100 inside [target − 30min, target + 90min]; −20 points per hour short,
  /// −10 per hour of oversleep beyond the window.
  static int sleepScore(int minutes, int target) {
    if (minutes >= target - 30 && minutes <= target + 90) return 100;
    if (minutes < target - 30) {
      final short = (target - 30) - minutes;
      return (100 - short * 20 / 60).round().clamp(0, 100);
    }
    final over = minutes - (target + 90);
    return (100 - over * 10 / 60).round().clamp(0, 100);
  }

  /// 40 pts for having a plan for today, 30 for an active budget,
  /// 30 for checking in (logging anything) today.
  static int planningScore(LifeScoreInput input) {
    final hasPlan = input.tasks.any((t) {
      final a = t.anchorDate;
      return !t.deleted && a != null && Dates.sameDay(a, input.day);
    });
    return (hasPlan ? 40 : 0) + (input.budget != null ? 30 : 0) + (input.checkedInToday ? 30 : 0);
  }

  /// Compares [today] with [previous] and returns the dominant reasons.
  ScoreExplanation explain(LifeScore today, LifeScore? previous) {
    if (today.total == null || previous?.total == null) {
      return const ScoreExplanation(totalDelta: 0, topFactors: []);
    }
    final delta = today.total! - previous!.total!;
    final totalWeight = today.components.keys.fold<double>(0, (s, k) => s + (weights[k] ?? 0));
    final factors = <ScoreFactor>[];
    for (final k in today.components.keys) {
      final prev = previous.components[k];
      if (prev == null) continue;
      final d = today.components[k]! - prev;
      if (d == 0) continue;
      factors.add(ScoreFactor(k, d, totalWeight == 0 ? 0 : d * (weights[k] ?? 0) / totalWeight));
    }
    factors.removeWhere((f) => delta == 0 || f.delta.sign != delta.sign);
    factors.sort((a, b) => b.weightedImpact.abs().compareTo(a.weightedImpact.abs()));
    return ScoreExplanation(totalDelta: delta, topFactors: factors.take(2).toList());
  }

  /// The single weakest component, used to suggest what to improve next.
  ScoreComponent? weakest(LifeScore score) {
    if (score.components.isEmpty) return null;
    final entries = score.components.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return entries.first.key;
  }
}
