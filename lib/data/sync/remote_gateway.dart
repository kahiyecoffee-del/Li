/// A page of remote changes.
class RemotePage {
  const RemotePage(this.records, this.cursor, {required this.hasMore});

  /// Records including sync metadata (`id`, `updatedAt`, `deleted`).
  final List<Map<String, dynamic>> records;

  /// Opaque cursor to resume from (null when unchanged).
  final String? cursor;
  final bool hasMore;
}

/// Cloud persistence used by [SyncEngine]. Implemented by
/// `FirestoreSyncGateway`; tests use an in-memory fake.
abstract class RemoteSyncGateway {
  /// Uploads a record. Implementations must stamp a server-side change time
  /// used for [changesSince] cursors.
  Future<void> upsert(String uid, String collection, String id, Map<String, dynamic> record);

  /// Records changed after [cursor] (exclusive), ordered by server change
  /// time, at most [limit] per page.
  Future<RemotePage> changesSince(String uid, String collection, String? cursor, {int limit = 200});
}
