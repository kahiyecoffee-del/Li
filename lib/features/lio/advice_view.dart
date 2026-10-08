import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/lio/lio_advisor.dart';
import '../../l10n/gen/app_localizations.dart';

/// A suggestion in words with what to do about it.
class AdviceText {
  const AdviceText(this.text, this.action, this.go, this.icon, this.accent);
  final String text;
  final String action;

  /// Runs the action (navigates).
  final void Function(BuildContext) go;
  final IconData icon;
  final Accent accent;
}

String _nonce() => '${DateTime.now().microsecondsSinceEpoch}';

AdviceText describeAdvice(Advice a, AppLocalizations l, Fmt fmt) {
  String money(int? minor) => fmt.money(minor ?? 0);
  void push(BuildContext c, String r) => c.push(r);
  void lio(BuildContext c, String topic) => c.push('/ai?topic=$topic&n=${_nonce()}');
  const wallet = Icons.account_balance_wallet_rounded;
  return switch (a.kind) {
    AdviceKind.overBudgetToday => AdviceText(
      l.advOverBudget(money(a.amountMinor)),
      l.actOpenMoney,
      (c) => push(c, '/money'),
      wallet,
      Accent.money,
    ),
    AdviceKind.budgetTight => AdviceText(
      l.advBudgetTight(money(a.amountMinor)),
      l.actOpenMoney,
      (c) => push(c, '/money'),
      wallet,
      Accent.money,
    ),
    AdviceKind.savingsOffTrack => AdviceText(
      l.advSavingsOff(money(a.amountMinor)),
      l.actOpenMoney,
      (c) => push(c, '/money'),
      Icons.savings_rounded,
      Accent.money,
    ),
    AdviceKind.setUpBudget => AdviceText(
      l.advSetUpBudget,
      l.actOpenMoney,
      (c) => push(c, '/money'),
      wallet,
      Accent.money,
    ),
    AdviceKind.weeklySpendUp => AdviceText(
      l.advWeeklyUp(a.percent ?? 0),
      l.actOpenMoney,
      (c) => push(c, '/money'),
      Icons.trending_up_rounded,
      Accent.money,
    ),
    AdviceKind.weeklySpendDown => AdviceText(
      l.advWeeklyDown(a.percent ?? 0),
      l.actOpenMoney,
      (c) => push(c, '/money'),
      Icons.trending_down_rounded,
      Accent.money,
    ),
    AdviceKind.categorySpike => AdviceText(
      l.advCategorySpike(l.expenseCategory(a.category!), a.percent ?? 0),
      l.actOpenMoney,
      (c) => push(c, '/money'),
      Icons.pie_chart_rounded,
      Accent.money,
    ),
    AdviceKind.subscriptions => AdviceText(
      l.advSubscriptions(a.count ?? 0, a.name ?? '', money(a.amountMinor)),
      l.actOpenMoney,
      (c) => push(c, '/money'),
      Icons.autorenew_rounded,
      Accent.money,
    ),
    AdviceKind.billsDue => AdviceText(
      l.advBillsDue(a.count ?? 0, a.name ?? '', money(a.amountMinor)),
      l.billPay,
      (c) => push(c, '/money?tab=plan'),
      Icons.receipt_long_rounded,
      Accent.money,
    ),
    AdviceKind.topCategory => AdviceText(
      l.advTopCategory(l.expenseCategory(a.category!), a.percent ?? 0),
      l.actOpenMoney,
      (c) => push(c, '/money'),
      Icons.donut_large_rounded,
      Accent.money,
    ),
    AdviceKind.overdueTasks => AdviceText(
      l.advOverdue(a.count ?? 0),
      l.actPlanDay,
      (c) => lio(c, 'plan'),
      Icons.event_busy_rounded,
      Accent.plan,
    ),
    AdviceKind.noPlanToday => AdviceText(
      l.advNoPlan,
      l.actPlanDay,
      (c) => lio(c, 'plan'),
      Icons.event_available_rounded,
      Accent.plan,
    ),
    AdviceKind.unscheduledToday => AdviceText(
      l.advUnscheduled(a.count ?? 0),
      l.actPlanDay,
      (c) => lio(c, 'plan'),
      Icons.schedule_rounded,
      Accent.plan,
    ),
    AdviceKind.tasksGoingWell => AdviceText(
      l.advTasksGood(a.count ?? 0),
      l.actOpenPlan,
      (c) => push(c, '/plan'),
      Icons.task_alt_rounded,
      Accent.plan,
    ),
    AdviceKind.habitAtRisk => AdviceText(
      l.advHabitRisk(a.count ?? 0, a.name ?? ''),
      l.actOpenHabits,
      (c) => push(c, '/habits'),
      Icons.local_fire_department_rounded,
      Accent.goals,
    ),
    AdviceKind.habitRateDown => AdviceText(
      l.advHabitDown(a.percent ?? 0),
      l.actOpenHabits,
      (c) => push(c, '/habits'),
      Icons.repeat_rounded,
      Accent.goals,
    ),
    AdviceKind.habitRateUp => AdviceText(
      l.advHabitUp(a.percent ?? 0),
      l.actOpenHabits,
      (c) => push(c, '/habits'),
      Icons.repeat_rounded,
      Accent.goals,
    ),
    AdviceKind.moodDown => AdviceText(
      l.advMoodDown,
      l.actTalk,
      (c) => lio(c, 'mood'),
      Icons.favorite_rounded,
      Accent.wellbeing,
    ),
    AdviceKind.moodShortSleep => AdviceText(
      l.advMoodSleep,
      l.actLogMood,
      (c) => push(c, '/mood'),
      Icons.bedtime_rounded,
      Accent.wellbeing,
    ),
    AdviceKind.journalNudge => AdviceText(
      l.advJournalNudge,
      l.actWrite,
      (c) => push(c, '/journal/new'),
      Icons.menu_book_rounded,
      Accent.insight,
    ),
    AdviceKind.journalStreak => AdviceText(
      l.advJournalStreak(a.count ?? 0),
      l.actWrite,
      (c) => push(c, '/journal/new'),
      Icons.menu_book_rounded,
      Accent.insight,
    ),
    AdviceKind.journalLift => AdviceText(
      l.advJournalLift(a.name ?? ''),
      l.actPlanDay,
      (c) => lio(c, 'plan'),
      Icons.wb_sunny_rounded,
      Accent.insight,
    ),
    AdviceKind.journalDrain => AdviceText(
      l.advJournalDrain(a.name ?? ''),
      l.actTalk,
      (c) => lio(c, 'mood'),
      Icons.cloud_rounded,
      Accent.insight,
    ),
    AdviceKind.shoppingPending => AdviceText(
      l.advShopping(a.count ?? 0),
      l.actShopping,
      (c) => push(c, '/shopping'),
      Icons.shopping_cart_rounded,
      Accent.food,
    ),
    AdviceKind.cookFromPantry => AdviceText(
      l.advCook(a.name ?? '', a.count ?? 0),
      l.actRecipe,
      (c) => push(c, '/food'),
      Icons.restaurant_menu_rounded,
      Accent.food,
    ),
  };
}

/// A suggestion card: icon, sentence and one clear action.
class AdviceCard extends ConsumerWidget {
  const AdviceCard(this.advice, {super.key});
  final Advice advice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = describeAdvice(advice, context.l10n, ref.fmt(context));
    return AppCard(
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.sm, Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBubble(icon: t.icon, accent: t.accent, size: 36),
              const SizedBox(width: Space.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, right: Space.sm),
                  child: Text(t.text, style: context.text.bodyMedium),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => t.go(context), child: Text(t.action)),
          ),
        ],
      ),
    );
  }
}
