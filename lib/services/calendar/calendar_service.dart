import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';

/// An event from the phone's calendar, shown on the planner as busy time.
@immutable
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool allDay;

  int get minutes => end.difference(start).inMinutes;
}

/// Read-only access to the device calendar (Google, iCloud, Outlook… —
/// whatever the phone syncs). Nothing is uploaded or changed.
abstract class CalendarService {
  bool get supported;
  Future<bool> hasAccess();
  Future<bool> requestAccess();
  Future<List<CalendarEvent>> events(DateTime from, DateTime to);
}

/// Web and tests: no device calendar (tests may hand it events).
class NoCalendarService implements CalendarService {
  NoCalendarService({this.fake = const [], this.granted = false});

  final List<CalendarEvent> fake;
  bool granted;

  @override
  bool get supported => fake.isNotEmpty;

  @override
  Future<bool> hasAccess() async => granted;

  @override
  Future<bool> requestAccess() async => granted = supported;

  @override
  Future<List<CalendarEvent>> events(DateTime from, DateTime to) async =>
      fake.where((e) => e.start.isBefore(to) && e.end.isAfter(from)).toList();
}

class DeviceCalendarService implements CalendarService {
  final _plugin = DeviceCalendar.instance;

  @override
  bool get supported => true;

  @override
  Future<bool> hasAccess() async {
    try {
      return await _plugin.hasPermissions() == CalendarPermissionStatus.granted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestAccess() async {
    try {
      return await _plugin.requestPermissions() == CalendarPermissionStatus.granted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<CalendarEvent>> events(DateTime from, DateTime to) async {
    try {
      final list = await _plugin.listEvents(from, to);
      return [
        for (final e in list)
          if (e.status != EventStatus.canceled)
            CalendarEvent(
              id: e.instanceId,
              title: e.title.trim().isEmpty ? '—' : e.title.trim(),
              start: e.startDate,
              end: e.endDate,
              allDay: e.isAllDay,
            ),
      ];
    } catch (e) {
      debugPrint('calendar read failed: $e');
      return const [];
    }
  }
}
