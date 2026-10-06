import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
import '../../domain/engines/budget_engine.dart';
import '../../domain/engines/insight_engine.dart';
import '../../domain/engines/money_insights.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/money_models.dart';
import '../shell/main_shell.dart';
import 'expense_sheet.dart';
import 'money_plan.dart';

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key, this.initialTab = 0});

  /// 0 overview, 1 activity, 2 plan (bills, jars, limits).
  final int initialTab;

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
  static const _pageSize = 30;
  int _visible = _pageSize;
  DateTime? _month;
  ExpenseCategory? _filter;
  String _query = '';

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
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
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l.moneyTabOverview),
            Tab(text: l.moneyTabActivity),
            Tab(text: l.moneyTabPlan),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-money',
        onPressed: () => showExpenseSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l.addExpense),
      ),
      body: TabBarView(controller: _tabs, children: [_overview(), _activity(), _plan()]),
    );
  }

  // --------------------------------------------------------------- overview

  Widget _overview() {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final b = ref.watch(budgetSnapshotProvider);
    final now = ref.watch(todayProvider);
    final summary = summarizeMonth(ref.watch(transactionsProvider).list, now, now);
    final catInsight = ref.watch(insightsProvider).where((i) => i.kind == InsightKind.categorySpendChange).firstOrNull;
    final change = summary.changePercent;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, 120),
      children: [
        if (b == null)
          AppCard(
            onTap: () => showBudgetSettings(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.setUpBudget, style: context.text.titleLarge),
                const SizedBox(height: Space.xs),
                Text(l.setUpBudgetBody, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
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
                  context.upper(l.moneyDailySafe),
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
        ],
        const SizedBox(height: Space.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showExpenseSheet(context, type: TransactionType.income),
            icon: const Icon(Icons.south_west, size: 18),
            label: Text(l.moneyAddIncome),
          ),
        ),
        if (catInsight != null) ...[
          const SizedBox(height: Space.sm),
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
        if (summary.spentMinor > 0) ...[
          SectionTitle(l.moneyChartTitle),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox.square(dimension: 120, child: _Donut(summary)),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fmt.money(summary.spentMinor), style: context.text.headlineSmall),
                          if (change != null && change != 0)
                            Text(
                              change > 0 ? l.moneyMoreThanLast(change) : l.moneyLessThanLast(-change),
                              style: context.text.bodySmall?.copyWith(
                                color: change > 0 ? context.semantic.negative : context.semantic.positive,
                              ),
                            ),
                          const SizedBox(height: Space.xs),
                          Text(
                            l.moneyDailyAvg(fmt.money(summary.dailyAverageMinor)),
                            style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.md),
                ..._categoryRows(summary, b),
              ],
            ),
          ),
        ],
        if (b != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => showAddLimit(context), child: Text(l.moneyAddBudget)),
          ),
      ],
    );
  }

  List<Widget> _categoryRows(MonthSummary summary, BudgetSnapshot? b) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final limits = {for (final c in b?.byCategory ?? const <CategorySpend>[]) c.category: c.limitMinor};
    return [
      for (final e in summary.ranked)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: categoryColor(e.key), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(child: Text(l.expenseCategory(e.key))),
                  Text(
                    limits[e.key] == null
                        ? fmt.money(e.value)
                        : l.ofLimit(fmt.money(e.value), fmt.money(limits[e.key]!)),
                    style: context.text.titleSmall,
                  ),
                ],
              ),
              if (limits[e.key] case final limit? when limit > 0) ...[
                const SizedBox(height: Space.xs),
                ProgressBar(
                  value: e.value / limit,
                  height: 6,
                  color: e.value > limit ? context.semantic.negative : categoryColor(e.key),
                  label: l.expenseCategory(e.key),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  // --------------------------------------------------------------- activity

  Widget _activity() {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final now = ref.watch(todayProvider);
    final month = _month ?? DateTime(now.year, now.month);
    final all = ref.watch(transactionsProvider).list;
    final summary = summarizeMonth(all, month, now);
    final next = DateTime(month.year, month.month + 1);
    final q = _query.trim().toLowerCase();
    final tx =
        all
            .where((t) => !t.deleted && !t.date.isBefore(month) && t.date.isBefore(next))
            .where((t) => _filter == null || (t.isExpense && t.category == _filter))
            .where(
              (t) =>
                  q.isEmpty ||
                  t.description.toLowerCase().contains(q) ||
                  (t.merchant ?? '').toLowerCase().contains(q) ||
                  l.expenseCategory(t.category).toLowerCase().contains(q),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final isCurrent = month.year == now.year && month.month == now.month;
    final rows = <Widget>[];
    String? lastDay;
    for (final t in tx.take(_visible)) {
      final day = fmt.weekdayDayMonth(t.date);
      if (day != lastDay) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: Space.md, bottom: Space.xs),
            child: Text(day, style: context.text.labelMedium?.copyWith(color: context.semantic.muted)),
          ),
        );
        lastDay = day;
      }
      rows.add(_TransactionTile(t: t));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 120),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l.moneyPrevMonth,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                _month = DateTime(month.year, month.month - 1);
                _visible = _pageSize;
              }),
            ),
            Expanded(
              child: Text(fmt.monthYear(month), textAlign: TextAlign.center, style: context.text.titleMedium),
            ),
            IconButton(
              tooltip: l.moneyNextMonth,
              icon: const Icon(Icons.chevron_right),
              onPressed: isCurrent
                  ? null
                  : () => setState(() {
                      _month = DateTime(month.year, month.month + 1);
                      _visible = _pageSize;
                    }),
            ),
          ],
        ),
        Text(
          [
            l.moneyMonthTotal(fmt.money(summary.spentMinor)),
            l.moneyDailyAvg(fmt.money(summary.dailyAverageMinor)),
            if (summary.biggest case final big?)
              l.moneyBiggest(
                big.description.isEmpty ? l.expenseCategory(big.category) : big.description,
                fmt.money(big.amountMinor),
              ),
          ].join(' · '),
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
        ),
        const SizedBox(height: Space.md),
        TextField(
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: l.moneySearch),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: Space.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final c in [null, ...summary.ranked.map((e) => e.key)])
                Padding(
                  padding: const EdgeInsets.only(right: Space.sm),
                  child: ChoiceChip(
                    avatar: c == null ? null : Icon(categoryIcon(c), size: 16),
                    label: Text(c == null ? l.foodAllMeals : l.expenseCategory(c)),
                    selected: _filter == c,
                    onSelected: (_) => setState(() => _filter = c),
                  ),
                ),
            ],
          ),
        ),
        if (tx.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.xl),
            child: EmptyState(icon: Icons.receipt_long_outlined, message: l.moneyNoMatch),
          ),
        ...rows,
        if (tx.length > _visible)
          TextButton(onPressed: () => setState(() => _visible += _pageSize), child: Text(l.seeAll)),
      ],
    );
  }

  // ------------------------------------------------------------------- plan

  Widget _plan() => ListView(
    padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 120),
    children: [
      const BillsSection(),
      const GoalsSection(),
      LimitsSection(onAdd: () => showAddLimit(context)),
    ],
  );
}

class _Donut extends StatelessWidget {
  const _Donut(this.summary);
  final MonthSummary summary;

  @override
  Widget build(BuildContext context) => PieChart(
    PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 34,
      startDegreeOffset: -90,
      sections: [
        for (final e in summary.ranked)
          PieChartSectionData(value: e.value.toDouble(), color: categoryColor(e.key), radius: 22, showTitle: false),
      ],
    ),
  );
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
            context.upper(label),
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
          child: Icon(income ? Icons.south_west : categoryIcon(t.category), size: 20),
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
