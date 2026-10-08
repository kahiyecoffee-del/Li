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

import 'package:intl/intl.dart';

import '../../domain/engines/meal_engine.dart';
import '../../domain/engines/recipe_library.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/food.dart';
import '../../domain/models/user_profile.dart';
import '../premium/native_slot.dart';
import 'meal_picker.dart';
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
  const FoodScreen({super.key, this.initialTab = 0});

  /// 0 today, 1 recipes, 2 week.
  final int initialTab;

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
  bool _aiBusy = false;
  final _filters = <RecipeFilter>{};
  MealType? _type;
  String _query = '';

  String get _lang => Localizations.localeOf(context).languageCode;
  Iterable<String> get _pantry => ref.read(pantryProvider).list.map((x) => x.name);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<Recipe> _localSuggestions(UserProfile p, DateTime day) =>
      const MealEngine().suggestDay(recipes: RecipeLibrary.all(_lang), prefs: p.food, pantry: _pantry, day: day);

  Future<void> _generateAi(UserProfile p, DateTime day) async {
    setState(() => _aiBusy = true);
    try {
      final r = await ref.read(servicesProvider).ai.task(AiTaskType.mealPlan, {
        'date': Dates.dayKey(day),
        'locale': _lang,
        'currency': p.currency,
        'preferences': p.food.toJson(),
        'pantry': _pantry.take(40).toList(),
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
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l.foodTabToday),
            Tab(text: l.foodTabRecipes),
            Tab(text: l.foodTabWeek),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: [_today(profile), _recipes(profile), _week(profile)]),
    );
  }

  // ------------------------------------------------------------------ today

  Widget _today(UserProfile profile) {
    final l = context.l10n;
    final today = ref.watch(todayProvider);
    final plan = ref.watch(mealPlansProvider).list.where((m) => m.id == Dates.dayKey(today)).firstOrNull;
    final meals = plan?.meals ?? _localSuggestions(profile, today);
    final total = meals.fold(0, (s, m) => s + m.calories);
    final pantry = ref.watch(pantryProvider).list.map((x) => x.name).toList();
    final canMake = pantry.isEmpty
        ? 0
        : const MealEngine()
              .matchPantry(const MealEngine().eligible(RecipeLibrary.all(_lang), profile.food), pantry)
              .where((m) => m.makeable)
              .length;
    return PageList(
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
        if (canMake > 0) ...[
          const SizedBox(height: Space.md),
          AppCard(
            onTap: () {
              setState(
                () => _filters
                  ..clear()
                  ..add(RecipeFilter.canMake),
              );
              _tabs.animateTo(1);
            },
            child: Row(
              children: [
                const IconBubble(icon: Icons.kitchen_rounded, accent: Accent.food, size: 36),
                const SizedBox(width: Space.md),
                Expanded(child: Text(l.foodCanMakeNow(canMake))),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.md),
        Text(
          '${l.foodCalories(total)} · ${l.nutritionDisclaimer}',
          style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
        ),
        const SizedBox(height: Space.sm),
        ...meals.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: RecipeCard(
              recipe: m,
              onChange: () => _choose(today, m.mealType, base: meals),
              onRemove: () => ref.read(actionsProvider).removeMeal(today, m.mealType, base: meals),
            ),
          ),
        ),
        if (MealType.values.any((t) => !meals.any((m) => m.mealType == t)))
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final t in MealType.values.where((t) => !meals.any((m) => m.mealType == t)))
                OutlinedButton.icon(
                  onPressed: () => _choose(today, t, base: meals),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('${l.foodAddMeal}: ${l.mealType(t)}'),
                ),
            ],
          ),
      ],
    );
  }

  /// Lets the user pick the [slot] meal of [day] by hand.
  Future<void> _choose(DateTime day, MealType slot, {List<Recipe> base = const []}) async {
    final r = await pickMeal(context, slot);
    if (r == null || !mounted) return;
    await ref.read(actionsProvider).setMeal(day, slot, r, base: base);
  }

  // ---------------------------------------------------------------- recipes

  Widget _recipes(UserProfile profile) {
    final l = context.l10n;
    final favorites = ref.watch(settingsProvider.select((s) => s.favoriteRecipes));
    final pantry = ref.watch(pantryProvider).list.map((x) => x.name).toSet();
    final all = const MealEngine().eligible(RecipeLibrary.all(_lang), profile.food);
    final list = all
        .where((r) => _type == null || r.mealType == _type)
        .where((r) => recipeSearch(r, _query, _lang))
        .where((r) => _filters.every((f) => recipeMatches(r, f, favorites: favorites, pantry: pantry)))
        .toList();
    final missing = {for (final m in const MealEngine().matchPantry(list, pantry)) m.recipe.id: m.missing.length};
    list.sort((a, b) {
      final fa = favorites.contains(a.id) ? 0 : 1, fb = favorites.contains(b.id) ? 0 : 1;
      if (fa != fb) return fa - fb;
      return missing[a.id]!.compareTo(missing[b.id]!);
    });
    String filterLabel(RecipeFilter f) => switch (f) {
      RecipeFilter.favorites => l.foodFilterFavorites,
      RecipeFilter.canMake => l.foodFilterCanMake,
      RecipeFilter.quick => l.foodFilterQuick,
      RecipeFilter.vegetarian => l.foodFilterVeg,
      RecipeFilter.highProtein => l.foodFilterProtein,
      RecipeFilter.budget => l.foodFilterBudget,
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.xl),
      children: [
        TextField(
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: l.foodSearchHint),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: Space.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final t in [null, ...MealType.values])
                Padding(
                  padding: const EdgeInsets.only(right: Space.sm),
                  child: ChoiceChip(
                    label: Text(t == null ? l.foodAllMeals : l.mealType(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            for (final f in RecipeFilter.values)
              FilterChip(
                label: Text(filterLabel(f)),
                selected: _filters.contains(f),
                onSelected: (on) => setState(() => on ? _filters.add(f) : _filters.remove(f)),
              ),
          ],
        ),
        const SizedBox(height: Space.md),
        Text(l.foodRecipeCount(list.length), style: context.text.labelMedium?.copyWith(color: context.semantic.muted)),
        const SizedBox(height: Space.sm),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xl),
            child: Text(l.foodNoRecipes, textAlign: TextAlign.center),
          ),
        for (final (i, r) in list.indexed) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: _RecipeTile(recipe: r, missing: missing[r.id]!, favorite: favorites.contains(r.id)),
          ),
          if (NativeSlot.after(ref, i)) const NativeSlot(),
        ],
      ],
    );
  }

  // ------------------------------------------------------------------- week

  Widget _week(UserProfile profile) {
    final l = context.l10n;
    final today = ref.watch(todayProvider);
    final days = [for (var i = 0; i < 7; i++) Dates.addDays(today, i)];
    final plans = {for (final p in ref.watch(mealPlansProvider).list) p.id: p};
    final week = [for (final d in days) plans[Dates.dayKey(d)]];
    final planned = week.whereType<MealPlan>().toList();
    final avgKcal = planned.isEmpty ? 0 : planned.fold(0, (s, p) => s + p.totalCalories) ~/ planned.length;
    final loc = Localizations.localeOf(context).toString();
    return PageList(
      children: [
        Text(l.foodWeekIntro, style: context.text.bodyMedium),
        const SizedBox(height: Space.md),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            FilledButton.icon(
              onPressed: () async {
                final plan = suggestWeek(
                  recipes: RecipeLibrary.all(_lang),
                  prefs: profile.food,
                  pantry: _pantry,
                  start: today,
                );
                for (final (i, meals) in plan.indexed) {
                  await ref.read(actionsProvider).saveMealPlan(days[i], meals, ai: false);
                }
                if (mounted) showSnack(context, l.foodWeekPlanned);
              },
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(planned.length == 7 ? l.foodWeekReplan : l.foodWeekPlan),
            ),
            if (planned.isNotEmpty)
              FilledButton.tonalIcon(
                onPressed: () async {
                  final missing = missingForMeals(planned.expand((p) => p.meals), _pantry);
                  if (missing.isEmpty) {
                    showSnack(context, l.foodWeekNothingMissing);
                    return;
                  }
                  final n = await ref
                      .read(actionsProvider)
                      .addShoppingItems(missing.map((x) => ingredientName(x, _lang)).toList());
                  if (!mounted) return;
                  showSnack(
                    context,
                    l.foodAddedToList(n),
                    action: SnackBarAction(label: l.actShopping, onPressed: () => context.push('/shopping')),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: Text(l.foodWeekShopping),
              ),
          ],
        ),
        if (avgKcal > 0) ...[
          const SizedBox(height: Space.sm),
          Text(l.foodWeekCalories(avgKcal), style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
        ],
        const SizedBox(height: Space.md),
        for (final (i, d) in days.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i == 0 ? l.today : (i == 1 ? l.tomorrow : DateFormat.EEEE(loc).add_MMMd().format(d)),
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: Space.xs),
                  if (week[i] == null)
                    Text(l.foodNotPlanned, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
                  for (final t in MealType.values)
                    if (week[i]?.meals.where((m) => m.mealType == t).firstOrNull case final m?)
                      _WeekMealRow(
                        type: t,
                        name: m.name,
                        onOpen: () => openRecipe(context, m),
                        onChange: () => _choose(d, t),
                      )
                    else if (t != MealType.snack)
                      _WeekMealRow(type: t, onChange: () => _choose(d, t)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _editPrefs(BuildContext context, UserProfile p) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _FoodPrefsSheet(profile: p),
  );
}

/// Opens the full recipe page (library recipes by id, others as data).
void openRecipe(BuildContext context, Recipe r) => context.push('/recipe/${Uri.encodeComponent(r.id)}', extra: r);

class _WeekMealRow extends StatelessWidget {
  const _WeekMealRow({required this.type, this.name, this.onOpen, required this.onChange});

  final MealType type;
  final String? name;
  final VoidCallback? onOpen;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return InkWell(
      onTap: onOpen ?? onChange,
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(l.mealType(type), style: context.text.labelSmall?.copyWith(color: context.semantic.muted)),
          ),
          Expanded(
            child: Text(
              name ?? l.foodPick,
              style: name == null
                  ? context.text.bodyMedium?.copyWith(color: context.colors.primary)
                  : context.text.bodyMedium,
            ),
          ),
          IconButton(
            tooltip: name == null ? l.foodPick : l.foodChange,
            visualDensity: VisualDensity.compact,
            icon: Icon(name == null ? Icons.add_rounded : Icons.swap_horiz_rounded, size: 20),
            onPressed: onChange,
          ),
        ],
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe, required this.missing, required this.favorite});

  final Recipe recipe;
  final int missing;
  final bool favorite;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      onTap: () => openRecipe(context, recipe),
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          IconBubble(icon: _mealIcon(recipe.mealType), accent: Accent.food, size: 40),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.name, style: context.text.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${l.minutesShort(recipe.prepMinutes)} · ${l.foodCalories(recipe.calories)}',
                  style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (favorite) Icon(Icons.favorite_rounded, size: 16, color: context.colors.error),
              Text(
                missing == 0 ? l.foodHaveAll : l.foodMissingCount(missing),
                style: context.text.labelSmall?.copyWith(
                  color: missing == 0 ? context.colors.primary : context.semantic.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _mealIcon(MealType t) => switch (t) {
  MealType.breakfast => Icons.free_breakfast_rounded,
  MealType.lunch => Icons.lunch_dining_rounded,
  MealType.dinner => Icons.dinner_dining_rounded,
  MealType.snack => Icons.cookie_rounded,
};

class RecipeCard extends ConsumerWidget {
  const RecipeCard({super.key, required this.recipe, this.onChange, this.onRemove});

  final Recipe recipe;

  /// Shown as "Change" / "Remove" when set (manual meal choice).
  final VoidCallback? onChange;
  final VoidCallback? onRemove;

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
      onTap: () => openRecipe(context, recipe),
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
          if (onChange != null || onRemove != null)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                children: [
                  if (onRemove != null) TextButton(onPressed: onRemove, child: Text(l.foodRemoveMeal)),
                  if (onChange != null)
                    TextButton.icon(
                      onPressed: onChange,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text(l.foodChange),
                    ),
                ],
              ),
            ),
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
