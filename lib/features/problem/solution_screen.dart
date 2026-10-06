import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../core/widgets/mascot.dart';
import '../../domain/engines/meal_engine.dart';
import '../../domain/engines/recipe_library.dart';
import '../../domain/problem/problem_solver.dart';
import '../../services/analytics/analytics_service.dart';
import 'problem_flow.dart';
import 'solution_view.dart';

/// Shows the answer to a problem typed on Home. Everything here is computed
/// on the phone, so it works offline and the numbers are exact.
class SolutionScreen extends ConsumerStatefulWidget {
  const SolutionScreen({super.key, required this.query});

  final String query;

  @override
  ConsumerState<SolutionScreen> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends ConsumerState<SolutionScreen> {
  late final ProblemResult _result = problemSolver.solve(widget.query);

  @override
  void initState() {
    super.initState();
    final a = ref.read(servicesProvider).analytics;
    final r = _result;
    if (r is Solution) {
      unawaited(a.log(AnalyticsEvent.problemSolved, {'kind': r.kind, 'on_device': true}));
      if (r is UnitPriceSolution || r is PriceChangeSolution || r is InstallmentSolution) {
        unawaited(a.log(AnalyticsEvent.savingCalculated, {'kind': r.kind}));
      }
    } else if (r is ToolRoute && r.tool == ProblemTool.recipe) {
      unawaited(a.log(AnalyticsEvent.recipeGenerated, {'source': 'ingredients', 'count': r.options.length}));
    }
  }

  void _askLio() {
    final q = Uri.encodeQueryComponent(widget.query);
    context.go('/ai?q=$q&send=1&n=${DateTime.now().microsecondsSinceEpoch}');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: Text(l.solutionTitle)),
      body: PageList(
        children: [
          FadeSlideIn(child: _Question(widget.query)),
          const SizedBox(height: Space.lg),
          switch (r) {
            final Solution s => FadeSlideIn(
              delay: Motion.fast,
              child: _SolutionCard(s, query: widget.query),
            ),
            ToolRoute(tool: ProblemTool.recipe, :final options) => FadeSlideIn(
              delay: Motion.fast,
              child: _RecipeResults(ingredients: options, query: widget.query),
            ),
            _ => const SizedBox.shrink(),
          },
          const SizedBox(height: Space.lg),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _askLio,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(l.askLioAbout),
              ),
              TextButton(onPressed: () => context.pop(), child: Text(l.solveAnother)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Question extends StatelessWidget {
  const _Question(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Mascot(mood: MascotMood.thoughtful, size: 44, float: false),
      const SizedBox(width: Space.md),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Text(text, style: context.text.bodyLarge),
        ),
      ),
    ],
  );
}

class _SolutionCard extends ConsumerWidget {
  const _SolutionCard(this.solution, {required this.query});
  final Solution solution;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = describeSolution(solution, l, ref.fmt(context));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 18, color: context.semantic.positive),
              const SizedBox(width: Space.xs),
              Flexible(
                child: Text(l.solvedOnDevice, style: context.text.labelMedium?.copyWith(color: context.semantic.muted)),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Semantics(liveRegion: true, child: Text(t.headline, style: context.text.headlineSmall)),
          if (t.rows.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            for (final (k, v) in t.rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.xs + 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(k, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
                    ),
                    const SizedBox(width: Space.md),
                    Flexible(
                      child: Text(
                        v,
                        textAlign: TextAlign.end,
                        style: context.text.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (t.note != null) ...[
            const SizedBox(height: Space.sm),
            Text(t.note!, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
          ],
          const SizedBox(height: Space.lg),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => saveProblem(
                  context,
                  ref,
                  kind: solution.kind,
                  title: query,
                  summary: t.headline,
                  payload: {'q': query},
                ),
                icon: const Icon(Icons.bookmark_add_outlined),
                label: Text(l.save),
              ),
              const SizedBox(width: Space.sm),
              IconButton(
                tooltip: MaterialLocalizations.of(context).copyButtonLabel,
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: [t.headline, ...t.rows.map((r) => '${r.$1}: ${r.$2}')].join('\n')),
                  );
                  HapticFeedback.selectionClick();
                },
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecipeResults extends ConsumerWidget {
  const _RecipeResults({required this.ingredients, required this.query});
  final List<String> ingredients;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final matches = bestForIngredients(RecipeLibrary.all(lang), ingredients);
    if (matches.isEmpty) {
      return AppCard(child: Text(l.recipeNoMatch, style: context.text.bodyLarge));
    }
    final missingAll = {for (final m in matches.take(1)) ...m.missing}.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.recipeHeadline, style: context.text.headlineSmall),
        const SizedBox(height: Space.md),
        for (final (i, m) in matches.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${i + 1}', style: context.text.titleLarge?.copyWith(color: Accent.food.color)),
                      const SizedBox(width: Space.md),
                      Expanded(child: Text(m.recipe.name, style: context.text.titleMedium)),
                      Text(
                        l.recipeMinutes(m.recipe.prepMinutes),
                        style: context.text.labelMedium?.copyWith(color: context.semantic.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.sm),
                  Text(
                    m.missing.isEmpty
                        ? l.recipeHaveAll
                        : l.recipeMissing(m.missing.map((x) => ingredientName(x, lang)).join(', ')),
                    style: context.text.bodyMedium?.copyWith(
                      color: m.missing.isEmpty ? context.semantic.positive : context.semantic.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            if (missingAll.isNotEmpty)
              FilledButton.icon(
                onPressed: () async {
                  await ref
                      .read(actionsProvider)
                      .addShoppingItems(missingAll.map((x) => ingredientName(x, lang)).toList());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.addedToList)));
                  }
                },
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: Text(l.addMissingToList),
              ),
            OutlinedButton.icon(
              onPressed: () => saveProblem(
                context,
                ref,
                kind: 'recipe',
                title: query,
                summary: matches.map((m) => m.recipe.name).join(' · '),
                payload: {'q': query},
              ),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(l.save),
            ),
          ],
        ),
      ],
    );
  }
}
