import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/money_insights.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/money_models.dart';

IconData categoryIcon(ExpenseCategory c) => switch (c) {
  ExpenseCategory.housing => Icons.home_outlined,
  ExpenseCategory.food => Icons.restaurant_outlined,
  ExpenseCategory.transport => Icons.directions_bus_outlined,
  ExpenseCategory.shopping => Icons.shopping_bag_outlined,
  ExpenseCategory.bills => Icons.receipt_outlined,
  ExpenseCategory.entertainment => Icons.movie_outlined,
  ExpenseCategory.health => Icons.favorite_outline,
  ExpenseCategory.subscriptions => Icons.autorenew,
  ExpenseCategory.other => Icons.more_horiz,
};

/// Earthy palette for the category chart (same order as the enum).
Color categoryColor(ExpenseCategory c) => const [
  Color(0xFF4A6B52),
  Color(0xFFC0673F),
  Color(0xFFD29D45),
  Color(0xFF7A8FB0),
  Color(0xFF8C6A9E),
  Color(0xFFB5838D),
  Color(0xFF5E9C8F),
  Color(0xFF9C7A54),
  Color(0xFF9A948C),
][c.index];

Widget _amountField(TextEditingController c, String label, {String? suffix, bool autofocus = false}) => TextField(
  controller: c,
  autofocus: autofocus,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
  decoration: InputDecoration(labelText: label, suffixText: suffix),
);

// ------------------------------------------------------------------ bills

class BillsSection extends ConsumerWidget {
  const BillsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final bills = ref.watch(billsProvider).list;
    final now = ref.watch(todayProvider);
    final status = billsThisMonth(bills, now);
    final unpaid = billsUnpaidMinor(bills, now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          l.billsTitle,
          trailing: TextButton.icon(
            onPressed: () => showBillSheet(context),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.billAdd),
          ),
        ),
        if (status.isEmpty)
          AppCard(
            onTap: () => showBillSheet(context),
            child: Text(l.billsEmpty, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
          )
        else
          AppCard(
            padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.sm, Space.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs, bottom: Space.xs),
                  child: Text(
                    '${l.billsMonthly(fmt.money(bills.where((b) => !b.deleted).fold(0, (s, b) => s + b.amountMinor)))}'
                    '${unpaid > 0 ? ' · ${l.billsLeft(fmt.money(unpaid))}' : ''}',
                    style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                  ),
                ),
                for (final s in status) _BillRow(s),
              ],
            ),
          ),
      ],
    );
  }
}

class _BillRow extends ConsumerWidget {
  const _BillRow(this.s);
  final BillStatus s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final (label, color) = switch (s.state) {
      BillState.paid => (l.billPaid, context.semantic.positive),
      BillState.overdue => (l.billOverdue(-s.daysLeft), context.semantic.negative),
      BillState.dueSoon => (s.daysLeft == 0 ? l.billDueToday : l.billDueIn(s.daysLeft), context.semantic.warning),
      BillState.upcoming => (l.billDueIn(s.daysLeft), context.semantic.muted),
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => showBillSheet(context, bill: s.bill),
      leading: CircleAvatar(
        backgroundColor: context.semantic.surfaceAlt,
        child: Icon(categoryIcon(s.bill.category), size: 20),
      ),
      title: Text(s.bill.name),
      subtitle: Text('${fmt.dayMonth(s.due)} · $label', style: TextStyle(color: color)),
      trailing: s.state == BillState.paid
          ? Text(fmt.money(s.bill.amountMinor), style: context.text.titleSmall)
          : FilledButton.tonal(
              onPressed: () async {
                await ref.read(actionsProvider).payBill(s.bill);
                if (context.mounted) showSnack(context, l.billPaidSnack);
              },
              child: Text('${l.billPay} · ${fmt.compactMoney(s.bill.amountMinor)}'),
            ),
    );
  }
}

Future<void> showBillSheet(
  BuildContext context, {
  RecurringBill? bill,
  ExpenseCategory? category,
  String? name,
  int? amountMinor,
  int? day,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _BillSheet(bill: bill, category: category, name: name, amountMinor: amountMinor, day: day),
);

class _BillSheet extends ConsumerStatefulWidget {
  const _BillSheet({this.bill, this.category, this.name, this.amountMinor, this.day});
  final RecurringBill? bill;

  /// Defaults for a new bill (e.g. a found subscription).
  final ExpenseCategory? category;
  final String? name;
  final int? amountMinor;
  final int? day;

  @override
  ConsumerState<_BillSheet> createState() => _BillSheetState();
}

class _BillSheetState extends ConsumerState<_BillSheet> {
  late final _name = TextEditingController(text: widget.bill?.name ?? widget.name);
  late final _amount = TextEditingController(
    text: switch (widget.bill?.amountMinor ?? widget.amountMinor) {
      null => '',
      final m => m % 100 == 0 ? '${m ~/ 100}' : (m / 100).toStringAsFixed(2),
    },
  );
  late int _day = widget.bill?.dayOfMonth ?? widget.day ?? DateTime.now().day;
  late ExpenseCategory _cat = widget.bill?.category ?? widget.category ?? ExpenseCategory.bills;
  late bool _remind = widget.bill?.remind ?? true;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final currency = ref.watch(profileProvider).value?.currency;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.bill == null ? l.billAdd : widget.bill!.name, style: context.text.titleLarge),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.billName),
            ),
            const SizedBox(height: Space.md),
            _amountField(_amount, l.amount, suffix: currency),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final c in const [
                  ExpenseCategory.bills,
                  ExpenseCategory.housing,
                  ExpenseCategory.subscriptions,
                  ExpenseCategory.transport,
                  ExpenseCategory.health,
                  ExpenseCategory.other,
                ])
                  ChoiceChip(
                    avatar: Icon(categoryIcon(c), size: 16),
                    label: Text(l.expenseCategory(c)),
                    selected: _cat == c,
                    onSelected: (_) => setState(() => _cat = c),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(child: Text(l.billDay, style: context.text.titleSmall)),
                IconButton.outlined(
                  onPressed: _day > 1 ? () => setState(() => _day--) : null,
                  icon: const Icon(Icons.remove, size: 18),
                ),
                SizedBox(
                  width: 40,
                  child: Text('$_day', textAlign: TextAlign.center, style: context.text.titleMedium),
                ),
                IconButton.outlined(
                  onPressed: _day < 31 ? () => setState(() => _day++) : null,
                  icon: const Icon(Icons.add, size: 18),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.billRemind),
              value: _remind,
              onChanged: (v) => setState(() => _remind = v),
            ),
            const SizedBox(height: Space.md),
            FilledButton(
              onPressed: () async {
                final minor = Money.parseMinor(_amount.text);
                final name = _name.text.trim();
                if (minor == null || minor <= 0 || name.isEmpty) return;
                final actions = ref.read(actionsProvider);
                final b = widget.bill;
                await actions.saveBill(
                  b == null
                      ? RecurringBill(
                          id: newId(),
                          updatedAt: DateTime.now(),
                          name: name,
                          amountMinor: minor,
                          category: _cat,
                          dayOfMonth: _day,
                          remind: _remind,
                        )
                      : b.copyWith(name: name, amountMinor: minor, category: _cat, dayOfMonth: _day, remind: _remind),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l.save),
            ),
            if (widget.bill != null)
              TextButton(
                onPressed: () async {
                  await ref.read(actionsProvider).deleteBill(widget.bill!.id);
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

// ------------------------------------------------------------------ jars

class GoalsSection extends ConsumerWidget {
  const GoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final now = ref.watch(todayProvider);
    final goals = ref.watch(savingsGoalsProvider).list.where((g) => !g.deleted).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          l.goalsTitle,
          trailing: TextButton.icon(
            onPressed: () => showGoalSheet(context),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.goalAdd),
          ),
        ),
        if (goals.isEmpty)
          AppCard(
            onTap: () => showGoalSheet(context),
            child: Row(
              children: [
                const Text('🐷', style: TextStyle(fontSize: 28)),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Text(l.goalsEmpty, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
                ),
              ],
            ),
          ),
        for (final g in goals)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: AppCard(
              onTap: () => showGoalSheet(context, goal: g),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(g.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: Space.sm),
                      Expanded(child: Text(g.name, style: context.text.titleMedium)),
                      Text('${(g.progress * 100).round()}%', style: context.text.titleSmall),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  ProgressBar(value: g.progress, label: g.name, color: g.reached ? context.semantic.positive : null),
                  const SizedBox(height: Space.xs),
                  Text(
                    g.reached
                        ? l.goalReached
                        : [
                            l.goalProgress(fmt.money(g.savedMinor), fmt.money(g.targetMinor)),
                            if (g.monthlyNeededMinor(now) case final m?) l.goalMonthly(fmt.money(m)),
                          ].join(' · '),
                    style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                  ),
                  const SizedBox(height: Space.xs),
                  Wrap(
                    spacing: Space.sm,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _move(context, ref, g, deposit: true),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l.goalDeposit),
                      ),
                      if (g.savedMinor > 0)
                        TextButton(
                          onPressed: () => _move(context, ref, g, deposit: false),
                          child: Text(l.goalWithdraw),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _move(BuildContext context, WidgetRef ref, SavingsGoal g, {required bool deposit}) async {
    final l = context.l10n;
    final minor = await showDialog<int>(
      context: context,
      builder: (_) => _AmountDialog(
        title: deposit ? l.goalDeposit : l.goalWithdraw,
        currency: ref.read(profileProvider).value?.currency,
      ),
    );
    if (minor == null || minor <= 0) return;
    final next = await ref.read(actionsProvider).addToSavingsGoal(g, deposit ? minor : -minor);
    if (context.mounted && next.reached && !g.reached) showSnack(context, l.goalReached);
  }
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.title, this.currency});
  final String title;
  final String? currency;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: _amountField(_c, l.goalAmount, suffix: widget.currency, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, Money.parseMinor(_c.text)), child: Text(l.ok)),
      ],
    );
  }
}

Future<void> showGoalSheet(BuildContext context, {SavingsGoal? goal}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _GoalSheet(goal: goal),
);

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet({this.goal});
  final SavingsGoal? goal;

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  static const _emojis = ['🎯', '✈️', '🏠', '🚗', '💻', '📱', '🎓', '💍', '🛟', '🎁'];
  late final _name = TextEditingController(text: widget.goal?.name);
  late final _target = TextEditingController(
    text: widget.goal == null ? '' : (widget.goal!.targetMinor / 100).toStringAsFixed(0),
  );
  late String _emoji = widget.goal?.emoji ?? '🎯';
  late DateTime? _deadline = widget.goal?.deadline;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.goal == null ? l.goalAdd : widget.goal!.name, style: context.text.titleLarge),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.xs,
              children: [
                for (final e in _emojis)
                  ChoiceChip(
                    label: Text(e, style: const TextStyle(fontSize: 18)),
                    selected: _emoji == e,
                    onSelected: (_) => setState(() => _emoji = e),
                  ),
              ],
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.goalName),
            ),
            const SizedBox(height: Space.md),
            _amountField(_target, l.goalTarget, suffix: ref.watch(profileProvider).value?.currency),
            const SizedBox(height: Space.md),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: DateTime(now.year + 10),
                  initialDate: _deadline ?? DateTime(now.year, now.month + 6, now.day),
                );
                if (d != null) setState(() => _deadline = d);
              },
              icon: const Icon(Icons.event),
              label: Text(_deadline == null ? l.goalDeadline : fmt.monthYear(_deadline!)),
            ),
            if (_deadline != null)
              TextButton(onPressed: () => setState(() => _deadline = null), child: Text(l.goalNoDeadline)),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: () async {
                final minor = Money.parseMinor(_target.text);
                final name = _name.text.trim();
                if (minor == null || minor <= 0 || name.isEmpty) return;
                final g = widget.goal;
                await ref
                    .read(actionsProvider)
                    .saveSavingsGoal(
                      g == null
                          ? SavingsGoal(
                              id: newId(),
                              updatedAt: DateTime.now(),
                              name: name,
                              targetMinor: minor,
                              deadline: _deadline,
                              emoji: _emoji,
                              createdAt: DateTime.now(),
                            )
                          : g.copyWith(
                              name: name,
                              targetMinor: minor,
                              deadline: _deadline,
                              clearDeadline: _deadline == null,
                              emoji: _emoji,
                            ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l.save),
            ),
            if (widget.goal != null)
              TextButton(
                onPressed: () async {
                  await ref.read(actionsProvider).deleteSavingsGoal(widget.goal!.id);
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

// ---------------------------------------------------------------- limits

class LimitsSection extends ConsumerWidget {
  const LimitsSection({super.key, required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final now = ref.watch(todayProvider);
    // The limit in force for each scope (the latest one set).
    final current = <String, Budget>{};
    for (final b in ref.watch(budgetsProvider).list) {
      if (b.deleted || b.periodStart.isAfter(now)) continue;
      final key = '${b.period.name}:${b.category?.name}';
      final have = current[key];
      if (have == null || b.periodStart.isAfter(have.periodStart)) current[key] = b;
    }
    final list = current.values.toList()..sort((a, b) => a.period.index.compareTo(b.period.index));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          l.limitsTitle,
          trailing: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(l.moneyAddBudget),
          ),
        ),
        if (list.isEmpty)
          AppCard(
            onTap: onAdd,
            child: Text(l.limitsEmpty, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
            child: Column(
              children: [
                for (final b in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(b.category == null ? Icons.speed_rounded : categoryIcon(b.category!)),
                    title: Text(
                      b.category != null
                          ? l.expenseCategory(b.category!)
                          : (b.period == BudgetPeriod.week ? l.limitWeekly : l.limitMonthlyAll),
                    ),
                    subtitle: Text(b.period == BudgetPeriod.week ? l.budgetPeriodWeek : l.budgetPeriodMonth),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(fmt.money(b.limitMinor), style: context.text.titleSmall),
                        IconButton(
                          tooltip: l.delete,
                          icon: const Icon(Icons.close, size: 18),
                          // Deletes every record of this scope so it does not
                          // fall back to an older limit.
                          onPressed: () async {
                            final actions = ref.read(actionsProvider);
                            for (final old in ref.read(budgetsProvider).list) {
                              if (!old.deleted && old.period == b.period && old.category == b.category) {
                                await actions.deleteBudget(old.id);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
