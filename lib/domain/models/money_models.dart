import '../../core/utils/json.dart';
import 'entity.dart';
import 'enums.dart';

/// An expense or extra income entry.
class MoneyTransaction extends Entity {
  const MoneyTransaction({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.category,
    required this.date,
    this.description = '',
    this.merchant,
    this.source = TransactionSource.manual,
  }) : assert(amountMinor >= 0);

  factory MoneyTransaction.fromJson(Map<String, dynamic> j) => MoneyTransaction(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    type: J.enumByName(TransactionType.values, j['type'], TransactionType.expense),
    amountMinor: J.integer(j, 'amountMinor').abs(),
    currency: J.str(j, 'currency', 'USD'),
    category: J.enumByName(ExpenseCategory.values, j['category'], ExpenseCategory.other),
    date: J.date(j, 'date') ?? Meta.updated(j),
    description: J.str(j, 'description'),
    merchant: J.strOrNull(j, 'merchant'),
    source: J.enumByName(TransactionSource.values, j['source'], TransactionSource.manual),
  );

  static const codec = EntityCodec<MoneyTransaction>(collection: 'transactions', fromJson: MoneyTransaction.fromJson);

  final TransactionType type;

  /// Always positive; the sign comes from [type].
  final int amountMinor;
  final String currency;
  final ExpenseCategory category;
  final DateTime date;
  final String description;
  final String? merchant;
  final TransactionSource source;

  bool get isExpense => type == TransactionType.expense;

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'amountMinor': amountMinor,
    'currency': currency,
    'category': category.name,
    'date': date.millisecondsSinceEpoch,
    'description': description,
    if (merchant != null) 'merchant': merchant,
    'source': source.name,
  };

  MoneyTransaction copyWith({
    int? amountMinor,
    ExpenseCategory? category,
    DateTime? date,
    String? description,
    bool? deleted,
  }) => MoneyTransaction(
    id: id,
    updatedAt: DateTime.now(),
    deleted: deleted ?? this.deleted,
    type: type,
    amountMinor: amountMinor ?? this.amountMinor,
    currency: currency,
    category: category ?? this.category,
    date: date ?? this.date,
    description: description ?? this.description,
    merchant: merchant,
    source: source,
  );
}

/// A spending limit for a week or month, optionally scoped to one category.
class Budget extends Entity {
  const Budget({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.period,
    required this.periodStart,
    required this.limitMinor,
    required this.currency,
    this.category,
  });

  factory Budget.fromJson(Map<String, dynamic> j) => Budget(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    period: J.enumByName(BudgetPeriod.values, j['period'], BudgetPeriod.month),
    periodStart: J.date(j, 'periodStart') ?? Meta.updated(j),
    limitMinor: J.integer(j, 'limitMinor'),
    currency: J.str(j, 'currency', 'USD'),
    category: j['category'] == null ? null : J.enumByName(ExpenseCategory.values, j['category'], ExpenseCategory.other),
  );

  static const codec = EntityCodec<Budget>(collection: 'budgets', fromJson: Budget.fromJson);

  final BudgetPeriod period;
  final DateTime periodStart;
  final int limitMinor;
  final String currency;

  /// `null` means the limit applies to all variable spending.
  final ExpenseCategory? category;

  DateTime get periodEnd => period == BudgetPeriod.week
      ? DateTime(periodStart.year, periodStart.month, periodStart.day + 7)
      : DateTime(periodStart.year, periodStart.month + 1);

  bool covers(DateTime d) => !d.isBefore(periodStart) && d.isBefore(periodEnd);

  @override
  Map<String, dynamic> toJson() => {
    'period': period.name,
    'periodStart': periodStart.millisecondsSinceEpoch,
    'limitMinor': limitMinor,
    'currency': currency,
    if (category != null) 'category': category!.name,
  };
}

/// A savings jar ("Kumbara"): a target amount the user puts money into.
class SavingsGoal extends Entity {
  const SavingsGoal({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.name,
    required this.targetMinor,
    this.savedMinor = 0,
    this.deadline,
    this.emoji = '🎯',
    required this.createdAt,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    name: J.str(j, 'name'),
    targetMinor: J.integer(j, 'targetMinor'),
    savedMinor: J.integer(j, 'savedMinor'),
    deadline: J.date(j, 'deadline'),
    emoji: J.str(j, 'emoji', '🎯'),
    createdAt: J.date(j, 'createdAt') ?? Meta.updated(j),
  );

  static const codec = EntityCodec<SavingsGoal>(collection: 'savings_goals', fromJson: SavingsGoal.fromJson);

  final String name;
  final int targetMinor;
  final int savedMinor;
  final DateTime? deadline;
  final String emoji;
  final DateTime createdAt;

  double get progress => targetMinor <= 0 ? 0 : (savedMinor / targetMinor).clamp(0, 1).toDouble();
  bool get reached => savedMinor >= targetMinor;

  /// How much to put aside each month to reach the target by [deadline]
  /// (null without a deadline; the rest when the deadline is this month).
  int? monthlyNeededMinor(DateTime now) {
    if (deadline == null || reached) return null;
    final months = (deadline!.year - now.year) * 12 + deadline!.month - now.month + 1;
    final left = targetMinor - savedMinor;
    return months <= 1 ? left : (left + months - 1) ~/ months;
  }

  SavingsGoal copyWith({
    String? name,
    int? targetMinor,
    int? savedMinor,
    DateTime? deadline,
    bool clearDeadline = false,
    String? emoji,
  }) => SavingsGoal(
    id: id,
    updatedAt: DateTime.now(),
    name: name ?? this.name,
    targetMinor: targetMinor ?? this.targetMinor,
    savedMinor: savedMinor ?? this.savedMinor,
    deadline: clearDeadline ? null : (deadline ?? this.deadline),
    emoji: emoji ?? this.emoji,
    createdAt: createdAt,
  );

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'targetMinor': targetMinor,
    'savedMinor': savedMinor,
    if (deadline != null) 'deadline': deadline!.millisecondsSinceEpoch,
    'emoji': emoji,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}

/// A bill or subscription that comes every month on [dayOfMonth].
class RecurringBill extends Entity {
  const RecurringBill({
    required super.id,
    required super.updatedAt,
    super.deleted,
    required this.name,
    required this.amountMinor,
    required this.category,
    required this.dayOfMonth,
    this.lastPaidMonth,
    this.remind = true,
  });

  factory RecurringBill.fromJson(Map<String, dynamic> j) => RecurringBill(
    id: Meta.idOf(j),
    updatedAt: Meta.updated(j),
    deleted: Meta.isDeleted(j),
    name: J.str(j, 'name'),
    amountMinor: J.integer(j, 'amountMinor'),
    category: J.enumByName(ExpenseCategory.values, j['category'], ExpenseCategory.bills),
    dayOfMonth: J.integer(j, 'dayOfMonth', 1).clamp(1, 31),
    lastPaidMonth: J.strOrNull(j, 'lastPaidMonth'),
    remind: J.boolean(j, 'remind', true),
  );

  static const codec = EntityCodec<RecurringBill>(collection: 'recurring_bills', fromJson: RecurringBill.fromJson);

  final String name;
  final int amountMinor;
  final ExpenseCategory category;
  final int dayOfMonth;

  /// `yyyy-MM` of the last month it was marked paid.
  final String? lastPaidMonth;
  final bool remind;

  /// The due date in the month of [now] (day clamped to the month's length).
  DateTime dueIn(DateTime now) {
    final last = DateTime(now.year, now.month + 1, 0).day;
    return DateTime(now.year, now.month, dayOfMonth > last ? last : dayOfMonth);
  }

  RecurringBill copyWith({
    String? name,
    int? amountMinor,
    ExpenseCategory? category,
    int? dayOfMonth,
    String? lastPaidMonth,
    bool? remind,
  }) => RecurringBill(
    id: id,
    updatedAt: DateTime.now(),
    name: name ?? this.name,
    amountMinor: amountMinor ?? this.amountMinor,
    category: category ?? this.category,
    dayOfMonth: dayOfMonth ?? this.dayOfMonth,
    lastPaidMonth: lastPaidMonth ?? this.lastPaidMonth,
    remind: remind ?? this.remind,
  );

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'amountMinor': amountMinor,
    'category': category.name,
    'dayOfMonth': dayOfMonth,
    if (lastPaidMonth != null) 'lastPaidMonth': lastPaidMonth,
    'remind': remind,
  };
}
