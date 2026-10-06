import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Premium entitlement. Written only by the backend after verifying the
/// purchase with Google Play (clients cannot write `entitlements/{uid}`).
class Entitlement {
  const Entitlement({required this.isPremium, this.expiresAt, this.productId, this.autoRenewing = false});

  static const free = Entitlement(isPremium: false);

  final bool isPremium;
  final DateTime? expiresAt;
  final String? productId;
  final bool autoRenewing;

  /// Premium is honoured until expiry even if the doc is stale (e.g. offline).
  bool activeAt(DateTime now) => isPremium && (expiresAt == null || expiresAt!.isAfter(now));
}

abstract class EntitlementService {
  Stream<Entitlement> watch();
  Entitlement get current;
}

class FirestoreEntitlementService implements EntitlementService {
  FirestoreEntitlementService(this._db, this._uid, this._prefs) : _current = _cached(_prefs);

  final FirebaseFirestore _db;
  final String _uid;
  final SharedPreferences _prefs;
  Entitlement _current;

  static Entitlement _cached(SharedPreferences p) {
    final exp = p.getInt('ent_exp');
    return Entitlement(
      isPremium: p.getBool('ent_premium') ?? false,
      expiresAt: exp == null ? null : DateTime.fromMillisecondsSinceEpoch(exp),
      productId: p.getString('ent_product'),
    );
  }

  @override
  Entitlement get current => _current;

  @override
  Stream<Entitlement> watch() async* {
    yield _current;
    yield* _db
        .collection('entitlements')
        .doc(_uid)
        .snapshots()
        .map((s) {
          final d = s.data() ?? const {};
          final exp = d['expiresAt'];
          final e = Entitlement(
            isPremium: d['premium'] == true,
            expiresAt: exp is Timestamp ? exp.toDate() : null,
            productId: d['productId'] as String?,
            autoRenewing: d['autoRenewing'] == true,
          );
          _current = e;
          unawaited(_persist(e));
          return e;
        })
        .handleError((Object _) {});
  }

  Future<void> _persist(Entitlement e) async {
    await _prefs.setBool('ent_premium', e.isPremium);
    if (e.expiresAt != null) {
      await _prefs.setInt('ent_exp', e.expiresAt!.millisecondsSinceEpoch);
    } else {
      await _prefs.remove('ent_exp');
    }
    if (e.productId != null) await _prefs.setString('ent_product', e.productId!);
  }
}

class StaticEntitlementService implements EntitlementService {
  StaticEntitlementService([this.current = Entitlement.free]);

  @override
  Entitlement current;

  @override
  Stream<Entitlement> watch() => Stream.value(current);
}
