import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/mascot.dart';
import '../../domain/problem/decision_engine.dart';
import '../../domain/problem/quantities.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../services/analytics/analytics_service.dart';
import '../premium/interstitial.dart';
import '../problem/problem_flow.dart';

/// "Decide": options × what matters → a recommendation with reasons. The
/// user rates; the engine weighs. No facts are invented.
class DecideScreen extends ConsumerStatefulWidget {
  const DecideScreen({super.key, this.initialOptions = const []});

  final List<String> initialOptions;

  @override
  ConsumerState<DecideScreen> createState() => _DecideScreenState();
}

class _Option {
  _Option(String name) : name = TextEditingController(text: name);
  final TextEditingController name;
  final price = TextEditingController();
  final ratings = <int, double>{}; // criterion index → 1..5
  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _DecideScreenState extends ConsumerState<DecideScreen> {
  late final List<_Option> _options = [
    for (final o in widget.initialOptions.take(4)) _Option(o),
    for (var i = widget.initialOptions.length; i < 2; i++) _Option(''),
  ];
  final _criteria = <Criterion>[
    const Criterion(kind: CriterionKind.price, weight: 2),
    const Criterion(kind: CriterionKind.quality, weight: 2),
    const Criterion(kind: CriterionKind.fit, weight: 3),
  ];
  final _custom = TextEditingController();
  DecisionOutcome? _outcome;
  final _resultKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(servicesProvider).analytics.log(AnalyticsEvent.decisionStarted, {
        'prefilled': widget.initialOptions.length,
      }),
    );
  }

  @override
  void dispose() {
    for (final o in _options) {
      o.dispose();
    }
    _custom.dispose();
    super.dispose();
  }

  String _critLabel(AppLocalizations l, Criterion c) => switch (c.kind) {
    CriterionKind.price => l.critPrice,
    CriterionKind.quality => l.critQuality,
    CriterionKind.fit => l.critFit,
    CriterionKind.longTerm => l.critLongTerm,
    CriterionKind.risk => l.critRisk,
    CriterionKind.custom => c.label,
  };

  List<_Option> get _named => _options.where((o) => o.name.text.trim().isNotEmpty).toList();

  void _decide() {
    final l = context.l10n;
    final named = _named;
    if (named.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.decideNeedTwo)));
      return;
    }
    final outcome = const DecisionEngine().decide(
      options: named.length,
      criteria: _criteria,
      ratings: [
        for (final o in named) [for (var c = 0; c < _criteria.length; c++) o.ratings[c] ?? 3],
      ],
      prices: [
        for (final o in named)
          o.price.text.trim().isEmpty ? null : Quantities.parseNumber(o.price.text.replaceAll(RegExp(r'[^\d.,]'), '')),
      ],
    );
    setState(() => _outcome = outcome);
    unawaited(
      ref.read(servicesProvider).analytics.log(AnalyticsEvent.decisionCompleted, {
        'options': named.length,
        'criteria': _criteria.length,
        'confidence': outcome.confidence.name,
      }),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: Motion.normal, curve: Motion.curve);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final named = _named;
    return PopScope(
      // A finished decision is a natural break for an (rare, capped) ad.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _outcome != null) unawaited(maybeShowInterstitial(ref));
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.decideTitle)),
        body: PageList(
          children: [
            Row(
              children: [
                const Mascot(mood: MascotMood.thoughtful, size: 48, float: false),
                const SizedBox(width: Space.md),
                Expanded(child: Text(l.decideIntro, style: context.text.bodyLarge)),
              ],
            ),
            const SizedBox(height: Space.lg),
            for (var i = 0; i < _options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _options[i].name,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(labelText: l.optionN(i + 1)),
                        onChanged: (_) => setState(() => _outcome = null),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _options[i].price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: l.decidePrice),
                        onChanged: (_) => setState(() => _outcome = null),
                      ),
                    ),
                    if (_options.length > 2)
                      IconButton(
                        tooltip: l.delete,
                        onPressed: () => setState(() {
                          _options.removeAt(i).dispose();
                          _outcome = null;
                        }),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            if (_options.length < 4)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _options.add(_Option(''))),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l.decideAddOption),
                ),
              ),
            const SizedBox(height: Space.lg),
            SectionTitle(l.decideWhatMatters),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final k in CriterionKind.values.where((k) => k != CriterionKind.custom))
                  FilterChip(
                    label: Text(_critLabel(l, Criterion(kind: k))),
                    selected: _criteria.any((c) => c.kind == k),
                    onSelected: (on) => setState(() {
                      _outcome = null;
                      if (on) {
                        _criteria.add(Criterion(kind: k));
                      } else if (_criteria.length > 1) {
                        final i = _criteria.indexWhere((c) => c.kind == k);
                        _criteria.removeAt(i);
                        for (final o in _options) {
                          _shiftRatings(o, i);
                        }
                      }
                    }),
                  ),
                for (final c in _criteria.where((c) => c.kind == CriterionKind.custom))
                  InputChip(
                    label: Text(c.label),
                    onDeleted: _criteria.length > 1
                        ? () => setState(() {
                            final i = _criteria.indexOf(c);
                            _criteria.removeAt(i);
                            for (final o in _options) {
                              _shiftRatings(o, i);
                            }
                            _outcome = null;
                          })
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _custom,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l.critCustomHint,
                suffixIcon: IconButton(tooltip: l.add, icon: const Icon(Icons.add_rounded), onPressed: _addCustom),
              ),
              onSubmitted: (_) => _addCustom(),
            ),
            const SizedBox(height: Space.lg),
            if (named.length >= 2) ...[
              SectionTitle(l.decideRate),
              Text(l.decideRateHelp, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
              const SizedBox(height: Space.md),
              for (var c = 0; c < _criteria.length; c++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: AppCard(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_critLabel(l, _criteria[c]), style: context.text.titleSmall),
                        const SizedBox(height: Space.sm),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<int>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(visualDensity: VisualDensity.compact),
                            segments: [
                              ButtonSegment(
                                value: 1,
                                label: Text(l.weight1, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              ButtonSegment(
                                value: 2,
                                label: Text(l.weight2, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              ButtonSegment(
                                value: 3,
                                label: Text(l.weight3, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            selected: {_criteria[c].weight},
                            onSelectionChanged: (v) => setState(() {
                              _criteria[c] = _criteria[c].copyWith(weight: v.first);
                              _outcome = null;
                            }),
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        for (final o in named)
                          if (!(_criteria[c].kind == CriterionKind.price && o.price.text.trim().isNotEmpty))
                            Row(
                              children: [
                                Expanded(child: Text(o.name.text.trim(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                Expanded(
                                  flex: 2,
                                  child: Slider(
                                    value: o.ratings[c] ?? 3,
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    label: '${(o.ratings[c] ?? 3).round()}',
                                    semanticFormatterCallback: (v) => '${o.name.text.trim()}: ${v.round()} / 5',
                                    onChanged: (v) => setState(() {
                                      o.ratings[c] = v;
                                      _outcome = null;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                      ],
                    ),
                  ),
                ),
            ],
            FilledButton.icon(
              onPressed: _decide,
              icon: const Icon(Icons.emoji_events_outlined),
              label: Text(l.decideShow),
            ),
            if (_outcome != null) ...[
              const SizedBox(height: Space.xl),
              KeyedSubtree(
                key: _resultKey,
                child: _Result(outcome: _outcome!, names: named, label: (c) => _critLabel(l, c)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addCustom() {
    final t = _custom.text.trim();
    if (t.isEmpty || _criteria.length >= 7) return;
    setState(() {
      _criteria.add(Criterion(kind: CriterionKind.custom, label: t.length > 40 ? t.substring(0, 40) : t));
      _custom.clear();
      _outcome = null;
    });
  }

  /// Ratings are keyed by criterion index; keep them aligned after a removal.
  void _shiftRatings(_Option o, int removed) {
    final next = <int, double>{};
    o.ratings.forEach((k, v) {
      if (k < removed) next[k] = v;
      if (k > removed) next[k - 1] = v;
    });
    o.ratings
      ..clear()
      ..addAll(next);
  }
}

class _Result extends ConsumerWidget {
  const _Result({required this.outcome, required this.names, required this.label});

  final DecisionOutcome outcome;
  final List<_Option> names;
  final String Function(Criterion) label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final winner = names[outcome.winner].name.text.trim();
    final verdict = switch (outcome.confidence) {
      Confidence.tooClose => l.decideTooClose,
      Confidence.slight => l.decideSlight,
      Confidence.clear => l.decideClear,
    };
    final ranked = List<int>.generate(names.length, (i) => i)
      ..sort((a, b) => outcome.totals[b].compareTo(outcome.totals[a]));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 22)),
              const SizedBox(width: Space.sm),
              Text(
                context.upper(l.decideRecommended),
                style: context.text.labelMedium?.copyWith(color: context.semantic.muted, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Semantics(liveRegion: true, child: Text(winner, style: context.text.headlineSmall)),
          const SizedBox(height: Space.xs),
          Text(verdict, style: context.text.bodyMedium),
          const SizedBox(height: Space.lg),
          for (final i in ranked)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: ProgressBar(
                value: outcome.totals[i] / 100,
                color: i == outcome.winner ? Accent.score.color : context.semantic.muted,
                label: '${names[i].name.text.trim()} · ${l.decideScore(outcome.totals[i].round())}',
              ),
            ),
          if (outcome.strengths.isNotEmpty || outcome.weaknesses.isNotEmpty) ...[
            const SizedBox(height: Space.md),
            Text(l.decideWhy, style: context.text.titleSmall),
            const SizedBox(height: Space.xs),
            for (final e in outcome.strengths)
              _Reason(icon: Icons.add_circle_outline, text: l.decideStrength(label(e.criterion)), good: true),
            for (final e in outcome.weaknesses)
              _Reason(icon: Icons.remove_circle_outline, text: l.decideWeakness(label(e.criterion)), good: false),
          ],
          const SizedBox(height: Space.md),
          Text(l.decideDisclaimer, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
          const SizedBox(height: Space.md),
          FilledButton.tonalIcon(
            onPressed: () => saveProblem(
              context,
              ref,
              kind: 'decision',
              title: names.map((o) => o.name.text.trim()).join(' vs '),
              summary: '🏆 $winner · $verdict',
              payload: {
                'options': [for (final o in names) o.name.text.trim()],
                'totals': [for (final t in outcome.totals) t.round()],
              },
            ),
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(l.save),
          ),
        ],
      ),
    );
  }
}

class _Reason extends StatelessWidget {
  const _Reason({required this.icon, required this.text, required this.good});
  final IconData icon;
  final String text;
  final bool good;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, size: 18, color: good ? context.semantic.positive : context.semantic.warning),
        const SizedBox(width: Space.sm),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ],
    ),
  );
}
