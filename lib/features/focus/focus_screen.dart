import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/mascot.dart';
import '../premium/happy_moment.dart';

/// A running (or paused) focus session, kept on the device so it survives
/// leaving the app.
class FocusSession {
  const FocusSession({required this.minutes, required this.endsAt, this.taskId, this.title, this.pausedLeft});

  final int minutes;
  final DateTime endsAt;
  final String? taskId;
  final String? title;

  /// Time left when paused (null while running).
  final Duration? pausedLeft;

  bool get paused => pausedLeft != null;
  Duration left(DateTime now) => pausedLeft ?? (endsAt.isAfter(now) ? endsAt.difference(now) : Duration.zero);

  Map<String, dynamic> toJson() => {
    'm': minutes,
    'e': endsAt.millisecondsSinceEpoch,
    'k': taskId,
    't': title,
    'p': pausedLeft?.inSeconds,
  };

  static FocusSession? fromJson(String? raw) {
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return FocusSession(
        minutes: j['m'] as int,
        endsAt: DateTime.fromMillisecondsSinceEpoch(j['e'] as int),
        taskId: j['k'] as String?,
        title: j['t'] as String?,
        pausedLeft: j['p'] == null ? null : Duration(seconds: j['p'] as int),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Today's finished focus sessions: (count, minutes).
class FocusLog extends Notifier<(int, int)> {
  @override
  (int, int) build() {
    final p = ref.watch(servicesProvider).prefs;
    final today = Dates.dayKey(ref.watch(todayProvider));
    if (p.getString('focus_day') != today) return (0, 0);
    return (p.getInt('focus_count') ?? 0, p.getInt('focus_minutes') ?? 0);
  }

  Future<void> add(int minutes) async {
    final p = ref.read(servicesProvider).prefs;
    final next = (state.$1 + 1, state.$2 + minutes);
    state = next;
    await p.setString('focus_day', Dates.dayKey(ref.read(todayProvider)));
    await p.setInt('focus_count', next.$1);
    await p.setInt('focus_minutes', next.$2);
  }
}

final focusLogProvider = NotifierProvider<FocusLog, (int, int)>(FocusLog.new);

class FocusController extends Notifier<FocusSession?> {
  static const _key = 'focus_session';

  @override
  FocusSession? build() => FocusSession.fromJson(ref.watch(servicesProvider).prefs.getString(_key));

  Future<void> _save(FocusSession? s) async {
    state = s;
    final p = ref.read(servicesProvider).prefs;
    s == null ? await p.remove(_key) : await p.setString(_key, jsonEncode(s.toJson()));
  }

  Future<void> start({required int minutes, String? taskId, String? title, required String doneBody}) async {
    final s = FocusSession(
      minutes: minutes,
      endsAt: DateTime.now().add(Duration(minutes: minutes)),
      taskId: taskId,
      title: title,
    );
    await _save(s);
    await ref
        .read(servicesProvider)
        .notifications
        .startFocus(endsAt: s.endsAt, title: title ?? '⏳', doneBody: doneBody);
  }

  Future<void> pause() async {
    final s = state;
    if (s == null || s.paused) return;
    await _save(
      FocusSession(
        minutes: s.minutes,
        endsAt: s.endsAt,
        taskId: s.taskId,
        title: s.title,
        pausedLeft: s.left(DateTime.now()),
      ),
    );
    await ref.read(servicesProvider).notifications.stopFocus();
  }

  Future<void> resume({required String doneBody}) async {
    final s = state;
    if (s == null || !s.paused) return;
    final ends = DateTime.now().add(s.pausedLeft!);
    await _save(FocusSession(minutes: s.minutes, endsAt: ends, taskId: s.taskId, title: s.title));
    await ref.read(servicesProvider).notifications.startFocus(endsAt: ends, title: s.title ?? '⏳', doneBody: doneBody);
  }

  /// Ends the session; counts it when at least a minute was spent.
  Future<int> finish() async {
    final s = state;
    if (s == null) return 0;
    final spent = s.minutes - (s.left(DateTime.now()).inSeconds / 60).ceil();
    await _save(null);
    await ref.read(servicesProvider).notifications.stopFocus();
    if (spent >= 1) await ref.read(focusLogProvider.notifier).add(spent);
    return spent;
  }
}

final focusProvider = NotifierProvider<FocusController, FocusSession?>(FocusController.new);

/// The focus timer: pick a length, put the phone down, get told when time
/// is up. Optionally tied to a task, which can be ticked off at the end.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key, this.taskId});
  final String? taskId;

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int _minutes = 25;
  Timer? _tick;
  int? _doneMinutes;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _onTick() async {
    if (!mounted) return;
    final s = ref.read(focusProvider);
    if (s != null && !s.paused && s.left(DateTime.now()) == Duration.zero) {
      final spent = await ref.read(focusProvider.notifier).finish();
      unawaited(HapticFeedback.heavyImpact());
      if (mounted) setState(() => _doneMinutes = spent);
      return;
    }
    setState(() {});
  }

  String _clock(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final session = ref.watch(focusProvider);
    final log = ref.watch(focusLogProvider);
    final taskId = session?.taskId ?? widget.taskId;
    final task = taskId == null
        ? null
        : ref.watch(tasksProvider).list.where((t) => t.id == taskId && !t.deleted).firstOrNull;
    final now = DateTime.now();
    final total = Duration(minutes: session?.minutes ?? _minutes);
    final left = session?.left(now) ?? total;
    final progress = total.inSeconds == 0 ? 0.0 : 1 - left.inSeconds / total.inSeconds;
    final gold = Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold;

    return Scaffold(
      appBar: AppBar(title: Text(l.focusTitle)),
      body: AmbientBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.xl),
            children: [
              Center(child: Eyebrow(task == null ? l.focusFree : l.focusOn)),
              if (task != null) ...[
                const SizedBox(height: Space.xs),
                Text(task.title, textAlign: TextAlign.center, style: context.text.headlineSmall),
              ],
              const SizedBox(height: Space.xl),
              Center(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _FocusRing(
                            progress: progress,
                            color: context.colors.primary,
                            track: context.semantic.border,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Mascot(
                            mood: _doneMinutes != null ? MascotMood.excited : MascotMood.thoughtful,
                            size: 64,
                            float: false,
                          ),
                          const SizedBox(height: Space.sm),
                          Text(
                            _doneMinutes != null ? '00:00' : _clock(left),
                            key: const Key('focus-clock'),
                            style: context.text.displaySmall?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: session?.paused ?? false ? context.semantic.muted : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.xl),
              if (_doneMinutes != null) ...[
                Text(
                  l.focusDoneTitle(_doneMinutes!),
                  textAlign: TextAlign.center,
                  style: context.text.titleLarge?.copyWith(color: gold),
                ),
                const SizedBox(height: Space.lg),
                if (task != null && !task.isCompleted)
                  FilledButton.icon(
                    onPressed: () async {
                      await ref.read(actionsProvider).toggleTask(task);
                      if (!context.mounted) return;
                      Navigator.of(context).maybePop();
                      unawaited(happyMoment(ref));
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l.focusDoneTask),
                  ),
                const SizedBox(height: Space.sm),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _doneMinutes = null;
                    _minutes = 5;
                  }),
                  icon: const Icon(Icons.local_cafe_outlined),
                  label: Text(l.focusBreak),
                ),
              ] else if (session == null) ...[
                Center(child: Text(l.focusHowLong, style: context.text.titleSmall)),
                const SizedBox(height: Space.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    for (final m in const [5, 15, 25, 45, 60])
                      ChoiceChip(
                        label: Text(l.minutesShort(m)),
                        selected: _minutes == m,
                        onSelected: (_) => setState(() => _minutes = m),
                      ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                FilledButton.icon(
                  key: const Key('focus-start'),
                  onPressed: () async {
                    unawaited(HapticFeedback.mediumImpact());
                    await ref
                        .read(focusProvider.notifier)
                        .start(minutes: _minutes, taskId: task?.id, title: task?.title, doneBody: l.focusNotifDone);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l.focusStart),
                ),
              ] else ...[
                Text(
                  l.focusPhoneDown,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(color: context.semantic.muted),
                ),
                const SizedBox(height: Space.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => session.paused
                            ? ref.read(focusProvider.notifier).resume(doneBody: l.focusNotifDone)
                            : ref.read(focusProvider.notifier).pause(),
                        icon: Icon(session.paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                        label: Text(session.paused ? l.focusResume : l.focusPause),
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('focus-stop'),
                        onPressed: () async {
                          final spent = await ref.read(focusProvider.notifier).finish();
                          if (mounted) setState(() => _doneMinutes = spent >= 1 ? spent : null);
                        },
                        icon: const Icon(Icons.stop_rounded),
                        label: Text(l.focusStop),
                      ),
                    ),
                  ],
                ),
              ],
              if (log.$1 > 0) ...[
                const SizedBox(height: Space.xl),
                Center(
                  child: Text(
                    l.focusToday(log.$1, log.$2),
                    style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusRing extends CustomPainter {
  _FocusRing({required this.progress, required this.color, required this.track});
  final double progress;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final rect = r.deflate(6);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(_FocusRing old) => old.progress != progress || old.color != color;
}
