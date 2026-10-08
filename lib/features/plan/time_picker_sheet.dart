import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/gen/app_localizations.dart';

/// A start time (null = any time that day) and how long it takes.
class TimeChoice {
  const TimeChoice(this.time, this.minutes);
  final TimeOfDay? time;
  final int minutes;
}

/// "1 sa 30 dk", "45 dk", "2 sa".
String durationLabel(AppLocalizations l, int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return l.minutesShort(m);
  return m == 0 ? l.durH(h) : l.durHM(h, m);
}

String _two(int v) => v.toString().padLeft(2, '0');
String hhmm(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

/// "10:00 – 10:45" for a start and a length.
String rangeLabel(TimeOfDay t, int minutes) {
  final end = (t.hour * 60 + t.minute + minutes) % (24 * 60);
  return '${hhmm(t)} – ${_two(end ~/ 60)}:${_two(end % 60)}';
}

/// Bottom sheet: time wheel + duration chips with a live summary.
Future<TimeChoice?> pickTimeAndDuration(
  BuildContext context, {
  TimeOfDay? time,
  int minutes = 30,
  bool allowNoTime = true,
}) => showModalBottomSheet<TimeChoice>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _TimeSheet(time: time, minutes: minutes, allowNoTime: allowNoTime),
);

class _TimeSheet extends StatefulWidget {
  const _TimeSheet({this.time, required this.minutes, required this.allowNoTime});
  final TimeOfDay? time;
  final int minutes;
  final bool allowNoTime;

  @override
  State<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<_TimeSheet> {
  static const _presets = [15, 30, 45, 60, 90, 120, 180];
  late TimeOfDay _time = widget.time ?? _nextQuarter();
  late int _minutes = widget.minutes;
  late bool _custom = !_presets.contains(widget.minutes);

  /// Bumped to rebuild the wheel at a preset time.
  int _wheel = 0;

  void _setTime(TimeOfDay t) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _time = t;
      _wheel++;
    });
  }

  static TimeOfDay _inAnHour() {
    final n = DateTime.now().add(const Duration(hours: 1));
    return TimeOfDay(hour: n.hour, minute: (n.minute ~/ 5) * 5);
  }

  static TimeOfDay _nextQuarter() {
    final n = DateTime.now().add(const Duration(minutes: 15));
    final m = (n.minute ~/ 15) * 15;
    return TimeOfDay(hour: n.hour, minute: m);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final gold = Theme.of(context).brightness == Brightness.dark ? Palette.goldDark : Palette.gold;
    final now = DateTime.now();
    final initial = DateTime(now.year, now.month, now.day, _time.hour, _time.minute - _time.minute % 5);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.timeSheetTitle, style: context.text.headlineSmall),
            const SizedBox(height: Space.lg),
            // Live summary: what you will do, from when to when.
            AnimatedSwitcher(
              duration: Motion.of(context, Motion.fast),
              child: Container(
                key: ValueKey('${_time.hour}:${_time.minute}:$_minutes'),
                padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(Radii.md),
                  border: Border.all(color: gold.withValues(alpha: 0.35), width: 0.8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: context.colors.primary, size: 20),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        rangeLabel(_time, _minutes),
                        style: context.text.headlineSmall?.copyWith(
                          fontSize: 22,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Text(durationLabel(l, _minutes), style: context.text.labelLarge?.copyWith(color: gold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            Text(l.timeStart, style: context.text.titleSmall?.copyWith(color: context.semantic.muted)),
            const SizedBox(height: Space.sm),
            // One tap for the usual times; the wheel is for the exact minute.
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final (label, t) in [
                  (l.presetMorning, const TimeOfDay(hour: 9, minute: 0)),
                  (l.presetNoon, const TimeOfDay(hour: 12, minute: 30)),
                  (l.presetAfternoon, const TimeOfDay(hour: 15, minute: 0)),
                  (l.presetEvening, const TimeOfDay(hour: 19, minute: 0)),
                  (l.presetInHour, _inAnHour()),
                ])
                  ActionChip(
                    label: Text('$label · ${hhmm(t)}'),
                    onPressed: () => _setTime(t),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            SizedBox(
              height: 168,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: Theme.of(context).brightness,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: context.text.titleLarge?.copyWith(fontSize: 22, fontFamily: 'Jakarta'),
                  ),
                ),
                child: CupertinoDatePicker(
                  key: ValueKey('time-wheel-$_wheel'),
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat:
                      MediaQuery.alwaysUse24HourFormatOf(context) ||
                      Localizations.localeOf(context).languageCode != 'en',
                  minuteInterval: 5,
                  initialDateTime: initial,
                  onDateTimeChanged: (d) {
                    unawaited(HapticFeedback.selectionClick());
                    setState(() => _time = TimeOfDay(hour: d.hour, minute: d.minute));
                  },
                ),
              ),
            ),
            const SizedBox(height: Space.md),
            Text(l.taskDuration, style: context.text.titleSmall?.copyWith(color: context.semantic.muted)),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final m in _presets)
                  ChoiceChip(
                    label: Text(durationLabel(l, m)),
                    selected: !_custom && _minutes == m,
                    onSelected: (_) => setState(() {
                      _custom = false;
                      _minutes = m;
                    }),
                  ),
                ChoiceChip(
                  label: Text(l.timeCustom),
                  selected: _custom,
                  onSelected: (_) => setState(() => _custom = true),
                ),
              ],
            ),
            AnimatedSize(
              duration: Motion.of(context, Motion.normal),
              curve: Motion.emphasized,
              child: _custom
                  ? Slider(
                      value: _minutes.clamp(5, 480).toDouble(),
                      min: 5,
                      max: 480,
                      divisions: 95,
                      label: durationLabel(l, _minutes),
                      onChanged: (v) => setState(() => _minutes = v.round()),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                if (widget.allowNoTime)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, TimeChoice(null, _minutes)),
                      child: Text(l.timeNoTime),
                    ),
                  ),
                if (widget.allowNoTime) const SizedBox(width: Space.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, TimeChoice(_time, _minutes)),
                    child: Text(l.ok),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
