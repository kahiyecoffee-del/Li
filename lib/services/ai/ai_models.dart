import '../../core/utils/json.dart';
import '../../domain/ai/ai_action.dart';
import '../../domain/models/enums.dart';

/// Daily AI usage as reported (and enforced) by the backend.
class AiCredits {
  const AiCredits({
    required this.used,
    required this.dailyLimit,
    required this.bonus,
    required this.premium,
    required this.rewardedAdsLeft,
  });

  factory AiCredits.fromJson(Map<String, dynamic> j) => AiCredits(
    used: J.integer(j, 'used'),
    dailyLimit: J.integer(j, 'limit'),
    bonus: J.integer(j, 'bonus'),
    premium: J.boolean(j, 'premium'),
    rewardedAdsLeft: J.integer(j, 'rewardedRemaining'),
  );

  static const unknown = AiCredits(used: 0, dailyLimit: 0, bonus: 0, premium: false, rewardedAdsLeft: 0);

  final int used;
  final int dailyLimit;

  /// Extra credits earned today from rewarded ads.
  final int bonus;
  final bool premium;
  final int rewardedAdsLeft;

  int get remaining => premium ? 999 : (dailyLimit + bonus - used).clamp(0, 9999);
  bool get exhausted => !premium && remaining == 0;
  bool get canEarnMore => !premium && rewardedAdsLeft > 0;
}

class AiMemorySuggestion {
  const AiMemorySuggestion(this.category, this.content);

  final MemoryCategory category;
  final String content;
}

class AiChatResponse {
  const AiChatResponse({
    required this.reply,
    required this.actions,
    required this.memorySuggestions,
    required this.credits,
    this.rawActions = const [],
    this.summary,
    this.rejectedActions = 0,
  });

  final String reply;

  /// JSON of the actions that passed validation (persisted with the message
  /// and re-validated when shown again).
  final List<Map<String, dynamic>> rawActions;

  /// Already validated by [AiActionValidator]; each still needs confirmation.
  final List<AiAction> actions;
  final List<AiMemorySuggestion> memorySuggestions;
  final AiCredits credits;

  /// Updated rolling conversation summary, when the backend compressed history.
  final String? summary;

  /// Number of proposed actions dropped by client-side validation.
  final int rejectedActions;
}

enum AiTaskType {
  parseExpense('parse_expense'),
  mealPlan('meal_plan'),
  weeklySummary('weekly_summary'),
  monthlySummary('monthly_summary'),
  newsWhy('news_why'),
  categorizeShopping('categorize_shopping');

  const AiTaskType(this.wire);

  final String wire;
}

class AiTaskResponse {
  const AiTaskResponse(this.result, this.credits);

  final Map<String, dynamic> result;
  final AiCredits credits;
}

class AiTurn {
  const AiTurn(this.fromUser, this.text);

  final bool fromUser;
  final String text;

  Map<String, dynamic> toJson() => {'role': fromUser ? 'user' : 'assistant', 'text': text};
}

class AiChatRequest {
  const AiChatRequest({
    required this.message,
    required this.history,
    required this.summary,
    required this.context,
    required this.memories,
    required this.memoryEnabled,
    this.toSummarize = const [],
  });

  final String message;

  /// Turns leaving the history window, to be folded into [summary] by the
  /// backend (conversation compression).
  final List<AiTurn> toSummarize;

  /// Recent turns only (older ones are represented by [summary]).
  final List<AiTurn> history;
  final String summary;

  /// Only the data scopes the user allowed (see `AiContextBuilder`).
  final Map<String, dynamic> context;
  final List<Map<String, String>> memories;
  final bool memoryEnabled;

  Map<String, dynamic> toJson() => {
    'message': message,
    'history': history.map((h) => h.toJson()).toList(),
    'summary': summary,
    'context': context,
    'memories': memories,
    'memoryEnabled': memoryEnabled,
    if (toSummarize.isNotEmpty) 'toSummarize': toSummarize.map((h) => h.toJson()).toList(),
  };
}
