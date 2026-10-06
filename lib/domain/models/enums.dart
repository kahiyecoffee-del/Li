/// Areas the user wants to improve; drives which Home cards are shown.
enum FocusArea { money, health, productivity, food, habits, planning }

enum TaskPriority { low, medium, high }

enum Recurrence { none, daily, weekly, monthly }

enum TaskCategory { work, personal, health, errands, learning, social, other }

enum TransactionType { expense, income }

enum ExpenseCategory {
  housing,
  food,
  transport,
  shopping,
  bills,
  entertainment,
  health,
  subscriptions,
  other;

  /// Fixed-cost categories are covered by the "fixed expenses" bucket of the
  /// budget instead of the daily discretionary allowance.
  bool get isFixed => this == housing || this == bills || this == subscriptions;
}

enum TransactionSource { manual, smartInput, receipt, ai }

enum HabitType {
  water,
  reading,
  exercise,
  meditation,
  sleep,
  custom;

  /// Habits that feed the Health sub-score.
  bool get isHealth => this == water || this == exercise || this == meditation || this == sleep;
}

enum MealType { breakfast, lunch, dinner, snack }

enum Difficulty { easy, medium, hard }

enum CookingSkill { beginner, intermediate, advanced }

enum FoodBudget { low, medium, high }

enum ShoppingCategory { produce, meat, dairy, bakery, pantry, frozen, drinks, household, personalCare, other }

enum MemoryCategory { preferences, goals, habits, food, budget, schedule }

enum NotificationFrequency { off, low, normal }

enum BudgetPeriod { week, month }
