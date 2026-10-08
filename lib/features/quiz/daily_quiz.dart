import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../domain/lio/daily_question.dart';
import '../../services/ads/ads_service.dart';
import '../premium/rewarded.dart';

/// Today's question and the player's progress (kept on the device).
class QuizController extends Notifier<QuizProgress> {
  static const _key = 'quiz_progress', _hint = 'quiz_hint';

  @override
  QuizProgress build() {
    final raw = ref.watch(servicesProvider).prefs.getString(_key);
    if (raw == null) return const QuizProgress();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return QuizProgress(
        answeredDay: j['day'] as String?,
        answer: j['answer'] as int?,
        streak: j['streak'] as int? ?? 0,
        correctTotal: j['total'] as int? ?? 0,
        lastCorrectDay: j['last'] as String?,
      );
    } catch (_) {
      return const QuizProgress();
    }
  }

  DailyQuestion get today => DailyQuestion.forDay(ref.read(todayProvider));

  bool get hintUsed => ref.read(servicesProvider).prefs.getString(_hint) == today.index.toString() + _dayKey;

  String get _dayKey => '@${ref.read(todayProvider).toIso8601String().substring(0, 10)}';

  Future<void> useHint() async {
    await ref.read(servicesProvider).prefs.setString(_hint, today.index.toString() + _dayKey);
    ref.invalidateSelf();
  }

  /// Answers today's question (once). Returns whether it was right.
  Future<bool> answer(int pick) async {
    final day = ref.read(todayProvider);
    final q = DailyQuestion.forDay(day);
    final right = pick == q.correct;
    if (state.answeredOn(day)) return state.answer == q.correct;
    final next = state.answerOn(day, pick, right: right);
    await ref
        .read(servicesProvider)
        .prefs
        .setString(
          _key,
          jsonEncode({
            'day': next.answeredDay,
            'answer': next.answer,
            'streak': next.streak,
            'total': next.correctTotal,
            'last': next.lastCorrectDay,
          }),
        );
    state = next;
    return right;
  }
}

final quizProvider = NotifierProvider<QuizController, QuizProgress>(QuizController.new);

/// Answered today's question right (Lio's energy counts it).
final quizRightTodayProvider = Provider<bool>((ref) {
  final p = ref.watch(quizProvider);
  final day = ref.watch(todayProvider);
  return p.answeredOn(day) && p.answer == DailyQuestion.forDay(day).correct;
});

/// One general-knowledge question a day, a streak, and +1 Lio energy when
/// right. The hint (two wrong answers removed) is a rewarded ad, free for
/// Premium.
class DailyQuizCard extends ConsumerWidget {
  const DailyQuizCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final progress = ref.watch(quizProvider);
    final day = ref.watch(todayProvider);
    final ctrl = ref.read(quizProvider.notifier);
    final q = DailyQuestion.forDay(day);
    final answered = progress.answeredOn(day);
    final options = q.options(lang);
    final hidden = !answered && ctrl.hintUsed ? q.hintHides.toSet() : const <int>{};
    final streak = progress.streakOn(day);
    final premium = ref.watch(isPremiumProvider);
    return AppCard(
      key: const Key('daily-quiz'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeader(
            icon: Icons.quiz_rounded,
            title: l.quizTitle,
            accent: Accent.score,
            trailing: streak > 0
                ? Text(
                    '🔥 ${l.quizStreak(streak)}',
                    style: context.text.labelMedium?.copyWith(color: Accent.score.color),
                  )
                : null,
          ),
          const SizedBox(height: Space.md),
          Text(q.question(lang), style: context.text.titleMedium),
          const SizedBox(height: Space.md),
          for (var i = 0; i < options.length; i++)
            if (!hidden.contains(i))
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: _Option(
                  key: Key('quiz-option-$i'),
                  label: options[i],
                  state: !answered ? null : (i == q.correct ? true : (i == progress.answer ? false : null)),
                  onTap: answered
                      ? null
                      : () async {
                          final right = await ctrl.answer(i);
                          unawaited(right ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact());
                        },
                ),
              ),
          if (answered) ...[
            const SizedBox(height: Space.xs),
            Text(
              progress.answer == q.correct ? l.quizRight : l.quizWrong(options[q.correct]),
              key: const Key('quiz-result'),
              style: context.text.bodyMedium?.copyWith(
                color: progress.answer == q.correct ? context.semantic.positive : context.semantic.negative,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${l.quizTotal(progress.correctTotal)} · ${l.quizComeBack}',
              style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
            ),
          ] else if (hidden.isEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('quiz-hint'),
                onPressed: () async {
                  final ok = premium || await watchRewardedAd(context, ref, RewardPlacement.quizHint);
                  if (ok) await ctrl.useHint();
                },
                icon: Icon(premium ? Icons.lightbulb_outline_rounded : Icons.play_circle_outline_rounded, size: 18),
                label: Text(l.quizHint),
              ),
            ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({super.key, required this.label, required this.state, required this.onTap});

  final String label;

  /// true: the right answer, false: the wrong pick, null: neutral.
  final bool? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      true => context.semantic.positive,
      false => context.semantic.negative,
      null => null,
    };
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.md),
        side: color == null ? null : BorderSide(color: color, width: 1.6),
        foregroundColor: color,
        disabledForegroundColor: color ?? context.semantic.muted,
        backgroundColor: color?.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (state == true) Icon(Icons.check_circle_rounded, color: color, size: 20),
          if (state == false) Icon(Icons.cancel_rounded, color: color, size: 20),
        ],
      ),
    );
  }
}
