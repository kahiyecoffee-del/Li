import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/derived_providers.dart';
import '../../app/ml_providers.dart';
import '../../app/providers.dart';
import '../../core/errors/app_failure.dart';
import '../../core/utils/ids.dart';
import '../../domain/ai/ai_action.dart';
import '../../domain/ai/ai_action_validator.dart';
import '../../domain/models/ai_models.dart';
import '../../domain/models/user_profile.dart';
import '../../services/ai/ai_action_executor.dart';
import '../../services/ai/ai_context_builder.dart';
import '../../services/ai/ai_models.dart';
import '../../services/ai/memory_manager.dart';
import '../../services/ai/offline/offline_prompt.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/config/feature_flags.dart';
import '../../services/config/remote_config_service.dart';
import '../../services/settings/app_settings.dart';

enum ActionStatus { pending, done, dismissed, failed }

class ChatState {
  const ChatState({required this.conversation, this.sending = false, this.lastError, this.savedMemory});

  final AiConversation conversation;
  final bool sending;
  final Object? lastError;

  /// Memory auto-saved from the last reply (shown with an Undo action).
  final AiMemory? savedMemory;

  ChatState copyWith({
    AiConversation? conversation,
    bool? sending,
    Object? lastError,
    bool clearError = false,
    AiMemory? savedMemory,
    bool clearMemory = false,
  }) => ChatState(
    conversation: conversation ?? this.conversation,
    sending: sending ?? this.sending,
    lastError: clearError ? null : (lastError ?? this.lastError),
    savedMemory: clearMemory ? null : (savedMemory ?? this.savedMemory),
  );
}

/// Orchestrates one assistant conversation: builds the consented context,
/// calls the backend, persists messages locally and executes confirmed
/// actions.
class ChatController extends AsyncNotifier<ChatState> {
  static const _conversationId = 'current';

  /// Turns sent verbatim; older ones are folded into the rolling summary.
  static const historyWindow = 8;

  @override
  Future<ChatState> build() async {
    final repos = ref.watch(reposProvider);
    final c =
        await repos.conversations.get(_conversationId) ??
        AiConversation(id: _conversationId, updatedAt: DateTime.now(), messages: const []);
    return ChatState(conversation: c);
  }

  ChatState get _s => state.requireValue;

  MemoryManager memoryManager() {
    final s = ref.read(servicesProvider);
    final premium = ref.read(isPremiumProvider);
    final unlimited = premium || !s.flags.isPremiumOnly(PremiumFeature.aiMemoryUnlimited);
    return MemoryManager(
      ref.read(reposProvider).memories,
      limit: unlimited ? null : s.remote.getInt(RcKeys.freeMemoryLimit),
      enabled: ref.read(settingsProvider).aiMemoryEnabled,
    );
  }

  Future<void> _persist(AiConversation c) async {
    await ref.read(reposProvider).conversations.save(c);
    state = AsyncData(_s.copyWith(conversation: c));
  }

  Future<void> send(String text, {required String locale}) async {
    final msg = text.trim();
    if (msg.isEmpty || _s.sending) return;
    final services = ref.read(servicesProvider);
    final now = DateTime.now();
    final user = ChatMessage(id: newId(), role: ChatRole.user, text: msg, at: now);
    var conv = _s.conversation.copyWith(messages: [..._s.conversation.messages, user]);
    state = AsyncData(_s.copyWith(conversation: conv, sending: true, clearError: true, clearMemory: true));
    await ref.read(reposProvider).conversations.save(conv);
    unawaited(services.analytics.log(AnalyticsEvent.aiMessageSent, {'length_bucket': msg.length ~/ 50}));

    if (shouldUseOffline()) {
      await _replyLocally(conv, user, msg, locale);
      return;
    }

    try {
      final usable = conv.messages.where((m) => !m.failed).toList();
      final prior = usable.sublist(0, usable.length - 1);
      final window = prior.length > historyWindow ? prior.sublist(prior.length - historyWindow) : prior;
      final leaving = prior.length > historyWindow
          ? prior.sublist(conv.summarizedCount.clamp(0, prior.length - historyWindow), prior.length - historyWindow)
          : const <ChatMessage>[];
      final request = AiChatRequest(
        message: msg,
        history: window.map((m) => AiTurn(m.role == ChatRole.user, m.text)).toList(),
        summary: conv.summary,
        toSummarize: leaving.map((m) => AiTurn(m.role == ChatRole.user, m.text)).toList(),
        context: await _context(locale),
        memories: await memoryManager().forPrompt(),
        memoryEnabled: ref.read(settingsProvider).aiMemoryEnabled,
      );
      final res = await services.ai.chat(request);
      ref.read(creditsProvider.notifier).set(res.credits);

      final reply = ChatMessage(
        id: newId(),
        role: ChatRole.assistant,
        text: res.reply,
        at: DateTime.now(),
        actions: res.rawActions.map((r) => {'raw': r, 'status': ActionStatus.pending.name}).toList(),
      );
      conv = conv.copyWith(
        messages: [...conv.messages, reply],
        summary: res.summary ?? conv.summary,
        summarizedCount: res.summary != null ? prior.length - window.length : conv.summarizedCount,
      );
      for (final a in res.actions) {
        unawaited(services.analytics.log(AnalyticsEvent.aiActionStarted, {'intent': a.intent.wire}));
      }
      AiMemory? saved;
      if (res.memorySuggestions.isNotEmpty) {
        final mm = memoryManager();
        for (final m in res.memorySuggestions) {
          final (r, mem) = await mm.save(m.category, m.content);
          if (r == MemorySaveResult.saved) saved = mem;
        }
      }
      await _persist(conv);
      state = AsyncData(_s.copyWith(sending: false, savedMemory: saved));
    } catch (e) {
      // Network trouble: answer on device if an offline model is installed.
      if (e is AppFailure &&
          (e.kind == FailureKind.network || e.kind == FailureKind.timeout || e.kind == FailureKind.unavailable) &&
          services.offlineModel.current.ready) {
        await _replyLocally(conv, user, msg, locale);
        return;
      }
      final failed = ChatMessage(id: user.id, role: ChatRole.user, text: msg, at: now, failed: true);
      conv = conv.copyWith(messages: [...conv.messages.where((m) => m.id != user.id), failed]);
      await _persist(conv);
      state = AsyncData(_s.copyWith(sending: false, lastError: e));
      if (e is AppFailure && e.kind == FailureKind.quotaExceeded) {
        unawaited(services.analytics.log(AnalyticsEvent.aiLimitReached));
        await ref.read(creditsProvider.notifier).refresh();
      }
    }
  }

  /// Whether the next message is answered by the on-device model.
  bool shouldUseOffline() {
    final services = ref.read(servicesProvider);
    if (!services.offlineModel.current.ready) return false;
    final online = ref.read(onlineProvider).value ?? true;
    return ref.read(settingsProvider).preferOfflineAi || !online || !services.aiEnabled;
  }

  Future<void> _replyLocally(AiConversation conv, ChatMessage user, String msg, String locale) async {
    final services = ref.read(servicesProvider);
    try {
      final history = conv.messages
          .where((m) => !m.failed && m.id != user.id)
          .map((m) => AiTurn(m.role == ChatRole.user, m.text))
          .toList();
      final text = await services.offlineModel.reply(
        system: OfflinePrompt.system(locale: locale, context: await _context(locale)),
        history: history,
        message: msg,
      );
      final reply = ChatMessage(id: newId(), role: ChatRole.assistant, text: text, at: DateTime.now(), local: true);
      await _persist(conv.copyWith(messages: [...conv.messages, reply]));
      state = AsyncData(_s.copyWith(sending: false));
      unawaited(services.analytics.log(AnalyticsEvent.aiMessageSent, {'offline': 1}));
    } catch (e) {
      final failed = ChatMessage(id: user.id, role: ChatRole.user, text: msg, at: user.at, failed: true);
      await _persist(conv.copyWith(messages: [...conv.messages.where((m) => m.id != user.id), failed]));
      state = AsyncData(_s.copyWith(sending: false, lastError: e));
    }
  }

  Future<void> retry(ChatMessage failed, {required String locale}) async {
    await _persist(
      _s.conversation.copyWith(messages: _s.conversation.messages.where((m) => m.id != failed.id).toList()),
    );
    await send(failed.text, locale: locale);
  }

  Future<Map<String, dynamic>> _context(String locale) async {
    final services = ref.read(servicesProvider);
    final scopes = ref.read(settingsProvider).aiScopes;
    return const AiContextBuilder().build(
      now: DateTime.now(),
      locale: locale,
      timeZone: await services.notifications.timeZoneName(),
      profile: ref.read(profileProvider).value ?? UserProfile.empty(),
      scopes: scopes,
      score: ref.read(lifeScoreProvider).score,
      budget: ref.read(budgetSnapshotProvider),
      tasks: ref.read(tasksProvider).list,
      habits: ref.read(habitsProvider).list,
      habitLogs: ref.read(habitLogsProvider).list,
      moods: ref.read(moodsProvider).list,
      sleeps: ref.read(sleepsProvider).list,
      pantry: ref.read(pantryProvider).list,
      journal: scopes.contains(AiDataScope.journal) ? await ref.read(reposProvider).journal.getAll() : const [],
    );
  }

  /// Validates the stored JSON again; returns null if it no longer passes.
  static AiAction? actionOf(Map<String, dynamic> stored) => const AiActionValidator().validate(stored['raw']).action;

  static ActionStatus statusOf(Map<String, dynamic> stored) =>
      ActionStatus.values.firstWhere((s) => s.name == stored['status'], orElse: () => ActionStatus.pending);

  Future<void> resolveAction(String messageId, int index, {required bool confirm, required String languageCode}) async {
    final conv = _s.conversation;
    final msg = conv.messages.firstWhere((m) => m.id == messageId);
    final stored = msg.actions[index];
    final action = actionOf(stored);
    var status = ActionStatus.dismissed;
    final analytics = ref.read(servicesProvider).analytics;
    if (confirm && action != null) {
      try {
        final outcome = await AiActionExecutor(
          repos: ref.read(reposProvider),
          profile: ref.read(profileProvider).value ?? UserProfile.empty(),
          memory: memoryManager(),
          languageCode: languageCode,
          shoppingCategorizer: ref.read(localModelsNowProvider).shoppingCategorizer,
        ).execute(action);
        status = outcome.success ? ActionStatus.done : ActionStatus.failed;
        unawaited(
          analytics.log(AnalyticsEvent.aiActionConfirmed, {
            'intent': action.intent.wire,
            'success': outcome.success ? 1 : 0,
          }),
        );
      } catch (_) {
        status = ActionStatus.failed;
      }
    } else {
      unawaited(analytics.log(AnalyticsEvent.aiActionDismissed, {'intent': action?.intent.wire ?? 'invalid'}));
    }
    final actions = [...msg.actions]..[index] = {...stored, 'status': status.name};
    await _persist(
      conv.copyWith(messages: conv.messages.map((m) => m.id == messageId ? m.copyWith(actions: actions) : m).toList()),
    );
  }

  Future<void> undoMemory() async {
    final m = _s.savedMemory;
    if (m == null) return;
    await memoryManager().delete(m.id);
    state = AsyncData(_s.copyWith(clearMemory: true));
  }

  Future<void> newChat() async {
    await ref.read(reposProvider).conversations.delete(_conversationId);
    state = AsyncData(
      ChatState(
        conversation: AiConversation(id: _conversationId, updatedAt: DateTime.now(), messages: const []),
      ),
    );
  }
}

final chatProvider = AsyncNotifierProvider<ChatController, ChatState>(ChatController.new);
