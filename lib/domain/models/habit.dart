import '../../core/utils/json.dart';
import 'entity.dart';
import 'enums.dart';

class Habit extends Entity {
  const Habit({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.name,
    required this.type,
    this.targetPerDay = 1,
    this.unit = '',
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
    this.archived = false,
    required this.createdAt,
  });

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    name: J.str(j, 'name'),
    type: J.enumByName(HabitType.values, j['type'], HabitType.custom),
    targetPerDay: J.integer(j, 'targetPerDay', 1).clamp(1, 1000),
    unit: J.str(j, 'unit'),
    weekdays: j['weekdays'] is List
        ? (j['weekdays'] as List<Object?>).whereType<int>().where((d) => d >= 1 && d <= 7).toSet()
        : const {1, 2, 3, 4, 5, 6, 7},
    archived: J.boolean(j, 'archived'),
    createdAt: J.date(j, 'createdAt') ?? Meta.updated(j),
  );

  static const codec = EntityCodec<Habit>(collection: 'habits', fromJson: Habit.fromJson);

  final String name;
  final HabitType type;

  /// Number of check-ins per day that counts as "done" (e.g. 8 glasses).
  final int targetPerDay;
  final String unit;

  /// ISO weekdays (1 = Monday) on which the habit is expected.
  final Set<int> weekdays;
  final bool archived;
  final DateTime createdAt;

  bool isScheduledOn(DateTime day) => !archived && weekdays.contains(day.weekday);

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'targetPerDay': targetPerDay,
    'unit': unit,
    'weekdays': (weekdays.toList()..sort()),
    'archived': archived,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  Habit copyWith({String? name, int? targetPerDay, String? unit, Set<int>? weekdays, bool? archived, bool? deleted}) =>
      Habit(
        id: id,
        updatedAt: DateTime.now(),
        deleted: deleted ?? this.deleted,
        name: name ?? this.name,
        type: type,
        targetPerDay: targetPerDay ?? this.targetPerDay,
        unit: unit ?? this.unit,
        weekdays: weekdays ?? this.weekdays,
        archived: archived ?? this.archived,
        createdAt: createdAt,
      );
}

/// Progress for one habit on one day. Id is `{habitId}_{dayKey}` so concurrent
/// edits on two devices converge on the same record.
class HabitLog extends Entity {
  const HabitLog({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.habitId,
    required this.day,
    required this.count,
  });

  factory HabitLog.fromJson(Map<String, dynamic> j) => HabitLog(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    habitId: J.str(j, 'habitId'),
    day: J.str(j, 'day'),
    count: J.integer(j, 'count'),
  );

  static const codec = EntityCodec<HabitLog>(collection: 'habit_logs', fromJson: HabitLog.fromJson);

  static String idFor(String habitId, String day) => '${habitId}_$day';

  final String habitId;

  /// Day key `yyyy-MM-dd`.
  final String day;
  final int count;

  @override
  Map<String, dynamic> toJson() => {'habitId': habitId, 'day': day, 'count': count};
}
