import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../domain/engines/meal_engine.dart';
import '../../domain/engines/recipe_library.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/food.dart';
import '../../domain/models/user_profile.dart';

/// Lets the user choose a dish for one meal by hand: recipes of that meal
/// type (or all of them), favorites and what can be cooked from the pantry
/// first. Returns the chosen recipe or null.
Future<Recipe?> pickMeal(BuildContext context, MealType type) => showModalBottomSheet<Recipe>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _MealPicker(type: type),
);

class _MealPicker extends ConsumerStatefulWidget {
  const _MealPicker({required this.type});
  final MealType type;

  @override
  ConsumerState<_MealPicker> createState() => _MealPickerState();
}

class _MealPickerState extends ConsumerState<_MealPicker> {
  String _query = '';
  bool _allTypes = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final prefs = (ref.watch(profileProvider).value ?? UserProfile.empty()).food;
    final favorites = ref.watch(settingsProvider.select((s) => s.favoriteRecipes));
    final pantry = ref.watch(pantryProvider).list.map((p) => p.name);
    final pool = const MealEngine()
        .eligible(RecipeLibrary.all(lang), prefs)
        .where((r) => _allTypes || r.mealType == widget.type)
        .where((r) => recipeSearch(r, _query, lang))
        .toList();
    final matches = const MealEngine().matchPantry(pool, pantry)
      ..sort((a, b) {
        final fa = favorites.contains(a.recipe.id) ? 0 : 1, fb = favorites.contains(b.recipe.id) ? 0 : 1;
        return fa != fb ? fa - fb : a.missing.length.compareTo(b.missing.length);
      });
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, controller) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.foodPickTitle(l.mealType(widget.type)), style: context.text.titleLarge),
                  const SizedBox(height: Space.md),
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: l.foodSearchHint,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(l.foodShowAllTypes),
                    value: _allTypes,
                    onChanged: (v) => setState(() => _allTypes = v),
                  ),
                ],
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(child: Text(l.foodNoRecipes))
                  : ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
                      itemCount: matches.length,
                      itemBuilder: (_, i) {
                        final m = matches[i];
                        final fav = favorites.contains(m.recipe.id);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () => Navigator.pop(context, m.recipe),
                          title: Text(m.recipe.name),
                          subtitle: Text(
                            '${l.minutesShort(m.recipe.prepMinutes)} · ${l.foodCalories(m.recipe.calories)} · '
                            '${m.missing.isEmpty ? l.foodHaveAll : l.foodMissingCount(m.missing.length)}',
                          ),
                          trailing: fav
                              ? Icon(Icons.favorite_rounded, size: 18, color: context.colors.error)
                              : const Icon(Icons.add_circle_outline_rounded),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
