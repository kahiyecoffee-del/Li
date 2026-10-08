import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/task_item.dart';

Future<void> showTaskEditor(BuildContext context, {TaskItem? task, DateTime? day, String? title, TimeOfDay? time}) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => TaskEditor(task: task, day: day, title: title, time: time),
    );

class TaskEditor extends ConsumerStatefulWidget {
  const TaskEditor({super.key, this.task, this.day, this.title, this.time});

  final TaskItem? task;

  /// Pre-filled title for a new task (e.g. "remind me…" typed on Home).
  final String? title;
  final DateTime? day;

  /// Pre-filled start time for a new task (tapping a free slot).
  final TimeOfDay? time;

  @override
  ConsumerState<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends ConsumerState<TaskEditor> {
  late final _title = TextEditingController(text: widget.task?.title ?? widget.title ?? '');
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;
  late int _minutes = widget.task?.estimatedMinutes ?? 30;
  late TaskCategory _category = widget.task?.category ?? TaskCategory.personal;
  late Recurrence _repeat = widget.task?.recurrence ?? Recurrence.none;
  late DateTime? _date = Dates.dateOnly(widget.task?.anchorDate ?? widget.day ?? DateTime.now());
  late TimeOfDay? _time = widget.task?.scheduledAt == null
      ? widget.time
      : TimeOfDay(hour: widget.task!.scheduledAt!.hour, minute: widget.task!.scheduledAt!.minute);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final scheduled = _date != null && _time != null
        ? DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute)
        : null;
    final now = DateTime.now();
    final existing = widget.task;
    final t = TaskItem(
      id: existing?.id ?? newId(),
      updatedAt: now,
      title: title,
      priority: _priority,
      estimatedMinutes: _minutes,
      category: _category,
      scheduledAt: scheduled,
      deadline: scheduled == null ? _date : null,
      recurrence: _repeat,
      completedAt: existing?.completedAt,
      createdAt: existing?.createdAt ?? now,
    );
    await ref.read(actionsProvider).saveTask(t, isNew: existing == null);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.task == null ? l.newTask : l.editTask, style: context.text.titleLarge),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _title,
              autofocus: widget.task == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.taskTitle, hintText: l.taskTitleHint),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(_date == null ? l.taskNoTime : fmt.weekdayDayMonth(_date!)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(_time == null ? l.taskNoTime : _time!.format(context)),
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
                      setState(() => _time = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            Text(l.taskPriority, style: context.text.titleSmall),
            const SizedBox(height: Space.sm),
            SegmentedButton<TaskPriority>(
              segments: TaskPriority.values
                  .map((p) => ButtonSegment(value: p, label: Text(l.priorityLabel(p))))
                  .toList(),
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: Space.lg),
            Text('${l.taskDuration}: ${l.minutesShort(_minutes)}', style: context.text.titleSmall),
            Slider(
              value: _minutes.toDouble(),
              min: 5,
              max: 240,
              divisions: 47,
              label: l.minutesShort(_minutes),
              onChanged: (v) => setState(() => _minutes = v.round()),
            ),
            Text(l.taskCategory, style: context.text.titleSmall),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: TaskCategory.values
                  .map(
                    (c) => ChoiceChip(
                      label: Text(l.taskCategoryLabel(c)),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: Space.lg),
            DropdownButtonFormField<Recurrence>(
              initialValue: _repeat,
              decoration: InputDecoration(labelText: l.taskRepeat),
              items: Recurrence.values.map((r) => DropdownMenuItem(value: r, child: Text(l.recurrence(r)))).toList(),
              onChanged: (v) => setState(() => _repeat = v ?? Recurrence.none),
            ),
            const SizedBox(height: Space.xl),
            FilledButton(onPressed: _save, child: Text(l.save)),
            if (widget.task != null)
              TextButton(
                onPressed: () async {
                  await ref.read(actionsProvider).deleteTask(widget.task!.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    showSnack(context, l.deleted);
                  }
                },
                child: Text(l.delete, style: TextStyle(color: context.semantic.negative)),
              ),
          ],
        ),
      ),
    );
  }
}
