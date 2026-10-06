import 'dart:async';

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
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _tzName;

  static const _channel = AndroidNotificationDetails(
    'lifeos_reminders',
    'Reminders',
    channelDescription: 'Task reminders and gentle daily check-ins',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  @override
  Future<void> initialize() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      _tzName = info.identifier;
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
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
      try {
        await _plugin.zonedSchedule(
          id: n.id,
          title: t.title,
          body: t.body,
          scheduledDate: tz.TZDateTime.from(n.at, tz.local),
          notificationDetails: const NotificationDetails(android: _channel, iOS: DarwinNotificationDetails()),
          // Inexact scheduling avoids the SCHEDULE_EXACT_ALARM permission;
          // a few minutes of drift is fine for nudges.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('schedule failed: $e');
      }
    }
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
      notificationDetails: const NotificationDetails(android: _channel, iOS: DarwinNotificationDetails()),
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
}
