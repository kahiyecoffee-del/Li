import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/debts.dart';
import '../../domain/models/care.dart';

/// Who owes whom, settle with undo, a friendly reminder to share, and a
/// bill splitter that can save the shares as debts.
class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final debts = ref.watch(debtsProvider).list.where((d) => !d.deleted).toList();
    final balances = debtBalances(debts);
    final (owed, owe) = debtTotals(debts);
    final settled = debts.where((d) => d.settledAt != null).toList()
      ..sort((a, b) => b.settledAt!.compareTo(a.settledAt!));
    return Scaffold(
      appBar: AppBar(title: Text(l.debtsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('debt-add'),
        onPressed: () => showDebtSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.debtsAdd),
      ),
      body: PageList(
        animate: false,
        children: [
          Row(
            children: [
              Expanded(
                child: _Total(label: l.debtsOwedToYou, amount: fmt.money(owed), color: context.semantic.positive),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: _Total(label: l.debtsYouOwe, amount: fmt.money(owe), color: context.semantic.negative),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          OutlinedButton.icon(
            key: const Key('split-open'),
            onPressed: () => showSplitSheet(context),
            icon: const Icon(Icons.call_split_rounded),
            label: Text(l.debtsSplit),
          ),
          const SizedBox(height: Space.md),
          if (balances.isEmpty) EmptyState(icon: Icons.handshake_outlined, message: l.debtsEmpty),
          for (final (person, net) in balances)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: _PersonCard(person: person, net: net, debts: debts),
            ),
          if (settled.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            SectionTitle(l.debtsHistory),
            for (final d in settled.take(10))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(d.person),
                subtitle: d.note.isEmpty ? null : Text(d.note),
                trailing: Text(
                  fmt.money(d.amountMinor),
                  style: context.text.bodyMedium?.copyWith(
                    color: context.semantic.muted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.amount, required this.color});
  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.text.labelMedium?.copyWith(color: context.semantic.muted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(amount, style: context.text.titleLarge?.copyWith(color: color)),
        ),
      ],
    ),
  );
}

class _PersonCard extends ConsumerWidget {
  const _PersonCard({required this.person, required this.net, required this.debts});
  final String person;
  final int net;
  final List<Debt> debts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final key = person.toLowerCase();
    final items = debts.where((d) => d.isOpen && d.person.trim().toLowerCase() == key).toList();
    final amount = fmt.money(net.abs());
    return AppCard(
      key: Key('debt-person-$key'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, child: Text(person.isEmpty ? '?' : person.characters.first.toUpperCase())),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person, style: context.text.titleMedium),
                    Text(
                      net > 0 ? l.debtsPersonOwes(amount) : l.debtsYouOwePerson(amount),
                      style: context.text.bodyMedium?.copyWith(
                        color: net > 0 ? context.semantic.positive : context.semantic.negative,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final d in items.where((d) => d.note.isNotEmpty).take(3))
            Padding(
              padding: const EdgeInsets.only(top: Space.xs, left: 52),
              child: Text(
                '${d.note} · ${fmt.money(d.amountMinor)}',
                style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
              ),
            ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.sm,
            children: [
              FilledButton.tonalIcon(
                key: Key('debt-settle-$key'),
                onPressed: () async {
                  final actions = ref.read(actionsProvider);
                  final closed = await actions.settleWith(person);
                  unawaited(HapticFeedback.mediumImpact());
                  if (!context.mounted) return;
                  showSnack(
                    context,
                    l.debtsSettled(person),
                    action: SnackBarAction(label: l.undo, onPressed: () => actions.restoreDebts(closed)),
                  );
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(l.debtsSettle),
              ),
              if (net > 0)
                TextButton.icon(
                  onPressed: () => ref.read(servicesProvider).share.shareText(l.debtsRemindText(person, amount)),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(l.debtsRemind),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showDebtSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => const _DebtSheet(),
);

class _DebtSheet extends ConsumerStatefulWidget {
  const _DebtSheet();

  @override
  ConsumerState<_DebtSheet> createState() => _DebtSheetState();
}

class _DebtSheetState extends ConsumerState<_DebtSheet> {
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  bool _theyOwe = true;

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final currency = ref.watch(profileProvider).value?.currency;
    final people = {for (final d in ref.watch(debtsProvider).list.where((d) => !d.deleted)) d.person.trim()}
        .where((p) => p.isNotEmpty)
        .take(8)
        .toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.debtsAdd, style: context.text.titleLarge),
            const SizedBox(height: Space.md),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(l.debtsTheyOwe)),
                ButtonSegment(value: false, label: Text(l.debtsIOwe)),
              ],
              selected: {_theyOwe},
              onSelectionChanged: (v) => setState(() => _theyOwe = v.first),
            ),
            const SizedBox(height: Space.md),
            TextField(
              key: const Key('debt-person'),
              controller: _person,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.debtsPerson),
            ),
            if (people.isNotEmpty) ...[
              const SizedBox(height: Space.xs),
              Wrap(
                spacing: Space.xs,
                children: [
                  for (final p in people) ActionChip(label: Text(p), onPressed: () => setState(() => _person.text = p)),
                ],
              ),
            ],
            const SizedBox(height: Space.md),
            TextField(
              key: const Key('debt-amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.amount, suffixText: currency),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.debtsNote),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              key: const Key('debt-save'),
              onPressed: () async {
                final minor = Money.parseMinor(_amount.text);
                if (minor == null || minor <= 0 || _person.text.trim().isEmpty) return;
                await ref
                    .read(actionsProvider)
                    .addDebt(person: _person.text, amountMinor: minor, theyOwe: _theyOwe, note: _note.text);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showSplitSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => const _SplitSheet(),
);

class _SplitSheet extends ConsumerStatefulWidget {
  const _SplitSheet();

  @override
  ConsumerState<_SplitSheet> createState() => _SplitSheetState();
}

class _SplitSheetState extends ConsumerState<_SplitSheet> {
  final _amount = TextEditingController();
  final _names = TextEditingController();
  int _people = 2;
  int _tip = 0;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
    _names.addListener(_syncPeople);
  }

  List<String> get _others =>
      _names.text.split(RegExp(r'[,;\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  /// Names typed: the head count follows (them + you).
  void _syncPeople() {
    final n = _others.length + 1;
    setState(() {
      if (_others.isNotEmpty && n > _people) _people = n;
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _names.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final currency = ref.watch(profileProvider).value?.currency;
    final minor = Money.parseMinor(_amount.text) ?? 0;
    final split = splitBill(minor, _people, tipPercent: _tip);
    final others = _others;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.debtsSplit, style: context.text.titleLarge),
            const SizedBox(height: Space.md),
            TextField(
              key: const Key('split-amount'),
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.splitTotal, suffixText: currency),
            ),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(child: Text(l.splitPeople, style: context.text.titleSmall)),
                IconButton.outlined(
                  onPressed: _people > 1 ? () => setState(() => _people--) : null,
                  icon: const Icon(Icons.remove, size: 18),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$_people',
                    key: const Key('split-people'),
                    textAlign: TextAlign.center,
                    style: context.text.titleMedium,
                  ),
                ),
                IconButton.outlined(
                  key: const Key('split-more'),
                  onPressed: _people < 50 ? () => setState(() => _people++) : null,
                  icon: const Icon(Icons.add, size: 18),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(l.splitTip, style: context.text.titleSmall),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              children: [
                for (final t in const [0, 5, 10, 15, 20])
                  ChoiceChip(label: Text('%$t'), selected: _tip == t, onSelected: (_) => setState(() => _tip = t)),
              ],
            ),
            const SizedBox(height: Space.md),
            AppCard(
              child: Column(
                children: [
                  Text(
                    l.splitEach(fmt.money(split.perPersonMinor, cents: true)),
                    key: const Key('split-each'),
                    style: context.text.headlineSmall,
                  ),
                  if (_tip > 0)
                    Text(
                      l.splitWithTip(fmt.money(split.totalMinor, cents: true)),
                      style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
            TextField(
              key: const Key('split-names'),
              controller: _names,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.splitNames),
            ),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: minor <= 0
                        ? null
                        : () => ref
                              .read(servicesProvider)
                              .share
                              .shareText(
                                l.splitShareText(
                                  fmt.money(split.totalMinor, cents: true),
                                  _people,
                                  fmt.money(split.perPersonMinor, cents: true),
                                ),
                              ),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(l.share),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('split-save'),
                    onPressed: minor <= 0 || others.isEmpty
                        ? null
                        : () async {
                            final actions = ref.read(actionsProvider);
                            // Shares after yours (the first) go to the others.
                            for (final (i, name) in others.indexed) {
                              await actions.addDebt(
                                person: name,
                                amountMinor: split.shares[(i + 1) % split.shares.length],
                                theyOwe: true,
                                note: l.splitNote,
                              );
                            }
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            showSnack(context, l.splitSaved(others.length));
                          },
                    child: Text(l.splitSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
