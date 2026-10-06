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
