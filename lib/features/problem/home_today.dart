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
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/capture/capture.dart';
import '../../domain/engines/expense_parser.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/task_item.dart';
import '../../domain/plan/day_timeline.dart';
import '../../domain/problem/list_splitter.dart';
import '../../services/ads/ads_service.dart';
import '../plan/time_picker_sheet.dart';
import '../premium/rewarded.dart';
import '../voice/voice_button.dart';

// --------------------------------------------------------------- capture

/// "Write anything": one line becomes a task, an expense, a shopping list or
/// a journal note. Shows what it understood before saving; the kind can be
/// switched with a tap.
class QuickCaptureCard extends ConsumerStatefulWidget {
  const QuickCaptureCard({super.key});

  @override
  ConsumerState<QuickCaptureCard> createState() => _QuickCaptureCardState();
}

class _QuickCaptureCardState extends ConsumerState<QuickCaptureCard> {
  final _c = TextEditingController();
  final _mic = GlobalKey<VoiceMicButtonState>();
  CaptureKind? _override;

  @override
  void initState() {
    super.initState();
    _c.addListener(() => setState(() {}));
    // Siri / Google Assistant / an app shortcut sent something to add.
    ref.listenManual(captureRequestProvider, (_, r) {
      if (r != null) WidgetsBinding.instance.addPostFrameCallback((_) => _takeRequest());
    }, fireImmediately: true);
  }

  Future<void> _takeRequest() async {
    if (!mounted) return;
    final r = ref.read(captureRequestProvider.notifier).take();
    if (r == null) return;
    if (r.text != null) {
      _c.text = r.text!;
      _override = null;
      await _save();
    } else {
      await _mic.currentState?.start();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Capture _understood(DateTime now) {
    final auto = classifyCapture(_c.text, now);
    final kind = _override ?? auto.kind;
    if (kind == auto.kind) return auto;
    final text = _c.text.trim();
    return switch (kind) {
      CaptureKind.task => () {
        final d = parseDay(text, now);
        return Capture.task(parseQuickTask(d?.rest ?? text), d?.day ?? Dates.dateOnly(now));
      }(),
      CaptureKind.expense => Capture.expense(text.isEmpty ? null : const ExpenseParser().parse(text)),
      CaptureKind.shopping => Capture.shopping(ListSplitter.split(text, ListKind.ingredients)),
      CaptureKind.journal => Capture.journal(text),
    };
  }

  String _preview(Capture c, DateTime now) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    switch (c.kind) {
      case CaptureKind.task:
        final q = c.task!;
        final day = c.day!;
        final dayLabel = Dates.sameDay(day, now)
            ? l.today
            : (Dates.sameDay(day, Dates.addDays(Dates.dateOnly(now), 1)) ? l.tomorrow : fmt.weekdayDayMonth(day));
        return [
          if (q.title.isNotEmpty) q.title,
          dayLabel,
          if (q.hasTime) hhmm(TimeOfDay(hour: q.hour!, minute: q.minute)),
          if (q.minutes != null) durationLabel(l, q.minutes!),
        ].join(' · ');
      case CaptureKind.expense:
        final e = c.expense;
        if (e == null) return l.captureNeedAmount;
        return '${e.type == TransactionType.income ? '+' : '−'}${fmt.money(e.amountMinor)} · '
            '${e.type == TransactionType.income ? l.incomeLabel : l.expenseCategory(e.category)}';
      case CaptureKind.shopping:
        return c.items.join(', ');
      case CaptureKind.journal:
        return l.captureJournalNote;
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final now = DateTime.now();
    if (_c.text.trim().isEmpty) return;
    final c = _understood(now);
    final actions = ref.read(actionsProvider);
    unawaited(HapticFeedback.lightImpact());
    String? message;
    switch (c.kind) {
      case CaptureKind.task:
        if (c.task!.title.isEmpty) return;
        final t = await actions.addQuickTask(c.task!, c.day!);
        message = l.captureSavedTask(t.title, _preview(c, now).split(' · ').skip(1).join(' · '));
      case CaptureKind.expense:
        final e = c.expense;
        if (e == null) {
          showSnack(context, l.captureNeedAmount);
          return;
        }
        await actions.addTransaction(
          amountMinor: e.amountMinor,
          category: e.category,
          description: e.description,
          type: e.type,
          source: TransactionSource.smartInput,
        );
        message = l.captureSavedExpense(fmt.money(e.amountMinor), l.expenseCategory(e.category));
      case CaptureKind.shopping:
        if (c.items.isEmpty) return;
        final n = await actions.addShoppingItems(c.items);
        message = l.foodAddedToList(n);
      case CaptureKind.journal:
        await actions.addJournal(c.text);
        message = l.journalSaved;
    }
    _c.clear();
    _override = null;
    if (mounted) {
      FocusScope.of(context).unfocus();
      showSnack(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = DateTime.now();
    final has = _c.text.trim().isNotEmpty;
    final c = has ? _understood(now) : null;
    IconData icon(CaptureKind k) => switch (k) {
      CaptureKind.task => Icons.event_available_rounded,
      CaptureKind.expense => Icons.account_balance_wallet_rounded,
      CaptureKind.shopping => Icons.shopping_basket_rounded,
      CaptureKind.journal => Icons.menu_book_rounded,
    };
    String label(CaptureKind k) => switch (k) {
      CaptureKind.task => l.captureTask,
      CaptureKind.expense => l.captureExpense,
      CaptureKind.shopping => l.captureShopping,
      CaptureKind.journal => l.captureJournal,
    };
    return AppCard(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.sm, Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('capture-field'),
                  controller: _c,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    hintText: l.captureHint,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              VoiceMicButton(key: _mic, controller: _c),
              AnimatedScale(
                scale: has ? 1 : 0.85,
                duration: Motion.of(context, Motion.fast),
                child: IconButton.filled(
                  tooltip: l.save,
                  onPressed: has ? _save : null,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.normal),
            curve: Motion.emphasized,
            alignment: Alignment.topCenter,
            child: c == null
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _preview(c, now),
                        key: const Key('capture-preview'),
                        style: context.text.bodySmall?.copyWith(color: context.colors.primary),
                      ),
                      const SizedBox(height: Space.sm),
                      Wrap(
                        spacing: Space.xs,
                        runSpacing: Space.xs,
                        children: [
                          for (final k in CaptureKind.values)
                            ChoiceChip(
                              avatar: Icon(icon(k), size: 16),
                              label: Text(label(k)),
                              selected: c.kind == k,
                              showCheckmark: false,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => setState(() => _override = k),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- today flow

/// Today at a glance: what is next, progress, today's spending room and the
/// habits still to tick.
class TodayFlowCard extends ConsumerWidget {
  const TodayFlowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final now = DateTime.now();
    final today = ref.watch(todayProvider);
    final tasks = ref.watch(tasksProvider).list.where((t) => !t.deleted).toList();
    final dayTasks = tasks.where((t) => t.anchorDate != null && Dates.sameDay(t.anchorDate!, today)).toList();
    final done = dayTasks.where((t) => t.isCompleted).length;
    final timed = dayTasks.where((t) => !t.isCompleted && t.scheduledAt != null).toList()
      ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    // The one happening now, else the next one.
    final next = timed.where((t) => t.scheduledAt!.add(Duration(minutes: t.estimatedMinutes)).isAfter(now)).firstOrNull;
    final budget = ref.watch(budgetSnapshotProvider);
    final habits = ref.watch(habitsProvider).list.where((h) => !h.deleted && h.isScheduledOn(today)).toList();
    final logs = {for (final g in ref.watch(habitLogsProvider).list) g.id: g.count};
    final open = habits.where((h) => (logs[HabitLog.idFor(h.id, Dates.dayKey(today))] ?? 0) < h.targetPerDay).toList();

    return AppCard(
      onTap: () => context.push('/plan'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(l.todayFlow),
                    const SizedBox(height: 4),
                    Text(
                      dayTasks.isEmpty ? l.planEmptyShort : l.planProgress(done, dayTasks.length),
                      style: context.text.titleLarge,
                    ),
                  ],
                ),
              ),
              ProgressRing(
                value: dayTasks.isEmpty ? 0 : done / dayTasks.length,
                size: 48,
                stroke: 4,
                child: Text('${dayTasks.length - done}', style: context.text.labelLarge),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (next == null)
            Text(l.noNextTask, style: context.text.bodySmall?.copyWith(color: context.semantic.muted))
          else
            _NextUp(task: next, now: now),
          if (budget != null) ...[
            const SizedBox(height: Space.md),
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 18, color: context.semantic.muted),
                const SizedBox(width: Space.sm),
                Text(
                  budget.overToday
                      ? l.overToday(fmt.money(-budget.remainingTodayMinor))
                      : l.leftToday(fmt.money(budget.remainingTodayMinor)),
                  style: context.text.bodyMedium?.copyWith(color: budget.overToday ? context.semantic.negative : null),
                ),
              ],
            ),
          ],
          if (open.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final h in open.take(4))
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      h.targetPerDay > 1
                          ? '${h.name} ${logs[HabitLog.idFor(h.id, Dates.dayKey(today))] ?? 0}/${h.targetPerDay}'
                          : h.name,
                    ),
                    onPressed: () {
                      unawaited(HapticFeedback.selectionClick());
                      unawaited(ref.read(actionsProvider).logHabit(h, 1));
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: Space.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => context.push('/plan'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(l.openPlan),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextUp extends ConsumerWidget {
  const _NextUp({required this.task, required this.now});
  final TaskItem task;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final start = task.scheduledAt!;
    final running = !start.isAfter(now);
    final gold = Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold;
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.xs, Space.sm),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.upper(running ? l.planNow : l.nextUp),
                  style: context.text.labelSmall?.copyWith(
                    color: running ? gold : context.semantic.muted,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(task.title, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  [
                    rangeLabel(TimeOfDay(hour: start.hour, minute: start.minute), task.estimatedMinutes),
                    if (!running) l.startsIn(durationLabel(l, start.difference(now).inMinutes.clamp(1, 24 * 60))),
                  ].join(' · '),
                  style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l.markDone,
            icon: Icon(Icons.check_circle_outline_rounded, color: context.colors.primary),
            onPressed: () {
              unawaited(HapticFeedback.mediumImpact());
              unawaited(ref.read(actionsProvider).toggleTask(task));
            },
          ),
        ],
      ),
    );
  }
}

/// "You took yesterday off": keep the streak with a rewarded ad (free for
/// Premium), at most once a week.
class StreakSaverCard extends ConsumerWidget {
  const StreakSaverCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(streakSaverProvider);
    if (days == null) return const SizedBox.shrink();
    final l = context.l10n;
    final premium = ref.watch(isPremiumProvider);
    final gold = Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: AppCard(
        key: const Key('streak-saver'),
        child: Row(
          children: [
            Icon(Icons.local_fire_department_rounded, color: gold, size: 32),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.streakSaveTitle(days), style: context.text.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    premium ? l.streakSaveBodyPremium : l.streakSaveBody,
                    style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                  ),
                  const SizedBox(height: Space.sm),
                  FilledButton.icon(
                    onPressed: () async {
                      final ok = premium || await watchRewardedAd(context, ref, RewardPlacement.streakRecovery);
                      if (!ok || !context.mounted) return;
                      final today = ref.read(todayProvider);
                      await ref.read(frozenDaysProvider.notifier).freeze(Dates.addDays(today, -1), today: today);
                      unawaited(HapticFeedback.mediumImpact());
                      if (context.mounted) showSnack(context, l.streakSaved(days));
                    },
                    icon: Icon(premium ? Icons.ac_unit_rounded : Icons.play_circle_outline_rounded, size: 18),
                    label: Text(premium ? l.streakSaveFree : l.streakSaveWatch),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
