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
import '../plan/task_editor.dart';

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

/// Lio lives above the tab content and walks along the bottom of the
/// screen: now and then he strolls somewhere else, hops when you switch
/// tabs and shares a tip. Tap him for help, drag him anywhere, long-press
/// to send him to rest.
class LioCompanion extends ConsumerStatefulWidget {
  const LioCompanion({super.key, required this.tab});

  final int tab;

  /// Shell tabs where Lio steps aside (none: he goes everywhere).
  static const hiddenOnTabs = <int>{};

  /// Shell tab index (home, explore, saved, profile) → [LioScript] tab
  /// (0 home, 1 plan, 2 money, 3 life, 4 other).
  static const scriptTab = [0, 3, 0, 4];

  @override
  ConsumerState<LioCompanion> createState() => _LioCompanionState();
}

class _LioCompanionState extends ConsumerState<LioCompanion> with TickerProviderStateMixin {
  static const _autoLimit = 6;
  static const _size = 60.0;

  late final AnimationController _hop = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));

  /// Little steps while he walks.
  late final AnimationController _step = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
  final _rand = math.Random();
  final _seen = <String>{};
  final _greetedTabs = <int>{};
  Timer? _speakTimer;
  Timer? _hideTimer;
  Timer? _ambient;
  Timer? _arrive;
  LioLine? _line;

  /// Where he stands along the bottom, -1 (left) … 1 (right).
  double _x = -0.85;
  bool _facingRight = true;
  Duration _walkTime = Duration.zero;
  double? _dragX;
  int _autoCount = 0;

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void initState() {
    super.initState();
    _scheduleTabGreeting(const Duration(milliseconds: 2400));
    // Ambient life: a stroll or a hop every so often, and now and then a thought.
    _ambient = Timer.periodic(const Duration(seconds: 9), (t) {
      if (!mounted) return;
      if (_line == null && _dragX == null && _rand.nextDouble() < 0.6) {
        _walkTo(_pickSpot());
      } else {
        _doHop();
      }
      if (_line == null && t.tick % 9 == 0 && _autoCount < _autoLimit) _say(auto: true);
    });
  }

  double _pickSpot() {
    for (var i = 0; i < 6; i++) {
      final x = _rand.nextDouble() * 2 - 1;
      if ((x - _x).abs() > 0.35) return x;
    }
    return -_x;
  }

  void _walkTo(double x) {
    if (_reduceMotion) return;
    final distance = (x - _x).abs();
    setState(() {
      _facingRight = x > _x;
      _walkTime = Duration(milliseconds: (distance * 1700).round().clamp(500, 3400));
      _x = x;
    });
    _step.repeat(reverse: true);
    _arrive?.cancel();
    _arrive = Timer(_walkTime, () {
      if (!mounted) return;
      _step
        ..stop()
        ..value = 0;
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
    _arrive?.cancel();
    _hop.dispose();
    _step.dispose();
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

  LioLine _pick() {
    final all = _lines();
    final fresh = all.where((x) => !_seen.contains(x.text)).toList();
    final pool = fresh.isEmpty ? all : fresh;
    if (fresh.isEmpty) _seen.clear();
    final top = pool.map((x) => x.priority).fold<int>(0, math.max);
    // Contextual lines first; otherwise mix tips and inspiration.
    final candidates = top > 0 ? pool.where((x) => x.priority == top).toList() : pool;
    final pick = candidates[_rand.nextInt(candidates.length)];
    _seen.add(pick.text);
    return pick;
  }

  void _say({bool auto = false}) {
    final pick = _pick();
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

  Future<void> _help() async {
    _close();
    unawaited(HapticFeedback.selectionClick());
    _doHop();
    final hide = await showLioHelp(context, line: _pick());
    if (hide == true && mounted) _hideLio();
  }

  void _hideLio() {
    final l = context.l10n;
    unawaited(HapticFeedback.mediumImpact());
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
    final x = _dragX ?? _x;
    final d = Motion.of(context, Motion.slow);
    // He stands just behind the tab bar, so he covers less of the page.
    return Transform.translate(
      offset: const Offset(0, 18),
      child: AnimatedSlide(
        offset: hidden ? const Offset(0, 1.6) : Offset.zero,
        duration: d,
        curve: Motion.curve,
        child: AnimatedAlign(
          alignment: Alignment(x, 1),
          duration: _dragX != null ? Duration.zero : (_walkTime == Duration.zero ? d : _walkTime),
          curve: _walkTime == Duration.zero ? Curves.easeOutBack : Curves.easeInOutSine,
          onEnd: () => _walkTime = Duration.zero,
          child: Padding(
            // On the right, sit above the screen's + button.
            padding: EdgeInsets.fromLTRB(Space.md, 0, Space.md, x > 0.6 && _dragX == null ? 76 : Space.sm),
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
                            context.push('/ai');
                          },
                          onAnother: () => _say(),
                          onClose: _close,
                        ),
                ),
                const SizedBox(height: Space.xs),
                Semantics(
                  button: true,
                  label: context.l10n.lioHelpTitle,
                  child: GestureDetector(
                    key: const Key('lio-companion'),
                    onTap: _help,
                    onLongPress: _hideLio,
                    onHorizontalDragUpdate: (e) => setState(() {
                      final cur = _dragX ?? _x;
                      final next = (cur + e.delta.dx / (width / 2)).clamp(-1.0, 1.0);
                      if (next != cur) _facingRight = next > cur;
                      _dragX = next;
                    }),
                    onHorizontalDragEnd: (_) => setState(() {
                      _x = _dragX ?? _x;
                      _dragX = null;
                      _walkTime = Duration.zero;
                      _doHop();
                    }),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_hop, _step]),
                      builder: (_, child) {
                        final t = _hop.value;
                        final lift = math.sin(t * math.pi) * 14 + _step.value * 4;
                        final squash = 1 + math.sin(t * math.pi * 2) * 0.04;
                        final tilt = (_step.value - 0.5) * 0.12 * (_step.isAnimating ? 1 : 0);
                        return Transform.translate(
                          offset: Offset(0, -lift),
                          child: Transform.rotate(
                            angle: tilt,
                            child: Transform.scale(scaleY: squash, scaleX: 2 - squash, child: child),
                          ),
                        );
                      },
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(_facingRight ? -1 : 1, 1, 1),
                        child: Mascot(
                          mood: _line?.mood ?? (_step.isAnimating ? MascotMood.happy : MascotMood.front),
                          size: _size,
                          float: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What Lio offers when tapped: the most useful thing he noticed and a few
/// one-tap shortcuts. Returns true when the person wants him hidden.
Future<bool?> showLioHelp(BuildContext context, {required LioLine line}) => showModalBottomSheet<bool>(
  context: context,
  useRootNavigator: true,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _LioHelpSheet(line: line),
);

class _LioHelpSheet extends ConsumerWidget {
  const _LioHelpSheet({required this.line});
  final LioLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    String n() => '${DateTime.now().microsecondsSinceEpoch}';
    final actions = <(IconData, String, Accent, VoidCallback)>[
      (Icons.event_available_rounded, l.lioHelpPlan, Accent.plan, () => context.push('/ai?topic=plan&n=${n()}')),
      (
        Icons.add_task_rounded,
        l.lioHelpTask,
        Accent.goals,
        () => showTaskEditor(context, day: ref.read(todayProvider)),
      ),
      (Icons.account_balance_wallet_outlined, l.lioHelpMoney, Accent.money, () => context.push('/money')),
      (Icons.center_focus_strong_outlined, l.lioHelpFocus, Accent.wellbeing, () => context.push('/focus')),
      (Icons.menu_book_rounded, l.lioHelpWrite, Accent.news, () => context.push('/journal/new')),
      (Icons.chat_bubble_outline_rounded, l.lioHelpAsk, Accent.ai, () => context.push('/ai')),
    ];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Mascot(mood: line.mood, size: 56, float: false),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.lioHelpTitle, style: context.text.titleLarge),
                          const SizedBox(height: 4),
                          Text(line.text, style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: Space.sm,
                  crossAxisSpacing: Space.sm,
                  childAspectRatio: 1.05 / MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
                  children: [
                    for (final (icon, label, accent, go) in actions)
                      AppCard(
                        padding: const EdgeInsets.all(Space.sm),
                        onTap: () {
                          Navigator.pop(context);
                          go();
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: accent.color.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, size: 22, color: accent.color),
                            ),
                            const SizedBox(height: Space.sm),
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelMedium,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: Space.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(l.lioHelpTip, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: context.semantic.muted),
                      child: Text(l.lioHelpHide),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
                Text(
                  ref.watch(settingsProvider.select((s) => s.assistantName)),
                  style: context.text.titleSmall?.copyWith(color: context.colors.primary),
                ),
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
