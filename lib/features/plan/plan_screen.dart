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
import '../../domain/engines/money_insights.dart';
import '../../domain/engines/plan_optimizer.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/food.dart';
import '../../domain/models/task_item.dart';
import '../../domain/plan/day_timeline.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shell/main_shell.dart';
import '../../services/calendar/calendar_service.dart';
import 'calendar_busy.dart';
import 'routines_screen.dart';
import 'task_editor.dart';
import 'time_picker_sheet.dart';

String formatDuration(AppLocalizations l, int minutes) => durationLabel(l, minutes);

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

  /// Time and length picked with the chip (wins over what the text says).
  TimeChoice? _choice;

  /// Keeps "now", the countdown and the free time current.
  late final Timer _tick = Timer.periodic(const Duration(seconds: 30), (_) {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _tick;
  }

  @override
  void dispose() {
    _tick.cancel();
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
    final parsed = parseQuickTask(text);
    if (parsed.title.isEmpty) return;
    final c = _choice;
    final q = c == null
        ? parsed
        : QuickTask(
            parsed.title,
            hour: c.time?.hour ?? parsed.hour,
            minute: c.time?.minute ?? parsed.minute,
            minutes: c.minutes,
          );
    unawaited(HapticFeedback.lightImpact());
    final others = [...ref.read(tasksProvider).list, ...busyOn(ref, day)];
    final t = await ref.read(actionsProvider).addQuickTask(q, day);
    _input.clear();
    setState(() => _choice = null);
    if (!mounted) return;
    final clash = t.scheduledAt == null ? null : clashFor(others, t.scheduledAt!, t.estimatedMinutes);
    if (clash == null) {
      showSnack(context, context.l10n.planQuickAdded(q.title));
    } else {
      warnClash(context, ref, t, clash);
    }
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
    final events = ref.watch(calendarDayProvider(Dates.dateOnly(day))).value ?? const [];
    final busy = calendarBusy(events);
    final withBusy = [...dayTasks, ...busy];
    final timeline = buildTimeline(
      tasks: [...dayTasks.where((t) => !t.isCompleted), ...busy],
      day: day,
      dayStart: start,
      dayEnd: end,
      now: now,
    );
    final stats = dayStats(dayTasks, timeline);
    final clashes = countClashes(withBusy, day);
    final fmt = ref.fmt(context);
    final isPast = Dates.dateOnly(day).isBefore(today);
    final work = isPast ? 0 : remainingWorkMinutes(withBusy, now);
    final left = isPast ? 0 : minutesLeft(start, end, isToday ? now : start);
    final overloaded = isOverloaded(work, left);
    final open = dayTasks.where((t) => !t.isCompleted).toList();
    final evening = isToday && now.isAfter(end.subtract(const Duration(hours: 5)));
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
          // Add a whole routine (morning, focus, evening…) to this day.
          IconButton(
            key: const Key('plan-routine'),
            tooltip: l.planAddRoutine,
            icon: const Icon(Icons.auto_mode_rounded),
            onPressed: () => pickRoutineForDay(context, ref, day),
          ),
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
        choice: _choice,
        onPickTime: () async {
          final c = await pickTimeAndDuration(context, time: _choice?.time, minutes: _choice?.minutes ?? 30);
          if (c != null) setState(() => _choice = c);
        },
        onClearTime: () => setState(() => _choice = null),
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
                      clashes: clashes,
                      overload: overloaded ? (formatDuration(l, work), formatDuration(l, left)) : null,
                      onLighten: () async {
                        unawaited(HapticFeedback.mediumImpact());
                        final move = lightenPlan(withBusy, left, now);
                        final n = await ref.read(actionsProvider).moveAllToTomorrow(move, day);
                        if (context.mounted) showSnack(context, l.planLightened(n));
                      },
                      hours: l.planDayHours(fmt.time(start), fmt.time(end)),
                      onEditHours: _editDayHours,
                      onFixClashes: () async {
                        unawaited(HapticFeedback.mediumImpact());
                        final n = await ref.read(actionsProvider).fixClashes(day, fixed: busy);
                        if (context.mounted) showSnack(context, l.planClashesFixed(n));
                      },
                      onOptimize: () async {
                        final n = await ref.read(actionsProvider).optimizePlan();
                        if (context.mounted) showSnack(context, l.planOptimized(n));
                      },
                    ),
                  ),
                  if (isToday ? _nowOrNext(timeline, now) : null case final b?)
                    enter(
                      Padding(
                        padding: const EdgeInsets.only(top: Space.md),
                        child: _NowCard(block: b, now: now),
                      ),
                    ),
                  if (evening && dayTasks.isNotEmpty)
                    enter(
                      Padding(
                        padding: const EdgeInsets.only(top: Space.md),
                        child: _ShutdownCard(
                          done: dayTasks.length - open.length,
                          open: open,
                          onReview: () => _reviewDay(open, day),
                        ),
                      ),
                    ),
                  if (_alsoChips(context, day).isNotEmpty)
                    enter(
                      Padding(
                        padding: const EdgeInsets.only(top: Space.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Eyebrow(l.planAlso),
                            const SizedBox(height: Space.sm),
                            Wrap(spacing: Space.xs, runSpacing: Space.xs, children: _alsoChips(context, day)),
                          ],
                        ),
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
                    SectionTitle(
                      l.planOverdue,
                      trailing: TextButton(
                        key: const Key('overdue-all-today'),
                        onPressed: () async {
                          for (final t in overdue) {
                            await ref.read(actionsProvider).moveTaskTo(t, today);
                          }
                        },
                        child: Text('${l.planAllToday} (${overdue.length})'),
                      ),
                    ),
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Text(l.planHowTo, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
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

  /// The block running now, or else the next one today.
  TaskBlock? _nowOrNext(List<TimelineEntry> timeline, DateTime now) {
    for (final e in timeline.whereType<TaskBlock>()) {
      if (e.end.isAfter(now)) return e;
    }
    return null;
  }

  Future<void> _reviewDay(List<TaskItem> open, DateTime day) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ShutdownSheet(day: day, ids: [for (final t in open) t.id]),
  );

  Future<void> _editDayHours() async {
    final p = ref.read(profileProvider).value;
    final hours = await showModalBottomSheet<(DayTime, DayTime)>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) =>
          _DayHoursSheet(wake: p?.wakeTime ?? const DayTime(8 * 60), sleep: p?.sleepTime ?? const DayTime(23 * 60)),
    );
    if (hours != null) await ref.read(actionsProvider).setDayHours(hours.$1, hours.$2);
  }

  /// Bills due, planned meals and habits for [day]: the rest of the day.
  List<Widget> _alsoChips(BuildContext context, DateTime day) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final out = <Widget>[];
    for (final b in billsThisMonth(ref.watch(billsProvider).list, day)) {
      if (b.state == BillState.paid || !Dates.sameDay(b.due, day)) continue;
      out.add(
        ActionChip(
          avatar: const Icon(Icons.receipt_long_rounded, size: 16),
          label: Text('${b.bill.name} · ${fmt.money(b.bill.amountMinor)}'),
          onPressed: () => context.push('/money?tab=plan'),
        ),
      );
    }
    final meals = ref.watch(mealPlansProvider).list.where((m) => m.id == Dates.dayKey(day)).firstOrNull;
    for (final m in meals?.meals ?? const <Recipe>[]) {
      out.add(
        ActionChip(
          avatar: const Icon(Icons.restaurant_rounded, size: 16),
          label: Text('${l.mealType(m.mealType)}: ${m.name}'),
          onPressed: () => context.push('/food?tab=week'),
        ),
      );
    }
    for (final e in ref.watch(calendarDayProvider(Dates.dateOnly(day))).value ?? const <CalendarEvent>[]) {
      if (!e.allDay) continue;
      out.add(Chip(avatar: const Icon(Icons.event_rounded, size: 16), label: Text(e.title)));
    }
    final habits = ref.watch(habitsProvider).list.where((h) => !h.deleted && h.isScheduledOn(day)).length;
    if (habits > 0) {
      out.add(
        ActionChip(
          avatar: const Icon(Icons.repeat_rounded, size: 16),
          label: Text(l.planHabitsCount(habits)),
          onPressed: () => context.push('/habits'),
        ),
      );
    }
    if (ref.watch(servicesProvider).calendar.supported && !ref.watch(settingsProvider.select((s) => s.showCalendar))) {
      out.add(
        ActionChip(
          key: const Key('plan-calendar-connect'),
          avatar: const Icon(Icons.calendar_month_rounded, size: 16),
          label: Text(l.planCalendarConnect),
          onPressed: () => connectCalendar(context, ref),
        ),
      );
    }
    return out;
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
        case TaskBlock(:final task) when isCalendarBlock(task):
          rows.add(
            _TimelineRow(
              time: fmt.time(e.start),
              dot: _Dot.task,
              color: context.semantic.muted,
              child: _EventCard(title: task.title, range: '${fmt.time(e.start)} – ${fmt.time(e.end)}'),
            ),
          );
        case TaskBlock(:final task, :final clash):
          rows.add(
            _TimelineRow(
              time: fmt.time(e.start),
              dot: _Dot.task,
              color: clash == null ? categoryAccent(task.category).color : context.semantic.negative,
              onTapTime: () => changeTaskTime(context, ref, task),
              child: _TaskCard(
                task: task,
                range: '${fmt.time(e.start)} – ${fmt.time(e.end)}',
                postponeFrom: day,
                clash: clash,
              ),
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
  const _DaySummary({
    required this.day,
    required this.isToday,
    required this.stats,
    required this.clashes,
    required this.overload,
    required this.onLighten,
    required this.hours,
    required this.onEditHours,
    required this.onFixClashes,
    required this.onOptimize,
  });
  final DateTime day;
  final bool isToday;
  final DayStats stats;
  final int clashes;

  /// (work, time left) when the day holds more than fits.
  final (String, String)? overload;
  final VoidCallback onLighten;
  final String hours;
  final VoidCallback onEditHours;
  final VoidCallback onFixClashes;
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
                    const SizedBox(height: 2),
                    // The planning day itself is editable: when it starts and ends.
                    InkWell(
                      key: const Key('plan-day-hours'),
                      onTap: onEditHours,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wb_twilight_rounded, size: 14, color: context.colors.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                hours,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.labelMedium?.copyWith(
                                  color: context.colors.primary,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.edit_rounded, size: 12, color: context.colors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (clashes > 0) ...[
            const SizedBox(height: Space.md),
            Container(
              key: const Key('plan-clashes'),
              padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.xs, Space.xs),
              decoration: BoxDecoration(
                color: context.semantic.negative.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: context.semantic.negative.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: context.semantic.negative),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      l.planClashes(clashes),
                      style: context.text.labelLarge?.copyWith(color: context.semantic.negative),
                    ),
                  ),
                  TextButton(onPressed: onFixClashes, child: Text(l.planFixClashes)),
                ],
              ),
            ),
          ],
          if (overload case (final work, final left)) ...[
            const SizedBox(height: Space.md),
            Container(
              key: const Key('plan-overload'),
              padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.xs, Space.xs),
              decoration: BoxDecoration(
                color: Palette.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: Palette.gold.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hourglass_bottom_rounded, size: 20, color: Palette.goldDark),
                      const SizedBox(width: Space.sm),
                      Expanded(child: Text(l.planOverloaded(work, left), style: context.text.labelLarge)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 2),
                    child: Text(
                      l.planOverloadedHint,
                      style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: onLighten, child: Text(l.planLighten)),
                  ),
                ],
              ),
            ),
          ],
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
                  onPressed: () => context.push('/ai?topic=plan&n=${DateTime.now().microsecondsSinceEpoch}'),
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
  const _TimelineRow({required this.time, required this.dot, required this.child, this.color, this.onTapTime});
  final String time;
  final _Dot dot;
  final Widget child;
  final Color? color;

  /// Tapping the time on the left changes it.
  final VoidCallback? onTapTime;

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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapTime,
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
  const _TaskCard({
    required this.task,
    this.range,
    this.overdue = false,
    this.trailingAction,
    this.postponeFrom,
    this.clash,
  });

  final TaskItem task;
  final String? range;
  final bool overdue;
  final (String, VoidCallback)? trailingAction;

  /// An earlier task this one overlaps.
  final TaskItem? clash;

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
      if (task.rolledOver >= 2 && !task.isCompleted) '↻ ${l.planRolled(task.rolledOver)}',
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
                    if (clash != null && !task.isCompleted) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 14, color: context.semantic.negative),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              l.planClashWith(clash!.title),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelSmall?.copyWith(color: context.semantic.negative),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          key: Key('move-after-${task.id}'),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                          onPressed: () => moveAfterClash(context, ref, task, clash!),
                          child: Text(l.planMoveAfter),
                        ),
                      ),
                    ],
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
            _TaskMenu(task: task),
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
  const _Composer({
    required this.controller,
    required this.focus,
    required this.choice,
    required this.onPickTime,
    required this.onClearTime,
    required this.onSubmit,
    required this.onDetails,
  });
  final TextEditingController controller;
  final FocusNode focus;
  final TimeChoice? choice;
  final VoidCallback onPickTime;
  final VoidCallback onClearTime;
  final VoidCallback onSubmit;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = Theme.of(context).brightness;
    final c = choice;
    final timeText = c == null
        ? l.timeChip
        : (c.time == null
              ? l.timeAnytime(durationLabel(l, c.minutes))
              : '${hhmm(c.time!)} · ${durationLabel(l, c.minutes)}');
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
                padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.xs, Space.sm),
                decoration: BoxDecoration(
                  color: context.colors.surface.withValues(alpha: b == Brightness.dark ? 0.8 : 0.88),
                  borderRadius: BorderRadius.circular(Radii.xl),
                  border: Border.all(color: context.semantic.border, width: 0.8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 12),
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
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.xs,
                      children: [
                        // When and for how long: a tap opens the time wheel.
                        InputChip(
                          key: const Key('composer-time'),
                          avatar: Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: c == null ? context.semantic.muted : context.colors.primary,
                          ),
                          label: Text(
                            timeText,
                            style: context.text.labelMedium?.copyWith(
                              color: c == null ? context.semantic.muted : context.colors.primary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          selected: c != null,
                          showCheckmark: false,
                          onPressed: onPickTime,
                          onDeleted: c == null ? null : onClearTime,
                          deleteIconColor: context.semantic.muted,
                        ),
                        ActionChip(
                          avatar: Icon(Icons.tune_rounded, size: 18, color: context.semantic.muted),
                          label: Text(
                            l.planDetails,
                            style: context.text.labelMedium?.copyWith(color: context.semantic.muted),
                          ),
                          onPressed: onDetails,
                        ),
                      ],
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

// ------------------------------------------------------------- task helpers

/// Opens the time wheel for [task] and saves what was picked ("any time"
/// takes the time off but keeps the day).
Future<void> changeTaskTime(BuildContext context, WidgetRef ref, TaskItem task) async {
  final s = task.scheduledAt;
  final c = await pickTimeAndDuration(
    context,
    time: s == null ? null : TimeOfDay(hour: s.hour, minute: s.minute),
    minutes: task.estimatedMinutes,
  );
  if (c == null) return;
  final day = Dates.dateOnly(s ?? task.anchorDate ?? DateTime.now());
  final actions = ref.read(actionsProvider);
  if (c.time == null) {
    await actions.saveTask(
      task.copyWith(estimatedMinutes: c.minutes, clearSchedule: true, deadline: day),
      isNew: false,
    );
    return;
  }
  final at = DateTime(day.year, day.month, day.day, c.time!.hour, c.time!.minute);
  final others = [...ref.read(tasksProvider).list, ...busyOn(ref, day)];
  final updated = task.copyWith(estimatedMinutes: c.minutes, scheduledAt: at, clearDeadline: true);
  await actions.saveTask(updated, isNew: false);
  final clash = clashFor(others, at, c.minutes, exceptId: task.id);
  if (clash != null && context.mounted) warnClash(context, ref, updated, clash);
}

/// "This overlaps X" with a one-tap fix.
void warnClash(BuildContext context, WidgetRef ref, TaskItem task, TaskItem clash) {
  final l = context.l10n;
  showSnack(
    context,
    l.planClashWith(clash.title),
    action: SnackBarAction(label: l.planMoveAfter, onPressed: () => moveAfterClash(context, ref, task, clash)),
  );
}

/// Moves [task] to the first free time after [clash] ends.
Future<void> moveAfterClash(BuildContext context, WidgetRef ref, TaskItem task, TaskItem clash) async {
  final l = context.l10n;
  final fmt = ref.fmt(context);
  final gap = ref.read(settingsProvider).planBreak;
  final from = clash.scheduledAt!.add(Duration(minutes: clash.estimatedMinutes + gap));
  final dayEnd = Dates.addDays(Dates.dateOnly(from), 1).subtract(const Duration(minutes: 1));
  final at = nextFreeStart(
    [...ref.read(tasksProvider).list, ...busyOn(ref, from)],
    from,
    task.estimatedMinutes,
    dayEnd: dayEnd,
    exceptId: task.id,
    gap: gap,
  );
  if (at == null) {
    showSnack(context, l.planNoSlot);
    return;
  }
  unawaited(HapticFeedback.selectionClick());
  await ref.read(actionsProvider).scheduleTask(task, at);
  if (context.mounted) showSnack(context, l.planScheduledAt(fmt.time(at)));
}

enum _TaskAction { edit, time, tomorrow, otherDay, clearTime, duplicate, delete }

/// Everything about a task, one tap away.
class _TaskMenu extends ConsumerWidget {
  const _TaskMenu({required this.task});
  final TaskItem task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final actions = ref.read(actionsProvider);
    PopupMenuItem<_TaskAction> item(_TaskAction a, IconData icon, String label, {Color? color}) => PopupMenuItem(
      value: a,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? context.semantic.muted),
          const SizedBox(width: Space.md),
          Flexible(
            child: Text(label, style: color == null ? null : TextStyle(color: color)),
          ),
        ],
      ),
    );
    return PopupMenuButton<_TaskAction>(
      key: Key('task-menu-${task.id}'),
      tooltip: l.taskMore,
      icon: Icon(Icons.more_horiz_rounded, color: context.semantic.muted),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        item(_TaskAction.edit, Icons.edit_outlined, l.edit),
        if (!task.isCompleted) ...[
          item(_TaskAction.time, Icons.schedule_rounded, l.taskChangeTime),
          item(_TaskAction.tomorrow, Icons.east_rounded, l.planPostpone),
          item(_TaskAction.otherDay, Icons.calendar_month_outlined, l.taskOtherDay),
          if (task.scheduledAt != null) item(_TaskAction.clearTime, Icons.timer_off_outlined, l.taskClearTime),
        ],
        item(_TaskAction.duplicate, Icons.copy_rounded, l.taskDuplicate),
        item(_TaskAction.delete, Icons.delete_outline_rounded, l.delete, color: context.semantic.negative),
      ],
      onSelected: (a) async {
        final day = Dates.dateOnly(task.anchorDate ?? DateTime.now());
        switch (a) {
          case _TaskAction.edit:
            await showTaskEditor(context, task: task);
          case _TaskAction.time:
            await changeTaskTime(context, ref, task);
          case _TaskAction.tomorrow:
            await actions.postponeTask(task, day);
            if (context.mounted) showSnack(context, l.planPostponed);
          case _TaskAction.otherDay:
            final d = await showDatePicker(
              context: context,
              initialDate: day,
              firstDate: Dates.addDays(day, -365),
              lastDate: Dates.addDays(day, 730),
            );
            if (d == null) return;
            await actions.moveTaskTo(task, d);
            if (context.mounted) showSnack(context, l.taskMoved);
          case _TaskAction.clearTime:
            await actions.unscheduleTask(task);
          case _TaskAction.duplicate:
            await actions.duplicateTask(task);
            if (context.mounted) showSnack(context, l.taskDuplicated);
          case _TaskAction.delete:
            await actions.deleteTask(task.id);
            if (context.mounted) showSnack(context, l.deleted);
        }
      },
    );
  }
}

/// When the planning day starts and ends.
class _DayHoursSheet extends ConsumerStatefulWidget {
  const _DayHoursSheet({required this.wake, required this.sleep});
  final DayTime wake, sleep;

  @override
  ConsumerState<_DayHoursSheet> createState() => _DayHoursSheetState();
}

class _DayHoursSheetState extends ConsumerState<_DayHoursSheet> {
  late var _wake = widget.wake;
  late var _sleep = widget.sleep;

  Widget _pick(String label, DayTime value, ValueChanged<DayTime> onPick) => AppCard(
    onTap: () async {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: value.hour, minute: value.minutes % 60),
      );
      if (t != null) setState(() => onPick(DayTime.hm(t.hour, t.minute)));
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label),
        const SizedBox(height: 4),
        Text(
          hhmm(TimeOfDay(hour: value.hour, minute: value.minutes % 60)),
          style: context.text.headlineMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.planDayHoursTitle, style: context.text.titleLarge),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(child: _pick(l.planDayStart, _wake, (v) => _wake = v)),
                const SizedBox(width: Space.md),
                Expanded(child: _pick(l.planDayEnd, _sleep, (v) => _sleep = v)),
              ],
            ),
            const SizedBox(height: Space.lg),
            Text(l.planBreakLabel, style: context.text.titleSmall?.copyWith(color: context.semantic.muted)),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              children: [
                for (final m in const [0, 5, 10, 15])
                  ChoiceChip(
                    label: Text(m == 0 ? l.planBreakNone : l.minutesShort(m)),
                    selected: ref.watch(settingsProvider.select((s) => s.planBreak)) == m,
                    onSelected: (_) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(planBreak: m)),
                  ),
              ],
            ),
            if (ref.watch(servicesProvider).calendar.supported) ...[
              const SizedBox(height: Space.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.planCalendarToggle),
                subtitle: Text(l.planCalendarToggleHint),
                value: ref.watch(settingsProvider.select((s) => s.showCalendar)),
                onChanged: (on) => on
                    ? connectCalendar(context, ref)
                    : ref.read(settingsProvider.notifier).update((s) => s.copyWith(showCalendar: false)),
              ),
            ],
            const SizedBox(height: Space.lg),
            FilledButton(onPressed: () => Navigator.pop(context, (_wake, _sleep)), child: Text(l.save)),
          ],
        ),
      ),
    );
  }
}

/// What is happening now (with the time left) or what comes next.
class _NowCard extends ConsumerWidget {
  const _NowCard({required this.block, required this.now});
  final TaskBlock block;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final running = !block.start.isAfter(now);
    final accent = categoryAccent(block.task.category).color;
    final total = block.minutes == 0 ? 1 : block.minutes;
    final done = running ? now.difference(block.start).inMinutes.clamp(0, total) : 0;
    final leftMin = running ? block.end.difference(now).inMinutes : block.start.difference(now).inMinutes;
    final gold = Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold;
    return AppCard(
      key: const Key('plan-now'),
      onTap: isCalendarBlock(block.task) ? null : () => showTaskEditor(context, task: block.task),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Eyebrow(running ? l.planNow : l.planUpNext),
              const Spacer(),
              Text(
                running
                    ? l.planTimeLeft(formatDuration(l, leftMin.clamp(1, 24 * 60)))
                    : l.planStartsIn(formatDuration(l, leftMin.clamp(1, 24 * 60))),
                style: context.text.labelLarge?.copyWith(
                  color: running ? gold : context.semantic.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(block.task.title, style: context.text.titleLarge),
          if (running) ...[
            const SizedBox(height: Space.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.pill),
              child: LinearProgressIndicator(
                value: done / total,
                minHeight: 6,
                color: accent,
                backgroundColor: accent.withValues(alpha: 0.12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Evening: how the day went and a nudge to place what is still open.
class _ShutdownCard extends StatelessWidget {
  const _ShutdownCard({required this.done, required this.open, required this.onReview});
  final int done;
  final List<TaskItem> open;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      key: const Key('plan-shutdown'),
      child: Row(
        children: [
          Icon(open.isEmpty ? Icons.celebration_outlined : Icons.nights_stay_outlined, color: context.colors.primary),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.planShutdown, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  open.isEmpty ? l.planShutdownGood : l.planShutdownBody(done, open.length),
                  style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                ),
              ],
            ),
          ),
          if (open.isNotEmpty) TextButton(onPressed: onReview, child: Text(l.planShutdownReview)),
        ],
      ),
    );
  }
}

/// One decision per open task: tomorrow, another day, smaller, or let go.
class _ShutdownSheet extends ConsumerWidget {
  const _ShutdownSheet({required this.day, required this.ids});
  final DateTime day;
  final List<String> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final actions = ref.read(actionsProvider);
    final open = ref
        .watch(tasksProvider)
        .list
        .where((t) => ids.contains(t.id) && !t.deleted && !t.isCompleted && t.anchorDate != null)
        .where((t) => Dates.sameDay(t.anchorDate!, day))
        .toList();
    if (open.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
          child: Text(l.planShutdownGood, style: context.text.titleLarge, textAlign: TextAlign.center),
        ),
      );
    }
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
          children: [
            Text(l.planShutdown, style: context.text.headlineSmall),
            const SizedBox(height: Space.md),
            for (final t in open)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.sm, Space.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.title, style: context.text.titleMedium),
                      if (t.rolledOver >= 2)
                        Text(
                          '${l.planRolled(t.rolledOver)} · ${l.planRolledHint}',
                          style: context.text.bodySmall?.copyWith(color: context.semantic.negative),
                        ),
                      Wrap(
                        children: [
                          TextButton(onPressed: () => actions.postponeTask(t, day), child: Text(l.planPostpone)),
                          TextButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: Dates.addDays(day, 1),
                                firstDate: day,
                                lastDate: Dates.addDays(day, 730),
                              );
                              if (d != null) await actions.moveTaskTo(t, d);
                            },
                            child: Text(l.taskOtherDay),
                          ),
                          if (t.estimatedMinutes >= 20 && t.rolledOver >= 2)
                            TextButton(
                              onPressed: () => actions.saveTask(
                                t.copyWith(estimatedMinutes: (t.estimatedMinutes / 2).round()),
                                isNew: false,
                              ),
                              child: Text(l.planShrink),
                            ),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: context.semantic.muted),
                            onPressed: () => actions.deleteTask(t.id),
                            child: Text(l.planDrop),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: Space.sm),
            FilledButton.icon(
              key: const Key('shutdown-all-tomorrow'),
              onPressed: () async {
                await actions.moveAllToTomorrow(open, day);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.east_rounded),
              label: Text(l.planAllTomorrow),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for calendar access and, when allowed, shows events on the plan.
Future<void> connectCalendar(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final ok = await ref.read(servicesProvider).calendar.requestAccess();
  if (!context.mounted) return;
  if (!ok) {
    showSnack(context, l.planCalendarDenied);
    return;
  }
  await ref.read(settingsProvider.notifier).update((s) => s.copyWith(showCalendar: true));
  if (!context.mounted) return;
  showSnack(context, l.planCalendarShown);
}

/// An event from the phone's calendar: busy time, not editable here.
class _EventCard extends StatelessWidget {
  const _EventCard({required this.title, required this.range});
  final String title;
  final String range;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      key: const Key('plan-event'),
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.md, Space.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: context.semantic.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '$range · ${l.planCalendarEvent}',
                  style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                ),
              ],
            ),
          ),
          Icon(Icons.event_rounded, size: 20, color: context.semantic.muted),
        ],
      ),
    );
  }
}
