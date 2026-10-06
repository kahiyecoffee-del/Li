import '../../core/utils/money.dart';
import '../models/enums.dart';
import 'ai_action.dart';

enum ActionRejection { notAnObject, unknownIntent, missingField, invalidValue, outOfRange }

class ValidationResult {
  const ValidationResult.ok(AiAction this.action) : rejection = null, field = null;

  const ValidationResult.rejected(ActionRejection this.rejection, [this.field]) : action = null;

  final AiAction? action;
  final ActionRejection? rejection;
  final String? field;

  bool get isValid => action != null;
}

/// Validates raw JSON proposed by the model before anything is shown or run.
///
/// Expected shape:
/// ```json
/// {"intent": "create_task", "requires_confirmation": true,
///  "data": {"title": "Gym", "date": "2026-01-02T18:00:00", "duration_minutes": 60}}
/// ```
/// Amounts are in major units (e.g. 250.50) and converted to minor units here.
class AiActionValidator {
  const AiActionValidator({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  static const maxTitle = 120;
  static const maxText = 500;
  static const maxAmountMinor = 100000000000; // 1 billion major units
  static const maxShoppingItems = 40;

  ValidationResult validate(Object? raw) {
    if (raw is! Map) return const ValidationResult.rejected(ActionRejection.notAnObject);
    final intent = AiIntent.fromWire(raw['intent']);
    if (intent == null) return const ValidationResult.rejected(ActionRejection.unknownIntent, 'intent');
    final dataRaw = raw['data'];
    final data = dataRaw is Map ? dataRaw.map((k, v) => MapEntry('$k', v)) : <String, dynamic>{};
    try {
      return ValidationResult.ok(_build(intent, data));
    } on _Reject catch (e) {
      return ValidationResult.rejected(e.reason, e.field);
    }
  }

  /// Validates a list, dropping invalid entries.
  List<AiAction> validateAll(Object? raw) {
    if (raw is! List) return const [];
    return raw.map(validate).where((r) => r.isValid).map((r) => r.action!).take(5).toList();
  }

  AiAction _build(AiIntent intent, Map<String, dynamic> d) {
    switch (intent) {
      case AiIntent.createTask:
        final dt = _optDate(d, 'date');
        final hasTime = dt != null && (dt.hour != 0 || dt.minute != 0 || d['time'] != null);
        return CreateTaskAction(
          title: _text(d, 'title', maxTitle),
          scheduledAt: hasTime ? dt : null,
          deadline: hasTime ? null : dt,
          durationMinutes: _optInt(d, 'duration_minutes', 5, 12 * 60) ?? 30,
          priority: _optEnum(TaskPriority.values, d['priority']) ?? TaskPriority.medium,
          category: _optEnum(TaskCategory.values, d['category']) ?? TaskCategory.personal,
        );
      case AiIntent.optimizePlan:
        return const OptimizePlanAction();
      case AiIntent.createBudget:
        return CreateBudgetAction(
          period: _optEnum(BudgetPeriod.values, d['period']) ?? BudgetPeriod.month,
          amountMinor: _amount(d, 'amount'),
          category: _optEnum(ExpenseCategory.values, d['category']),
        );
      case AiIntent.addExpense:
        return AddExpenseAction(
          amountMinor: _amount(d, 'amount'),
          category: _optEnum(ExpenseCategory.values, d['category']) ?? ExpenseCategory.other,
          description: _optText(d, 'description', maxTitle) ?? '',
          date: _optDate(d, 'date') ?? _clock(),
        );
      case AiIntent.setSavingsGoal:
        return SetSavingsGoalAction(_amount(d, 'amount'));
      case AiIntent.generateMealPlan:
        return GenerateMealPlanAction(
          date: _optDate(d, 'date') ?? _clock(),
          usePantry: d['use_pantry'] is bool ? d['use_pantry'] as bool : true,
        );
      case AiIntent.addShoppingItems:
        final items = d['items'];
        if (items is! List) throw const _Reject(ActionRejection.missingField, 'items');
        final names = items
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty && s.length <= 60)
            .toSet()
            .take(maxShoppingItems)
            .toList();
        if (names.isEmpty) throw const _Reject(ActionRejection.invalidValue, 'items');
        return AddShoppingItemsAction(names);
      case AiIntent.createHabit:
        return CreateHabitAction(
          name: _text(d, 'name', 60),
          type: _optEnum(HabitType.values, d['type']) ?? HabitType.custom,
          targetPerDay: _optInt(d, 'target_per_day', 1, 100) ?? 1,
        );
      case AiIntent.logMood:
        final mood = _optInt(d, 'mood', 1, 5);
        if (mood == null) throw const _Reject(ActionRejection.missingField, 'mood');
        return LogMoodAction(mood, note: _optText(d, 'note', maxText));
      case AiIntent.saveMemory:
        final cat = _optEnum(MemoryCategory.values, d['category']);
        if (cat == null) throw const _Reject(ActionRejection.invalidValue, 'category');
        return SaveMemoryAction(category: cat, content: _text(d, 'content', 200));
    }
  }

  String _text(Map<String, dynamic> d, String k, int max) {
    final v = _optText(d, k, max);
    if (v == null) throw _Reject(ActionRejection.missingField, k);
    return v;
  }

  String? _optText(Map<String, dynamic> d, String k, int max) {
    final v = d[k];
    if (v == null) return null;
    if (v is! String) throw _Reject(ActionRejection.invalidValue, k);
    // Strip control characters; AI text is rendered, never executed.
    final s = v.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ').trim();
    if (s.isEmpty) return null;
    if (s.length > max) throw _Reject(ActionRejection.outOfRange, k);
    return s;
  }

  int _amount(Map<String, dynamic> d, String k) {
    final v = d[k];
    int? minor;
    if (v is num) {
      if (v.isNaN || v.isInfinite) throw _Reject(ActionRejection.invalidValue, k);
      minor = (v * 100).round();
    } else if (v is String) {
      minor = Money.parseMinor(v);
    }
    if (minor == null) throw _Reject(ActionRejection.missingField, k);
    if (minor <= 0 || minor > maxAmountMinor) throw _Reject(ActionRejection.outOfRange, k);
    return minor;
  }

  int? _optInt(Map<String, dynamic> d, String k, int min, int max) {
    final v = d[k];
    if (v == null) return null;
    final i = v is num ? v.round() : (v is String ? int.tryParse(v) : null);
    if (i == null) throw _Reject(ActionRejection.invalidValue, k);
    if (i < min || i > max) throw _Reject(ActionRejection.outOfRange, k);
    return i;
  }

  DateTime? _optDate(Map<String, dynamic> d, String k) {
    final v = d[k];
    if (v == null) return null;
    if (v is! String) throw _Reject(ActionRejection.invalidValue, k);
    var dt = DateTime.tryParse(v);
    if (dt == null) throw _Reject(ActionRejection.invalidValue, k);
    final time = d['time'];
    if (time is String) {
      final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(time.trim());
      if (m != null) {
        final h = int.parse(m.group(1)!);
        final mi = int.parse(m.group(2)!);
        if (h < 24 && mi < 60) dt = DateTime(dt.year, dt.month, dt.day, h, mi);
      }
    }
    // The model works in the user's local time; drop any zone it attached.
    if (dt.isUtc) dt = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
    final now = _clock();
    if (dt.isBefore(now.subtract(const Duration(days: 366))) || dt.isAfter(now.add(const Duration(days: 731)))) {
      throw _Reject(ActionRejection.outOfRange, k);
    }
    return dt;
  }

  T? _optEnum<T extends Enum>(List<T> values, Object? v) {
    if (v == null) return null;
    for (final e in values) {
      if (e.name == v || _snake(e.name) == v) return e;
    }
    return null;
  }

  static String _snake(String camel) => camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
}

class _Reject implements Exception {
  const _Reject(this.reason, [this.field]);

  final ActionRejection reason;
  final String? field;
}
