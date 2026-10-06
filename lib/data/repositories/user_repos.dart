import '../../domain/models/ai_models.dart';
import '../../domain/models/food.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/money_models.dart';
import '../../domain/models/progress.dart';
import '../../domain/models/saved_item.dart';
import '../../domain/models/task_item.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/wellbeing.dart';
import '../local/local_store.dart';
import 'journal_repository.dart';
import 'repository.dart';

/// All repositories for the signed-in user.
class UserRepos {
  UserRepos(
    LocalStore store, {
    required JournalKeyStore journalKeys,
    void Function()? onWrite,
    DateTime Function()? clock,
  }) : profile = Repository(store, UserProfile.codec, onLocalWrite: onWrite, clock: clock),
       tasks = Repository(store, TaskItem.codec, onLocalWrite: onWrite, clock: clock),
       transactions = Repository(store, MoneyTransaction.codec, onLocalWrite: onWrite, clock: clock),
       budgets = Repository(store, Budget.codec, onLocalWrite: onWrite, clock: clock),
       habits = Repository(store, Habit.codec, onLocalWrite: onWrite, clock: clock),
       habitLogs = Repository(store, HabitLog.codec, onLocalWrite: onWrite, clock: clock),
       moods = Repository(store, MoodLog.codec, onLocalWrite: onWrite, clock: clock),
       sleeps = Repository(store, SleepLog.codec, onLocalWrite: onWrite, clock: clock),
       mealPlans = Repository(store, MealPlan.codec, onLocalWrite: onWrite, clock: clock),
       pantry = Repository(store, PantryItem.codec, onLocalWrite: onWrite, clock: clock),
       shopping = Repository(store, ShoppingItem.codec, onLocalWrite: onWrite, clock: clock),
       memories = Repository(store, AiMemory.codec, onLocalWrite: onWrite, clock: clock),
       conversations = Repository(store, AiConversation.codec, clock: clock),
       scores = Repository(store, DailyScoreRecord.codec, onLocalWrite: onWrite, clock: clock),
       goals = Repository(store, DailyGoalsRecord.codec, onLocalWrite: onWrite, clock: clock),
       achievements = Repository(store, AchievementRecord.codec, onLocalWrite: onWrite, clock: clock),
       saved = Repository(store, SavedItem.codec, onLocalWrite: onWrite, clock: clock),
       savingsGoals = Repository(store, SavingsGoal.codec, onLocalWrite: onWrite, clock: clock),
       bills = Repository(store, RecurringBill.codec, onLocalWrite: onWrite, clock: clock),
       journal = JournalRepository(Repository(store, JournalEntry.codec, clock: clock), journalKeys);

  final Repository<UserProfile> profile;
  final Repository<TaskItem> tasks;
  final Repository<MoneyTransaction> transactions;
  final Repository<Budget> budgets;
  final Repository<Habit> habits;
  final Repository<HabitLog> habitLogs;
  final Repository<MoodLog> moods;
  final Repository<SleepLog> sleeps;
  final Repository<MealPlan> mealPlans;
  final Repository<PantryItem> pantry;
  final Repository<ShoppingItem> shopping;
  final Repository<AiMemory> memories;
  final Repository<AiConversation> conversations;
  final Repository<DailyScoreRecord> scores;
  final Repository<DailyGoalsRecord> goals;
  final Repository<AchievementRecord> achievements;
  final Repository<SavedItem> saved;
  final Repository<SavingsGoal> savingsGoals;
  final Repository<RecurringBill> bills;
  final JournalRepository journal;
}
