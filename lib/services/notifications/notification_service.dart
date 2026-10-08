import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_planner.dart';

/// Localized title/body for a planned notification.
typedef NotificationText = ({String title, String body}) Function(PlannedNotification n);

abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> apply(List<PlannedNotification> plan, NotificationText text);
  Future<void> cancelAll();
  Future<String?> timeZoneName();

  /// Routes from tapped notifications (and the one that launched the app).
  Stream<String> get taps;

  /// Task ids the user marked done from a reminder's "Done" button.
  Stream<String> get doneTasks;

  /// A running focus session: a live countdown in the notification shade
  /// (Android) and a "time is up" alert at [endsAt] (both platforms).
  Future<void> startFocus({required DateTime endsAt, required String title, required String doneBody});
  Future<void> stopFocus();
}

const _focusOngoingId = 9000, _focusDoneId = 9001;

/// Reminder buttons. Ids are shared with the background handler.
const snoozeActionId = 'snooze10';
const doneActionId = 'done';
const taskCategoryId = 'task_reminder';
const snoozeMinutes = 10;

bool get _turkish => PlatformDispatcher.instance.locale.languageCode == 'tr';
String get _snoozeLabel => _turkish ? '$snoozeMinutes dk ertele' : 'Snooze $snoozeMinutes min';
String get _doneLabel => _turkish ? 'Bitti' : 'Done';

/// What a task reminder carries so it can be snoozed without the app.
String taskPayload({required String route, required String taskId, required String title, required String body}) =>
    jsonEncode({'r': route, 'k': taskId, 't': title, 'b': body});

Map<String, dynamic>? _decode(String? payload) {
  if (payload == null || !payload.startsWith('{')) return null;
  try {
    return jsonDecode(payload) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

AndroidNotificationDetails _androidDetails({required bool task}) => AndroidNotificationDetails(
  'lifeos_reminders',
  'Reminders',
  channelDescription: 'Task reminders and gentle daily check-ins',
  importance: Importance.defaultImportance,
  priority: Priority.defaultPriority,
  actions: task
      ? [
          AndroidNotificationAction(snoozeActionId, _snoozeLabel, cancelNotification: true),
          AndroidNotificationAction(doneActionId, _doneLabel, showsUserInterface: true, cancelNotification: true),
        ]
      : null,
);

NotificationDetails _details({required bool task}) => NotificationDetails(
  android: _androidDetails(task: task),
  iOS: DarwinNotificationDetails(categoryIdentifier: task ? taskCategoryId : null),
);

/// Schedules the same reminder again [snoozeMinutes] from now.
Future<void> _snooze(FlutterLocalNotificationsPlugin plugin, NotificationResponse r) async {
  final p = _decode(r.payload);
  if (p == null) return;
  final at = tz.TZDateTime.now(tz.local).add(const Duration(minutes: snoozeMinutes));
  await plugin.zonedSchedule(
    id: r.id ?? (p['k'].hashCode & 0xFFFFF),
    title: p['t'] as String?,
    body: p['b'] as String?,
    scheduledDate: at,
    payload: r.payload,
    notificationDetails: _details(task: true),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

Future<void> _initZone() async {
  tzdata.initializeTimeZones();
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } catch (_) {
    tz.setLocalLocation(tz.UTC);
  }
}

/// Runs in the background when "Snooze" is pressed (the app stays closed).
@pragma('vm:entry-point')
Future<void> onBackgroundNotificationAction(NotificationResponse r) async {
  if (r.actionId != snoozeActionId) return;
  await _initZone();
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );
  await _snooze(plugin, r);
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _tzName;
  final _taps = StreamController<String>.broadcast();
  final _done = StreamController<String>.broadcast();
  ({DateTime endsAt, String title, String doneBody})? _focus;

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Stream<String> get doneTasks => _done.stream;

  void _onTap(NotificationResponse r) {
    final task = _decode(r.payload);
    if (r.actionId == snoozeActionId) {
      unawaited(_snooze(_plugin, r));
      return;
    }
    if (r.actionId == doneActionId && task != null) {
      _done.add(task['k'] as String);
      return;
    }
    final route = task?['r'] as String? ?? r.payload;
    if (route != null && route.startsWith('/')) _taps.add(route);
  }

  @override
  Future<void> initialize() async {
    if (_ready) return;
    await _initZone();
    _tzName = tz.local.name;
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              taskCategoryId,
              actions: [
                DarwinNotificationAction.plain(snoozeActionId, _snoozeLabel),
                DarwinNotificationAction.plain(
                  doneActionId,
                  _doneLabel,
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationAction,
    );
    _ready = true;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final r = launch?.notificationResponse;
    if ((launch?.didNotificationLaunchApp ?? false) && r != null) {
      // Let the app finish starting before navigating.
      Future<void>.delayed(const Duration(milliseconds: 800), () => _onTap(r));
    }
  }

  @override
  Future<String?> timeZoneName() async => _tzName;

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  @override
  Future<void> apply(List<PlannedNotification> plan, NotificationText text) async {
    await initialize();
    // Replace the whole plan: simpler and race-free versus diffing.
    await _plugin.cancelAll();
    for (final n in plan) {
      final t = text(n);
      final task = n.kind == NotificationKind.taskReminder && n.taskId != null;
      try {
        await _plugin.zonedSchedule(
          id: n.id,
          title: t.title,
          body: t.body,
          scheduledDate: tz.TZDateTime.from(n.at, tz.local),
          payload: task
              ? taskPayload(route: n.kind.route, taskId: n.taskId!, title: t.title, body: t.body)
              : n.kind.route,
          notificationDetails: _details(task: task),
          // Inexact scheduling avoids the SCHEDULE_EXACT_ALARM permission;
          // a few minutes of drift is fine for nudges.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('schedule failed: $e');
      }
    }
    // cancelAll() above also removed a running focus session: put it back.
    final f = _focus;
    if (f != null && f.endsAt.isAfter(DateTime.now())) {
      await startFocus(endsAt: f.endsAt, title: f.title, doneBody: f.doneBody);
    }
  }

  @override
  Future<void> startFocus({required DateTime endsAt, required String title, required String doneBody}) async {
    await initialize();
    _focus = (endsAt: endsAt, title: title, doneBody: doneBody);
    try {
      // Android: a quiet, ongoing countdown in the shade and on the lock screen.
      await _plugin.show(
        id: _focusOngoingId,
        title: title,
        body: null,
        payload: '/focus',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'dayly_focus',
            'Focus',
            channelDescription: 'The running focus timer',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: true,
            when: endsAt.millisecondsSinceEpoch,
            usesChronometer: true,
            chronometerCountDown: true,
            timeoutAfter: endsAt.difference(DateTime.now()).inMilliseconds.clamp(1000, 1 << 31),
          ),
        ),
      );
    } catch (e) {
      debugPrint('focus ongoing failed: $e');
    }
    try {
      await _plugin.zonedSchedule(
        id: _focusDoneId,
        title: title,
        body: doneBody,
        scheduledDate: tz.TZDateTime.from(endsAt, tz.local),
        payload: '/focus',
        notificationDetails: NotificationDetails(
          android: const AndroidNotificationDetails(
            'dayly_focus_done',
            'Focus finished',
            channelDescription: 'When a focus session ends',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('focus done failed: $e');
    }
  }

  @override
  Future<void> stopFocus() async {
    _focus = null;
    await _plugin.cancel(id: _focusOngoingId);
    await _plugin.cancel(id: _focusDoneId);
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Shows an FCM message received while the app is in the foreground.
  Future<void> showRemote(RemoteMessage m) async {
    final n = m.notification;
    if (n == null) return;
    await _plugin.show(
      id: m.messageId.hashCode & 0x7FFFFFFF,
      title: n.title,
      body: n.body,
      notificationDetails: _details(task: false),
    );
  }
}

class NoopNotificationService implements NotificationService {
  final applied = <PlannedNotification>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> apply(List<PlannedNotification> plan, NotificationText text) async {
    applied
      ..clear()
      ..addAll(plan);
  }

  @override
  Future<void> cancelAll() async => applied.clear();

  @override
  Future<String?> timeZoneName() async => null;

  @override
  Stream<String> get taps => const Stream.empty();

  @override
  Stream<String> get doneTasks => const Stream.empty();

  DateTime? focusEndsAt;

  @override
  Future<void> startFocus({required DateTime endsAt, required String title, required String doneBody}) async =>
      focusEndsAt = endsAt;

  @override
  Future<void> stopFocus() async => focusEndsAt = null;
}
