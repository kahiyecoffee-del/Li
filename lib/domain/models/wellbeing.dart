import '../../core/utils/json.dart';
import 'entity.dart';

/// Self-reported mood, 1 (very low) – 5 (great). Not a medical measurement.
class MoodLog extends Entity {
  const MoodLog({required super.id, required super.updatedAt, super.deleted, required this.mood, this.note})
    : assert(mood >= 1 && mood <= 5);

  factory MoodLog.fromJson(Map<String, dynamic> j) => MoodLog(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    mood: J.integer(j, 'mood', 3).clamp(1, 5),
    note: J.strOrNull(j, 'note'),
  );

  static const codec = EntityCodec<MoodLog>(collection: 'mood_logs', fromJson: MoodLog.fromJson);

  /// Id is the day key: one mood per day.
  String get day => id;
  final int mood;
  final String? note;

  @override
  Map<String, dynamic> toJson() => {'mood': mood, if (note != null) 'note': note};
}

/// Hours slept the night before the given day (id = day key).
class SleepLog extends Entity {
  const SleepLog({required super.id, required super.updatedAt, super.deleted, required this.minutes});

  factory SleepLog.fromJson(Map<String, dynamic> j) => SleepLog(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    minutes: J.integer(j, 'minutes').clamp(0, 24 * 60),
  );

  static const codec = EntityCodec<SleepLog>(collection: 'sleep_logs', fromJson: SleepLog.fromJson);

  String get day => id;
  final int minutes;

  @override
  Map<String, dynamic> toJson() => {'minutes': minutes};
}

/// Private journal entry. Never synced to the cloud and encrypted at rest
/// on device (see `EncryptedJournalRepository`).
class JournalEntry extends Entity {
  const JournalEntry({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.createdAt,
    required this.text,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    createdAt: J.date(j, 'createdAt') ?? Meta.updated(j),
    text: J.str(j, 'text'),
  );

  static const codec = EntityCodec<JournalEntry>(
    collection: 'journal_entries',
    fromJson: JournalEntry.fromJson,
    syncs: false,
  );

  final DateTime createdAt;
  final String text;

  @override
  Map<String, dynamic> toJson() => {'createdAt': createdAt.millisecondsSinceEpoch, 'text': text};
}
