import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/errors/app_failure.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../core/widgets/mascot.dart';
import '../../domain/ai/ai_action.dart';
import '../../domain/models/ai_models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../services/ads/ads_service.dart';
import '../../services/config/feature_flags.dart';
import '../../services/config/remote_config_service.dart';
import '../premium/rewarded.dart';
import '../shell/main_shell.dart';
import 'chat_controller.dart';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key, this.initialPrompt});

  /// Pre-filled question (e.g. from a Home card).
  final String? initialPrompt;

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _consumedPrompt;

  @override
  void didUpdateWidget(covariant AiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybePrefill();
  }

  @override
  void initState() {
    super.initState();
    _maybePrefill();
  }

  void _maybePrefill() {
    final p = widget.initialPrompt;
    if (p != null && p != _consumedPrompt) {
      _consumedPrompt = p;
      _input.text = p;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _locale => Localizations.localeOf(context).languageCode;

  Future<void> _send([String? text]) async {
    final t = text ?? _input.text;
    if (t.trim().isEmpty) return;
    _input.clear();
    await ref.read(chatProvider.notifier).send(t, locale: _locale);
    _scrollToEnd();
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      unawaited(_scroll.animateTo(_scroll.position.maxScrollExtent, duration: Motion.normal, curve: Motion.curve));
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final chat = ref.watch(chatProvider);
    final offlineReady = ref.watch(offlineModelStatusProvider).value?.ready ?? false;
    final cloud = ref.watch(servicesProvider).aiEnabled || offlineReady;
    // Re-evaluated on connectivity/settings changes.
    ref.watch(onlineProvider);
    ref.watch(settingsProvider.select((s) => s.preferOfflineAi));
    final offlineNext = offlineReady && ref.read(chatProvider.notifier).shouldUseOffline();
    ref.listen(chatProvider.select((s) => s.value?.savedMemory), (_, m) {
      if (m != null) {
        showSnack(
          context,
          l.aiMemorySaved(m.content),
          action: SnackBarAction(label: l.undo, onPressed: () => ref.read(chatProvider.notifier).undoMemory()),
        );
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(l.aiTitle),
        actions: [
          IconButton(
            tooltip: l.aiNewChat,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => ref.read(chatProvider.notifier).newChat(),
          ),
          const ProfileButton(),
        ],
      ),
      body: chat.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e),
        data: (s) => Column(
          children: [
            Expanded(
              child: s.conversation.messages.isEmpty
                  ? _Empty(onPick: _send, enabled: cloud)
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.lg),
                      itemCount: s.conversation.messages.length + (s.sending ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == s.conversation.messages.length) return const _Typing();
                        return _Bubble(message: s.conversation.messages[i], locale: _locale);
                      },
                    ),
            ),
            if (s.lastError != null) _ErrorBar(error: s.lastError!),
            const _CreditsLine(),
            if (offlineNext)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.page),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.offline_bolt_outlined, size: 18),
                    label: Text(context.l10n.offlineModeChip),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            _InputBar(controller: _input, enabled: !s.sending && cloud, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty({required this.onPick, required this.enabled});

  final ValueChanged<String> onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final scopes = ref.watch(settingsProvider).aiScopes;
    final suggestions = [l.aiSuggestion1, l.aiSuggestion2, l.aiSuggestion3, l.aiSuggestion4, l.aiSuggestion5];
    return ListView(
      padding: const EdgeInsets.all(Space.page),
      children: [
        const SizedBox(height: Space.xl),
        Center(child: Mascot(mood: enabled ? MascotMood.happy : MascotMood.curious, size: 150)),
        const SizedBox(height: Space.md),
        Text(l.aiEmptyTitle, style: context.text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: Space.xl),
        if (!enabled) ...[
          FadeSlideIn(
            delay: Motion.fast,
            child: HeroBanner(
              gradient: Gradients.forest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.aiSetupTitle, style: context.text.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: Space.xs),
                  Text(
                    l.aiSetupBody,
                    style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
                  ),
                  const SizedBox(height: Space.lg),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Palette.accent),
                    onPressed: () => context.push('/settings/offline-ai'),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(l.aiSetupCta),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: suggestions
              .map((s) => ActionChip(label: Text(s), onPressed: enabled ? () => onPick(s) : null))
              .toList(),
        ),
        const SizedBox(height: Space.xl),
        Text(
          l.aiDataNotice(scopes.isEmpty ? l.aiNoScopes : scopes.map(l.scopeShort).join(', ')),
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
        ),
        TextButton(onPressed: () => context.push('/settings/privacy'), child: Text(l.settingsPrivacy)),
        Text(
          l.aiDisclaimer,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
        ),
      ],
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Semantics(
        liveRegion: true,
        label: context.l10n.aiThinking,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(mood: MascotMood.thoughtful, size: 40, float: false),
            const SizedBox(width: Space.sm),
            Text(context.l10n.aiThinking, style: context.text.bodySmall),
          ],
        ),
      ),
    ),
  );
}

class _Bubble extends ConsumerWidget {
  const _Bubble({required this.message, required this.locale});

  final ChatMessage message;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = message.role == ChatRole.user;
    final bg = mine ? context.colors.primary : context.semantic.surfaceAlt;
    final fg = mine ? Colors.white : context.colors.onSurface;
    return Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (mine)
          Container(
            margin: const EdgeInsets.symmetric(vertical: Space.xs),
            padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
            decoration: BoxDecoration(
              color: mine ? null : bg,
              gradient: mine ? Gradients.forest : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(Radii.md),
                topRight: const Radius.circular(Radii.md),
                bottomLeft: Radius.circular(mine ? Radii.md : 6),
                bottomRight: Radius.circular(mine ? 6 : Radii.md),
              ),
            ),
            child: SelectableText(message.text, style: context.text.bodyMedium?.copyWith(color: fg)),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: Space.xs, right: Space.xs),
                child: Mascot(mood: MascotMood.happy, size: 30, float: false),
              ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: Space.xs),
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
                  decoration: BoxDecoration(
                    color: mine ? null : bg,
                    gradient: mine ? Gradients.forest : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(Radii.md),
                      topRight: const Radius.circular(Radii.md),
                      bottomLeft: Radius.circular(mine ? Radii.md : 6),
                      bottomRight: Radius.circular(mine ? 6 : Radii.md),
                    ),
                  ),
                  child: SelectableText(message.text, style: context.text.bodyMedium?.copyWith(color: fg)),
                ),
              ),
            ],
          ),
        if (message.local)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: Text(
              context.l10n.offlineAnswerLabel,
              style: context.text.labelSmall?.copyWith(color: context.semantic.muted),
            ),
          ),
        if (message.failed)
          TextButton.icon(
            onPressed: () => ref.read(chatProvider.notifier).retry(message, locale: locale),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(context.l10n.retry),
          ),
        for (var i = 0; i < message.actions.length; i++)
          _ActionCard(messageId: message.id, index: i, stored: message.actions[i]),
      ],
    );
  }
}

/// Every AI-proposed change is shown here and only runs after "Confirm".
class _ActionCard extends ConsumerWidget {
  const _ActionCard({required this.messageId, required this.index, required this.stored});

  final String messageId;
  final int index;
  final Map<String, dynamic> stored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final action = ChatController.actionOf(stored);
    if (action == null) return const SizedBox.shrink();
    final status = ChatController.statusOf(stored);
    final fmt = ref.fmt(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Container(
      margin: const EdgeInsets.only(bottom: Space.sm),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
      child: AppCard(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon(action), size: 20, color: context.colors.primary),
                const SizedBox(width: Space.sm),
                Expanded(child: Text(describeAction(l, fmt, action), style: context.text.titleSmall)),
              ],
            ),
            const SizedBox(height: Space.sm),
            switch (status) {
              ActionStatus.pending => Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ref
                        .read(chatProvider.notifier)
                        .resolveAction(messageId, index, confirm: false, languageCode: lang),
                    child: Text(l.dismiss),
                  ),
                  const SizedBox(width: Space.sm),
                  FilledButton(
                    onPressed: () => ref
                        .read(chatProvider.notifier)
                        .resolveAction(messageId, index, confirm: true, languageCode: lang),
                    child: Text(l.confirm),
                  ),
                ],
              ),
              ActionStatus.done => Text(
                '✓ ${l.aiActionDone}',
                style: context.text.labelMedium?.copyWith(color: context.semantic.positive),
              ),
              ActionStatus.dismissed => Text(
                l.aiActionDismissed,
                style: context.text.labelMedium?.copyWith(color: context.semantic.muted),
              ),
              ActionStatus.failed => Text(
                l.aiActionFailed,
                style: context.text.labelMedium?.copyWith(color: context.semantic.negative),
              ),
            },
          ],
        ),
      ),
    );
  }

  static IconData _icon(AiAction a) => switch (a) {
    CreateTaskAction _ => Icons.event_available_outlined,
    OptimizePlanAction _ => Icons.auto_fix_high,
    CreateBudgetAction _ => Icons.account_balance_wallet_outlined,
    AddExpenseAction _ => Icons.payments_outlined,
    SetSavingsGoalAction _ => Icons.savings_outlined,
    GenerateMealPlanAction _ => Icons.restaurant_menu_outlined,
    AddShoppingItemsAction _ => Icons.add_shopping_cart,
    CreateHabitAction _ => Icons.repeat_rounded,
    LogMoodAction _ => Icons.mood_outlined,
    SaveMemoryAction _ => Icons.psychology_outlined,
  };
}

/// Human-readable, localized description of a proposed action.
String describeAction(AppLocalizations l, Fmt fmt, AiAction a) => switch (a) {
  final CreateTaskAction t when t.scheduledAt != null => l.aiActionCreateTaskAt(t.title, fmt.dateTime(t.scheduledAt!)),
  final CreateTaskAction t when t.deadline != null => l.aiActionCreateTaskAt(t.title, fmt.weekdayDayMonth(t.deadline!)),
  final CreateTaskAction t => l.aiActionCreateTask(t.title),
  OptimizePlanAction _ => l.aiActionOptimize,
  final CreateBudgetAction b => l.aiActionBudget(l.budgetPeriod(b.period).toLowerCase(), fmt.money(b.amountMinor)),
  final AddExpenseAction e => l.aiActionExpense(
    fmt.money(e.amountMinor, cents: e.amountMinor % 100 != 0),
    l.expenseCategory(e.category),
  ),
  final SetSavingsGoalAction s => l.aiActionSavings(fmt.money(s.amountMinor)),
  final GenerateMealPlanAction m => l.aiActionMeal(fmt.weekdayDayMonth(m.date)),
  final AddShoppingItemsAction s => '${l.aiActionShopping(s.items.length)}: ${s.items.take(5).join(', ')}',
  final CreateHabitAction h => l.aiActionHabit(h.name),
  final LogMoodAction m => l.aiActionMood(l.mood(m.mood)),
  final SaveMemoryAction m => l.aiActionMemory(m.content),
};

class _ErrorBar extends ConsumerWidget {
  const _ErrorBar({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final quota = error is AppFailure && (error as AppFailure).kind == FailureKind.quotaExceeded;
    final unavailable = error is AppFailure && (error as AppFailure).kind == FailureKind.unavailable;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.sm),
      child: AppCard(
        padding: const EdgeInsets.all(Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(unavailable ? l.errorAiUnavailable : l.failure(error), style: context.text.bodyMedium),
            if (quota) ...[const SizedBox(height: Space.sm), const _EarnMore()],
          ],
        ),
      ),
    );
  }
}

/// Rewarded-ad and Premium options shown when credits run low or out.
class _EarnMore extends ConsumerWidget {
  const _EarnMore();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final credits = ref.watch(creditsProvider).value;
    final perAd = ref.watch(servicesProvider).remote.getInt(RcKeys.rewardedCreditsPerAd);
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        if (credits?.canEarnMore ?? true)
          FilledButton.tonalIcon(
            onPressed: () => watchRewardedAd(context, ref, RewardPlacement.aiCredits),
            icon: const Icon(Icons.play_circle_outline),
            label: Text(l.aiWatchAd(perAd)),
          ),
        OutlinedButton(onPressed: () => context.push('/premium?from=ai_limit'), child: Text(l.aiGoPremium)),
      ],
    );
  }
}

class _CreditsLine extends ConsumerWidget {
  const _CreditsLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = ref.watch(creditsProvider).value;
    if (c == null || (c.dailyLimit == 0 && !c.premium)) return const SizedBox.shrink();
    final services = ref.watch(servicesProvider);
    final inline = Experiments(services.remote, (_, _) {}).variant(Experiment.rewardedPlacement) == 'inline';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.page),
      child: Row(
        children: [
          Expanded(
            child: Text(
              c.premium ? l.aiUnlimited : l.aiCreditsLeft(c.remaining),
              style: context.text.labelSmall?.copyWith(color: context.semantic.muted),
            ),
          ),
          if (inline && !c.premium && c.remaining <= 1 && c.canEarnMore)
            TextButton(
              onPressed: () => watchRewardedAd(context, ref, RewardPlacement.aiCredits),
              child: Text(l.aiWatchAd(services.remote.getInt(RcKeys.rewardedCreditsPerAd))),
            ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.enabled, required this.onSend});

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, Space.xs, Space.sm, Space.sm),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l.aiInputHint, counterText: ''),
                onSubmitted: onSend,
              ),
            ),
            const SizedBox(width: Space.xs),
            IconButton.filled(
              tooltip: l.aiSend,
              onPressed: enabled ? () => onSend(controller.text) : null,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
