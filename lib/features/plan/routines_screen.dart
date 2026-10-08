import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/ids.dart';
import '../../core/widgets/common.dart';
import '../../domain/models/routine_goal.dart';
import '../../domain/plan/day_timeline.dart';
import '../../domain/plan/routines.dart';
import 'time_picker_sheet.dart';

String _summary(BuildContext context, Routine r) {
  final l = context.l10n;
  return [
    if (r.startMinutes != null)
      l.routineStartsAt(hhmm(TimeOfDay(hour: r.startMinutes! ~/ 60, minute: r.startMinutes! % 60))),
    l.routineSummary(r.steps.length, durationLabel(l, r.totalMinutes)),
  ].join(' · ');
}

/// Your routines and ready-made ones; add any of them to a day in a tap.
class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final mine = ref.watch(routinesProvider).list.where((r) => !r.deleted).toList()
      ..sort((a, b) => (a.startMinutes ?? 0).compareTo(b.startMinutes ?? 0));
    final used = {for (final r in mine) r.id};
    return Scaffold(
      appBar: AppBar(title: Text(l.routinesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-routines',
        onPressed: () => showRoutineEditor(context),
        icon: const Icon(Icons.add),
        label: Text(l.routineNew),
      ),
      body: PageList(
        children: [
          Text(l.routinesIntro, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
          if (mine.isNotEmpty) ...[
            SectionTitle(l.routinesMine),
            for (final r in mine)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _RoutineCard(
                  routine: r,
                  onTap: () => showRoutineEditor(context, routine: r),
                  action: FilledButton.tonalIcon(
                    onPressed: () => addRoutineToDay(context, ref, r, ref.read(todayProvider)),
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: Text(l.routineAddToDay),
                  ),
                ),
              ),
          ],
          SectionTitle(l.routinesReady),
          for (final t in routineTemplates)
            if (!used.contains('tpl-${t.key}'))
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _RoutineCard(
                  routine: t.toRoutine('tpl-${t.key}', lang),
                  action: OutlinedButton(
                    onPressed: () async {
                      unawaited(HapticFeedback.selectionClick());
                      await ref.read(actionsProvider).saveRoutine(t.toRoutine('tpl-${t.key}', lang));
                    },
                    child: Text(l.routineUse),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine, required this.action, this.onTap});
  final Routine routine;
  final Widget action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(routine.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routine.name, style: context.text.titleMedium),
                  Text(
                    _summary(context, routine),
                    style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Text(
          routine.steps.map((s) => s.title).join(' → '),
          style: context.text.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Space.sm),
        Align(alignment: AlignmentDirectional.centerEnd, child: action),
      ],
    ),
  );
}

/// Asks for the start time (pre-filled with the routine's usual one) and
/// adds the steps to [day].
Future<void> addRoutineToDay(BuildContext context, WidgetRef ref, Routine r, DateTime day) async {
  final l = context.l10n;
  final start = r.startMinutes ?? 9 * 60;
  final c = await pickTimeAndDuration(
    context,
    time: TimeOfDay(hour: start ~/ 60, minute: start % 60),
    minutes: r.totalMinutes.clamp(5, 480),
    allowNoTime: false,
  );
  if (c?.time == null) return;
  final n = await ref.read(actionsProvider).applyRoutine(r, day, c!.time!.hour * 60 + c.time!.minute);
  if (context.mounted) showSnack(context, l.routineAdded(n));
}

/// Picks one of your routines and adds it to [day].
Future<void> pickRoutineForDay(BuildContext context, WidgetRef ref, DateTime day) async {
  final l = context.l10n;
  final lang = Localizations.localeOf(context).languageCode;
  final mine = ref.read(routinesProvider).list.where((r) => !r.deleted).toList();
  final options = mine.isNotEmpty ? mine : [for (final t in routineTemplates) t.toRoutine('tpl-${t.key}', lang)];
  final r = await showModalBottomSheet<Routine>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
        children: [
          Text(l.routinesTitle, style: sheet.text.headlineSmall),
          const SizedBox(height: Space.md),
          for (final r in options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(r.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(r.name),
              subtitle: Text(_summary(sheet, r)),
              trailing: const Icon(Icons.add_circle_outline_rounded),
              onTap: () => Navigator.pop(sheet, r),
            ),
        ],
      ),
    ),
  );
  if (r == null || !context.mounted) return;
  if (!mine.any((m) => m.id == r.id)) await ref.read(actionsProvider).saveRoutine(r);
  if (context.mounted) await addRoutineToDay(context, ref, r, day);
}

Future<void> showRoutineEditor(BuildContext context, {Routine? routine}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _RoutineEditor(routine: routine),
);

class _RoutineEditor extends ConsumerStatefulWidget {
  const _RoutineEditor({this.routine});
  final Routine? routine;

  @override
  ConsumerState<_RoutineEditor> createState() => _RoutineEditorState();
}

class _RoutineEditorState extends ConsumerState<_RoutineEditor> {
  static const _emojis = ['✨', '🌅', '🎯', '💪', '🌙', '🧺', '📚', '🧘', '🍳', '🚶'];
  late final _name = TextEditingController(text: widget.routine?.name);
  final _step = TextEditingController();
  late String _emoji = widget.routine?.emoji ?? '✨';
  late int? _start = widget.routine?.startMinutes ?? 8 * 60;
  late final List<RoutineStep> _steps = [...?widget.routine?.steps];

  @override
  void dispose() {
    _name.dispose();
    _step.dispose();
    super.dispose();
  }

  void _addStep() {
    final q = parseQuickTask(_step.text);
    if (q.title.isEmpty) return;
    setState(() => _steps.add(RoutineStep(q.title, q.minutes ?? 15)));
    _step.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.routine == null ? l.routineNew : widget.routine!.name, style: context.text.headlineSmall),
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
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.routineName),
            ),
            const SizedBox(height: Space.md),
            AppCard(
              onTap: () async {
                final s = _start ?? 8 * 60;
                final c = await pickTimeAndDuration(
                  context,
                  time: TimeOfDay(hour: s ~/ 60, minute: s % 60),
                  minutes: _steps.fold(0, (a, x) => a + x.minutes).clamp(5, 480),
                );
                if (c != null) setState(() => _start = c.time == null ? null : c.time!.hour * 60 + c.time!.minute);
              },
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: context.colors.primary),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      _start == null
                          ? l.timeNoTime
                          : l.routineStartsAt(hhmm(TimeOfDay(hour: _start! ~/ 60, minute: _start! % 60))),
                      style: context.text.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            SectionTitle(l.foodSteps),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (a, b) => setState(() => _steps.insert(b, _steps.removeAt(a))),
              children: [
                for (final (i, s) in _steps.indexed)
                  ListTile(
                    key: ValueKey('step-$i-${s.title}'),
                    contentPadding: EdgeInsets.zero,
                    leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator_rounded)),
                    title: Text(s.title),
                    subtitle: Text(durationLabel(l, s.minutes)),
                    trailing: IconButton(
                      tooltip: l.delete,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _steps.removeAt(i)),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _step,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _addStep(),
                    decoration: InputDecoration(hintText: l.routineStepHint),
                  ),
                ),
                const SizedBox(width: Space.sm),
                IconButton.filledTonal(tooltip: l.routineAddStep, onPressed: _addStep, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: () async {
                final name = _name.text.trim();
                if (name.isEmpty || _steps.isEmpty) return;
                final r = widget.routine;
                await ref
                    .read(actionsProvider)
                    .saveRoutine(
                      r == null
                          ? Routine(
                              id: newId(),
                              updatedAt: DateTime.now(),
                              name: name,
                              emoji: _emoji,
                              startMinutes: _start,
                              steps: _steps,
                            )
                          : Routine(
                              id: r.id,
                              updatedAt: DateTime.now(),
                              name: name,
                              emoji: _emoji,
                              startMinutes: _start,
                              steps: _steps,
                            ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l.save),
            ),
            if (widget.routine != null)
              TextButton(
                onPressed: () async {
                  await ref.read(actionsProvider).deleteRoutine(widget.routine!.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(l.delete, style: TextStyle(color: context.semantic.negative)),
              ),
          ],
        ),
      ),
    );
  }
}
