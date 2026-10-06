import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/errors/app_failure.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/ids.dart';
import '../../core/utils/json.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/meal_engine.dart';
import '../../domain/engines/recipe_library.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/food.dart';
import '../../domain/models/user_profile.dart';
import '../../services/ai/ai_models.dart';

/// Validates AI recipes: clamps numbers, trims text, drops malformed meals.
List<Recipe> parseAiRecipes(Map<String, dynamic> result, String currency) {
  int clampInt(Map<String, dynamic> m, String k, int max) => J.integer(m, k).clamp(0, max);
  return J
      .mapList(result, 'meals')
      .take(6)
      .map((m) {
        final name = J.str(m, 'name').trim();
        final ingredients = J
            .strList(m, 'ingredients')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s.length < 60)
            .take(20)
            .toList();
        if (name.isEmpty || name.length > 80 || ingredients.isEmpty) return null;
        final cost = J.dbl(m, 'estimatedCost');
        return Recipe(
          id: 'ai_${newId()}',
          name: name,
          mealType: J.enumByName(MealType.values, m['mealType'], MealType.lunch),
          ingredients: ingredients,
          steps: J
              .strList(m, 'steps')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty && s.length < 300)
              .take(12)
              .toList(),
          calories: clampInt(m, 'calories', 3000),
          proteinG: clampInt(m, 'proteinG', 300),
          carbsG: clampInt(m, 'carbsG', 500),
          fatG: clampInt(m, 'fatG', 300),
          prepMinutes: clampInt(m, 'prepMinutes', 600),
          difficulty: J.enumByName(Difficulty.values, m['difficulty'], Difficulty.easy),
          estimatedCostMinor: cost > 0 && cost < 1e6 ? (cost * 100).round() : null,
          currency: currency,
          aiGenerated: true,
        );
      })
      .whereType<Recipe>()
      .toList();
}

class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  bool _aiBusy = false;

  List<Recipe> _localSuggestions(UserProfile p, DateTime day) => const MealEngine().suggestDay(
    recipes: RecipeLibrary.all(Localizations.localeOf(context).languageCode),
    prefs: p.food,
    pantry: (ref.read(pantryProvider).list).map((x) => x.name),
    day: day,
  );

  Future<void> _generateAi(UserProfile p, DateTime day) async {
    setState(() => _aiBusy = true);
    try {
      final r = await ref.read(servicesProvider).ai.task(AiTaskType.mealPlan, {
        'date': Dates.dayKey(day),
        'locale': Localizations.localeOf(context).languageCode,
        'currency': p.currency,
        'preferences': p.food.toJson(),
        'pantry': (ref.read(pantryProvider).list).map((x) => x.name).take(40).toList(),
        'mealTypes': ['breakfast', 'lunch', 'dinner'],
      });
      ref.read(creditsProvider.notifier).set(r.credits);
      final meals = parseAiRecipes(r.result, p.currency);
      if (meals.isEmpty) throw const AppFailure(FailureKind.unknown);
      await ref.read(actionsProvider).saveMealPlan(day, meals, ai: true);
    } catch (e) {
      if (!mounted) return;
      if (e is AppFailure && e.kind == FailureKind.quotaExceeded) {
        showSnack(
          context,
          context.l10n.errorQuota,
          action: SnackBarAction(label: context.l10n.premium, onPressed: () => context.push('/premium?from=meals')),
        );
      } else {
        showSnack(context, context.l10n.failure(e));
      }
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider).value ?? UserProfile.empty();
    final today = ref.watch(todayProvider);
    final plan = (ref.watch(mealPlansProvider).list).where((m) => m.id == Dates.dayKey(today)).firstOrNull;
    final meals = plan?.meals ?? _localSuggestions(profile, today);
    final total = meals.fold(0, (s, m) => s + m.calories);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.foodWhatToEat),
        actions: [
          IconButton(
            tooltip: l.foodPreferences,
            icon: const Icon(Icons.tune),
            onPressed: () => _editPrefs(context, profile),
          ),
        ],
      ),
      body: PageList(
        children: [
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(actionsProvider).saveMealPlan(today, _localSuggestions(profile, today), ai: false),
                icon: const Icon(Icons.kitchen_outlined),
                label: Text(l.foodRefreshLocal),
              ),
              if (ref.watch(servicesProvider).cloudEnabled)
                FilledButton.icon(
                  onPressed: _aiBusy ? null : () => _generateAi(profile, today),
                  icon: _aiBusy
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(l.foodGenerateAi),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(
            '${l.foodCalories(total)} · ${l.nutritionDisclaimer}',
            style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
          ),
          const SizedBox(height: Space.sm),
          ...meals.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: RecipeCard(recipe: m),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editPrefs(BuildContext context, UserProfile p) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _FoodPrefsSheet(profile: p),
  );
}

class RecipeCard extends ConsumerWidget {
  const RecipeCard({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final cost = recipe.estimatedCostMinor != null
        ? l.foodEstimatedCost(fmt.money(recipe.estimatedCostMinor!))
        : recipe.tags.contains('cost:low')
        ? l.foodCostLow
        : recipe.tags.contains('cost:high')
        ? l.foodCostHigh
        : l.foodCostMedium;
    return AppCard(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        builder: (_) => _RecipeDetail(recipe: recipe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.upper(l.mealType(recipe.mealType)),
                style: context.text.labelSmall?.copyWith(color: context.semantic.muted, letterSpacing: 1),
              ),
              const Spacer(),
              if (recipe.aiGenerated) Icon(Icons.auto_awesome, size: 16, color: context.colors.primary),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(recipe.name, style: context.text.titleLarge),
          const SizedBox(height: Space.xs),
          Text(
            '${l.foodCalories(recipe.calories)} · ${l.foodMacros(recipe.proteinG, recipe.carbsG, recipe.fatG)}',
            style: context.text.bodySmall,
          ),
          Text(
            '${l.minutesShort(recipe.prepMinutes)} · ${l.difficulty(recipe.difficulty)} · $cost',
            style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
          ),
        ],
      ),
    );
  }
}

class _RecipeDetail extends ConsumerWidget {
  const _RecipeDetail({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final pantry = (ref.watch(pantryProvider).list).map((p) => p.name);
    final missing = const MealEngine().matchPantry([recipe], pantry).first.missing;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
        children: [
          Text(recipe.name, style: context.text.headlineSmall),
          const SizedBox(height: Space.sm),
          Text(
            '${l.foodCalories(recipe.calories)} · ${l.foodMacros(recipe.proteinG, recipe.carbsG, recipe.fatG)} · ${l.minutesShort(recipe.prepMinutes)}',
          ),
          SectionTitle(l.foodIngredients),
          ...recipe.ingredients.map(
            (i) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                missing.contains(normalizeIngredient(i)) ? Icons.radio_button_unchecked : Icons.check_circle,
                size: 20,
              ),
              title: Text(i),
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Text(l.foodMissing(missing.join(', ')), style: context.text.bodySmall),
            const SizedBox(height: Space.sm),
            OutlinedButton.icon(
              onPressed: () async {
                final n = await ref.read(actionsProvider).addShoppingItems(missing);
                if (context.mounted) showSnack(context, l.foodAddedToList(n));
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(l.foodAddMissing),
            ),
          ],
          if (recipe.steps.isNotEmpty) ...[
            SectionTitle(l.foodSteps),
            for (final (i, s) in recipe.steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: Text('${i + 1}. $s'),
              ),
          ],
          const SizedBox(height: Space.md),
          Text(l.nutritionDisclaimer, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
        ],
      ),
    );
  }
}

class _FoodPrefsSheet extends ConsumerStatefulWidget {
  const _FoodPrefsSheet({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_FoodPrefsSheet> createState() => _FoodPrefsSheetState();
}

class _FoodPrefsSheetState extends ConsumerState<_FoodPrefsSheet> {
  late FoodPreferences _p = widget.profile.food;
  late final _avoid = TextEditingController(text: [..._p.allergies, ..._p.dislikes].join(', '));

  @override
  void dispose() {
    _avoid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget chips<T>(List<T> values, T selected, String Function(T) label, void Function(T) on) => Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: values
          .map(
            (v) => ChoiceChip(label: Text(label(v)), selected: v == selected, onSelected: (_) => setState(() => on(v))),
          )
          .toList(),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.page, 0, Space.page, MediaQuery.viewInsetsOf(context).bottom + Space.xl),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.foodPreferences, style: context.text.titleLarge),
            const SizedBox(height: Space.lg),
            Text(l.onbDiet, style: context.text.titleSmall),
            const SizedBox(height: Space.sm),
            chips(
              const ['none', 'vegetarian', 'vegan', 'pescatarian', 'keto', 'halal', 'glutenFree'],
              _p.diet,
              l.diet,
              (v) => _p = _p.copyWith(diet: v),
            ),
            const SizedBox(height: Space.lg),
            Text(l.foodSkill, style: context.text.titleSmall),
            const SizedBox(height: Space.sm),
            chips(CookingSkill.values, _p.skill, l.cookingSkill, (v) => _p = _p.copyWith(skill: v)),
            const SizedBox(height: Space.lg),
            Text(l.foodBudget, style: context.text.titleSmall),
            const SizedBox(height: Space.sm),
            chips(FoodBudget.values, _p.budget, l.foodBudgetLabel, (v) => _p = _p.copyWith(budget: v)),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _avoid,
              decoration: InputDecoration(labelText: l.onbAllergies, hintText: l.onbAllergiesHint),
            ),
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: () async {
                final avoid = _avoid.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                await ref
                    .read(actionsProvider)
                    .saveProfile(
                      widget.profile.copyWith(
                        food: _p.copyWith(allergies: avoid, dislikes: const []),
                      ),
                    );
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
