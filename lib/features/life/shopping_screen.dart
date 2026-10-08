import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../domain/lists/list_share.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/food.dart';
import '../../services/ai/ai_models.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final names = _input.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (names.isEmpty) return;
    _input.clear();
    await ref.read(actionsProvider).addShoppingItems(names);
    unawaited(_aiCategorizeUnknown());
  }

  /// A list someone sent (copied from WhatsApp etc.): one tap to add it.
  Future<void> _paste() async {
    final l = context.l10n;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final names = parseSharedList(data?.text ?? '', footer: l.shoppingShareFooter);
    if (!mounted) return;
    if (names.isEmpty) {
      showSnack(context, l.shoppingPasteEmpty);
      return;
    }
    final n = await ref.read(actionsProvider).addShoppingItems(names);
    if (mounted) showSnack(context, l.shoppingPasted(n));
    unawaited(_aiCategorizeUnknown());
  }

  /// Items the offline dictionary didn't recognize are sent (names only) to
  /// the cheap AI categorizer; failures are silently ignored.
  Future<void> _aiCategorizeUnknown() async {
    final unknown = (ref.read(shoppingProvider).list)
        .where((i) => i.category == ShoppingCategory.other && !i.checked)
        .toList();
    if (unknown.isEmpty || !ref.read(servicesProvider).cloudEnabled) return;
    try {
      final r = await ref.read(servicesProvider).ai.task(AiTaskType.categorizeShopping, {
        'items': unknown.map((i) => i.name).toList(),
      });
      final map = r.result['categories'];
      if (map is! Map) return;
      final repos = ref.read(reposProvider);
      for (final i in unknown) {
        final cat = ShoppingCategory.values.where((c) => c.name == map[i.name]).firstOrNull;
        if (cat != null && cat != ShoppingCategory.other) await repos.shopping.save(i.copyWith(category: cat));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = ref.watch(shoppingProvider).list;
    final groups = <ShoppingCategory, List<ShoppingItem>>{};
    for (final i in items) {
      groups.putIfAbsent(i.category, () => []).add(i);
    }
    final hasChecked = items.any((i) => i.checked);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.lifeShopping),
        actions: [
          if (items.any((i) => !i.checked))
            IconButton(
              key: const Key('shopping-share'),
              tooltip: l.shoppingShare,
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => ref
                  .read(servicesProvider)
                  .share
                  .shareText(
                    shoppingShareText(
                      [for (final i in items.where((i) => !i.checked)) i.name],
                      header: l.shoppingShareHeader,
                      footer: l.shoppingShareFooter,
                    ),
                    subject: l.shoppingShareHeader,
                  ),
            ),
          if (hasChecked)
            TextButton(
              onPressed: () async {
                final actions = ref.read(actionsProvider);
                final removed = await actions.clearCheckedShopping();
                if (!context.mounted || removed.isEmpty) return;
                showSnack(
                  context,
                  l.cleared,
                  action: SnackBarAction(label: l.undo, onPressed: () => actions.restoreShopping(removed)),
                );
              },
              child: Text(l.shoppingClearChecked),
            ),
        ],
      ),
      body: PageList(
        children: [
          TextField(
            controller: _input,
            decoration: InputDecoration(
              hintText: l.shoppingAddHint,
              suffixIcon: IconButton(tooltip: l.add, icon: const Icon(Icons.add), onPressed: _add),
            ),
            onSubmitted: (_) => _add(),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('shopping-paste'),
              onPressed: _paste,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: Text(l.shoppingPaste),
            ),
          ),
          if (items.isEmpty) EmptyState(icon: Icons.shopping_cart_outlined, message: l.shoppingEmpty),
          for (final c in ShoppingCategory.values)
            if (groups[c] != null) ...[
              SectionTitle(l.shoppingCategory(c)),
              ...(groups[c]!..sort((a, b) => (a.checked ? 1 : 0).compareTo(b.checked ? 1 : 0))).map(
                (i) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: i.checked,
                  onChanged: (_) => ref.read(actionsProvider).toggleShopping(i),
                  title: Text(
                    i.name,
                    style: TextStyle(
                      decoration: i.checked ? TextDecoration.lineThrough : null,
                      color: i.checked ? context.semantic.muted : null,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          const SizedBox(height: Space.xl),
        ],
      ),
    );
  }
}
