import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';

/// Private journal: encrypted on device, never synced.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final entries = ref.watch(journalProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.lifeJournal),
        actions: [
          IconButton(
            tooltip: l.journalSummarize,
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () => context.go('/ai?q=${Uri.encodeComponent(l.journalSummarize)}'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _write(context, ref),
        icon: const Icon(Icons.edit_outlined),
        label: Text(l.journalNew),
      ),
      body: entries.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e),
        data: (list) => list.isEmpty
            ? EmptyState(icon: Icons.lock_outline, message: l.journalEmpty)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 120),
                itemCount: list.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: Space.md),
                      child: Text(
                        l.journalPrivacy,
                        style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                      ),
                    );
                  }
                  final e = list[i - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  fmt.dateTime(e.createdAt),
                                  style: context.text.labelMedium?.copyWith(color: context.semantic.muted),
                                ),
                              ),
                              IconButton(
                                tooltip: l.delete,
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () async {
                                  if (await confirmDialog(
                                    context,
                                    title: l.deleteConfirmTitle,
                                    body: l.deleteConfirmBody,
                                    destructive: true,
                                  )) {
                                    await ref.read(actionsProvider).deleteJournal(e.id);
                                  }
                                },
                              ),
                            ],
                          ),
                          Text(e.text, style: context.text.bodyLarge),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _write(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final c = TextEditingController();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (s) => Padding(
        padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, MediaQuery.viewInsetsOf(s).bottom + Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: c,
              autofocus: true,
              minLines: 5,
              maxLines: 12,
              maxLength: 5000,
              decoration: InputDecoration(hintText: l.journalHint),
            ),
            FilledButton(onPressed: () => Navigator.pop(s, c.text), child: Text(l.save)),
          ],
        ),
      ),
    );
    c.dispose();
    if (text != null && text.trim().isNotEmpty) await ref.read(actionsProvider).addJournal(text);
  }
}
