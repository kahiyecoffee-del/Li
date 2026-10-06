import 'dart:async';

import 'package:sembast/sembast.dart';

import '../../domain/models/entity.dart';

/// Pending local change to push to the cloud.
class OutboxEntry {
  const OutboxEntry(this.collection, this.id, this.updatedAtMillis);

  final String collection;
  final String id;

  /// `updatedAt` of the local record when it was enqueued; used to avoid
  /// dropping a newer change that happened while a push was in flight.
  final int updatedAtMillis;
}

/// Offline-first local database (one per signed-in user).
///
/// Records are stored as JSON maps that always contain the sync metadata
/// [Meta.id], [Meta.updatedAt] (epoch ms) and [Meta.deleted].
class LocalStore {
  LocalStore(this._db);

  final Database _db;
  final _outbox = stringMapStoreFactory.store('_outbox');
  final _meta = stringMapStoreFactory.store('_meta');

  StoreRef<String, Map<String, Object?>> _store(String collection) => stringMapStoreFactory.store(collection);

  static Map<String, dynamic> _copy(Map<String, Object?> v) => Map<String, dynamic>.from(v);

  Future<Map<String, dynamic>?> get(String collection, String id) async {
    final v = await _store(collection).record(id).get(_db);
    return v == null ? null : _copy(v);
  }

  Future<List<Map<String, dynamic>>> all(String collection, {bool includeDeleted = false}) async {
    final records = await _store(collection).find(_db);
    return records.map((r) => _copy(r.value)).where((m) => includeDeleted || !Meta.isDeleted(m)).toList();
  }

  /// Emits the live (non-deleted) records of a collection on every change.
  Stream<List<Map<String, dynamic>>> watch(String collection) =>
      _store(collection)
          .query()
          .onSnapshots(_db)
          .map((s) => s.map((r) => _copy(r.value)).where((m) => !Meta.isDeleted(m)).toList());

  Stream<Map<String, dynamic>?> watchOne(String collection, String id) =>
      _store(collection).record(id).onSnapshot(_db).map((s) => s == null ? null : _copy(s.value));

  /// Writes a local change and (for synced collections) queues it for upload,
  /// atomically.
  Future<void> write(String collection, Map<String, dynamic> record, {required bool enqueue}) async {
    final id = Meta.idOf(record);
    assert(id.isNotEmpty, 'record without id');
    await _db.transaction((txn) async {
      await _store(collection).record(id).put(txn, record.cast<String, Object?>());
      if (enqueue) {
        await _outbox.record('$collection/$id').put(txn, {
          'collection': collection,
          'id': id,
          'updatedAt': record[Meta.updatedAt] as int? ?? 0,
        });
      }
    });
  }

  /// Applies a record pulled from the cloud without queuing it.
  Future<void> applyRemote(String collection, Map<String, dynamic> record) =>
      _store(collection).record(Meta.idOf(record)).put(_db, record.cast<String, Object?>());

  Future<void> hardDelete(String collection, String id) => _store(collection).record(id).delete(_db);

  Future<List<OutboxEntry>> pendingOutbox({int limit = 200}) async {
    final rows = await _outbox.find(_db, finder: Finder(limit: limit));
    return rows
        .map(
          (r) => OutboxEntry(
            r.value['collection']! as String,
            r.value['id']! as String,
            r.value['updatedAt'] as int? ?? 0,
          ),
        )
        .toList();
  }

  Future<int> outboxCount() => _outbox.count(_db);

  Stream<int> watchOutboxCount() => _outbox.query().onCount(_db);

  /// Removes an outbox entry only if no newer local write happened since it
  /// was read.
  Future<void> ackOutbox(OutboxEntry e) async {
    await _db.transaction((txn) async {
      final rec = _outbox.record('${e.collection}/${e.id}');
      final cur = await rec.get(txn);
      if (cur != null && (cur['updatedAt'] as int? ?? 0) <= e.updatedAtMillis) {
        await rec.delete(txn);
      }
    });
  }

  Future<void> enqueue(String collection, String id, int updatedAtMillis) =>
      _outbox.record('$collection/$id').put(_db, {'collection': collection, 'id': id, 'updatedAt': updatedAtMillis});

  Future<Object?> getMeta(String key) async => (await _meta.record(key).get(_db))?['v'];

  Future<void> setMeta(String key, Object? value) => _meta.record(key).put(_db, {'v': value});

  /// Purges tombstones older than [age] that are no longer pending upload.
  Future<int> purgeTombstones(String collection, Duration age, DateTime now) async {
    final cutoff = now.subtract(age).millisecondsSinceEpoch;
    final pending = (await pendingOutbox(limit: 100000)).map((e) => '${e.collection}/${e.id}').toSet();
    final finder = Finder(
      filter: Filter.and([Filter.equals(Meta.deleted, true), Filter.lessThan(Meta.updatedAt, cutoff)]),
    );
    final old = await _store(collection).find(_db, finder: finder);
    var n = 0;
    for (final r in old) {
      if (pending.contains('$collection/${r.key}')) continue;
      await _store(collection).record(r.key).delete(_db);
      n++;
    }
    return n;
  }

  /// Every record of every collection, for data export.
  Future<Map<String, List<Map<String, dynamic>>>> dumpAll(Iterable<String> collections) async => {
    for (final c in collections) c: await all(c),
  };

  /// Wipes all local data (account deletion / sign-out).
  Future<void> wipe(Iterable<String> collections) async {
    await _db.transaction((txn) async {
      for (final c in collections) {
        await _store(c).drop(txn);
      }
      await _outbox.drop(txn);
      await _meta.drop(txn);
    });
  }

  Future<void> close() => _db.close();
}
