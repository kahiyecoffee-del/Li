import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/formatters.dart';
import '../../core/widgets/mascot.dart';
import '../../l10n/gen/app_localizations.dart';
import 'mood_sheet.dart';

List<String> journalPrompts(AppLocalizations l) => [l.jp1, l.jp2, l.jp3, l.jp4, l.jp5, l.jp6, l.jp7];

/// Write today's entry: how you feel, a guiding question, and the page.
/// Entries are encrypted on the phone and never synced.
class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({super.key});

  @override
  ConsumerState<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _text = TextEditingController();
  int? _mood;
  var _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  int get _words => RegExp(r'\S+').allMatches(_text.text).length;

  void _usePrompt(String p) {
    HapticFeedback.selectionClick();
    final t = _text.text.trimRight();
    _text.text = t.isEmpty ? '$p\n' : '$t\n\n$p\n';
    _text.selection = TextSelection.collapsed(offset: _text.text.length);
    setState(() {});
  }

  Future<void> _save() async {
    final t = _text.text.trim();
    if (t.isEmpty && _mood == null) return;
    setState(() => _saving = true);
    final actions = ref.read(actionsProvider);
    if (t.isNotEmpty) await actions.addJournal(t);
    if (_mood != null) await actions.logMood(_mood!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.journalSaved)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final prompts = journalPrompts(l);
    final today = DateTime.now();
    final todays = prompts[today.difference(DateTime(2026)).inDays.abs() % prompts.length];
    return Scaffold(
      appBar: AppBar(
        title: Text(fmt.weekdayDayMonth(today)),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l.save)),
          const SizedBox(width: Space.sm),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xl),
          children: [
            Text(l.journalHowFeel, style: context.text.titleMedium),
            const SizedBox(height: Space.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final m in [1, 2, 3, 4, 5])
                  Semantics(
                    button: true,
                    selected: _mood == m,
                    label: '$m / 5',
                    child: InkResponse(
                      onTap: () => setState(() => _mood = _mood == m ? null : m),
                      radius: 30,
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        padding: const EdgeInsets.all(Space.sm),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _mood == m ? context.colors.primaryContainer : Colors.transparent,
                        ),
                        child: Text(moodEmojis[m]!, style: TextStyle(fontSize: _mood == m ? 34 : 28)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Space.lg),
            Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Row(
                children: [
                  const Mascot(mood: MascotMood.curious, size: 40, float: false),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.upper(l.journalTodayPrompt),
                          style: context.text.labelSmall?.copyWith(color: context.semantic.muted, letterSpacing: 1),
                        ),
                        Text(todays, style: context.text.titleSmall),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l.add,
                    onPressed: () => _usePrompt(todays),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.xs,
              children: [
                for (final p in prompts.where((p) => p != todays))
                  ActionChip(label: Text(p), onPressed: () => _usePrompt(p)),
              ],
            ),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _text,
              autofocus: false,
              minLines: 8,
              maxLines: null,
              maxLength: 5000,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: l.journalHint, counterText: l.journalWords(_words)),
            ),
            const SizedBox(height: Space.sm),
            Text(l.journalPrivacy, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
            const SizedBox(height: Space.lg),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}
