import '../../core/utils/dates.dart';
import '../models/enums.dart';
import '../models/food.dart';
import '../models/user_profile.dart';

/// Ingredients assumed available in any kitchen (not required for matching).
const _staples = {'salt', 'black pepper', 'water', 'olive oil', 'oil', 'spices'};

/// Canonical ingredient names for en/tr pantry entries.
const _aliases = <String, String>{
  'eggs': 'egg',
  'yumurta': 'egg',
  'tavuk': 'chicken',
  'chicken breast': 'chicken',
  'pirinç': 'rice',
  'pirinc': 'rice',
  'domates': 'tomato',
  'tomatoes': 'tomato',
  'yoğurt': 'yogurt',
  'yogurt': 'yogurt',
  'yoghurt': 'yogurt',
  'süt': 'milk',
  'sut': 'milk',
  'soğan': 'onion',
  'sogan': 'onion',
  'onions': 'onion',
  'biber': 'pepper',
  'peppers': 'pepper',
  'peynir': 'cheese',
  'ekmek': 'bread',
  'makarna': 'pasta',
  'mercimek': 'lentil',
  'lentils': 'lentil',
  'muz': 'banana',
  'bananas': 'banana',
  'yulaf': 'oats',
  'bal': 'honey',
  'kuruyemiş': 'nuts',
  'ton balığı': 'tuna',
  'marul': 'lettuce',
  'salatalık': 'cucumber',
  'limon': 'lemon',
  'nohut': 'chickpeas',
  'chickpea': 'chickpeas',
  'patates': 'potato',
  'potatoes': 'potato',
  'somon': 'salmon',
  'brokoli': 'broccoli',
  'kıyma': 'mince',
  'kiyma': 'mince',
  'ground beef': 'mince',
  'ıspanak': 'spinach',
  'mantar': 'mushroom',
  'mushrooms': 'mushroom',
  'sarımsak': 'garlic',
  'tereyağı': 'butter',
  'tereyagi': 'butter',
  'havuç': 'carrot',
  'carrots': 'carrot',
  'bulgur': 'bulgur',
  'salça': 'tomato paste',
  'elma': 'apple',
  'apples': 'apple',
  'avokado': 'avocado',
  'lavaş': 'tortilla',
  'zeytinyağı': 'olive oil',
  'soya sosu': 'soy sauce',
};

String normalizeIngredient(String raw) {
  final s = raw.toLowerCase().trim();
  return _aliases[s] ?? s;
}

class PantryMatch {
  const PantryMatch(this.recipe, this.missing);

  final Recipe recipe;

  /// Required ingredients not in the pantry (staples excluded).
  final List<String> missing;

  bool get makeable => missing.isEmpty;
}

/// Deterministic meal suggestion and pantry matching.
class MealEngine {
  const MealEngine();

  /// Filters recipes the user can eat given diet, allergies and dislikes.
  List<Recipe> eligible(List<Recipe> recipes, FoodPreferences prefs) {
    final banned = {...prefs.allergies, ...prefs.dislikes}.map(normalizeIngredient).toSet();
    return recipes.where((r) {
      if (r.ingredients.map(normalizeIngredient).any(banned.contains)) return false;
      if (prefs.skill == CookingSkill.beginner && r.difficulty == Difficulty.hard) return false;
      if (prefs.budget == FoodBudget.low && r.tags.contains('cost:high')) return false;
      switch (prefs.diet) {
        case 'vegetarian':
          return r.tags.contains('vegetarian') || r.tags.contains('vegan');
        case 'vegan':
          return r.tags.contains('vegan');
        case 'pescatarian':
          return r.tags.contains('pescatarian') || r.tags.contains('vegetarian') || r.tags.contains('vegan');
        case 'glutenFree':
          return r.tags.contains('glutenFree');
        case 'keto':
          return r.carbsG <= 20;
        default:
          return true;
      }
    }).toList();
  }

  List<PantryMatch> matchPantry(List<Recipe> recipes, Iterable<String> pantry) {
    final have = pantry.map(normalizeIngredient).toSet();
    final out = recipes.map((r) {
      final missing = r.ingredients
          .map(normalizeIngredient)
          .where((i) => !_staples.contains(i) && !have.contains(i))
          .toList();
      return PantryMatch(r, missing);
    }).toList()..sort((a, b) => a.missing.length.compareTo(b.missing.length));
    return out;
  }

  /// Picks one recipe per meal type for [day]. Prefers recipes needing the
  /// fewest missing pantry items, rotating deterministically by date so the
  /// suggestions change daily but are stable within a day.
  List<Recipe> suggestDay({
    required List<Recipe> recipes,
    required FoodPreferences prefs,
    required Iterable<String> pantry,
    required DateTime day,
    List<MealType> types = const [MealType.breakfast, MealType.lunch, MealType.dinner],
  }) {
    final ok = eligible(recipes, prefs);
    final matches = matchPantry(ok, pantry);
    final seed = Dates.daysBetween(DateTime(2024), day);
    final out = <Recipe>[];
    for (final t in types) {
      final ofType = matches.where((m) => m.recipe.mealType == t).toList();
      if (ofType.isEmpty) continue;
      final fewest = ofType.first.missing.length;
      // Candidates within one missing ingredient of the best match.
      final pool = ofType.where((m) => m.missing.length <= fewest + 1).toList();
      out.add(pool[seed % pool.length].recipe);
    }
    return out;
  }
}

const _trNames = <String, String>{
  'apple': 'elma',
  'avocado': 'avokado',
  'banana': 'muz',
  'bread': 'ekmek',
  'broccoli': 'brokoli',
  'bulgur': 'bulgur',
  'butter': 'tereyağı',
  'carrot': 'havuç',
  'cheese': 'peynir',
  'chicken': 'tavuk',
  'chickpeas': 'nohut',
  'cucumber': 'salatalık',
  'egg': 'yumurta',
  'garlic': 'sarımsak',
  'honey': 'bal',
  'lemon': 'limon',
  'lentil': 'mercimek',
  'lettuce': 'marul',
  'milk': 'süt',
  'mince': 'kıyma',
  'mushroom': 'mantar',
  'nuts': 'kuruyemiş',
  'oats': 'yulaf',
  'olive oil': 'zeytinyağı',
  'onion': 'soğan',
  'pasta': 'makarna',
  'pepper': 'biber',
  'potato': 'patates',
  'rice': 'pirinç',
  'salmon': 'somon',
  'soy sauce': 'soya sosu',
  'spinach': 'ıspanak',
  'tomato': 'domates',
  'tomato paste': 'salça',
  'tortilla': 'lavaş',
  'tuna': 'ton balığı',
  'yogurt': 'yoğurt',
};

/// Display name of a canonical (English) ingredient in [languageCode].
String ingredientName(String canonical, String languageCode) =>
    languageCode == 'tr' ? (_trNames[normalizeIngredient(canonical)] ?? canonical) : canonical;

/// Recipes that use the most of what the user has, then need the least.
List<PantryMatch> bestForIngredients(List<Recipe> recipes, Iterable<String> have, {int limit = 3}) {
  final h = have.map(normalizeIngredient).toSet();
  int used(Recipe r) => r.ingredients.map(normalizeIngredient).where(h.contains).length;
  final matches = const MealEngine().matchPantry(recipes, h).where((m) => used(m.recipe) > 0).toList()
    ..sort((a, b) {
      final u = used(b.recipe).compareTo(used(a.recipe));
      return u != 0 ? u : a.missing.length.compareTo(b.missing.length);
    });
  return matches.take(limit).toList();
}
