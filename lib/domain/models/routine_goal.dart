import '../../core/utils/json.dart';
import 'entity.dart';
import 'enums.dart';

/// One step of a routine: what and for how long.
class RoutineStep {
  const RoutineStep(this.title, this.minutes, {this.category = TaskCategory.personal});

  factory RoutineStep.fromJson(Map<String, dynamic> j) => RoutineStep(
    J.str(j, 'title'),
    J.integer(j, 'minutes', 15).clamp(1, 600),
    category: J.enumByName(TaskCategory.values, j['category'], TaskCategory.personal),
  );

  final String title;
  final int minutes;
  final TaskCategory category;

  Map<String, dynamic> toJson() => {'title': title, 'minutes': minutes, 'category': category.name};
}

/// A saved set of steps ("Morning routine") added to a day in one tap; the
/// steps become back-to-back tasks from [startMinutes].
class Routine extends Entity {
  const Routine({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.name,
    this.emoji = '✨',
    this.startMinutes,
    this.steps = const [],
  });

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    name: J.str(j, 'name'),
    emoji: J.str(j, 'emoji', '✨'),
    startMinutes: J.intOrNull(j, 'startMinutes'),
    steps: J.mapList(j, 'steps').map(RoutineStep.fromJson).take(30).toList(),
  );

  static const codec = EntityCodec<Routine>(collection: 'routines', fromJson: Routine.fromJson);

  final String name;
  final String emoji;

  /// Usual start, minutes after midnight (null: ask when adding).
  final int? startMinutes;
  final List<RoutineStep> steps;

  int get totalMinutes => steps.fold(0, (s, x) => s + x.minutes);

  Routine copyWith({String? name, String? emoji, int? startMinutes, List<RoutineStep>? steps}) => Routine(
    id: id,
    updatedAt: DateTime.now(),
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    startMinutes: startMinutes ?? this.startMinutes,
    steps: steps ?? this.steps,
  );

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'emoji': emoji,
    if (startMinutes != null) 'startMinutes': startMinutes,
    'steps': [for (final s in steps) s.toJson()],
  };
}

/// A step toward a long-term goal. [taskId] links it to a planned task;
/// the step counts as done when the task is completed.
class GoalStep {
  const GoalStep({required this.id, required this.title, this.done = false, this.taskId});

  factory GoalStep.fromJson(Map<String, dynamic> j) => GoalStep(
    id: J.str(j, 'id'),
    title: J.str(j, 'title'),
    done: J.boolean(j, 'done'),
    taskId: J.strOrNull(j, 'taskId'),
  );

  final String id;
  final String title;
  final bool done;
  final String? taskId;

  GoalStep copyWith({String? title, bool? done, String? taskId}) =>
      GoalStep(id: id, title: title ?? this.title, done: done ?? this.done, taskId: taskId ?? this.taskId);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done, if (taskId != null) 'taskId': taskId};
}

/// A long-term goal ("B1 English in 3 months") broken into steps.
class LifeGoal extends Entity {
  const LifeGoal({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.title,
    this.emoji = '🎯',
    this.why = '',
    this.deadline,
    this.steps = const [],
    this.archived = false,
    required this.createdAt,
  });

  factory LifeGoal.fromJson(Map<String, dynamic> j) => LifeGoal(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    title: J.str(j, 'title'),
    emoji: J.str(j, 'emoji', '🎯'),
    why: J.str(j, 'why'),
    deadline: J.date(j, 'deadline'),
    steps: J.mapList(j, 'steps').map(GoalStep.fromJson).take(60).toList(),
    archived: J.boolean(j, 'archived'),
    createdAt: J.date(j, 'createdAt') ?? Meta.updated(j),
  );

  static const codec = EntityCodec<LifeGoal>(collection: 'life_goals', fromJson: LifeGoal.fromJson);

  final String title;
  final String emoji;

  /// Why it matters (shown as motivation).
  final String why;
  final DateTime? deadline;
  final List<GoalStep> steps;
  final bool archived;
  final DateTime createdAt;

  /// Done steps, counting a step done when its linked task is completed.
  int doneSteps(Set<String> completedTaskIds) =>
      steps.where((s) => s.done || (s.taskId != null && completedTaskIds.contains(s.taskId))).length;

  double progress(Set<String> completedTaskIds) => steps.isEmpty ? 0 : doneSteps(completedTaskIds) / steps.length;

  LifeGoal copyWith({
    String? title,
    String? emoji,
    String? why,
    DateTime? deadline,
    bool clearDeadline = false,
    List<GoalStep>? steps,
    bool? archived,
  }) => LifeGoal(
    id: id,
    updatedAt: DateTime.now(),
    title: title ?? this.title,
    emoji: emoji ?? this.emoji,
    why: why ?? this.why,
    deadline: clearDeadline ? null : (deadline ?? this.deadline),
    steps: steps ?? this.steps,
    archived: archived ?? this.archived,
    createdAt: createdAt,
  );

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'emoji': emoji,
    'why': why,
    if (deadline != null) 'deadline': deadline!.millisecondsSinceEpoch,
    'steps': [for (final s in steps) s.toJson()],
    'archived': archived,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
