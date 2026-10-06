import 'dart:async';

import '../../domain/models/entity.dart';
import '../local/local_store.dart';

/// Generic offline-first repository: reads and writes go to the local store;
/// synced collections are queued for upload by the [SyncEngine].
class Repository<T extends Entity> {
  Repository(this._store, this.codec, {DateTime Function()? clock, this.onLocalWrite}) : _clock = clock ?? DateTime.now;

  final LocalStore _store;
  final EntityCodec<T> codec;
  final DateTime Function() _clock;

  /// Invoked after each local write (used to schedule a debounced sync).
  final void Function()? onLocalWrite;

  String get collection => codec.collection;

  T _decode(Map<String, dynamic> m) => codec.fromJson(m);

  Stream<List<T>> watchAll() => _store.watch(collection).map((l) => l.map(_decode).toList());

  Stream<T?> watch(String id) =>
      _store.watchOne(collection, id).map((m) => m == null || Meta.isDeleted(m) ? null : _decode(m));

  Future<List<T>> getAll() async => (await _store.all(collection)).map(_decode).toList();

  Future<T?> get(String id) async {
    final m = await _store.get(collection, id);
    return m == null || Meta.isDeleted(m) ? null : _decode(m);
  }

  /// Saves [entity], stamping a strictly increasing `updatedAt` so the latest
  /// local edit always wins over earlier ones even within the same
  /// millisecond.
  Future<void> save(T entity) async {
    final existing = await _store.get(collection, entity.id);
    await _store.write(collection, _encode(entity.id, entity.toJson(), existing, deleted: false), enqueue: codec.syncs);
    onLocalWrite?.call();
  }

  Future<void> saveAll(Iterable<T> entities) async {
    for (final e in entities) {
      final existing = await _store.get(collection, e.id);
      await _store.write(collection, _encode(e.id, e.toJson(), existing, deleted: false), enqueue: codec.syncs);
    }
    onLocalWrite?.call();
  }

  /// Soft-deletes (tombstones) a record so the deletion syncs to other
  /// devices. The payload is cleared to minimize retained personal data.
  Future<void> delete(String id) async {
    final existing = await _store.get(collection, id);
    if (existing == null) return;
    if (!codec.syncs) {
      await _store.hardDelete(collection, id);
      return;
    }
    await _store.write(collection, _encode(id, const {}, existing, deleted: true), enqueue: true);
    onLocalWrite?.call();
  }

  Future<void> deleteAll() async {
    for (final m in await _store.all(collection)) {
      await delete(Meta.idOf(m));
    }
  }

  Map<String, dynamic> _encode(
    String id,
    Map<String, dynamic> body,
    Map<String, dynamic>? existing, {
    required bool deleted,
  }) {
    var ts = _clock().millisecondsSinceEpoch;
    final prev = existing?[Meta.updatedAt];
    if (prev is int && prev >= ts) ts = prev + 1;
    return {...body, Meta.id: id, Meta.updatedAt: ts, Meta.deleted: deleted};
  }
}
