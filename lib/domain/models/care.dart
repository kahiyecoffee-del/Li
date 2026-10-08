import '../../core/utils/json.dart';
import 'entity.dart';

/// Money between you and someone else: "I owe Ali 300" or "Ayşe owes me 460".
class Debt extends Entity {
  const Debt({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.person,
    required this.amountMinor,
    required this.theyOwe,
    this.note = '',
    this.due,
    this.settledAt,
    required this.createdAt,
  });

  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    person: J.str(j, 'person'),
    amountMinor: J.integer(j, 'amountMinor'),
    theyOwe: J.boolean(j, 'theyOwe', true),
    note: J.str(j, 'note'),
    due: J.date(j, 'due'),
    settledAt: J.date(j, 'settledAt'),
    createdAt: J.date(j, 'createdAt') ?? Meta.updated(j),
  );

  static const codec = EntityCodec<Debt>(collection: 'debts', fromJson: Debt.fromJson);

  final String person;
  final int amountMinor;

  /// True: they owe me. False: I owe them.
  final bool theyOwe;
  final String note;
  final DateTime? due;
  final DateTime? settledAt;
  final DateTime createdAt;

  bool get isOpen => !deleted && settledAt == null;

  /// Positive when they owe me.
  int get signedMinor => theyOwe ? amountMinor : -amountMinor;

  Debt copyWith({
    String? person,
    int? amountMinor,
    bool? theyOwe,
    String? note,
    DateTime? due,
    bool clearDue = false,
    DateTime? settledAt,
    bool reopen = false,
  }) => Debt(
    id: id,
    updatedAt: DateTime.now(),
    person: person ?? this.person,
    amountMinor: amountMinor ?? this.amountMinor,
    theyOwe: theyOwe ?? this.theyOwe,
    note: note ?? this.note,
    due: clearDue ? null : (due ?? this.due),
    settledAt: reopen ? null : (settledAt ?? this.settledAt),
    createdAt: createdAt,
  );

  @override
  Map<String, dynamic> toJson() => {
    'person': person,
    'amountMinor': amountMinor,
    'theyOwe': theyOwe,
    if (note.isNotEmpty) 'note': note,
    if (due != null) 'due': due!.millisecondsSinceEpoch,
    if (settledAt != null) 'settledAt': settledAt!.millisecondsSinceEpoch,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}

/// A medicine or supplement taken at set times each day.
class Medication extends Entity {
  const Medication({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.name,
    this.dose = '',
    required this.times,
    this.stock,
    this.perDose = 1,
    this.active = true,
    required this.createdAt,
  });

  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    name: J.str(j, 'name'),
    dose: J.str(j, 'dose'),
    times: J.strList(j, 'times').where(validTime).toList()..sort(),
    stock: J.intOrNull(j, 'stock'),
    perDose: J.integer(j, 'perDose', 1).clamp(1, 20),
    active: J.boolean(j, 'active', true),
    createdAt: J.date(j, 'createdAt') ?? Meta.updated(j),
  );

  static const codec = EntityCodec<Medication>(collection: 'medications', fromJson: Medication.fromJson);

  static bool validTime(String t) => RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(t);

  /// Warn when this many days of pills are left.
  static const refillDays = 5;

  final String name;

  /// Free text such as "500 mg" or "1 tablet".
  final String dose;

  /// "HH:mm", sorted.
  final List<String> times;

  /// Pills (or doses) left; null when not tracked.
  final int? stock;
  final int perDose;
  final bool active;
  final DateTime createdAt;

  /// Days the stock lasts at the current schedule (null when not tracked).
  int? get daysLeft {
    final s = stock;
    if (s == null || times.isEmpty) return null;
    return s ~/ (perDose * times.length);
  }

  bool get needsRefill => active && daysLeft != null && daysLeft! <= refillDays;

  Medication copyWith({
    String? name,
    String? dose,
    List<String>? times,
    int? stock,
    bool clearStock = false,
    int? perDose,
    bool? active,
  }) => Medication(
    id: id,
    updatedAt: DateTime.now(),
    name: name ?? this.name,
    dose: dose ?? this.dose,
    times: times ?? this.times,
    stock: clearStock ? null : (stock ?? this.stock),
    perDose: perDose ?? this.perDose,
    active: active ?? this.active,
    createdAt: createdAt,
  );

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    if (dose.isNotEmpty) 'dose': dose,
    'times': times,
    if (stock != null) 'stock': stock,
    'perDose': perDose,
    'active': active,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}

/// One dose taken (id: `medId|yyyy-MM-dd|HH:mm`).
class MedDose extends Entity {
  const MedDose({required super.id, required super.updatedAt, super.deleted, required this.takenAt});

  factory MedDose.fromJson(Map<String, dynamic> j) => MedDose(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    takenAt: J.date(j, 'takenAt') ?? Meta.updated(j),
  );

  static const codec = EntityCodec<MedDose>(collection: 'med_doses', fromJson: MedDose.fromJson);

  static String idFor(String medId, String dayKey, String time) => '$medId|$dayKey|$time';

  final DateTime takenAt;

  String get medId => id.split('|').first;

  @override
  Map<String, dynamic> toJson() => {'takenAt': takenAt.millisecondsSinceEpoch};
}
