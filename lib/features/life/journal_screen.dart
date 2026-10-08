import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../core/widgets/mascot.dart';
import '../../domain/models/wellbeing.dart';
import 'mood_sheet.dart';

/// Private journal: encrypted on the phone, never synced. Shows the writing
/// streak, this month's entries and the week's mood, with search.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static int streak(List<JournalEntry> entries, DateTime now) {
    final days = entries.map((e) => Dates.dateOnly(e.createdAt)).toSet();
    final today = Dates.dateOnly(now);
    var n = 0;
    for (var d = days.contains(today) ? today : Dates.addDays(today, -1); days.contains(d); d = Dates.addDays(d, -1)) {
      n++;
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final entries = ref.watch(journalProvider);
    final moods = {for (final m in ref.watch(moodsProvider).list) m.id: m.mood};
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: Text(l.lifeJournal)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-journal',
        onPressed: () => context.push('/journal/new'),
        icon: const Icon(Icons.edit_outlined),
        label: Text(l.journalWriteToday),
      ),
      body: AmbientBackdrop(
        child: entries.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e),
          data: (all) {
            final list = [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (list.isEmpty) return EmptyState(icon: Icons.lock_outline, message: l.journalEmpty);
            final q = _search.text.trim().toLowerCase();
            final shown = q.isEmpty ? list : list.where((e) => e.text.toLowerCase().contains(q)).toList();
            final month = list.where((e) => e.createdAt.year == now.year && e.createdAt.month == now.month).length;
            final weekMoods = [for (var d = 0; d < 7; d++) moods[Dates.dayKey(Dates.addDays(now, -d))]]
                .whereType<int>()
                .toList();
            final avgMood = weekMoods.isEmpty ? null : (weekMoods.reduce((a, b) => a + b) / weekMoods.length).round();
            return ListView(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, 120),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        icon: Icons.local_fire_department_rounded,
                        accent: Accent.goals,
                        text: l.journalStreakLabel(streak(list, now)),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: _Stat(
                        icon: Icons.menu_book_rounded,
                        accent: Accent.insight,
                        text: l.journalThisMonth(month),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: _Stat(
                        emoji: avgMood == null ? '—' : moodEmojis[avgMood.clamp(1, 5)],
                        accent: Accent.wellbeing,
                        text: l.journalMoodWeek,
                      ),
                    ),
                  ],
                ),
                if (ref.watch(settingsProvider.select((x) => x.lioLearnsJournal))) ...[
                  const SizedBox(height: Space.md),
                  const _Learned(),
                ],
                const SizedBox(height: Space.md),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: l.journalSearch),
                ),
                const SizedBox(height: Space.sm),
                Text(l.journalPrivacy, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(Space.xl),
                    child: Center(child: Text(l.journalNoResults)),
                  ),
                for (final e in shown) ...[
                  if (shown.indexOf(e) == 0 ||
                      fmt.monthYear(shown[shown.indexOf(e) - 1].createdAt) != fmt.monthYear(e.createdAt))
                    Padding(
                      padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
                      child: Text(fmt.monthYear(e.createdAt), style: context.text.titleMedium),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: AppCard(
                      onTap: () => context.push('/journal/${e.id}'),
                      padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.xs, Space.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (moods[Dates.dayKey(e.createdAt)] != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: Space.sm),
                                  child: Text(
                                    moodEmojis[moods[Dates.dayKey(e.createdAt)]!]!,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
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
                          Padding(
                            padding: const EdgeInsets.only(right: Space.md),
                            child: Text(
                              e.text,
                              style: context.text.bodyLarge,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.text, required this.accent, this.icon, this.emoji});
  final String text;
  final Accent accent;
  final IconData? icon;
  final String? emoji;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.md),
    decoration: BoxDecoration(
      color: accent.tint(Theme.of(context).brightness),
      borderRadius: BorderRadius.circular(Radii.md),
    ),
    child: Column(
      children: [
        if (icon != null) Icon(icon, color: accent.color) else Text(emoji!, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: Space.xs),
        Text(text, textAlign: TextAlign.center, maxLines: 2, style: context.text.labelMedium),
      ],
    ),
  );
}

/// What Lio learned from the journal on this phone.
class _Learned extends ConsumerWidget {
  const _Learned();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = ref.watch(journalProfileProvider);
    Widget chips(String title, List<String> words, Color color) => Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.labelMedium?.copyWith(color: context.semantic.muted)),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final w in words)
                Chip(
                  label: Text(w),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                ),
            ],
          ),
        ],
      ),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Mascot(mood: MascotMood.thoughtful, size: 36, float: false),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(l.journalKnowsTitle, style: context.text.titleMedium)),
            ],
          ),
          if (p == null || p.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.sm),
              child: Text(l.journalLearnHint, style: context.text.bodyMedium),
            )
          else ...[
            if (p.themes.isNotEmpty)
              chips(l.journalThemes, p.themes.take(6).map((t) => t.word).toList(), Accent.insight.color),
            if (p.lifts.isNotEmpty)
              chips(l.journalLifts, p.lifts.map((x) => x.word).toList(), context.semantic.positive),
            if (p.drains.isNotEmpty)
              chips(l.journalDrains, p.drains.map((x) => x.word).toList(), context.semantic.warning),
          ],
          const SizedBox(height: Space.sm),
          Text(l.journalOnDevice, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
        ],
      ),
    );
  }
}
