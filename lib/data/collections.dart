import '../domain/models/ai_models.dart';
import '../domain/models/care.dart';
import '../domain/models/entity.dart';
import '../domain/models/food.dart';
import '../domain/models/habit.dart';
import '../domain/models/money_models.dart';
import '../domain/models/progress.dart';
import '../domain/models/routine_goal.dart';
import '../domain/models/saved_item.dart';
import '../domain/models/task_item.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/wellbeing.dart';

/// Registry of every persisted collection.
abstract final class Collections {
  static const List<EntityCodec<Entity>> all = [
    UserProfile.codec,
    TaskItem.codec,
    MoneyTransaction.codec,
    Budget.codec,
    Habit.codec,
    HabitLog.codec,
    MoodLog.codec,
    SleepLog.codec,
    JournalEntry.codec,
    MealPlan.codec,
    PantryItem.codec,
    ShoppingItem.codec,
    AiMemory.codec,
    AiConversation.codec,
    DailyScoreRecord.codec,
    DailyGoalsRecord.codec,
    AchievementRecord.codec,
    SavedItem.codec,
    SavingsGoal.codec,
    RecurringBill.codec,
    Routine.codec,
    LifeGoal.codec,
    Debt.codec,
    Medication.codec,
    MedDose.codec,
  ];

  static List<String> get names => all.map((c) => c.collection).toList();

  /// Collections replicated to Firestore (journal and AI chats stay local).
  static List<String> get synced => all.where((c) => c.syncs).map((c) => c.collection).toList();
}
