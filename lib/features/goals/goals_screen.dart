import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/models/routine_goal.dart';

Set<String> _doneTaskIds(WidgetRef ref) => {
  for (final t in ref.watch(tasksProvider).list)
    if (t.isCompleted && !t.deleted) t.id,
};

/// Long-term goals with their progress.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final done = _doneTaskIds(ref);
    final goals = ref.watch(lifeGoalsProvider).list.where((g) => !g.deleted && !g.archived).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Scaffold(
      appBar: AppBar(title: Text(l.goalsLife)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-goals',
        onPressed: () => showGoalEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l.goalNew),
      ),
      body: goals.isEmpty
          ? EmptyState(
              icon: Icons.flag_outlined,
              message: l.goalsLifeIntro,
              action: FilledButton(onPressed: () => showGoalEditor(context), child: Text(l.goalNew)),
            )
          : PageList(
              children: [
                Text(l.goalsLifeIntro, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
                const SizedBox(height: Space.md),
                for (final g in goals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: GoalCard(goal: g, doneTaskIds: done),
                  ),
              ],
            ),
    );
  }
}

class GoalCard extends ConsumerWidget {
  const GoalCard({super.key, required this.goal, required this.doneTaskIds});
  final LifeGoal goal;
  final Set<String> doneTaskIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final today = ref.watch(todayProvider);
    final p = goal.progress(doneTaskIds);
    final next = goal.steps.where((s) => !s.done && !(s.taskId != null && doneTaskIds.contains(s.taskId))).firstOrNull;
    return AppCard(
      onTap: () => context.push('/goals/${goal.id}'),
      child: Row(
        children: [
          ProgressRing(
            value: p,
            size: 60,
            stroke: 5,
            child: Text(goal.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  [
                    l.goalStepsCount(goal.doneSteps(doneTaskIds), goal.steps.length),
                    if (goal.deadline != null && !goal.deadline!.isBefore(today))
                      l.goalDaysLeft(Dates.daysBetween(today, goal.deadline!)),
                  ].join(' · '),
                  style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                ),
                if (next != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${l.goalNextStep}: ${next.title}',
                    style: context.text.bodySmall?.copyWith(color: context.colors.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

/// One goal: why it matters, its steps (tick or plan each), progress.
class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final done = _doneTaskIds(ref);
    final g = ref.watch(lifeGoalsProvider).list.where((x) => x.id == id && !x.deleted).firstOrNull;
    if (g == null) return Scaffold(appBar: AppBar(), body: const SizedBox());
    final actions = ref.read(actionsProvider);
    final p = g.progress(done);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showGoalEditor(context, goal: g),
          ),
          IconButton(
            tooltip: l.goalArchive,
            icon: const Icon(Icons.archive_outlined),
            onPressed: () async {
              await actions.saveLifeGoal(g.copyWith(archived: true));
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: PageList(
        children: [
          Row(
            children: [
              ProgressRing(
                value: p,
                size: 88,
                stroke: 7,
                child: Text('${(p * 100).round()}%', style: context.text.titleLarge),
              ),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.emoji, style: const TextStyle(fontSize: 28)),
                    Text(g.title, style: context.text.headlineSmall),
                    if (g.deadline != null)
                      Text(
                        fmt.weekdayDayMonth(g.deadline!),
                        style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (g.why.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded, color: context.colors.primary),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(g.why, style: context.text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
          SectionTitle(l.foodSteps, trailing: Text(l.goalStepsCount(g.doneSteps(done), g.steps.length))),
          if (p >= 1 && g.steps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Text(l.goalAllDone, style: context.text.titleMedium?.copyWith(color: context.semantic.positive)),
            ),
          for (final s in g.steps)
            Builder(
              builder: (context) {
                final isDone = s.done || (s.taskId != null && done.contains(s.taskId));
                return Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: AppCard(
                    padding: const EdgeInsets.fromLTRB(Space.xs, Space.xs, Space.sm, Space.xs),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isDone,
                          onChanged: (v) {
                            unawaited(HapticFeedback.selectionClick());
                            unawaited(
                              actions.saveLifeGoal(
                                g.copyWith(
                                  steps: [for (final x in g.steps) x.id == s.id ? x.copyWith(done: v ?? false) : x],
                                ),
                              ),
                            );
                          },
                        ),
                        Expanded(
                          child: Text(
                            s.title,
                            style: context.text.bodyLarge?.copyWith(
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              color: isDone ? context.semantic.muted : null,
                            ),
                          ),
                        ),
                        if (!isDone && s.taskId == null)
                          TextButton.icon(
                            onPressed: () async {
                              await actions.planGoalStep(g, s, ref.read(todayProvider));
                              if (context.mounted) showSnack(context, l.goalStepPlanned);
                            },
                            icon: const Icon(Icons.event_available_rounded, size: 18),
                            label: Text(l.goalPlanStep),
                          )
                        else if (!isDone)
                          Icon(Icons.event_available_rounded, size: 18, color: context.colors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

Future<void> showGoalEditor(BuildContext context, {LifeGoal? goal}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _GoalEditor(goal: goal),
);

class _GoalEditor extends ConsumerStatefulWidget {
  const _GoalEditor({this.goal});
  final LifeGoal? goal;

  @override
  ConsumerState<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends ConsumerState<_GoalEditor> {
  static const _emojis = ['🎯', '📚', '💪', '🗣️', '💼', '🏃', '🎨', '💰', '🧘', '✈️'];
  late final _title = TextEditingController(text: widget.goal?.title);
  late final _why = TextEditingController(text: widget.goal?.why);
  late final _steps = TextEditingController(text: widget.goal?.steps.map((s) => s.title).join('\n'));
  late String _emoji = widget.goal?.emoji ?? '🎯';
  late DateTime? _deadline = widget.goal?.deadline;

  @override
  void dispose() {
    _title.dispose();
    _why.dispose();
    _steps.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final old = {for (final s in widget.goal?.steps ?? const <GoalStep>[]) s.title: s};
    final steps = [
      for (final line in _steps.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty))
        old[line] ?? GoalStep(id: newId(), title: line),
    ];
    final g = widget.goal;
    await ref
        .read(actionsProvider)
        .saveLifeGoal(
          g == null
              ? LifeGoal(
                  id: newId(),
                  updatedAt: DateTime.now(),
                  title: title,
                  emoji: _emoji,
                  why: _why.text.trim(),
                  deadline: _deadline,
                  steps: steps,
                  createdAt: DateTime.now(),
                )
              : g.copyWith(
                  title: title,
                  emoji: _emoji,
                  why: _why.text.trim(),
                  deadline: _deadline,
                  clearDeadline: _deadline == null,
                  steps: steps,
                ),
        );
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
            Text(widget.goal == null ? l.goalNew : widget.goal!.title, style: context.text.headlineSmall),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.xs,
              children: [
                for (final e in _emojis)
                  ChoiceChip(
                    label: Text(e, style: const TextStyle(fontSize: 18)),
                    selected: _emoji == e,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _emoji = e),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l.goalTitleHint),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _why,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.goalWhy),
            ),
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: DateTime(now.year + 10),
                  initialDate: _deadline ?? DateTime(now.year, now.month + 3, now.day),
                );
                if (d != null) setState(() => _deadline = d);
              },
              icon: const Icon(Icons.event),
              label: Text(_deadline == null ? l.goalDeadline : fmt.weekdayDayMonth(_deadline!)),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _steps,
              minLines: 4,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.goalStepsHint, alignLabelWithHint: true),
            ),
            const SizedBox(height: Space.xl),
            FilledButton(onPressed: _save, child: Text(l.save)),
            if (widget.goal != null)
              TextButton(
                onPressed: () async {
                  await ref.read(actionsProvider).deleteLifeGoal(widget.goal!.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    context.go('/goals');
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
