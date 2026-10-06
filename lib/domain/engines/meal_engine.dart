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
  'un': 'flour',
  'şeker': 'sugar',
  'seker': 'sugar',
  'tarçın': 'cinnamon',
  'tarcin': 'cinnamon',
  'çilek': 'strawberry',
  'strawberries': 'strawberry',
  'zeytin': 'olives',
  'olive': 'olives',
  'maydanoz': 'parsley',
  'nane': 'mint',
  'kuru fasulye': 'beans',
  'fasulye': 'beans',
  'white beans': 'beans',
  'kabak': 'zucchini',
  'courgette': 'zucchini',
  'dereotu': 'dill',
  'tahin': 'tahini',
  'patlıcan': 'eggplant',
  'patlican': 'eggplant',
  'aubergine': 'eggplant',
  'taze fasulye': 'green beans',
  'karides': 'shrimp',
  'prawns': 'shrimp',
  'dana eti': 'beef',
  'kuşbaşı': 'beef',
  'mısır': 'corn',
  'misir': 'corn',
  'balık': 'fish',
  'balik': 'fish',
  'bezelye': 'peas',
  'hurma': 'dates',
  'fıstık ezmesi': 'peanut butter',
  'beyaz peynir': 'cheese',
  'kaşar': 'cheese',
  'kasar': 'cheese',
  'feta': 'cheese',
  'şehriye': 'pasta',
  'spaghetti': 'pasta',
  'spagetti': 'pasta',
  'wrap': 'tortilla',
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
  'flour': 'un',
  'sugar': 'şeker',
  'cinnamon': 'tarçın',
  'strawberry': 'çilek',
  'olives': 'zeytin',
  'parsley': 'maydanoz',
  'mint': 'nane',
  'beans': 'kuru fasulye',
  'zucchini': 'kabak',
  'dill': 'dereotu',
  'tahini': 'tahin',
  'eggplant': 'patlıcan',
  'green beans': 'taze fasulye',
  'shrimp': 'karides',
  'beef': 'dana eti',
  'corn': 'mısır',
  'fish': 'balık',
  'peas': 'bezelye',
  'dates': 'hurma',
  'peanut butter': 'fıstık ezmesi',
  'sucuk': 'sucuk',
};

/// Display name of a canonical (English) ingredient in [languageCode].
String ingredientName(String canonical, String languageCode) =>
    languageCode == 'tr' ? (_trNames[normalizeIngredient(canonical)] ?? canonical) : canonical;

/// Recipes that use what the user has and need the fewest extra items.
List<PantryMatch> bestForIngredients(List<Recipe> recipes, Iterable<String> have, {int limit = 3}) {
  final h = have.map(normalizeIngredient).toSet();
  int used(Recipe r) => r.ingredients.map(normalizeIngredient).where(h.contains).length;
  final matches = const MealEngine().matchPantry(recipes, h).where((m) => used(m.recipe) > 0).toList()
    // Fewest things to buy first, then the ones that use more of what you have.
    ..sort((a, b) {
      final m = a.missing.length.compareTo(b.missing.length);
      return m != 0 ? m : used(b.recipe).compareTo(used(a.recipe));
    });
  return matches.take(limit).toList();
}

/// Every ingredient name the app knows (English, Turkish and aliases),
/// lower-case. Used to read "yumurta domates zeytin yağı" without commas.
Set<String> get knownIngredientNames => {
  ..._aliases.keys,
  ..._aliases.values,
  ..._trNames.keys,
  ..._trNames.values,
  ..._staples,
  'zeytin yağı',
};

/// Recipe filters on the Recipes tab.
enum RecipeFilter { favorites, canMake, quick, vegetarian, highProtein, budget }

bool recipeMatches(Recipe r, RecipeFilter f, {Set<String> favorites = const {}, Set<String>? pantry}) => switch (f) {
  RecipeFilter.favorites => favorites.contains(r.id),
  RecipeFilter.canMake => pantry != null && const MealEngine().matchPantry([r], pantry).first.makeable,
  RecipeFilter.quick => r.prepMinutes <= 20,
  RecipeFilter.vegetarian => r.tags.contains('vegetarian') || r.tags.contains('vegan'),
  RecipeFilter.highProtein => r.proteinG >= 25,
  RecipeFilter.budget => r.tags.contains('cost:low'),
};

/// Whether [query] (name or ingredient, Turkish or English) matches [r].
bool recipeSearch(Recipe r, String query, String lang) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (r.name.toLowerCase().contains(q)) return true;
  final canon = normalizeIngredient(q);
  return r.ingredients.any((i) => i.contains(canon) || ingredientName(i, lang).toLowerCase().contains(q));
}

/// "1½", "250 g", "2 yemek kaşığı" — an ingredient amount scaled from the
/// recipe's own servings to [servings].
String formatAmount(double qty, String unit, String lang, {double factor = 1}) {
  var v = qty * factor;
  if (unit == 'g' || unit == 'ml') {
    v = v >= 100 ? (v / 10).round() * 10 : (v / 5).round() * 5;
    if (v == 0) v = 5;
    if (v >= 1000) return '${_num(v / 1000)} ${unit == 'g' ? 'kg' : 'L'}';
    return '${v.round()} $unit';
  }
  final n = _fraction(v);
  final tr = lang == 'tr';
  final many = v > 1;
  final word = switch (unit) {
    'tbsp' => tr ? 'yemek kaşığı' : 'tbsp',
    'tsp' => tr ? 'tatlı kaşığı' : 'tsp',
    'clove' => tr ? 'diş' : (many ? 'cloves' : 'clove'),
    'slice' => tr ? 'dilim' : (many ? 'slices' : 'slice'),
    'pinch' => tr ? 'tutam' : 'pinch',
    'bunch' => tr ? 'demet' : 'bunch',
    'can' => tr ? 'kutu' : (many ? 'cans' : 'can'),
    _ => tr ? 'adet' : '',
  };
  return word.isEmpty ? n : '$n $word';
}

String _num(double v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

/// Rounds to the nearest quarter and writes it as a fraction ("1½", "¾").
String _fraction(double v) {
  final q = (v * 4).round();
  if (q == 0) return '¼';
  final whole = q ~/ 4;
  final part = switch (q % 4) {
    1 => '¼',
    2 => '½',
    3 => '¾',
    _ => '',
  };
  return whole == 0 ? part : '$whole$part';
}

/// Plans [days] days from [start]: one recipe per meal, no repeats within
/// the week when there are enough recipes, preferring what the pantry has.
List<List<Recipe>> suggestWeek({
  required List<Recipe> recipes,
  required FoodPreferences prefs,
  required Iterable<String> pantry,
  required DateTime start,
  int days = 7,
}) {
  final ok = const MealEngine().eligible(recipes, prefs);
  final matches = const MealEngine().matchPantry(ok, pantry);
  final used = <String>{};
  final seed = Dates.daysBetween(DateTime(2024), start);
  final out = <List<Recipe>>[];
  for (var d = 0; d < days; d++) {
    final day = <Recipe>[];
    for (final t in const [MealType.breakfast, MealType.lunch, MealType.dinner]) {
      final ofType = matches.where((m) => m.recipe.mealType == t).toList();
      if (ofType.isEmpty) continue;
      var pool = ofType.where((m) => !used.contains(m.recipe.id)).toList();
      if (pool.isEmpty) {
        // Ran out: allow repeats again for this meal type.
        used.removeAll(ofType.map((m) => m.recipe.id));
        pool = ofType;
      }
      // Keep the pantry-friendliest third, then rotate by date.
      final best = pool.take((pool.length / 3).ceil().clamp(1, pool.length)).toList();
      final pick = best[(seed + d * 7 + t.index) % best.length].recipe;
      used.add(pick.id);
      day.add(pick);
    }
    out.add(day);
  }
  return out;
}

/// Everything the planned [meals] need that is not in [pantry] (staples
/// excluded), each canonical ingredient once.
List<String> missingForMeals(Iterable<Recipe> meals, Iterable<String> pantry) {
  final have = pantry.map(normalizeIngredient).toSet();
  final out = <String>{};
  for (final r in meals) {
    for (final i in r.ingredients.map(normalizeIngredient)) {
      if (!_staples.contains(i) && !have.contains(i)) out.add(i);
    }
  }
  return out.toList();
}
