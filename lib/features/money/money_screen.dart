import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/insight_engine.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/money_models.dart';
import '../shell/main_shell.dart';
import 'expense_sheet.dart';

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  static const _pageSize = 30;
  int _visible = _pageSize;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final b = ref.watch(budgetSnapshotProvider);
    final tx = [...ref.watch(transactionsProvider).list]..sort((a, b) => b.date.compareTo(a.date));
    final catInsight = ref.watch(insightsProvider).where((i) => i.kind == InsightKind.categorySpendChange).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navMoney),
        actions: [
          IconButton(
            tooltip: l.moneyBudgetSettings,
            icon: const Icon(Icons.tune),
            onPressed: () => showBudgetSettings(context),
          ),
          const ProfileButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showExpenseSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l.addExpense),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 0),
            sliver: SliverList.list(
              children: [
                if (b == null)
                  AppCard(
                    onTap: () => showBudgetSettings(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.setUpBudget, style: context.text.titleLarge),
                        const SizedBox(height: Space.xs),
                        Text(
                          l.setUpBudgetBody,
                          style: context.text.bodyMedium?.copyWith(color: context.semantic.muted),
                        ),
                        const SizedBox(height: Space.md),
                        FilledButton(onPressed: () => showBudgetSettings(context), child: Text(l.setUpBudget)),
                      ],
                    ),
                  )
                else ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.moneyDailySafe.toUpperCase(),
                          style: context.text.labelSmall?.copyWith(color: context.semantic.muted, letterSpacing: 1),
                        ),
                        const SizedBox(height: Space.xs),
                        Text(fmt.money(b.safeDailyMinor), style: context.text.displaySmall),
                        const SizedBox(height: Space.sm),
                        Text(
                          b.overToday
                              ? l.overToday(fmt.money(-b.remainingTodayMinor))
                              : l.leftToday(fmt.money(b.remainingTodayMinor)),
                          style: context.text.bodyMedium?.copyWith(
                            color: b.overToday ? context.semantic.negative : context.semantic.muted,
                          ),
                        ),
                        if (b.weeklyRemainingMinor != null) ...[
                          const SizedBox(height: Space.xs),
                          Text(l.moneyWeeklyLeft(fmt.money(b.weeklyRemainingMinor!)), style: context.text.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.md),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: Space.md,
                    crossAxisSpacing: Space.md,
                    childAspectRatio: 1.7,
                    children: [
                      _Stat(label: l.moneyIncome, value: fmt.money(b.incomeMinor)),
                      _Stat(label: l.moneySpent, value: fmt.money(b.spentMinor)),
                      _Stat(
                        label: l.moneySaved,
                        value: fmt.money(b.savingsGoalMinor),
                        note: b.savingsGoalMinor == 0 ? null : (b.savingsOnTrack ? l.moneyOnTrack : l.moneyAtRisk),
                        noteColor: b.savingsOnTrack ? context.semantic.positive : context.semantic.negative,
                      ),
                      _Stat(
                        label: l.moneyRemaining,
                        value: fmt.money(b.remainingMinor),
                        valueColor: b.remainingMinor < 0 ? context.semantic.negative : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    l.moneyProjected(fmt.money(b.projectedMonthSpendMinor)),
                    style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                  ),
                  if (catInsight != null) ...[
                    const SizedBox(height: Space.md),
                    AppCard(
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: context.colors.primary),
                          const SizedBox(width: Space.md),
                          Expanded(child: Text(l.insightText(catInsight))),
                        ],
                      ),
                    ),
                  ],
                  if (b.byCategory.isNotEmpty) ...[
                    SectionTitle(
                      l.moneyCategories,
                      trailing: TextButton(onPressed: () => showAddLimit(context), child: Text(l.moneyAddBudget)),
                    ),
                    AppCard(
                      child: Column(
                        children: b.byCategory.map((c) {
                          final limit = c.limitMinor;
                          final ratio = limit == null || limit == 0
                              ? (b.spentMinor == 0 ? 0.0 : c.amountMinor / b.spentMinor)
                              : c.amountMinor / limit;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: Space.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(l.expenseCategory(c.category))),
                                    Text(
                                      limit == null
                                          ? fmt.money(c.amountMinor)
                                          : l.ofLimit(fmt.money(c.amountMinor), fmt.money(limit)),
                                      style: context.text.titleSmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: Space.xs),
                                ProgressBar(
                                  value: ratio,
                                  height: 6,
                                  color: limit != null && c.amountMinor > limit ? context.semantic.negative : null,
                                  label: l.expenseCategory(c.category),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
                SectionTitle(l.moneyRecent),
                if (tx.isEmpty) EmptyState(icon: Icons.receipt_long_outlined, message: l.moneyNoTransactions),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, 120),
            sliver: SliverList.builder(
              itemCount: tx.length > _visible ? _visible + 1 : tx.length,
              itemBuilder: (_, i) {
                if (i == _visible) {
                  return TextButton(onPressed: () => setState(() => _visible += _pageSize), child: Text(l.seeAll));
                }
                return _TransactionTile(t: tx[i]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.note, this.noteColor, this.valueColor});

  final String label;
  final String value;
  final String? note;
  final Color? noteColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(Space.md),
    child: MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: context.text.labelSmall?.copyWith(color: context.semantic.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Space.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: context.text.titleLarge?.copyWith(color: valueColor)),
          ),
          if (note != null) Text(note!, style: context.text.labelSmall?.copyWith(color: noteColor)),
        ],
      ),
    ),
  );
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.t});

  final MoneyTransaction t;

  static IconData icon(ExpenseCategory c) => switch (c) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final income = !t.isExpense;
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: Space.xl),
        color: context.semantic.negative.withValues(alpha: 0.15),
        child: Icon(Icons.delete_outline, color: context.semantic.negative),
      ),
      onDismissed: (_) async {
        final actions = ref.read(actionsProvider);
        await actions.deleteTransaction(t.id);
        if (context.mounted) {
          showSnack(
            context,
            l.deleted,
            action: SnackBarAction(label: l.undo, onPressed: () => actions.restore(t)),
          );
        }
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: context.semantic.surfaceAlt,
          child: Icon(income ? Icons.south_west : icon(t.category), size: 20),
        ),
        title: Text(t.description.isEmpty ? (income ? l.incomeLabel : l.expenseCategory(t.category)) : t.description),
        subtitle: Text('${income ? l.incomeLabel : l.expenseCategory(t.category)} · ${fmt.dayMonth(t.date)}'),
        trailing: Text(
          '${income ? '+' : '−'}${fmt.money(t.amountMinor, cents: t.amountMinor % 100 != 0)}',
          style: context.text.titleSmall?.copyWith(color: income ? context.semantic.positive : null),
        ),
      ),
    );
  }
}

/// Monthly plan: income, fixed costs, savings goal and currency.
Future<void> showBudgetSettings(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => const _BudgetSettingsSheet(),
);

class _BudgetSettingsSheet extends ConsumerStatefulWidget {
  const _BudgetSettingsSheet();

  @override
  ConsumerState<_BudgetSettingsSheet> createState() => _BudgetSettingsSheetState();
}

class _BudgetSettingsSheetState extends ConsumerState<_BudgetSettingsSheet> {
  late final _profile = ref.read(profileProvider).value!;
  late final _income = TextEditingController(text: _major(_profile.monthlyIncomeMinor));
  late final _fixed = TextEditingController(text: _major(_profile.fixedExpensesMinor));
  late final _savings = TextEditingController(text: _major(_profile.savingsGoalMinor));
  late String _currency = _profile.currency;

  static String _major(int? minor) => minor == null ? '' : (minor / 100).toStringAsFixed(minor % 100 == 0 ? 0 : 2);

  @override
  void dispose() {
    _income.dispose();
    _fixed.dispose();
    _savings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget field(TextEditingController c, String label) => Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
        decoration: InputDecoration(labelText: label, suffixText: _currency),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.moneyBudgetSettings, style: context.text.titleLarge),
          const SizedBox(height: Space.lg),
          field(_income, l.moneyIncome),
          field(_fixed, l.onbFixedLabel),
          field(_savings, l.moneySaved),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: InputDecoration(labelText: l.currency),
            items: {
              'TRY',
              'USD',
              'EUR',
              'GBP',
              'BRL',
              'MXN',
              'JPY',
              'KRW',
              'INR',
              'SAR',
              'AED',
              'EGP',
              'CAD',
              'AUD',
              'ARS',
              'CHF',
              _currency,
            }.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _currency = v ?? _currency),
          ),
          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(actionsProvider)
                  .saveProfile(
                    _profile.copyWith(
                      monthlyIncomeMinor: Money.parseMinor(_income.text) ?? 0,
                      fixedExpensesMinor: Money.parseMinor(_fixed.text) ?? 0,
                      savingsGoalMinor: Money.parseMinor(_savings.text) ?? 0,
                      currency: _currency,
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}

/// Weekly total or monthly per-category spending limit.
Future<void> showAddLimit(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => const _LimitSheet(),
);

class _LimitSheet extends ConsumerStatefulWidget {
  const _LimitSheet();

  @override
  ConsumerState<_LimitSheet> createState() => _LimitSheetState();
}

class _LimitSheetState extends ConsumerState<_LimitSheet> {
  final _amount = TextEditingController();
  BudgetPeriod _period = BudgetPeriod.week;
  ExpenseCategory? _category;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.moneyAddBudget, style: context.text.titleLarge),
          const SizedBox(height: Space.lg),
          SegmentedButton<BudgetPeriod>(
            segments: [
              ButtonSegment(value: BudgetPeriod.week, label: Text(l.budgetPeriodWeek)),
              ButtonSegment(value: BudgetPeriod.month, label: Text(l.budgetPeriodMonth)),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() {
              _period = s.first;
              // Weekly limits apply to total spending; monthly ones per category.
              if (_period == BudgetPeriod.week) _category = null;
            }),
          ),
          const SizedBox(height: Space.md),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.budgetLimit),
          ),
          if (_period == BudgetPeriod.month) ...[
            const SizedBox(height: Space.md),
            DropdownButtonFormField<ExpenseCategory?>(
              initialValue: _category,
              decoration: InputDecoration(labelText: l.category),
              items: [
                DropdownMenuItem(value: null, child: Text(l.budgetAllCategories)),
                ...ExpenseCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(l.expenseCategory(c)))),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
          ],
          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed: () async {
              final minor = Money.parseMinor(_amount.text);
              if (minor == null || minor <= 0) return;
              await ref.read(actionsProvider).saveBudget(period: _period, limitMinor: minor, category: _category);
              if (context.mounted) {
                Navigator.pop(context);
                showSnack(context, l.budgetCreated);
              }
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}
