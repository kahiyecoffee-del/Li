import 'package:lifeos/data/sync/remote_gateway.dart';

/// In-memory stand-in for Firestore with a monotonically increasing server
/// clock, mirroring the `_serverTs` cursor semantics.
class FakeGateway implements RemoteSyncGateway {
  final Map<String, Map<String, ({int ts, Map<String, dynamic> data})>> _cols = {};
  int _serverClock = 0;
  bool offline = false;
  int upserts = 0;

  String _key(String uid, String c) => '$uid/$c';

  @override
  Future<void> upsert(String uid, String collection, String id, Map<String, dynamic> record) async {
    if (offline) throw Exception('offline');
    upserts++;
    _cols.putIfAbsent(_key(uid, collection), () => {})[id] = (ts: ++_serverClock, data: Map.of(record));
  }

  @override
  Future<RemotePage> changesSince(String uid, String collection, String? cursor, {int limit = 200}) async {
    if (offline) throw Exception('offline');
    final after = cursor == null ? 0 : int.parse(cursor);
    final rows = (_cols[_key(uid, collection)] ?? {}).entries.where((e) => e.value.ts > after).toList()
      ..sort((a, b) => a.value.ts.compareTo(b.value.ts));
    final page = rows.take(limit).toList();
    return RemotePage(
      page.map((e) => {...e.value.data, 'id': e.key}).toList(),
      page.isEmpty ? null : '${page.last.value.ts}',
      hasMore: rows.length > limit,
    );
  }

  Map<String, dynamic>? doc(String uid, String collection, String id) => _cols[_key(uid, collection)]?[id]?.data;
}
