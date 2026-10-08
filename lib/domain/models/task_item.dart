import '../../core/utils/json.dart';
import 'entity.dart';
import 'enums.dart';

class TaskItem extends Entity {
  const TaskItem({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.title,
    this.priority = TaskPriority.medium,
    this.estimatedMinutes = 30,
    this.category = TaskCategory.personal,
    this.deadline,
    this.scheduledAt,
    this.recurrence = Recurrence.none,
    this.completedAt,
    required this.createdAt,
    this.remindBefore,
    this.rolledOver = 0,
  });

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    title: J.str(j, 'title'),
    priority: J.enumByName(TaskPriority.values, j['priority'], TaskPriority.medium),
    estimatedMinutes: J.integer(j, 'estimatedMinutes', 30),
    category: J.enumByName(TaskCategory.values, j['category'], TaskCategory.personal),
    deadline: J.date(j, 'deadline'),
    scheduledAt: J.date(j, 'scheduledAt'),
    recurrence: J.enumByName(Recurrence.values, j['recurrence'], Recurrence.none),
    completedAt: J.date(j, 'completedAt'),
    createdAt: J.date(j, 'createdAt') ?? Meta.updated(j),
    remindBefore: J.intOrNull(j, 'remindBefore'),
    rolledOver: J.integer(j, 'rolledOver', 0),
  );

  static const codec = EntityCodec<TaskItem>(collection: 'tasks', fromJson: TaskItem.fromJson);

  final String title;
  final TaskPriority priority;
  final int estimatedMinutes;
  final TaskCategory category;
  final DateTime? deadline;

  /// Time-blocked start, if the task is placed on the timeline.
  final DateTime? scheduledAt;
  final Recurrence recurrence;
  final DateTime? completedAt;
  final DateTime createdAt;

  /// Minutes before [scheduledAt] to remind: null = the default (30),
  /// 0 = at the start, negative = no reminder.
  final int? remindBefore;

  /// The reminder lead to use, or null when reminders are off for this task.
  Duration? get reminderLead => switch (remindBefore) {
    null => const Duration(minutes: 30),
    final m when m < 0 => null,
    final m => Duration(minutes: m),
  };

  /// How many times it was pushed to a later day. A task that keeps moving
  /// is too big, mis-estimated or not really wanted.
  final int rolledOver;

  bool get isCompleted => completedAt != null;

  /// The day this task belongs to on the timeline.
  DateTime? get anchorDate => scheduledAt ?? deadline;

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'priority': priority.name,
    'estimatedMinutes': estimatedMinutes,
    'category': category.name,
    if (deadline != null) 'deadline': deadline!.millisecondsSinceEpoch,
    if (scheduledAt != null) 'scheduledAt': scheduledAt!.millisecondsSinceEpoch,
    'recurrence': recurrence.name,
    if (completedAt != null) 'completedAt': completedAt!.millisecondsSinceEpoch,
    'createdAt': createdAt.millisecondsSinceEpoch,
    if (remindBefore != null) 'remindBefore': remindBefore,
    if (rolledOver > 0) 'rolledOver': rolledOver,
  };

  TaskItem copyWith({
    String? title,
    TaskPriority? priority,
    int? estimatedMinutes,
    TaskCategory? category,
    DateTime? deadline,
    DateTime? scheduledAt,
    Recurrence? recurrence,
    DateTime? completedAt,
    bool clearCompleted = false,
    bool clearSchedule = false,
    bool clearDeadline = false,
    bool? deleted,
    int? remindBefore,
    int? rolledOver,
  }) => TaskItem(
    id: id,
    updatedAt: DateTime.now(),
    deleted: deleted ?? this.deleted,
    title: title ?? this.title,
    priority: priority ?? this.priority,
    estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    category: category ?? this.category,
    deadline: clearDeadline ? null : (deadline ?? this.deadline),
    scheduledAt: clearSchedule ? null : (scheduledAt ?? this.scheduledAt),
    recurrence: recurrence ?? this.recurrence,
    completedAt: clearCompleted ? null : (completedAt ?? this.completedAt),
    createdAt: createdAt,
    remindBefore: remindBefore ?? this.remindBefore,
    rolledOver: rolledOver ?? this.rolledOver,
  );
}
