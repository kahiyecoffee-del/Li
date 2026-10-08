import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/plan_optimizer.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/task_item.dart';
import '../../domain/plan/day_timeline.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shell/main_shell.dart';
import 'task_editor.dart';

/// "1 sa 30 dk", "45 dk", "2 sa".
String formatDuration(AppLocalizations l, int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return l.minutesShort(m);
  return m == 0 ? l.durH(h) : l.durHM(h, m);
}

Accent categoryAccent(TaskCategory c) => switch (c) {
  TaskCategory.work => Accent.plan,
  TaskCategory.personal => Accent.ai,
  TaskCategory.health => Accent.wellbeing,
  TaskCategory.errands => Accent.food,
  TaskCategory.learning => Accent.news,
  TaskCategory.social => Accent.goals,
  TaskCategory.other => Accent.score,
};

/// The day planner: pick a day on the strip, see it as a timeline with the
/// free time between tasks, and add tasks in one line at the bottom.
class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  DateTime? _day;
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  (DateTime, DateTime) _bounds(DateTime day) {
    final p = ref.read(profileProvider).value;
    final wake = p?.wakeTime?.minutes ?? 8 * 60;
    var sleep = p?.sleepTime?.minutes ?? 23 * 60;
    if (sleep <= wake) sleep = 24 * 60 - 1; // sleeps after midnight: plan until 23:59
    final d = Dates.dateOnly(day);
    return (d.add(Duration(minutes: wake)), d.add(Duration(minutes: sleep)));
  }

  Future<void> _quickAdd(DateTime day) async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final q = parseQuickTask(text);
    if (q.title.isEmpty) return;
    unawaited(HapticFeedback.lightImpact());
    await ref.read(actionsProvider).addQuickTask(q, day);
    _input.clear();
    if (mounted) showSnack(context, context.l10n.planQuickAdded(q.title));
  }

  Future<void> _autoSchedule(TaskItem t, DateTime day, List<TaskItem> dayTasks) async {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final (start, end) = _bounds(day);
    final slots = const PlanOptimizer().schedule(
      flexible: [t],
      fixed: dayTasks.where((x) => x.scheduledAt != null && !x.isCompleted && x.id != t.id).toList(),
      now: Dates.sameDay(day, DateTime.now()) ? DateTime.now() : start,
      dayStart: start,
      dayEnd: end,
    );
    if (slots.isEmpty) {
      showSnack(context, l.planNoSlot);
      return;
    }
    await ref.read(actionsProvider).scheduleTask(t, slots.first.start);
    if (mounted) showSnack(context, l.planScheduledAt(fmt.time(slots.first.start)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = ref.watch(todayProvider);
    final day = _day ?? today;
    final isToday = Dates.sameDay(day, today);
    final all = ref.watch(tasksProvider).list.where((t) => !t.deleted).toList();
    final dayTasks = all.where((t) => t.anchorDate != null && Dates.sameDay(t.anchorDate!, day)).toList();
    final overdue = isToday
        ? all
              .where((t) => !t.isCompleted && t.anchorDate != null && Dates.dateOnly(t.anchorDate!).isBefore(today))
              .toList()
        : const <TaskItem>[];
    final anytime = [
      ...dayTasks.where((t) => t.scheduledAt == null && !t.isCompleted),
      if (isToday) ...all.where((t) => t.anchorDate == null && !t.isCompleted),
    ];
    final done = dayTasks.where((t) => t.isCompleted).toList();
    final (start, end) = _bounds(day);
    final now = DateTime.now();
    final timeline = buildTimeline(
      tasks: dayTasks.where((t) => !t.isCompleted).toList(),
      day: day,
      dayStart: start,
      dayEnd: end,
      now: now,
    );
    final stats = dayStats(dayTasks, timeline);
    final busyDays = {
      for (final t in all)
        if (t.anchorDate != null && !t.isCompleted) Dates.dayKey(t.anchorDate!),
    };

    var i = 0;
    Widget enter(Widget w) => FadeSlideIn(delay: Motion.stagger(i++), offset: 0.04, child: w);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navPlan),
        actions: [
          IconButton(
            tooltip: l.planPickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: day,
                firstDate: Dates.addDays(today, -365),
                lastDate: Dates.addDays(today, 365 * 2),
              );
              if (d != null) setState(() => _day = d);
            },
          ),
          const ProfileButton(),
        ],
      ),
      bottomNavigationBar: _Composer(
        controller: _input,
        focus: _focus,
        onSubmit: () => _quickAdd(day),
        onDetails: () =>
            showTaskEditor(context, day: day, title: _input.text.trim().isEmpty ? null : _input.text.trim()),
      ),
      body: AmbientBackdrop(
        height: 360,
        child: Column(
          children: [
            _DateStrip(
              today: today,
              selected: day,
              busy: busyDays,
              onSelect: (d) {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _day = d);
              },
            ),
            Expanded(
              child: ListView(
                key: ValueKey(Dates.dayKey(day)),
                padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xxl),
                children: [
                  enter(
                    _DaySummary(
                      day: day,
                      isToday: isToday,
                      stats: stats,
                      onOptimize: () async {
                        final n = await ref.read(actionsProvider).optimizePlan();
                        if (context.mounted) showSnack(context, l.planOptimized(n));
                      },
                    ),
                  ),
                  if (dayTasks.isEmpty && overdue.isEmpty && anytime.isEmpty)
                    enter(
                      Padding(
                        padding: const EdgeInsets.only(top: Space.lg),
                        child: Text(
                          l.planDayEmpty,
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium?.copyWith(color: context.semantic.muted),
                        ),
                      ),
                    ),
                  if (overdue.isNotEmpty) ...[
                    SectionTitle(l.planOverdue, trailing: _CountPill(overdue.length)),
                    for (final t in overdue)
                      enter(
                        _TaskCard(
                          task: t,
                          overdue: true,
                          trailingAction: (l.planToToday, () => ref.read(actionsProvider).moveTaskTo(t, today)),
                        ),
                      ),
                  ],
                  if (timeline.isNotEmpty) ...[
                    SectionTitle(
                      l.planTimeline,
                      eyebrow: DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString()).format(day),
                    ),
                    ..._timelineRows(context, timeline, day, isToday, now).map(enter),
                  ],
                  if (anytime.isNotEmpty) ...[
                    SectionTitle(l.planUnscheduled, trailing: _CountPill(anytime.length)),
                    for (final t in anytime)
                      enter(
                        _TaskCard(
                          task: t,
                          trailingAction: (l.planScheduleIt, () => _autoSchedule(t, day, dayTasks)),
                          postponeFrom: day,
                        ),
                      ),
                  ],
                  if (done.isNotEmpty) ...[
                    SectionTitle(l.planCompleted, trailing: _CountPill(done.length)),
                    for (final t in done) enter(_TaskCard(task: t)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _timelineRows(
    BuildContext context,
    List<TimelineEntry> entries,
    DateTime day,
    bool isToday,
    DateTime now,
  ) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final rows = <Widget>[];
    var nowShown = !isToday;
    void maybeNow(DateTime before) {
      if (!nowShown && now.isBefore(before)) {
        rows.add(
          _TimelineRow(
            time: fmt.time(now),
            dot: _Dot.now,
            child: _NowMarker(label: l.planNow),
          ),
        );
        nowShown = true;
      }
    }

    for (final e in entries) {
      maybeNow(e.start);
      switch (e) {
        case TaskBlock(:final task):
          rows.add(
            _TimelineRow(
              time: fmt.time(e.start),
              dot: _Dot.task,
              color: categoryAccent(task.category).color,
              child: _TaskCard(task: task, range: '${fmt.time(e.start)} – ${fmt.time(e.end)}', postponeFrom: day),
            ),
          );
        case FreeGap():
          rows.add(
            _TimelineRow(
              time: fmt.time(e.start),
              dot: _Dot.free,
              child: _FreeSlot(
                label: l.planFree(formatDuration(l, e.minutes)),
                onAdd: () => showTaskEditor(
                  context,
                  day: day,
                  time: TimeOfDay(hour: e.start.hour, minute: e.start.minute),
                ),
              ),
            ),
          );
      }
    }
    if (!nowShown) {
      rows.add(
        _TimelineRow(
          time: fmt.time(now),
          dot: _Dot.now,
          child: _NowMarker(label: l.planNow),
        ),
      );
    }
    return rows;
  }
}

// ---------------------------------------------------------------- date strip

class _DateStrip extends StatefulWidget {
  const _DateStrip({required this.today, required this.selected, required this.busy, required this.onSelect});
  final DateTime today;
  final DateTime selected;
  final Set<String> busy;
  final ValueChanged<DateTime> onSelect;

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  static const _itemWidth = 56.0, _gap = 8.0;
  late final _scroll = ScrollController(initialScrollOffset: _offsetFor(widget.selected));

  DateTime get _first {
    final a = Dates.addDays(widget.today, -3);
    final b = Dates.addDays(widget.selected, -3);
    return a.isBefore(b) ? a : b;
  }

  double _offsetFor(DateTime d) => (Dates.daysBetween(_first, d) - 2).clamp(0, 999) * (_itemWidth + _gap);

  @override
  void didUpdateWidget(_DateStrip old) {
    super.didUpdateWidget(old);
    if (!Dates.sameDay(old.selected, widget.selected) && _scroll.hasClients) {
      _scroll.animateTo(_offsetFor(widget.selected), duration: Motion.normal, curve: Motion.emphasized);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).toString();
    final first = _first;
    final count = Dates.daysBetween(first, widget.today) + 31;
    return SizedBox(
      height: 84,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.page, vertical: Space.sm),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (_, i) {
          final d = Dates.addDays(first, i);
          final sel = Dates.sameDay(d, widget.selected);
          final isToday = Dates.sameDay(d, widget.today);
          final busy = widget.busy.contains(Dates.dayKey(d));
          final ink = context.colors.onSurface;
          return Semantics(
            selected: sel,
            button: true,
            label: DateFormat.MMMMEEEEd(loc).format(d),
            child: GestureDetector(
              key: ValueKey('day-${Dates.dayKey(d)}'),
              onTap: () => widget.onSelect(d),
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.normal),
                curve: Motion.emphasized,
                width: _itemWidth,
                decoration: BoxDecoration(
                  color: sel ? ink : context.colors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(
                    color: isToday && !sel ? context.colors.primary : context.semantic.border,
                    width: isToday && !sel ? 1.2 : 0.8,
                  ),
                  boxShadow: sel ? Shadows.lift(Theme.of(context).brightness) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.upper(DateFormat.E(loc).format(d)),
                      style: context.text.labelSmall?.copyWith(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: sel ? context.colors.surface.withValues(alpha: 0.7) : context.semantic.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.day}',
                      style: context.text.headlineSmall?.copyWith(
                        fontSize: 20,
                        color: sel ? context.colors.surface : ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedOpacity(
                      opacity: busy ? 1 : 0,
                      duration: Motion.fast,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel ? Palette.goldDark : context.colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------------- day summary

class _DaySummary extends ConsumerWidget {
  const _DaySummary({required this.day, required this.isToday, required this.stats, required this.onOptimize});
  final DateTime day;
  final bool isToday;
  final DayStats stats;
  final VoidCallback onOptimize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgressRing(
                value: stats.progress,
                size: 76,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCount(
                      value: stats.done,
                      format: (v) => '$v/${stats.total}',
                      style: context.text.titleLarge?.copyWith(fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(
                      isToday ? l.today : DateFormat.EEEE(Localizations.localeOf(context).toString()).format(day),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.total == 0 ? l.planEmptyShort : l.planProgress(stats.done, stats.total),
                      style: context.text.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (stats.plannedMinutes > 0) l.planPlannedTime(formatDuration(l, stats.plannedMinutes)),
                        if (stats.freeMinutes > 0) l.planFreeTime(formatDuration(l, stats.freeMinutes)),
                      ].join(' · '),
                      style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              if (isToday) ...[
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: onOptimize,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: FittedBox(child: Text(l.planOptimize)),
                  ),
                ),
                const SizedBox(width: Space.sm),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => context.go('/ai?topic=plan&n=${DateTime.now().microsecondsSinceEpoch}'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: FittedBox(child: Text(l.planWithLio)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: context.colors.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(Radii.pill),
    ),
    child: Text('$count', style: context.text.labelMedium?.copyWith(color: context.colors.primary)),
  );
}

// ------------------------------------------------------------------ timeline

enum _Dot { task, free, now }

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.time, required this.dot, required this.child, this.color});
  final String time;
  final _Dot dot;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold;
    final dotColor = switch (dot) {
      _Dot.task => color ?? context.colors.primary,
      _Dot.free => context.semantic.border,
      _Dot.now => gold,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                time,
                style: context.text.labelSmall?.copyWith(
                  color: dot == _Dot.now ? gold : context.semantic.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: dot == _Dot.now ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(width: 0.8, height: 18, color: context.semantic.border),
                Container(
                  width: dot == _Dot.now ? 10 : 8,
                  height: dot == _Dot.now ? 10 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dot == _Dot.free ? context.colors.surface : dotColor,
                    border: Border.all(color: dotColor, width: 1.5),
                    boxShadow: dot == _Dot.now ? [BoxShadow(color: gold.withValues(alpha: 0.5), blurRadius: 8)] : null,
                  ),
                ),
                Expanded(child: Container(width: 0.8, color: context.semantic.border)),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _NowMarker extends StatelessWidget {
  const _NowMarker({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Text(
            context.upper(label),
            style: context.text.labelSmall?.copyWith(color: gold, letterSpacing: 1.4, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [gold, gold.withValues(alpha: 0)])),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeSlot extends StatelessWidget {
  const _FreeSlot({required this.label, required this.onAdd});
  final String label;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(Radii.md),
      child: CustomPaint(
        painter: _DashedBorder(color: context.semantic.border, radius: Radii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
              ),
              Icon(Icons.add_rounded, size: 18, color: context.colors.primary),
              const SizedBox(width: 4),
              Text(context.l10n.add, style: context.text.labelMedium?.copyWith(color: context.colors.primary)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, (d + 4.5).clamp(0, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

// --------------------------------------------------------------------- tasks

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, this.range, this.overdue = false, this.trailingAction, this.postponeFrom});

  final TaskItem task;
  final String? range;
  final bool overdue;
  final (String, VoidCallback)? trailingAction;

  /// Swiping left moves the task to the day after this one.
  final DateTime? postponeFrom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final accent = categoryAccent(task.category);
    final meta = [
      ?range,
      if (range == null) l.minutesShort(task.estimatedMinutes) else formatDuration(l, task.estimatedMinutes),
      if (task.priority == TaskPriority.high) l.priorityLabel(task.priority),
      if (task.recurrence != Recurrence.none) l.recurrence(task.recurrence),
    ].join(' · ');

    Future<void> toggle() async {
      unawaited(HapticFeedback.mediumImpact());
      final next = await ref.read(actionsProvider).toggleTask(task);
      if (next && context.mounted) showSnack(context, l.taskAddedNextOccurrence);
    }

    final card = AppCard(
      onTap: () => showTaskEditor(context, task: task),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent.color.withValues(alpha: task.isCompleted ? 0.3 : 0.9)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.xs, Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: Motion.of(context, Motion.normal),
                      style: context.text.titleMedium!.copyWith(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? context.semantic.muted : null,
                      ),
                      child: Text(task.title),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: context.text.bodySmall?.copyWith(
                        color: overdue ? context.semantic.negative : context.semantic.muted,
                      ),
                    ),
                    if (trailingAction != null && !task.isCompleted)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                          onPressed: trailingAction!.$2,
                          child: Text(trailingAction!.$1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _CheckCircle(
              done: task.isCompleted,
              color: accent.color,
              label: task.isCompleted ? l.markNotDone : l.markDone,
              onTap: toggle,
            ),
          ],
        ),
      ),
    );

    if (task.isCompleted) return card;
    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: postponeFrom == null ? DismissDirection.startToEnd : DismissDirection.horizontal,
      background: _SwipeBg(icon: Icons.check_rounded, label: l.done, color: context.semantic.positive, left: true),
      secondaryBackground: _SwipeBg(
        icon: Icons.east_rounded,
        label: l.planPostpone,
        color: Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold,
        left: false,
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await toggle();
        } else {
          unawaited(HapticFeedback.selectionClick());
          await ref.read(actionsProvider).postponeTask(task, postponeFrom!);
          if (context.mounted) showSnack(context, l.planPostponed);
        }
        return false; // the list rebuilds from the new data
      },
      child: card,
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done, required this.color, required this.label, required this.onTap});
  final bool done;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: done,
    label: label,
    button: true,
    child: InkResponse(
      onTap: onTap,
      radius: 26,
      child: SizedBox(
        width: 56,
        child: Center(
          child: AnimatedContainer(
            duration: Motion.of(context, Motion.normal),
            curve: Motion.bounce,
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? color : Colors.transparent,
              border: Border.all(color: done ? color : context.semantic.border, width: 1.6),
            ),
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.fast),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: done
                  ? const Icon(Icons.check_rounded, key: ValueKey(true), size: 16, color: Colors.white)
                  : const SizedBox.shrink(key: ValueKey(false)),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({required this.icon, required this.label, required this.color, required this.left});
  final IconData icon;
  final String label;
  final Color color;
  final bool left;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 0),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(Radii.lg)),
    padding: const EdgeInsets.symmetric(horizontal: Space.xl),
    alignment: left ? Alignment.centerLeft : Alignment.centerRight,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: Space.sm),
        Text(label, style: context.text.labelLarge?.copyWith(color: color)),
      ],
    ),
  );
}

// ------------------------------------------------------------------ composer

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.focus, required this.onSubmit, required this.onDetails});
  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSubmit;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = Theme.of(context).brightness;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: Space.sm),
        child: Container(
          key: const Key('plan-composer'),
          margin: const EdgeInsets.fromLTRB(Space.lg, Space.xs, Space.lg, Space.xs),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Radii.xl), boxShadow: Shadows.lift(b)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(Space.xs, Space.xs, Space.xs, Space.xs),
                decoration: BoxDecoration(
                  color: context.colors.surface.withValues(alpha: b == Brightness.dark ? 0.8 : 0.88),
                  borderRadius: BorderRadius.circular(Radii.xl),
                  border: Border.all(color: context.semantic.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: l.planDetails,
                      icon: Icon(Icons.tune_rounded, color: context.semantic.muted),
                      onPressed: onDetails,
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focus,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => onSubmit(),
                        decoration: InputDecoration(
                          hintText: l.planQuickHint,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      tooltip: l.add,
                      onPressed: onSubmit,
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
