import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';

const moodEmojis = {5: '😄', 4: '🙂', 3: '😐', 2: '😔', 1: '😫'};

/// Row of five large, labelled mood buttons.
class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.selected, required this.onSelected});

  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: moodEmojis.entries.map((e) {
      final isSel = selected == e.key;
      return Semantics(
        button: true,
        selected: isSel,
        label: context.l10n.mood(e.key),
        child: InkResponse(
          onTap: () => onSelected(e.key),
          radius: 32,
          child: AnimatedContainer(
            duration: Motion.fast,
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSel ? context.colors.primary.withValues(alpha: 0.15) : Colors.transparent,
              border: Border.all(color: isSel ? context.colors.primary : Colors.transparent, width: 2),
            ),
            child: ExcludeSemantics(child: Text(e.value, style: const TextStyle(fontSize: 30))),
          ),
        ),
      );
    }).toList(),
  );
}

Future<void> showMoodSheet(BuildContext context, {int? initial}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _MoodSheet(initial: initial),
);

class _MoodSheet extends ConsumerStatefulWidget {
  const _MoodSheet({this.initial});

  final int? initial;

  @override
  ConsumerState<_MoodSheet> createState() => _MoodSheetState();
}

class _MoodSheetState extends ConsumerState<_MoodSheet> {
  late int? _mood = widget.initial;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
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
          Text(l.howAreYou, style: context.text.titleLarge),
          const SizedBox(height: Space.lg),
          MoodPicker(selected: _mood, onSelected: (m) => setState(() => _mood = m)),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _note,
            maxLines: 2,
            maxLength: 280,
            decoration: InputDecoration(labelText: l.moodWhy),
          ),
          const SizedBox(height: Space.md),
          FilledButton(
            onPressed: _mood == null
                ? null
                : () async {
                    await ref.read(actionsProvider).logMood(_mood!, note: _note.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      showSnack(context, l.moodSaved);
                    }
                  },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}

Future<void> showSleepSheet(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  var hours = 7.5;
  final r = await showModalBottomSheet<double>(
    context: context,
    useRootNavigator: true,
    builder: (c) => StatefulBuilder(
      builder: (c, set) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.sleepHoursQuestion, style: c.text.titleLarge),
            const SizedBox(height: Space.lg),
            Text(
              l.hoursMinutes(hours.floor(), ((hours % 1) * 60).round()),
              textAlign: TextAlign.center,
              style: c.text.headlineMedium,
            ),
            Slider(value: hours, min: 0, max: 12, divisions: 48, onChanged: (v) => set(() => hours = v)),
            FilledButton(onPressed: () => Navigator.pop(c, hours), child: Text(l.save)),
          ],
        ),
      ),
    ),
  );
  if (r != null) await ref.read(actionsProvider).logSleep((r * 60).round());
}
