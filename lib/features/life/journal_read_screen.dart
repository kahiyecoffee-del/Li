import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import 'mood_sheet.dart';

/// Reading one journal entry, calmly and in full.
class JournalReadScreen extends ConsumerWidget {
  const JournalReadScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final entry = ref.watch(journalProvider).list.where((e) => e.id == id).firstOrNull;
    if (entry == null) return Scaffold(appBar: AppBar(), body: const LoadingView());
    final mood = ref.watch(moodsProvider).list.where((m) => m.id == Dates.dayKey(entry.createdAt)).firstOrNull;
    final words = RegExp(r'\S+').allMatches(entry.text).length;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l.copy,
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: entry.text));
              showSnack(context, l.copied);
            },
          ),
          IconButton(
            tooltip: l.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirmDialog(
                context,
                title: l.deleteConfirmTitle,
                body: l.deleteConfirmBody,
                destructive: true,
              )) {
                await ref.read(actionsProvider).deleteJournal(entry.id);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xxl),
          children: [
            Row(
              children: [
                if (mood != null)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.md),
                    child: Text(moodEmojis[mood.mood]!, style: const TextStyle(fontSize: 34)),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fmt.fullDate(entry.createdAt), style: context.text.headlineSmall),
                      Text(
                        '${fmt.time(entry.createdAt)} · ${l.journalWords(words)}',
                        style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.xl),
            SelectableText(entry.text, style: context.text.bodyLarge?.copyWith(fontSize: 18, height: 1.7)),
          ],
        ),
      ),
    );
  }
}
