import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Registers the FCM token so the backend can send the weekly report push.
/// Tokens live in `users/{uid}/devices/{token}` and are removed on sign-out.
class PushService {
  PushService(this._fcm, this._db, {required this.onForegroundMessage});

  final FirebaseMessaging _fcm;
  final FirebaseFirestore _db;
  final Future<void> Function(RemoteMessage) onForegroundMessage;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _msgSub;
  String? _token;

  Future<void> register(String uid, {required String locale, String? timeZone}) async {
    try {
      _token = await _fcm.getToken();
      if (_token != null) await _save(uid, _token!, locale, timeZone);
      await _tokenSub?.cancel();
      _tokenSub = _fcm.onTokenRefresh.listen((t) {
        _token = t;
        unawaited(_save(uid, t, locale, timeZone));
      });
      await _msgSub?.cancel();
      _msgSub = FirebaseMessaging.onMessage.listen((m) => unawaited(onForegroundMessage(m)));
    } catch (_) {
      // Push is optional; local notifications still work.
    }
  }

  Future<void> _save(String uid, String token, String locale, String? tz) => _db
      .collection('users')
      .doc(uid)
      .collection('devices')
      .doc(token)
      .set({'platform': 'android', 'locale': locale, 'timeZone': ?tz, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> unregister(String uid) async {
    final t = _token;
    await _tokenSub?.cancel();
    await _msgSub?.cancel();
    if (t != null) {
      try {
        await _db.collection('users').doc(uid).collection('devices').doc(t).delete();
        await _fcm.deleteToken();
      } catch (_) {}
    }
  }
}
