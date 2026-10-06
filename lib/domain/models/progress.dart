import '../../core/utils/json.dart';
import 'entity.dart';

/// Persisted daily Life Score snapshot (id = day key) for history and trends.
class DailyScoreRecord extends Entity {
  const DailyScoreRecord({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.total,
    required this.components,
  });

  factory DailyScoreRecord.fromJson(Map<String, dynamic> j) => DailyScoreRecord(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    total: J.integer(j, 'total'),
    components: J.map(j, 'components').map((k, v) => MapEntry(k, v is num ? v.round() : 0)),
  );

  static const codec = EntityCodec<DailyScoreRecord>(collection: 'daily_scores', fromJson: DailyScoreRecord.fromJson);

  final int total;

  /// Sub-score by `ScoreComponent.name`; components without data are absent.
  final Map<String, int> components;

  @override
  Map<String, dynamic> toJson() => {'total': total, 'components': components};
}

/// Completion state of the day's goals (id = day key).
class DailyGoalsRecord extends Entity {
  const DailyGoalsRecord({required super.id, required super.updatedAt, super.deleted, required this.completedGoalIds});

  factory DailyGoalsRecord.fromJson(Map<String, dynamic> j) => DailyGoalsRecord(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    completedGoalIds: J.strList(j, 'completed').toSet(),
  );

  static const codec = EntityCodec<DailyGoalsRecord>(collection: 'daily_goals', fromJson: DailyGoalsRecord.fromJson);

  /// Ids of goals the user manually ticked. Data-backed goals (spending,
  /// habits, tasks) are evaluated live and need no record.
  final Set<String> completedGoalIds;

  @override
  Map<String, dynamic> toJson() => {'completed': completedGoalIds.toList()..sort()};
}

/// An unlocked badge (id = badge id).
class AchievementRecord extends Entity {
  const AchievementRecord({required super.id, required super.updatedAt, super.deleted, required this.unlockedAt});

  factory AchievementRecord.fromJson(Map<String, dynamic> j) => AchievementRecord(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    unlockedAt: J.date(j, 'unlockedAt') ?? Meta.updated(j),
  );

  static const codec = EntityCodec<AchievementRecord>(collection: 'achievements', fromJson: AchievementRecord.fromJson);

  final DateTime unlockedAt;

  @override
  Map<String, dynamic> toJson() => {'unlockedAt': unlockedAt.millisecondsSinceEpoch};
}
