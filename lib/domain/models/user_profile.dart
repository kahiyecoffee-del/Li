import '../../core/utils/dates.dart';
import '../../core/utils/json.dart';
import 'entity.dart';
import 'enums.dart';

/// Food preferences collected during onboarding and in the Food screen.
class FoodPreferences {
  const FoodPreferences({
    this.diet = 'none',
    this.allergies = const [],
    this.dislikes = const [],
    this.skill = CookingSkill.intermediate,
    this.budget = FoodBudget.medium,
    this.dailyCalorieTarget,
  });

  factory FoodPreferences.fromJson(Map<String, dynamic> j) => FoodPreferences(
    diet: J.str(j, 'diet', 'none'),
    allergies: J.strList(j, 'allergies'),
    dislikes: J.strList(j, 'dislikes'),
    skill: J.enumByName(CookingSkill.values, j['skill'], CookingSkill.intermediate),
    budget: J.enumByName(FoodBudget.values, j['budget'], FoodBudget.medium),
    dailyCalorieTarget: J.intOrNull(j, 'dailyCalorieTarget'),
  );

  /// One of: none, vegetarian, vegan, pescatarian, keto, halal, glutenFree.
  final String diet;
  final List<String> allergies;
  final List<String> dislikes;
  final CookingSkill skill;
  final FoodBudget budget;
  final int? dailyCalorieTarget;

  Map<String, dynamic> toJson() => {
    'diet': diet,
    'allergies': allergies,
    'dislikes': dislikes,
    'skill': skill.name,
    'budget': budget.name,
    if (dailyCalorieTarget != null) 'dailyCalorieTarget': dailyCalorieTarget,
  };

  FoodPreferences copyWith({
    String? diet,
    List<String>? allergies,
    List<String>? dislikes,
    CookingSkill? skill,
    FoodBudget? budget,
    int? dailyCalorieTarget,
  }) => FoodPreferences(
    diet: diet ?? this.diet,
    allergies: allergies ?? this.allergies,
    dislikes: dislikes ?? this.dislikes,
    skill: skill ?? this.skill,
    budget: budget ?? this.budget,
    dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
  );
}

/// Manually chosen or geolocated place used for weather.
class Place {
  const Place({required this.name, required this.latitude, required this.longitude});

  factory Place.fromJson(Map<String, dynamic> j) =>
      Place(name: J.str(j, 'name'), latitude: J.dbl(j, 'lat'), longitude: J.dbl(j, 'lon'));

  final String name;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {'name': name, 'lat': latitude, 'lon': longitude};
}

/// The user's profile. Stored as a single record with id [UserProfile.singletonId].
class UserProfile extends Entity {
  const UserProfile({
    required super.updatedAt,
    super.deleted,
    this.name = '',
    this.focusAreas = const {},
    this.currency = 'USD',
    this.monthlyIncomeMinor,
    this.fixedExpensesMinor,
    this.savingsGoalMinor,
    this.wakeTime,
    this.sleepTime,
    this.food = const FoodPreferences(),
    this.place,
    this.newsTopics = const ['technology', 'world'],
    this.onboardingCompleted = false,
    this.installedAt,
  }) : super(id: singletonId);

  factory UserProfile.empty() => UserProfile(updatedAt: DateTime.now());

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    name: J.str(j, 'name'),
    focusAreas: J.strList(j, 'focusAreas').map((n) => J.enumByName(FocusArea.values, n, FocusArea.planning)).toSet(),
    currency: J.str(j, 'currency', 'USD'),
    monthlyIncomeMinor: J.intOrNull(j, 'monthlyIncomeMinor'),
    fixedExpensesMinor: J.intOrNull(j, 'fixedExpensesMinor'),
    savingsGoalMinor: J.intOrNull(j, 'savingsGoalMinor'),
    wakeTime: J.intOrNull(j, 'wakeTime') == null ? null : DayTime(J.integer(j, 'wakeTime')),
    sleepTime: J.intOrNull(j, 'sleepTime') == null ? null : DayTime(J.integer(j, 'sleepTime')),
    food: FoodPreferences.fromJson(J.map(j, 'food')),
    place: j['place'] is Map ? Place.fromJson(J.map(j, 'place')) : null,
    newsTopics: j['newsTopics'] is List ? J.strList(j, 'newsTopics') : const ['technology', 'world'],
    onboardingCompleted: J.boolean(j, 'onboardingCompleted'),
    installedAt: J.date(j, 'installedAt'),
  );

  static const singletonId = 'profile';

  static const codec = EntityCodec<UserProfile>(collection: 'profile', fromJson: UserProfile.fromJson);

  final String name;
  final Set<FocusArea> focusAreas;
  final String currency;
  final int? monthlyIncomeMinor;
  final int? fixedExpensesMinor;
  final int? savingsGoalMinor;
  final DayTime? wakeTime;
  final DayTime? sleepTime;
  final FoodPreferences food;
  final Place? place;
  final List<String> newsTopics;
  final bool onboardingCompleted;
  final DateTime? installedAt;

  bool get hasBudget => (monthlyIncomeMinor ?? 0) > 0;

  /// Target sleep in minutes derived from the daily routine (default 8h).
  int get sleepTargetMinutes {
    if (wakeTime == null || sleepTime == null) return 8 * 60;
    var diff = wakeTime!.minutes - sleepTime!.minutes;
    if (diff <= 0) diff += 24 * 60;
    return diff.clamp(5 * 60, 11 * 60);
  }

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'focusAreas': focusAreas.map((e) => e.name).toList(),
    'currency': currency,
    if (monthlyIncomeMinor != null) 'monthlyIncomeMinor': monthlyIncomeMinor,
    if (fixedExpensesMinor != null) 'fixedExpensesMinor': fixedExpensesMinor,
    if (savingsGoalMinor != null) 'savingsGoalMinor': savingsGoalMinor,
    if (wakeTime != null) 'wakeTime': wakeTime!.minutes,
    if (sleepTime != null) 'sleepTime': sleepTime!.minutes,
    'food': food.toJson(),
    if (place != null) 'place': place!.toJson(),
    'newsTopics': newsTopics,
    'onboardingCompleted': onboardingCompleted,
    if (installedAt != null) 'installedAt': installedAt!.millisecondsSinceEpoch,
  };

  UserProfile copyWith({
    String? name,
    Set<FocusArea>? focusAreas,
    String? currency,
    int? monthlyIncomeMinor,
    int? fixedExpensesMinor,
    int? savingsGoalMinor,
    DayTime? wakeTime,
    DayTime? sleepTime,
    FoodPreferences? food,
    Place? place,
    List<String>? newsTopics,
    bool? onboardingCompleted,
    DateTime? installedAt,
    bool clearPlace = false,
  }) => UserProfile(
    updatedAt: DateTime.now(),
    name: name ?? this.name,
    focusAreas: focusAreas ?? this.focusAreas,
    currency: currency ?? this.currency,
    monthlyIncomeMinor: monthlyIncomeMinor ?? this.monthlyIncomeMinor,
    fixedExpensesMinor: fixedExpensesMinor ?? this.fixedExpensesMinor,
    savingsGoalMinor: savingsGoalMinor ?? this.savingsGoalMinor,
    wakeTime: wakeTime ?? this.wakeTime,
    sleepTime: sleepTime ?? this.sleepTime,
    food: food ?? this.food,
    place: clearPlace ? null : (place ?? this.place),
    newsTopics: newsTopics ?? this.newsTopics,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    installedAt: installedAt ?? this.installedAt,
  );
}
