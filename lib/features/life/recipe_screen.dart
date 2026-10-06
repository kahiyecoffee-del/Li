import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/meal_engine.dart';
import '../../domain/engines/recipe_library.dart';
import '../../domain/models/food.dart';

/// A recipe from the library (by id) or one passed in directly (AI recipes
/// from a meal plan).
class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({super.key, this.id, this.recipe});

  final String? id;
  final Recipe? recipe;

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  int? _servings;
  final _done = <int>{};

  String get _lang => Localizations.localeOf(context).languageCode;

  Recipe? _resolve() =>
      (widget.id == null ? null : RecipeLibrary.byId(widget.id!, _lang)) ??
      (widget.recipe == null ? null : (RecipeLibrary.byId(widget.recipe!.id, _lang) ?? widget.recipe));

  String _asText(Recipe r, double factor, int servings) {
    final l = context.l10n;
    final b = StringBuffer('${r.name}\n');
    if (r.hasAmounts) b.writeln(l.foodServings(servings));
    b.writeln('\n${l.foodIngredients}:');
    for (final (i, name) in r.ingredients.indexed) {
      final amount = r.hasAmounts ? '${formatAmount(r.quantities[i], r.units[i], _lang, factor: factor)} ' : '';
      b.writeln('• $amount${ingredientName(name, _lang)}');
    }
    if (r.steps.isNotEmpty) {
      b.writeln('\n${l.foodSteps}:');
      for (final (i, s) in r.steps.indexed) {
        b.writeln('${i + 1}. $s');
      }
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = _resolve();
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.restaurant_menu_rounded, message: l.foodNoRecipes),
      );
    }
    final fmt = ref.fmt(context);
    final favorites = ref.watch(settingsProvider.select((s) => s.favoriteRecipes));
    final fav = favorites.contains(r.id);
    final pantry = ref.watch(pantryProvider).list.map((p) => p.name);
    final missing = const MealEngine().matchPantry([r], pantry).first.missing;
    final servings = _servings ?? (r.servings > 0 ? r.servings : 1);
    final factor = r.servings > 0 ? servings / r.servings : 1.0;
    final cost = r.estimatedCostMinor != null
        ? l.foodEstimatedCost(fmt.money(r.estimatedCostMinor!))
        : r.tags.contains('cost:low')
        ? l.foodCostLow
        : r.tags.contains('cost:high')
        ? l.foodCostHigh
        : l.foodCostMedium;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l.foodCopyRecipe,
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _asText(r, factor, servings)));
              if (context.mounted) showSnack(context, l.copied);
            },
          ),
          IconButton(
            tooltip: fav ? l.foodFavoriteRemove : l.foodFavoriteAdd,
            icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded),
            color: fav ? context.colors.error : null,
            onPressed: () => ref
                .read(settingsProvider.notifier)
                .update(
                  (s) => s.copyWith(
                    favoriteRecipes: fav ? ({...s.favoriteRecipes}..remove(r.id)) : {...s.favoriteRecipes, r.id},
                  ),
                ),
          ),
        ],
      ),
      body: PageList(
        children: [
          Text(
            context.upper(l.mealType(r.mealType)),
            style: context.text.labelSmall?.copyWith(color: context.semantic.muted, letterSpacing: 1),
          ),
          const SizedBox(height: Space.xs),
          Text(r.name, style: context.text.headlineSmall),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              _Pill(Icons.schedule_rounded, l.minutesShort(r.prepMinutes)),
              _Pill(Icons.local_fire_department_rounded, l.foodCalories(r.calories)),
              _Pill(Icons.signal_cellular_alt_rounded, l.difficulty(r.difficulty)),
              _Pill(Icons.savings_rounded, cost),
            ],
          ),
          const SizedBox(height: Space.sm),
          Text(
            l.foodMacros(r.proteinG, r.carbsG, r.fatG),
            style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
          ),
          const SizedBox(height: Space.lg),
          Row(
            children: [
              Expanded(child: Text(l.foodIngredients, style: context.text.titleMedium)),
              if (r.hasAmounts) ...[
                IconButton.outlined(
                  visualDensity: VisualDensity.compact,
                  onPressed: servings > 1 ? () => setState(() => _servings = servings - 1) : null,
                  icon: const Icon(Icons.remove_rounded, size: 18),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                  child: Text(l.foodServings(servings), style: context.text.labelLarge),
                ),
                IconButton.outlined(
                  visualDensity: VisualDensity.compact,
                  onPressed: servings < 12 ? () => setState(() => _servings = servings + 1) : null,
                  icon: const Icon(Icons.add_rounded, size: 18),
                ),
              ],
            ],
          ),
          const SizedBox(height: Space.sm),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
            child: Column(
              children: [
                for (final (i, name) in r.ingredients.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          missing.contains(normalizeIngredient(name))
                              ? Icons.radio_button_unchecked_rounded
                              : Icons.check_circle_rounded,
                          size: 20,
                          color: missing.contains(normalizeIngredient(name))
                              ? context.semantic.muted
                              : context.colors.primary,
                        ),
                        const SizedBox(width: Space.md),
                        Expanded(child: Text(ingredientName(name, _lang))),
                        if (r.hasAmounts)
                          Text(
                            formatAmount(r.quantities[i], r.units[i], _lang, factor: factor),
                            style: context.text.bodyMedium?.copyWith(color: context.semantic.muted),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          if (missing.isEmpty)
            Text(l.foodHaveAll, style: context.text.bodySmall?.copyWith(color: context.colors.primary))
          else
            OutlinedButton.icon(
              onPressed: () async {
                final n = await ref
                    .read(actionsProvider)
                    .addShoppingItems(missing.map((x) => ingredientName(x, _lang)).toList());
                if (context.mounted) showSnack(context, l.foodAddedToList(n));
              },
              icon: const Icon(Icons.add_shopping_cart_rounded),
              label: Text('${l.foodAddMissing} (${missing.length})'),
            ),
          if (r.steps.isNotEmpty) ...[
            const SizedBox(height: Space.lg),
            Text(l.foodSteps, style: context.text.titleMedium),
            Text(l.foodStepsHint, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
            const SizedBox(height: Space.sm),
            for (final (i, step) in r.steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: AppCard(
                  onTap: () => setState(() => _done.contains(i) ? _done.remove(i) : _done.add(i)),
                  padding: const EdgeInsets.all(Space.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: _done.contains(i) ? context.colors.primary : context.colors.primaryContainer,
                        child: _done.contains(i)
                            ? Icon(Icons.check_rounded, size: 16, color: context.colors.onPrimary)
                            : Text('${i + 1}', style: context.text.labelMedium),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Text(
                          step,
                          style: context.text.bodyMedium?.copyWith(
                            decoration: _done.contains(i) ? TextDecoration.lineThrough : null,
                            color: _done.contains(i) ? context.semantic.muted : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: Space.md),
          FilledButton.icon(
            onPressed: () async {
              final today = ref.read(todayProvider);
              final current = ref.read(mealPlansProvider).list.where((m) => m.id == Dates.dayKey(today)).firstOrNull;
              final meals = [...?current?.meals.where((m) => m.mealType != r.mealType && m.id != r.id), r]
                ..sort((a, b) => a.mealType.index.compareTo(b.mealType.index));
              await ref.read(actionsProvider).saveMealPlan(today, meals, ai: false);
              if (context.mounted) showSnack(context, l.foodAddedToToday);
            },
            icon: const Icon(Icons.today_rounded),
            label: Text(l.foodAddToToday),
          ),
          const SizedBox(height: Space.md),
          Text(l.nutritionDisclaimer, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 6),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(Radii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.semantic.muted),
        const SizedBox(width: 6),
        Text(label, style: context.text.labelMedium),
      ],
    ),
  );
}
