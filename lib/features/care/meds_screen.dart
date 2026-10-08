import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/ids.dart';
import '../../core/widgets/common.dart';
import '../../domain/care/meds.dart';
import '../../domain/models/care.dart';

/// Taken dose ids (all days; small: a few per day).
final takenDoseIdsProvider = Provider<Set<String>>(
  (ref) => {
    for (final d in ref.watch(medDosesProvider).list)
      if (!d.deleted) d.id,
  },
);

final activeMedsProvider = Provider<List<Medication>>(
  (ref) =>
      ref.watch(medicationsProvider).list.where((m) => !m.deleted).toList()..sort((a, b) => a.name.compareTo(b.name)),
);

class MedsScreen extends ConsumerWidget {
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final meds = ref.watch(activeMedsProvider);
    final now = ref.watch(clockProvider)();
    final doses = dosesOn(now, meds, ref.watch(takenDoseIdsProvider));
    return Scaffold(
      appBar: AppBar(title: Text(l.medsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('meds-add'),
        onPressed: () => showMedSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.medsAdd),
      ),
      body: PageList(
        animate: false,
        children: [
          Text(l.medsIntro, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
          const SizedBox(height: Space.md),
          if (meds.isEmpty)
            EmptyState(icon: Icons.medication_outlined, message: l.medsEmpty)
          else ...[
            SectionTitle(l.today),
            if (doses.isEmpty)
              Text(l.medsNone, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted))
            else
              AppCard(
                child: Column(
                  children: [for (final d in doses) DoseRow(slot: d, now: now)],
                ),
              ),
            const SizedBox(height: Space.lg),
            SectionTitle(l.medsReminders),
            for (final m in meds)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: AppCard(
                  key: Key('med-${m.id}'),
                  onTap: () => showMedSheet(context, med: m),
                  child: Row(
                    children: [
                      IconBubble(
                        icon: Icons.medication_rounded,
                        accent: m.active ? Accent.wellbeing : Accent.news,
                        size: 40,
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text([m.name, if (m.dose.isNotEmpty) m.dose].join(' · '), style: context.text.titleMedium),
                            Text(
                              m.times.join(' · '),
                              style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                            ),
                            if (m.daysLeft != null)
                              Text(
                                m.needsRefill
                                    ? '${l.medsRefill} · ${l.medsDaysLeft(m.daysLeft!)}'
                                    : l.medsDaysLeft(m.daysLeft!),
                                style: context.text.bodySmall?.copyWith(
                                  color: m.needsRefill ? context.semantic.negative : context.semantic.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Switch(
                        value: m.active,
                        onChanged: (v) => ref.read(actionsProvider).saveMedication(m.copyWith(active: v)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: Space.md),
          Text(l.medsDisclaimer, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
        ],
      ),
    );
  }
}

/// One dose with a "Taken" toggle.
class DoseRow extends ConsumerWidget {
  const DoseRow({super.key, required this.slot, required this.now});
  final DoseSlot slot;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final late = !slot.taken && slot.at.isBefore(now);
    return ListTile(
      key: Key('dose-${slot.doseId}'),
      contentPadding: EdgeInsets.zero,
      leading: Text(
        slot.time,
        style: context.text.titleMedium?.copyWith(color: late ? context.semantic.negative : null),
      ),
      title: Text(slot.med.name),
      subtitle: slot.med.dose.isEmpty ? null : Text(slot.med.dose),
      trailing: slot.taken
          ? TextButton.icon(
              onPressed: () => ref.read(actionsProvider).undoDose(slot.doseId),
              icon: Icon(Icons.check_circle_rounded, color: context.semantic.positive),
              label: Text(l.medsTaken),
            )
          : FilledButton.tonal(
              key: Key('take-${slot.doseId}'),
              onPressed: () {
                unawaited(HapticFeedback.mediumImpact());
                ref.read(actionsProvider).takeDose(slot.doseId);
              },
              child: Text(l.medsTake),
            ),
    );
  }
}

/// Home: doses due now (or missed earlier today), taken with one tap.
class DueDosesCard extends ConsumerWidget {
  const DueDosesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(activeMedsProvider);
    if (meds.isEmpty) return const SizedBox.shrink();
    final now = currentNowOfRef(ref);
    final due = dueDoses(now, meds, ref.watch(takenDoseIdsProvider));
    if (due.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: AppCard(
        key: const Key('due-doses'),
        onTap: () => context.push('/meds'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardHeader(icon: Icons.medication_rounded, title: context.l10n.medsDueTitle, accent: Accent.wellbeing),
            for (final d in due.take(3)) DoseRow(slot: d, now: now),
          ],
        ),
      ),
    );
  }
}

DateTime currentNowOfRef(WidgetRef ref) => ref.watch(nowProvider).value ?? ref.watch(clockProvider)();

Future<void> showMedSheet(BuildContext context, {Medication? med}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _MedSheet(med: med),
);

class _MedSheet extends ConsumerStatefulWidget {
  const _MedSheet({this.med});
  final Medication? med;

  @override
  ConsumerState<_MedSheet> createState() => _MedSheetState();
}

class _MedSheetState extends ConsumerState<_MedSheet> {
  late final _name = TextEditingController(text: widget.med?.name);
  late final _dose = TextEditingController(text: widget.med?.dose);
  late final _stock = TextEditingController(text: widget.med?.stock?.toString());
  late final List<String> _times = [...?widget.med?.times];

  @override
  void initState() {
    super.initState();
    if (_times.isEmpty) _times.add('09:00');
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 21, minute: 0));
    if (t == null) return;
    final s = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (!_times.contains(s)) _times.add(s);
      _times.sort();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.med?.name ?? l.medsAdd, style: context.text.titleLarge),
            const SizedBox(height: Space.md),
            TextField(
              key: const Key('med-name'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.medsName),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _dose,
              decoration: InputDecoration(labelText: l.medsDose),
            ),
            const SizedBox(height: Space.md),
            Text(l.medsTimes, style: context.text.titleSmall),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final t in _times)
                  InputChip(
                    label: Text(t),
                    onDeleted: _times.length > 1 ? () => setState(() => _times.remove(t)) : null,
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l.medsAddTime),
                  onPressed: _addTime,
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _stock,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l.medsStock),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              key: const Key('med-save'),
              onPressed: () async {
                final name = _name.text.trim();
                if (name.isEmpty || _times.isEmpty) return;
                final stock = int.tryParse(_stock.text.trim());
                final m = widget.med;
                final now = DateTime.now();
                await ref
                    .read(actionsProvider)
                    .saveMedication(
                      m == null
                          ? Medication(
                              id: newId(),
                              updatedAt: now,
                              name: name,
                              dose: _dose.text.trim(),
                              times: [..._times],
                              stock: stock,
                              createdAt: now,
                            )
                          : m.copyWith(
                              name: name,
                              dose: _dose.text.trim(),
                              times: [..._times],
                              stock: stock,
                              clearStock: stock == null,
                            ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l.save),
            ),
            if (widget.med != null)
              TextButton(
                onPressed: () async {
                  final m = widget.med!;
                  final actions = ref.read(actionsProvider);
                  await actions.deleteMedication(m.id);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showSnack(
                    context,
                    l.delete,
                    action: SnackBarAction(label: l.undo, onPressed: () => actions.restoreMedication(m)),
                  );
                },
                child: Text(l.delete, style: TextStyle(color: context.semantic.negative)),
              ),
          ],
        ),
      ),
    );
  }
}
