import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../core/widgets/mascot.dart';
import '../../domain/models/saved_item.dart';
import '../problem/problem_flow.dart';

/// Saved answers, decisions, recipes and texts. Tap to reopen; swipe to
/// remove.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  static IconData _icon(String kind) => switch (kind) {
    'decision' => Icons.balance_rounded,
    'recipe' => Icons.restaurant_menu_rounded,
    'text' => Icons.edit_note_rounded,
    'unit_price' ||
    'price_change' ||
    'installment' ||
    'split_bill' ||
    'budget_runway' ||
    'yearly_cost' ||
    'fuel_cost' => Icons.account_balance_wallet_rounded,
    _ => Icons.calculate_rounded,
  };

  static Accent _accent(String kind) => switch (kind) {
    'decision' => Accent.insight,
    'recipe' => Accent.food,
    'text' => Accent.ai,
    'unit_price' ||
    'price_change' ||
    'installment' ||
    'split_bill' ||
    'budget_runway' ||
    'yearly_cost' ||
    'fuel_cost' => Accent.money,
    _ => Accent.score,
  };

  void _open(BuildContext context, WidgetRef ref, SavedItem item) {
    if (item.kind == 'decision') {
      final o = (item.payload['options'] as List?)?.whereType<String>().map(Uri.encodeQueryComponent).join('|') ?? '';
      context.push('/decide${o.isEmpty ? '' : '?o=$o'}');
      return;
    }
    openProblem(context, ref, item.payload['q'] as String? ?? item.title);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final items = [...?ref.watch(savedProvider).value]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(title: Text(l.savedTitle)),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Mascot(mood: MascotMood.curious, size: 110),
                    const SizedBox(height: Space.lg),
                    Text(l.savedEmptyTitle, style: context.text.titleLarge, textAlign: TextAlign.center),
                    const SizedBox(height: Space.sm),
                    Text(
                      l.savedEmptyBody,
                      style: context.text.bodyMedium?.copyWith(color: context.semantic.muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Space.lg),
                    FilledButton(onPressed: () => context.go('/home'), child: Text(l.solve)),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 120),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
              itemBuilder: (context, i) {
                final item = items[i];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: Space.xl),
                    decoration: BoxDecoration(
                      color: context.semantic.negative.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(Radii.lg),
                    ),
                    child: Icon(Icons.delete_outline, color: context.semantic.negative),
                  ),
                  onDismissed: (_) {
                    ref.read(reposProvider).saved.delete(item.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.removed)));
                  },
                  child: AppCard(
                    onTap: () => _open(context, ref, item),
                    padding: const EdgeInsets.all(Space.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconBubble(icon: _icon(item.kind), accent: _accent(item.kind), size: 40),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: context.text.titleSmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.summary.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.summary,
                                  style: context.text.bodyMedium,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: Space.xs),
                              Text(
                                fmt.dayMonth(item.createdAt),
                                style: context.text.labelSmall?.copyWith(color: context.semantic.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
