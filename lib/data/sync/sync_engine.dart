import 'dart:async';

import '../../domain/models/entity.dart';
import '../local/local_store.dart';
import 'remote_gateway.dart';

enum SyncStatus { idle, syncing, offline, error, disabled }

class SyncResult {
  const SyncResult({this.pushed = 0, this.pulled = 0, this.conflictsKeptLocal = 0});

  final int pushed;
  final int pulled;

  /// Remote records that lost to a newer local edit (re-queued for upload).
  final int conflictsKeptLocal;
}

/// Bidirectional sync between [LocalStore] and the cloud.
///
/// Conflict resolution is last-write-wins per record using the client
/// `updatedAt` (the time the user made the change). Deletions are
/// tombstones, so a delete on one device beats an older edit on another and
/// vice versa. Pull cursors use server-assigned change times, so a device
/// with a skewed clock cannot cause other devices to miss updates.
///
/// Trade-off (documented in docs/ARCHITECTURE.md): concurrent edits to
/// different fields of the same record are not merged — the most recent
/// whole record wins. Records in Dayly are small and mostly single-purpose
/// (one habit log per habit per day, one mood per day), which keeps this
/// rare.
class SyncEngine {
  SyncEngine({
    required this.store,
    required this.gateway,
    required this.uid,
    required this.collections,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LocalStore store;
  final RemoteSyncGateway gateway;
  final String uid;

  /// Synced collection names.
  final List<String> collections;
  final DateTime Function() _clock;

  final _status = StreamController<SyncStatus>.broadcast();
  SyncStatus _current = SyncStatus.idle;
  Future<SyncResult>? _running;
  Timer? _debounce;

  Stream<SyncStatus> get status => _status.stream;
  SyncStatus get currentStatus => _current;

  void _set(SyncStatus s) {
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  /// Coalesces bursts of local writes into one sync.
  void scheduleSync([Duration delay = const Duration(seconds: 3)]) {
    _debounce?.cancel();
    _debounce = Timer(delay, () => unawaited(sync().catchError((Object _) => const SyncResult())));
  }

  /// Runs push then pull. Concurrent calls share the same run.
  Future<SyncResult> sync() => _running ??= _run().whenComplete(() => _running = null);

  Future<SyncResult> _run() async {
    _set(SyncStatus.syncing);
    try {
      final pushed = await _push();
      var pulled = 0;
      var kept = 0;
      for (final c in collections) {
        final r = await _pull(c);
        pulled += r.$1;
        kept += r.$2;
      }
      if (kept > 0) await _push();
      await _purge();
      _set(SyncStatus.idle);
      return SyncResult(pushed: pushed, pulled: pulled, conflictsKeptLocal: kept);
    } catch (e) {
      _set(SyncStatus.error);
      rethrow;
    }
  }

  Future<int> _push() async {
    var n = 0;
    // Bounded rounds: records edited while a push is in flight stay queued
    // and are picked up by the next round or the next sync.
    for (var round = 0; round < 20; round++) {
      final batch = await store.pendingOutbox(limit: 100);
      if (batch.isEmpty) break;
      for (final e in batch) {
        final rec = await store.get(e.collection, e.id);
        if (rec != null) {
          await gateway.upsert(uid, e.collection, e.id, rec);
          n++;
        }
        final uploaded = rec?[Meta.updatedAt] as int? ?? e.updatedAtMillis;
        await store.ackOutbox(OutboxEntry(e.collection, e.id, uploaded));
      }
    }
    return n;
  }

  /// Returns (records applied, conflicts where local won).
  Future<(int, int)> _pull(String collection) async {
    final key = 'cursor:$collection';
    var cursor = await store.getMeta(key) as String?;
    var applied = 0;
    var keptLocal = 0;
    while (true) {
      final page = await gateway.changesSince(uid, collection, cursor);
      for (final remote in page.records) {
        final id = Meta.idOf(remote);
        if (id.isEmpty) continue;
        final local = await store.get(collection, id);
        final winner = resolve(local, remote);
        if (identical(winner, remote)) {
          await store.applyRemote(collection, remote);
          applied++;
        } else if (local != null && Meta.updated(local).isAfter(Meta.updated(remote))) {
          // Local edit is newer: make sure it gets (re-)uploaded.
          await store.enqueue(collection, id, local[Meta.updatedAt] as int? ?? 0);
          keptLocal++;
        }
      }
      if (page.cursor != null) {
        cursor = page.cursor;
        await store.setMeta(key, cursor);
      }
      if (!page.hasMore) break;
    }
    return (applied, keptLocal);
  }

  /// Last-write-wins. Ties prefer the tombstone (deletes are intentional),
  /// then the remote copy (so all devices converge on the server's state).
  static Map<String, dynamic> resolve(Map<String, dynamic>? local, Map<String, dynamic> remote) {
    if (local == null) return remote;
    final l = Meta.updated(local);
    final r = Meta.updated(remote);
    if (r.isAfter(l)) return remote;
    if (l.isAfter(r)) return local;
    if (Meta.isDeleted(local) && !Meta.isDeleted(remote)) return local;
    return remote;
  }

  Future<void> _purge() async {
    final last = await store.getMeta('lastPurge') as int?;
    final now = _clock();
    if (last != null && now.millisecondsSinceEpoch - last < const Duration(days: 1).inMilliseconds) return;
    for (final c in collections) {
      await store.purgeTombstones(c, const Duration(days: 30), now);
    }
    await store.setMeta('lastPurge', now.millisecondsSinceEpoch);
  }

  Future<void> dispose() async {
    _debounce?.cancel();
    await _status.close();
  }
}
