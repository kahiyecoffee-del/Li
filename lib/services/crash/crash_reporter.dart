import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract class CrashReporter {
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false, String? reason});
  Future<void> setUserId(String id);
  Future<void> setEnabled(bool enabled);
}

class CrashlyticsReporter implements CrashReporter {
  CrashlyticsReporter(this._c);

  final FirebaseCrashlytics _c;

  @override
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false, String? reason}) =>
      _c.recordError(error, stack, fatal: fatal, reason: reason);

  @override
  Future<void> setUserId(String id) => _c.setUserIdentifier(id);

  @override
  Future<void> setEnabled(bool enabled) => _c.setCrashlyticsCollectionEnabled(enabled && !kDebugMode);
}

class DebugCrashReporter implements CrashReporter {
  @override
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false, String? reason}) async {
    debugPrint('[crash${fatal ? ' FATAL' : ''}] ${reason ?? ''} $error\n$stack');
  }

  @override
  Future<void> setUserId(String id) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}
