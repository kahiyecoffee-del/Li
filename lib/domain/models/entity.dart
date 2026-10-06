/// Base contract for every persisted record.
///
/// [updatedAt] drives last-write-wins conflict resolution during sync and
/// [deleted] is a tombstone so deletions propagate across devices.
abstract class Entity {
  const Entity({required this.id, required this.updatedAt, this.deleted = false});

  final String id;
  final DateTime updatedAt;
  final bool deleted;

  /// Serializable payload, without sync metadata (added by the store).
  Map<String, dynamic> toJson();
}

/// Serialization descriptor for an entity type stored in a collection.
class EntityCodec<T extends Entity> {
  const EntityCodec({required this.collection, required this.fromJson, this.syncs = true});

  /// Collection name both locally and under `users/{uid}/` in Firestore.
  final String collection;

  /// Builds an entity from a stored map (includes `id`, `updatedAt`, `deleted`).
  final T Function(Map<String, dynamic> json) fromJson;

  /// Whether records are replicated to the cloud. Private data such as the
  /// journal and AI chats stay on device.
  final bool syncs;
}

/// Shared helpers to read the sync metadata embedded in stored maps.
abstract final class Meta {
  static const id = 'id';
  static const updatedAt = 'updatedAt';
  static const deleted = 'deleted';

  static DateTime updated(Map<String, dynamic> j) {
    final v = j[updatedAt];
    return v is int ? DateTime.fromMillisecondsSinceEpoch(v) : DateTime(2000);
  }

  static bool isDeleted(Map<String, dynamic> j) => j[deleted] == true;

  static String idOf(Map<String, dynamic> j) => j[id] as String? ?? '';
}
