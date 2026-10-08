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
import '../../domain/plan/day_timeline.dart';
import '../../app/providers.dart';
import 'calendar_busy.dart';
import 'time_picker_sheet.dart';

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
  late int _remind = widget.task?.remindBefore ?? 30;
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
      remindBefore: _remind,
    );
    await ref.read(actionsProvider).saveTask(t, isNew: existing == null);
    if (mounted) Navigator.pop(context);
  }

  /// Overlaps another task? Say so and offer the first free time after it.
  Widget? _clashWarning(BuildContext context) {
    if (_date == null || _time == null) return null;
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final start = DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
    final all = [
      ...ref.watch(tasksProvider).list,
      ...calendarBusy(ref.watch(calendarDayProvider(_date!)).value ?? const []),
    ];
    final clash = clashFor(all, start, _minutes, exceptId: widget.task?.id);
    if (clash == null) return null;
    final free = nextFreeStart(
      all,
      clash.scheduledAt!.add(Duration(minutes: clash.estimatedMinutes)),
      _minutes,
      dayEnd: Dates.addDays(_date!, 1).subtract(const Duration(minutes: 1)),
      exceptId: widget.task?.id,
    );
    return Padding(
      key: const Key('editor-clash'),
      padding: const EdgeInsets.only(top: Space.sm),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: context.semantic.negative),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(
              l.planClashWith(clash.title),
              style: context.text.labelMedium?.copyWith(color: context.semantic.negative),
            ),
          ),
          if (free != null)
            TextButton(
              onPressed: () => setState(() => _time = TimeOfDay(hour: free.hour, minute: free.minute)),
              child: Text(l.planUseFreeTime(fmt.time(free))),
            ),
        ],
      ),
    );
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
            Text(widget.task == null ? l.newTask : l.editTask, style: context.text.headlineSmall),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _title,
              autofocus: widget.task == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.taskTitle, hintText: l.taskTitleHint),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: Space.lg),
            // Day: today, tomorrow or any date.
            Text(l.timeWhenDay, style: context.text.titleSmall?.copyWith(color: context.semantic.muted)),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final (label, offset) in [(l.today, 0), (l.tomorrow, 1)])
                  ChoiceChip(
                    label: Text(label),
                    selected:
                        _date != null && Dates.sameDay(_date!, Dates.addDays(Dates.dateOnly(DateTime.now()), offset)),
                    onSelected: (_) => setState(() => _date = Dates.addDays(Dates.dateOnly(DateTime.now()), offset)),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(
                    _date == null ||
                            Dates.daysBetween(Dates.dateOnly(DateTime.now()), _date!) < 0 ||
                            Dates.daysBetween(Dates.dateOnly(DateTime.now()), _date!) > 1
                        ? (_date == null ? l.planPickDate : fmt.weekdayDayMonth(_date!))
                        : l.planPickDate,
                  ),
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
              ],
            ),
            const SizedBox(height: Space.lg),
            // Time and length: one card, one wheel.
            Text(l.timeSheetTitle, style: context.text.titleSmall?.copyWith(color: context.semantic.muted)),
            const SizedBox(height: Space.sm),
            AppCard(
              key: const Key('editor-time'),
              onTap: () async {
                final c = await pickTimeAndDuration(context, time: _time, minutes: _minutes);
                if (c != null) {
                  setState(() {
                    _time = c.time;
                    _minutes = c.minutes;
                  });
                }
              },
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: context.colors.primary),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      _time == null ? l.timeAnytime(durationLabel(l, _minutes)) : rangeLabel(_time!, _minutes),
                      style: context.text.headlineSmall?.copyWith(
                        fontSize: 20,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (_time != null)
                    Text(
                      durationLabel(l, _minutes),
                      style: context.text.labelLarge?.copyWith(color: context.semantic.muted),
                    ),
                  const SizedBox(width: Space.xs),
                  Icon(Icons.chevron_right_rounded, color: context.semantic.muted),
                ],
              ),
            ),
            ?_clashWarning(context),
            if (_time != null) ...[
              const SizedBox(height: Space.md),
              Text(l.remindLabel, style: context.text.titleSmall?.copyWith(color: context.semantic.muted)),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final m in const [-1, 0, 5, 15, 30, 60])
                    ChoiceChip(
                      avatar: m < 0 ? const Icon(Icons.notifications_off_outlined, size: 16) : null,
                      label: Text(m < 0 ? l.remindOff : (m == 0 ? l.remindAtStart : l.remindBefore(m))),
                      selected: _remind == m,
                      onSelected: (_) => setState(() => _remind = m),
                    ),
                ],
              ),
            ],
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
                  await ref.read(actionsProvider).duplicateTask(widget.task!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    showSnack(context, l.taskDuplicated);
                  }
                },
                child: Text(l.taskDuplicate),
              ),
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
