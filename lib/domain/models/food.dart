import '../../core/utils/json.dart';
import 'entity.dart';
import 'enums.dart';

/// A recipe, either from the built-in library or AI-generated.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.mealType,
    required this.ingredients,
    this.steps = const [],
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.prepMinutes = 0,
    this.difficulty = Difficulty.easy,
    this.estimatedCostMinor,
    this.currency,
    this.tags = const [],
    this.aiGenerated = false,
    this.servings = 0,
    this.quantities = const [],
    this.units = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
    id: J.str(j, 'id'),
    name: J.str(j, 'name'),
    mealType: J.enumByName(MealType.values, j['mealType'], MealType.lunch),
    ingredients: J.strList(j, 'ingredients'),
    steps: J.strList(j, 'steps'),
    calories: J.integer(j, 'calories'),
    proteinG: J.integer(j, 'proteinG'),
    carbsG: J.integer(j, 'carbsG'),
    fatG: J.integer(j, 'fatG'),
    prepMinutes: J.integer(j, 'prepMinutes'),
    difficulty: J.enumByName(Difficulty.values, j['difficulty'], Difficulty.easy),
    estimatedCostMinor: J.intOrNull(j, 'estimatedCostMinor'),
    currency: J.strOrNull(j, 'currency'),
    tags: J.strList(j, 'tags'),
    aiGenerated: J.boolean(j, 'aiGenerated'),
    servings: J.integer(j, 'servings'),
    quantities: (j['quantities'] is List)
        ? [for (final q in j['quantities'] as List) q is num ? q.toDouble() : 0.0]
        : const [],
    units: J.strList(j, 'units'),
  );

  final String id;
  final String name;
  final MealType mealType;

  /// Normalized lowercase ingredient names (used for pantry matching).
  final List<String> ingredients;
  final List<String> steps;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int prepMinutes;
  final Difficulty difficulty;
  final int? estimatedCostMinor;
  final String? currency;

  /// Diet tags, e.g. `vegetarian`, `vegan`, `glutenFree`.
  final List<String> tags;
  final bool aiGenerated;

  /// How many people the [quantities] are for; 0 when unknown (AI recipes).
  final int servings;

  /// Amount of each ingredient (same order as [ingredients]) and its unit
  /// (`''` for pieces, `g`, `ml`, `tbsp`, `tsp`, `clove`, `slice`, `pinch`,
  /// `bunch`, `can`). Empty when unknown.
  final List<double> quantities;
  final List<String> units;

  bool get hasAmounts => servings > 0 && quantities.length == ingredients.length && units.length == ingredients.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mealType': mealType.name,
    'ingredients': ingredients,
    'steps': steps,
    'calories': calories,
    'proteinG': proteinG,
    'carbsG': carbsG,
    'fatG': fatG,
    'prepMinutes': prepMinutes,
    'difficulty': difficulty.name,
    if (estimatedCostMinor != null) 'estimatedCostMinor': estimatedCostMinor,
    if (currency != null) 'currency': currency,
    'tags': tags,
    'aiGenerated': aiGenerated,
    if (servings > 0) 'servings': servings,
    if (quantities.isNotEmpty) 'quantities': quantities,
    if (units.isNotEmpty) 'units': units,
  };
}

/// Meals planned for one day (id = day key).
class MealPlan extends Entity {
  const MealPlan({required super.id, required super.updatedAt, super.deleted, required this.meals});

  factory MealPlan.fromJson(Map<String, dynamic> j) => MealPlan(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    meals: J.mapList(j, 'meals').map(Recipe.fromJson).toList(),
  );

  static const codec = EntityCodec<MealPlan>(collection: 'meal_plans', fromJson: MealPlan.fromJson);

  final List<Recipe> meals;

  int get totalCalories => meals.fold(0, (s, m) => s + m.calories);

  @override
  Map<String, dynamic> toJson() => {'meals': meals.map((m) => m.toJson()).toList()};
}

class PantryItem extends Entity {
  const PantryItem({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.name,
    this.quantity,
    this.expiresOn,
  });

  factory PantryItem.fromJson(Map<String, dynamic> j) => PantryItem(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    name: J.str(j, 'name'),
    quantity: J.strOrNull(j, 'quantity'),
    expiresOn: J.date(j, 'expiresOn'),
  );

  static const codec = EntityCodec<PantryItem>(collection: 'pantry_items', fromJson: PantryItem.fromJson);

  final String name;
  final String? quantity;
  final DateTime? expiresOn;

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    if (quantity != null) 'quantity': quantity,
    if (expiresOn != null) 'expiresOn': expiresOn!.millisecondsSinceEpoch,
  };
}

class ShoppingItem extends Entity {
  const ShoppingItem({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.name,
    required this.category,
    this.quantity,
    this.checked = false,
    required this.createdAt,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> j) => ShoppingItem(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    name: J.str(j, 'name'),
    category: J.enumByName(ShoppingCategory.values, j['category'], ShoppingCategory.other),
    quantity: J.strOrNull(j, 'quantity'),
    checked: J.boolean(j, 'checked'),
    createdAt: J.date(j, 'createdAt') ?? Meta.updated(j),
  );

  static const codec = EntityCodec<ShoppingItem>(collection: 'shopping_items', fromJson: ShoppingItem.fromJson);

  final String name;
  final ShoppingCategory category;
  final String? quantity;
  final bool checked;
  final DateTime createdAt;

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category.name,
    if (quantity != null) 'quantity': quantity,
    'checked': checked,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  ShoppingItem copyWith({bool? checked, ShoppingCategory? category, bool? deleted}) => ShoppingItem(
    id: id,
    updatedAt: DateTime.now(),
    deleted: deleted ?? this.deleted,
    name: name,
    category: category ?? this.category,
    quantity: quantity,
    checked: checked ?? this.checked,
    createdAt: createdAt,
  );
}
