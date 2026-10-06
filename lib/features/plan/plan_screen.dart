import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/task_item.dart';
import '../shell/main_shell.dart';
import 'task_editor.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.navPlan),
          actions: const [ProfileButton()],
          bottom: TabBar(
            tabs: [
              Tab(text: l.planToday),
              Tab(text: l.planWeek),
              Tab(text: l.planMonth),
            ],
          ),
        ),
        body: const TabBarView(children: [_TodayView(), _RangeView(days: 7), _RangeView(days: 31)]),
        floatingActionButton: FloatingActionButton(
          tooltip: l.newTask,
          onPressed: () => showTaskEditor(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _TodayView extends ConsumerWidget {
  const _TodayView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final today = ref.watch(todayProvider);
    final all = ref.watch(tasksProvider).list;
    final overdue = all
        .where((t) => !t.isCompleted && t.anchorDate != null && Dates.dateOnly(t.anchorDate!).isBefore(today))
        .toList();
    final todays = all.where((t) => t.anchorDate != null && Dates.sameDay(t.anchorDate!, today)).toList();
    final scheduled = todays.where((t) => t.scheduledAt != null && !t.isCompleted).toList()
      ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    final anytime = [
      ...todays.where((t) => t.scheduledAt == null && !t.isCompleted),
      ...all.where((t) => t.anchorDate == null && !t.isCompleted),
    ];
    final done = todays.where((t) => t.isCompleted).toList();

    if (overdue.isEmpty && todays.isEmpty && anytime.isEmpty) {
      return EmptyState(
        icon: Icons.event_available_outlined,
        message: l.planEmpty,
        action: FilledButton.tonalIcon(
          onPressed: () => _optimize(context, ref),
          icon: const Icon(Icons.auto_fix_high),
          label: Text(l.planOptimize),
        ),
      );
    }
    return PageList(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () => _optimize(context, ref),
            icon: const Icon(Icons.auto_fix_high),
            label: Text(l.planOptimize),
          ),
        ),
        if (overdue.isNotEmpty) ...[
          SectionTitle(l.planOverdue),
          ...overdue.map((t) => TaskTile(task: t, overdue: true)),
        ],
        if (scheduled.isNotEmpty) ...[SectionTitle(l.planToday), ...scheduled.map((t) => TaskTile(task: t))],
        if (anytime.isNotEmpty) ...[SectionTitle(l.planUnscheduled), ...anytime.map((t) => TaskTile(task: t))],
        if (done.isNotEmpty) ...[SectionTitle(l.planCompleted), ...done.map((t) => TaskTile(task: t))],
      ],
    );
  }

  Future<void> _optimize(BuildContext context, WidgetRef ref) async {
    final n = await ref.read(actionsProvider).optimizePlan();
    if (context.mounted) showSnack(context, context.l10n.planOptimized(n));
  }
}

class _RangeView extends ConsumerWidget {
  const _RangeView({required this.days});

  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final today = ref.watch(todayProvider);
    final all = ref.watch(tasksProvider).list;
    final byDay = <DateTime, List<TaskItem>>{};
    for (final t in all) {
      final a = t.anchorDate;
      if (a == null) continue;
      final d = Dates.dateOnly(a);
      if (d.isBefore(today) || !d.isBefore(Dates.addDays(today, days))) continue;
      byDay.putIfAbsent(d, () => []).add(t);
    }
    if (byDay.isEmpty) return EmptyState(icon: Icons.calendar_month_outlined, message: l.planEmpty);
    final keys = byDay.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 120),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final d = keys[i];
        final tasks = byDay[d]!..sort((a, b) => (a.scheduledAt ?? d).compareTo(b.scheduledAt ?? d));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(Dates.sameDay(d, today) ? l.today : fmt.weekdayDayMonth(d)),
            ...tasks.map((t) => TaskTile(task: t)),
          ],
        );
      },
    );
  }
}

class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task, this.overdue = false});

  final TaskItem task;
  final bool overdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final priorityColor = switch (task.priority) {
      TaskPriority.high => context.semantic.negative,
      TaskPriority.medium => context.semantic.warning,
      TaskPriority.low => context.semantic.muted,
    };
    final subtitle = [
      if (task.scheduledAt != null) fmt.time(task.scheduledAt!),
      l.minutesShort(task.estimatedMinutes),
      l.priorityLabel(task.priority),
      if (task.recurrence != Recurrence.none) l.recurrence(task.recurrence),
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: ListTile(
        onTap: () => showTaskEditor(context, task: task),
        leading: Checkbox(
          value: task.isCompleted,
          semanticLabel: task.isCompleted ? l.markNotDone : l.markDone,
          onChanged: (_) async {
            final next = await ref.read(actionsProvider).toggleTask(task);
            if (next && context.mounted) showSnack(context, l.taskAddedNextOccurrence);
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? context.semantic.muted : null,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: overdue ? context.semantic.negative : null)),
        trailing: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
