import '../../core/utils/json.dart';
import 'entity.dart';

/// Something the user kept from a solved problem: an answer, a decision, a
/// recipe or a written text. [payload] holds the inputs so it can be
/// reopened and re-run.
class SavedItem extends Entity {
  const SavedItem({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.kind,
    required this.title,
    this.summary = '',
    this.payload = const {},
    required this.createdAt,
  });

  factory SavedItem.fromJson(Map<String, dynamic> j) => SavedItem(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    kind: J.str(j, 'kind'),
    title: J.str(j, 'title'),
    summary: J.str(j, 'summary'),
    payload: J.map(j, 'payload'),
    createdAt: J.date(j, 'createdAt') ?? Meta.updated(j),
  );

  static const codec = EntityCodec<SavedItem>(collection: 'saved_items', fromJson: SavedItem.fromJson);

  /// A solution kind ("budget_runway", "unit_price", …), "decision",
  /// "recipe" or "text".
  final String kind;
  final String title;
  final String summary;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'title': title,
    'summary': summary,
    'payload': payload,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
