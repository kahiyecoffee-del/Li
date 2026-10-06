import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../core/widgets/mascot.dart';
import '../../l10n/gen/app_localizations.dart';

/// One thing Lio can say.
class LioLine {
  const LioLine(this.text, this.mood, {this.priority = 0});

  final String text;
  final MascotMood mood;

  /// Higher = more relevant right now (contextual lines beat generic tips).
  final int priority;
}

/// Picks what Lio says for the current tab, from live data first, then tips,
/// then inspiration. Pure, so it can be unit tested.
abstract final class LioScript {
  static List<LioLine> lines({
    required AppLocalizations l,
    required int tab,
    required int hour,
    required int goalsLeft,
    required bool allGoalsDone,
    required bool overBudgetToday,
    required String? budgetLeftToday,
    required int streak,
    required bool moodLogged,
  }) {
    final out = <LioLine>[];
    if (hour >= 23 || hour < 5) out.add(LioLine(l.lioNight, MascotMood.sleepy, priority: 3));
    if (allGoalsDone) {
      out.add(LioLine(l.lioAllDone, MascotMood.excited, priority: 3));
    } else if (goalsLeft > 0 && tab == 0) {
      out.add(LioLine(l.lioGoalsLeft(goalsLeft), MascotMood.happy, priority: 2));
    }
    // Money lives inside Life, so budget lines show on both.
    final moneyTab = tab == 2 || tab == 3;
    if (overBudgetToday) {
      out.add(LioLine(l.lioOverBudget, MascotMood.thoughtful, priority: moneyTab ? 3 : 2));
    } else if (budgetLeftToday != null && moneyTab) {
      out.add(LioLine(l.lioUnderBudget(budgetLeftToday), MascotMood.happy, priority: 2));
    }
    if (streak > 1) out.add(LioLine(l.lioStreak(streak), MascotMood.excited, priority: 1));
    if (!moodLogged && (tab == 0 || tab == 3)) out.add(LioLine(l.lioMoodCheck, MascotMood.curious, priority: 1));

    final tips = switch (tab) {
      0 => [l.lioTipHome1, l.lioTipHome2],
      1 => [l.lioTipPlan1, l.lioTipPlan2, l.lioTipPlan3],
      2 => [l.lioTipMoney1, l.lioTipMoney2, l.lioTipMoney3],
      3 => [l.lioTipLife1, l.lioTipLife2, l.lioTipLife3, l.lioTipMoney1, l.lioTipMoney2, l.lioTipMoney3],
      _ => const <String>[],
    };
    out.addAll(tips.map((t) => LioLine(t, MascotMood.curious)));
    out.addAll(inspirations(l).map((t) => LioLine(t, MascotMood.loving)));
    return out;
  }

  static List<String> inspirations(AppLocalizations l) => [
    l.lioInspire1,
    l.lioInspire2,
    l.lioInspire3,
    l.lioInspire4,
    l.lioInspire5,
    l.lioInspire6,
    l.lioInspire7,
    l.lioInspire8,
    l.lioInspire9,
    l.lioInspire10,
    l.lioInspire11,
    l.lioInspire12,
  ];
}

/// Lio lives above the tab content: he hops when you switch tabs, walks to
/// whichever side you drag him to, and now and then shares a tip or a bit of
/// inspiration. Tap him to talk, long-press to send him to rest.
class LioCompanion extends ConsumerStatefulWidget {
  const LioCompanion({super.key, required this.tab});

  final int tab;

  /// Shell tabs where Lio steps aside: Home and the assistant already feature
  /// him, and Profile is for settings. Keeps him helpful, not everywhere.
  static const hiddenOnTabs = {0, 3, 4};

  /// Shell tab index (home, explore, saved, AI, profile) → [LioScript] tab
  /// (0 home, 1 plan, 2 money, 3 life, 4 AI).
  static const scriptTab = [0, 3, 0, 4, 4];

  @override
  ConsumerState<LioCompanion> createState() => _LioCompanionState();
}

class _LioCompanionState extends ConsumerState<LioCompanion> with TickerProviderStateMixin {
  static const _autoLimit = 6;
  static const _size = 64.0;

  late final AnimationController _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
  final _rand = math.Random();
  final _seen = <String>{};
  final _greetedTabs = <int>{};
  Timer? _speakTimer;
  Timer? _hideTimer;
  Timer? _ambient;
  LioLine? _line;
  bool _right = false;
  double? _dragX;
  int _autoCount = 0;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void initState() {
    super.initState();
    _scheduleTabGreeting(const Duration(milliseconds: 2400));
    // Ambient life: a small hop every so often, and occasionally a thought.
    _ambient = Timer.periodic(const Duration(seconds: 14), (t) {
      if (!mounted) return;
      _doHop();
      if (_line == null && t.tick % 6 == 0 && _autoCount < _autoLimit) _say(auto: true);
    });
  }

  @override
  void didUpdateWidget(LioCompanion old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab) {
      _close();
      _doHop();
      if (!_greetedTabs.contains(widget.tab)) _scheduleTabGreeting(const Duration(milliseconds: 900));
    }
  }

  @override
  void dispose() {
    _speakTimer?.cancel();
    _hideTimer?.cancel();
    _ambient?.cancel();
    _hop.dispose();
    super.dispose();
  }

  void _scheduleTabGreeting(Duration after) {
    _speakTimer?.cancel();
    _speakTimer = Timer(after, () {
      if (!mounted || LioCompanion.hiddenOnTabs.contains(widget.tab) || _autoCount >= _autoLimit) return;
      _greetedTabs.add(widget.tab);
      _say(auto: true);
    });
  }

  void _doHop() {
    if (_reduceMotion || _hop.isAnimating) return;
    _hop.forward(from: 0);
  }

  List<LioLine> _lines() {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final goals = ref.read(dailyGoalsProvider);
    final budget = ref.read(budgetSnapshotProvider);
    final key = Dates.dayKey(ref.read(todayProvider));
    return LioScript.lines(
      l: l,
      tab: LioCompanion.scriptTab[widget.tab.clamp(0, LioCompanion.scriptTab.length - 1)],
      hour: DateTime.now().hour,
      goalsLeft: goals.where((g) => !g.completed).length,
      allGoalsDone: goals.isNotEmpty && goals.every((g) => g.completed),
      overBudgetToday: budget?.overToday ?? false,
      budgetLeftToday: budget == null || budget.overToday ? null : fmt.money(budget.remainingTodayMinor),
      streak: ref.read(streakProvider).current,
      moodLogged: ref.read(moodsProvider).list.any((m) => m.day == key),
    );
  }

  void _say({bool auto = false}) {
    final all = _lines();
    final fresh = all.where((x) => !_seen.contains(x.text)).toList();
    final pool = fresh.isEmpty ? all : fresh;
    if (fresh.isEmpty) _seen.clear();
    final top = pool.map((x) => x.priority).fold<int>(0, math.max);
    // Contextual lines first; otherwise mix tips and inspiration.
    final candidates = top > 0 ? pool.where((x) => x.priority == top).toList() : pool;
    final pick = candidates[_rand.nextInt(candidates.length)];
    _seen.add(pick.text);
    if (auto) _autoCount++;
    setState(() => _line = pick);
    _doHop();
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(seconds: auto ? 7 : 12), _close);
  }

  void _close() {
    _hideTimer?.cancel();
    if (mounted && _line != null) setState(() => _line = null);
  }

  void _hideLio() {
    final l = context.l10n;
    HapticFeedback.mediumImpact();
    final ctrl = ref.read(settingsProvider.notifier);
    ctrl.update((s) => s.copyWith(showLio: false));
    showSnack(
      context,
      l.lioHidden,
      action: SnackBarAction(label: l.undo, onPressed: () => ctrl.update((s) => s.copyWith(showLio: true))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hidden = LioCompanion.hiddenOnTabs.contains(widget.tab);
    final width = MediaQuery.sizeOf(context).width;
    final x = _dragX ?? (_right ? 1.0 : -1.0);
    final d = Motion.of(context, Motion.slow);
    return AnimatedSlide(
      offset: hidden ? const Offset(0, 1.6) : Offset.zero,
      duration: d,
      curve: Motion.curve,
      child: AnimatedAlign(
        alignment: Alignment(x, 1),
        duration: _dragX != null ? Duration.zero : d,
        curve: Curves.easeOutBack,
        child: Padding(
          // On the right, sit above the screen's + button.
          padding: EdgeInsets.fromLTRB(Space.md, 0, Space.md, _right && _dragX == null ? 76 : Space.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: x > 0 ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: Motion.of(context, Motion.normal),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(a),
                    alignment: x > 0 ? Alignment.bottomRight : Alignment.bottomLeft,
                    child: c,
                  ),
                ),
                child: _line == null || hidden
                    ? const SizedBox.shrink()
                    : _Bubble(
                        key: ValueKey(_line!.text),
                        line: _line!,
                        maxWidth: math.min(300, width - 2 * Space.md),
                        onAsk: () {
                          _close();
                          context.go('/ai');
                        },
                        onAnother: () => _say(),
                        onClose: _close,
                      ),
              ),
              const SizedBox(height: Space.xs),
              Semantics(
                button: true,
                label: context.l10n.lioName,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _line == null ? _say() : _close();
                  },
                  onLongPress: _hideLio,
                  onHorizontalDragUpdate: (e) => setState(() {
                    final cur = _dragX ?? (_right ? 1.0 : -1.0);
                    _dragX = (cur + e.delta.dx / (width / 2)).clamp(-1.0, 1.0);
                  }),
                  onHorizontalDragEnd: (_) => setState(() {
                    _right = (_dragX ?? -1) > 0;
                    _dragX = null;
                    _doHop();
                  }),
                  child: AnimatedBuilder(
                    animation: _hop,
                    builder: (_, child) {
                      final t = _hop.value;
                      final lift = math.sin(t * math.pi) * 14;
                      final squash = 1 + math.sin(t * math.pi * 2) * 0.04;
                      return Transform.translate(
                        offset: Offset(0, -lift),
                        child: Transform.scale(scaleY: squash, scaleX: 2 - squash, child: child),
                      );
                    },
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(x > 0 ? -1 : 1, 1, 1),
                      child: Mascot(mood: _line?.mood ?? MascotMood.front, size: _size, float: false),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.line,
    required this.maxWidth,
    required this.onAsk,
    required this.onAnother,
    required this.onClose,
  });

  final LioLine line;
  final double maxWidth;
  final VoidCallback onAsk;
  final VoidCallback onAnother;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final b = Theme.of(context).brightness;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.xs, Space.xs),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          boxShadow: [
            ...Shadows.soft(b),
            if (b == Brightness.light)
              BoxShadow(
                color: const Color(0xFF3B2A1E).withValues(alpha: 0.08),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
          ],
          border: b == Brightness.dark ? Border.all(color: context.semantic.border) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Lio', style: context.text.titleSmall?.copyWith(color: context.colors.primary)),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: l.close,
                  icon: Icon(Icons.close_rounded, size: 18, color: context.semantic.muted),
                  onPressed: onClose,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: Space.md),
              child: Text(line.text, style: context.text.bodyMedium),
            ),
            const SizedBox(height: Space.xs),
            Wrap(
              children: [
                TextButton.icon(
                  onPressed: onAsk,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(l.lioAsk),
                ),
                TextButton(
                  onPressed: onAnother,
                  style: TextButton.styleFrom(foregroundColor: context.semantic.muted),
                  child: Text(l.lioAnother),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
