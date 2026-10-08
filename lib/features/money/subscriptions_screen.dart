import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/debts.dart';
import '../../domain/engines/subscriptions.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/money_models.dart';
import 'money_plan.dart';

/// When each subscription was last confirmed "still using" (on device).
class SubscriptionReviews {
  SubscriptionReviews(this._ref);
  final Ref _ref;

  static const every = Duration(days: 90);
  static String _key(String id) => 'sub_reviewed_$id';

  bool needsReview(RecurringBill b, DateTime now) {
    final ms = _ref.read(servicesProvider).prefs.getInt(_key(b.id));
    return ms == null || now.difference(DateTime.fromMillisecondsSinceEpoch(ms)) > every;
  }

  Future<void> markReviewed(String id, DateTime now) =>
      _ref.read(servicesProvider).prefs.setInt(_key(id), now.millisecondsSinceEpoch);
}

final subscriptionReviewsProvider = Provider<SubscriptionReviews>(SubscriptionReviews.new);

/// Subscriptions still to check ("still using it?").
final subscriptionsToCheckProvider = Provider<List<RecurringBill>>((ref) {
  ref.watch(subscriptionReviewTick);
  final now = currentNow(ref);
  final reviews = ref.watch(subscriptionReviewsProvider);
  return subscriptionsOf(ref.watch(billsProvider).list).where((b) => reviews.needsReview(b, now)).toList();
});

/// Bumped after a review so the lists above refresh.
final subscriptionReviewTick = NotifierProvider<_Tick, int>(_Tick.new);

class _Tick extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final bills = ref.watch(billsProvider).list;
    final subs = subscriptionsOf(bills);
    final toCheck = ref.watch(subscriptionsToCheckProvider).map((b) => b.id).toSet();
    final found = findSubscriptionCandidates(ref.watch(transactionsProvider).list, bills, ref.read(clockProvider)());
    final monthly = subscriptionsMonthly(bills);
    return Scaffold(
      appBar: AppBar(title: Text(l.subsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('subs-add'),
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.subsAdd),
      ),
      body: PageList(
        animate: false,
        children: [
          AppCard(
            child: Row(
              children: [
                const IconBubble(icon: Icons.subscriptions_rounded, accent: Accent.insight, size: 48),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.subsYearly(fmt.money(monthly * 12)),
                        key: const Key('subs-yearly'),
                        style: context.text.headlineSmall,
                      ),
                      Text(
                        l.subsMonthly(fmt.money(monthly)),
                        style: context.text.bodyMedium?.copyWith(color: context.semantic.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(l.subsIntro, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
          const SizedBox(height: Space.md),
          if (subs.isEmpty && found.isEmpty) EmptyState(icon: Icons.subscriptions_outlined, message: l.subsEmpty),
          for (final b in subs)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: AppCard(
                key: Key('sub-${b.id}'),
                onTap: () => reviewSubscription(context, ref, b),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name, style: context.text.titleMedium),
                          Text(
                            '${l.subsMonthly(fmt.money(b.amountMinor))} · ${l.subsYearly(fmt.money(b.amountMinor * 12))}',
                            style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                          ),
                        ],
                      ),
                    ),
                    if (toCheck.contains(b.id))
                      TextButton(onPressed: () => reviewSubscription(context, ref, b), child: Text(l.subsReview))
                    else
                      Icon(Icons.check_circle_outline_rounded, color: context.semantic.positive, size: 20),
                  ],
                ),
              ),
            ),
          if (found.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            SectionTitle(l.subsFound),
            for (final c in found.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: context.text.titleMedium),
                            Text(
                              '${fmt.money(c.amountMinor)} · ${l.subsFoundBody(c.months)}',
                              style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: l.subsAdd,
                        onPressed: () => showBillSheet(
                          context,
                          category: ExpenseCategory.subscriptions,
                          name: c.name,
                          amountMinor: c.amountMinor,
                          day: c.dayOfMonth,
                        ),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final before = ref.read(billsProvider).list.map((b) => b.id).toSet();
    await showBillSheet(context, category: ExpenseCategory.subscriptions);
    // A subscription just added counts as checked.
    final now = ref.read(clockProvider)();
    for (final b in ref.read(billsProvider).list.where((b) => !before.contains(b.id))) {
      await ref.read(subscriptionReviewsProvider).markReviewed(b.id, now);
    }
    ref.read(subscriptionReviewTick.notifier).bump();
  }
}

/// "Still using it?": keep (checked for 3 months) or remove with undo.
Future<void> reviewSubscription(BuildContext context, WidgetRef ref, RecurringBill b) async {
  final l = context.l10n;
  final fmt = ref.fmt(context);
  final keep = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.subsStillUsing(b.name), style: ctx.text.titleLarge),
            const SizedBox(height: Space.xs),
            Text(l.subsStillUsingBody(fmt.money(b.amountMinor * 12)), style: ctx.text.bodyMedium),
            const SizedBox(height: Space.lg),
            FilledButton(
              key: const Key('subs-keep'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.subsKeep),
            ),
            const SizedBox(height: Space.sm),
            OutlinedButton(
              key: const Key('subs-cancel'),
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.subsCancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                showBillSheet(context, bill: b);
              },
              child: Text(l.edit),
            ),
          ],
        ),
      ),
    ),
  );
  if (keep == null || !context.mounted) return;
  final now = ref.read(clockProvider)();
  if (keep) {
    await ref.read(subscriptionReviewsProvider).markReviewed(b.id, now);
  } else {
    await ref.read(actionsProvider).deleteBill(b.id);
    if (context.mounted) {
      showSnack(
        context,
        l.subsCancelled(b.name),
        action: SnackBarAction(label: l.undo, onPressed: () => ref.read(actionsProvider).restoreBill(b)),
      );
    }
  }
  ref.read(subscriptionReviewTick.notifier).bump();
}

/// Money plan: shortcuts to subscriptions (yearly cost, how many to check)
/// and debts (net balance).
class MoneyExtrasRow extends ConsumerWidget {
  const MoneyExtrasRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final bills = ref.watch(billsProvider).list;
    final check = ref.watch(subscriptionsToCheckProvider).length;
    final (owed, owe) = debtTotals(ref.watch(debtsProvider).list);
    Widget tile(Key key, IconData icon, Accent accent, String title, String line, String route, {bool alert = false}) =>
        Expanded(
          child: AppCard(
            key: key,
            onTap: () => context.push(route),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBubble(icon: icon, accent: accent, size: 34),
                const SizedBox(height: Space.sm),
                Text(title, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  line,
                  maxLines: 2,
                  style: context.text.bodySmall?.copyWith(
                    color: alert ? context.semantic.negative : context.semantic.muted,
                  ),
                ),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tile(
              const Key('money-subs'),
              Icons.subscriptions_rounded,
              Accent.insight,
              l.subsTitle,
              check > 0 ? l.subsUnreviewed(check) : l.subsYearly(fmt.money(subscriptionsMonthly(bills) * 12)),
              '/subscriptions',
              alert: check > 0,
            ),
            const SizedBox(width: Space.sm),
            tile(
              const Key('money-debts'),
              Icons.handshake_rounded,
              Accent.money,
              l.debtsTitle,
              owed == 0 && owe == 0
                  ? l.debtsSplit
                  : [if (owed > 0) '+${fmt.money(owed)}', if (owe > 0) '−${fmt.money(owe)}'].join(' · '),
              '/debts',
            ),
          ],
        ),
      ),
    );
  }
}
