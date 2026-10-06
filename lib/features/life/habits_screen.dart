import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../core/widgets/common.dart';
import '../../domain/engines/insight_engine.dart';
import '../../domain/engines/streaks.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/habit.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final habits = (ref.watch(habitsProvider).list).where((h) => !h.archived).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final logs = ref.watch(habitLogsProvider).list;
    final today = ref.watch(todayProvider);
    final key = Dates.dayKey(today);
    final weekRate = InsightEngine.habitRate(habits, logs, today);
    final change = InsightEngine.habitRateChange(habits, logs, today);

    return Scaffold(
      appBar: AppBar(title: Text(l.lifeHabits)),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-habits',
        tooltip: l.newHabit,
        onPressed: () => _editHabit(context, ref),
        child: const Icon(Icons.add),
      ),
      body: habits.isEmpty
          ? EmptyState(icon: Icons.repeat_rounded, message: l.habitsEmpty)
          : PageList(
              children: [
                if (weekRate != null)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.habitWeeklyRate((weekRate * 100).round()), style: context.text.titleMedium),
                        const SizedBox(height: Space.sm),
                        ProgressBar(value: weekRate),
                        if (change != null && change.abs() >= 10) ...[
                          const SizedBox(height: Space.sm),
                          Text(
                            change > 0 ? l.insightHabitUp(change) : l.insightHabitDown(-change),
                            style: context.text.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: Space.md),
                ...habits.map((h) {
                  final count = logs.where((x) => x.id == HabitLog.idFor(h.id, key)).firstOrNull?.count ?? 0;
                  final streak = const StreakCalculator().habitStreak(
                    completedDays: {
                      for (final x in logs)
                        if (x.habitId == h.id && x.count >= h.targetPerDay) x.day,
                    },
                    weekdays: h.weekdays,
                    today: today,
                  );
                  return _HabitRow(habit: h, count: count, streak: streak, onEdit: () => _editHabit(context, ref, h));
                }),
              ],
            ),
    );
  }

  Future<void> _editHabit(BuildContext context, WidgetRef ref, [Habit? existing]) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _HabitEditor(existing: existing),
  );
}

class _HabitRow extends ConsumerWidget {
  const _HabitRow({required this.habit, required this.count, required this.streak, required this.onEdit});

  final Habit habit;
  final int count;
  final int streak;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final done = count >= habit.targetPerDay;
    final actions = ref.read(actionsProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: AppCard(
        onTap: onEdit,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.name, style: context.text.titleMedium),
                  const SizedBox(height: Space.xs),
                  Text(
                    '${count.clamp(0, 999)}/${habit.targetPerDay} ${habit.unit}  ·  🔥 ${l.habitStreak(streak)}',
                    style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                  ),
                  const SizedBox(height: Space.sm),
                  ProgressBar(
                    value: count / habit.targetPerDay,
                    height: 6,
                    color: done ? context.semantic.positive : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.md),
            if (habit.targetPerDay > 1)
              IconButton(
                tooltip: l.habitDecrement(habit.name),
                onPressed: count > 0 ? () => actions.logHabit(habit, -1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
            IconButton.filledTonal(
              tooltip: l.habitIncrement(habit.name),
              iconSize: 28,
              onPressed: () => actions.logHabit(habit, habit.targetPerDay == 1 && done ? -1 : 1),
              icon: Icon(done ? Icons.check_rounded : Icons.add_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitEditor extends ConsumerStatefulWidget {
  const _HabitEditor({this.existing});

  final Habit? existing;

  @override
  ConsumerState<_HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends ConsumerState<_HabitEditor> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _unit = TextEditingController(text: widget.existing?.unit ?? '');
  late HabitType _type = widget.existing?.type ?? HabitType.custom;
  late int _target = widget.existing?.targetPerDay ?? 1;
  late final Set<int> _days = {
    ...(widget.existing?.weekdays ?? const {1, 2, 3, 4, 5, 6, 7}),
  };

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    super.dispose();
  }

  static const _presets = {
    HabitType.water: (8, '🥛'),
    HabitType.reading: (1, '10 min'),
    HabitType.exercise: (1, '30 min'),
    HabitType.meditation: (1, '10 min'),
    HabitType.sleep: (1, ''),
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? l.newHabit : l.edit, style: context.text.titleLarge),
            const SizedBox(height: Space.lg),
            if (widget.existing == null) ...[
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: HabitType.values
                    .map(
                      (t) => ChoiceChip(
                        label: Text(l.habitType(t)),
                        selected: _type == t,
                        onSelected: (_) => setState(() {
                          _type = t;
                          final p = _presets[t];
                          if (p != null) {
                            _target = p.$1;
                            _unit.text = p.$2;
                            if (_name.text.isEmpty || HabitType.values.any((x) => l.habitType(x) == _name.text)) {
                              _name.text = l.habitType(t);
                            }
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: Space.lg),
            ],
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l.habitName),
            ),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(child: Text('${l.habitTarget}: $_target', style: context.text.titleSmall)),
                IconButton(
                  onPressed: _target > 1 ? () => setState(() => _target--) : null,
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: _target < 50 ? () => setState(() => _target++) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            TextField(
              controller: _unit,
              decoration: InputDecoration(labelText: l.habitUnit),
            ),
            const SizedBox(height: Space.md),
            Text(l.habitDays, style: context.text.titleSmall),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.xs,
              children: [1, 2, 3, 4, 5, 6, 7]
                  .map(
                    (d) => FilterChip(
                      label: Text(l.weekdayShort('$d')),
                      selected: _days.contains(d),
                      onSelected: (v) => setState(() => v ? _days.add(d) : (_days.length > 1 ? _days.remove(d) : null)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: () async {
                if (_name.text.trim().isEmpty) return;
                final e = widget.existing;
                final now = DateTime.now();
                final h =
                    e?.copyWith(
                      name: _name.text.trim(),
                      targetPerDay: _target,
                      unit: _unit.text.trim(),
                      weekdays: _days,
                    ) ??
                    Habit(
                      id: newId(),
                      updatedAt: now,
                      name: _name.text.trim(),
                      type: _type,
                      targetPerDay: _target,
                      unit: _unit.text.trim(),
                      weekdays: _days,
                      createdAt: now,
                    );
                await ref.read(actionsProvider).saveHabit(h, isNew: e == null);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l.save),
            ),
            if (widget.existing != null) ...[
              TextButton(
                onPressed: () async {
                  await ref.read(actionsProvider).saveHabit(widget.existing!.copyWith(archived: true), isNew: false);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(l.habitArchive),
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(actionsProvider).deleteHabit(widget.existing!.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(l.delete, style: TextStyle(color: context.semantic.negative)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
