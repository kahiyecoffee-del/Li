import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/entity.dart';
import 'remote_gateway.dart';

/// Firestore implementation: `users/{uid}/{collection}/{id}`.
///
/// Each write sets `_serverTs` with a server timestamp. Pulls page through
/// `_serverTs > cursor` ordered by (`_serverTs`, document id); the cursor is
/// `"<micros>|<docId>"` so ties on the timestamp are never skipped.
class FirestoreSyncGateway implements RemoteSyncGateway {
  FirestoreSyncGateway(this._db);

  final FirebaseFirestore _db;
  static const serverTsField = '_serverTs';
  static const timeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _col(String uid, String collection) =>
      _db.collection('users').doc(uid).collection(collection);

  @override
  Future<void> upsert(String uid, String collection, String id, Map<String, dynamic> record) async {
    final data = Map<String, dynamic>.from(record)..[serverTsField] = FieldValue.serverTimestamp();
    if (Meta.isDeleted(record)) {
      // Tombstones keep only metadata.
      data.removeWhere((k, _) => k != Meta.id && k != Meta.updatedAt && k != Meta.deleted && k != serverTsField);
    }
    // Without a timeout an offline write would wait forever; failing lets the
    // record stay in the outbox for the next attempt.
    await _col(uid, collection).doc(id).set(data).timeout(timeout);
  }

  @override
  Future<RemotePage> changesSince(String uid, String collection, String? cursor, {int limit = 200}) async {
    Query<Map<String, dynamic>> q = _col(
      uid,
      collection,
    ).orderBy(serverTsField).orderBy(FieldPath.documentId).limit(limit);
    if (cursor != null) {
      final parts = cursor.split('|');
      final micros = int.tryParse(parts.first);
      if (micros != null && parts.length == 2) {
        q = q.startAfter([Timestamp.fromMicrosecondsSinceEpoch(micros), parts[1]]);
      }
    }
    final snap = await q.get(const GetOptions(source: Source.server)).timeout(timeout);
    final records = <Map<String, dynamic>>[];
    String? next;
    for (final d in snap.docs) {
      final data = Map<String, dynamic>.from(d.data());
      final ts = data.remove(serverTsField);
      // Pending server timestamps (local echo) are skipped; they will be
      // returned once committed.
      if (ts is! Timestamp) continue;
      data[Meta.id] = d.id;
      records.add(data);
      next = '${ts.microsecondsSinceEpoch}|${d.id}';
    }
    return RemotePage(records, next, hasMore: snap.docs.length == limit);
  }
}
