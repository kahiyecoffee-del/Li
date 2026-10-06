import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/ai/ai_action.dart';
import 'package:lifeos/domain/ai/ai_action_validator.dart';
import 'package:lifeos/domain/models/enums.dart';

void main() {
  final v = AiActionValidator(clock: () => DateTime(2026, 6, 10, 12));

  test('valid create_task with time becomes a scheduled task', () {
    final r = v.validate({
      'intent': 'create_task',
      'requires_confirmation': false, // ignored: confirmation is always required
      'data': {'title': 'Meeting', 'date': '2026-06-11', 'time': '09:00', 'duration_minutes': 60, 'priority': 'high'},
    });
    expect(r.isValid, isTrue);
    final a = r.action! as CreateTaskAction;
    expect(a.scheduledAt, DateTime(2026, 6, 11, 9));
    expect(a.durationMinutes, 60);
    expect(a.priority, TaskPriority.high);
    expect(a.requiresConfirmation, isTrue);
  });

  test('date without time becomes a deadline', () {
    final a =
        v.validate({
              'intent': 'create_task',
              'data': {'title': 'Pay rent', 'date': '2026-06-30'},
            }).action!
            as CreateTaskAction;
    expect(a.deadline, DateTime(2026, 6, 30));
    expect(a.scheduledAt, isNull);
  });

  test('unknown or dangerous intents are rejected', () {
    for (final intent in ['transfer_money', 'run_code', 'delete_account', null, 42]) {
      final r = v.validate({
        'intent': intent,
        'data': {'amount': 100},
      });
      expect(r.isValid, isFalse, reason: '$intent');
      expect(r.rejection, ActionRejection.unknownIntent);
    }
  });

  test('non-object input rejected', () {
    expect(v.validate('create_task').rejection, ActionRejection.notAnObject);
    expect(v.validate(null).rejection, ActionRejection.notAnObject);
  });

  test('amounts are converted to minor units and bounded', () {
    final a =
        v.validate({
              'intent': 'create_budget',
              'data': {'period': 'week', 'amount': 10000},
            }).action!
            as CreateBudgetAction;
    expect(a.amountMinor, 1000000);
    expect(a.period, BudgetPeriod.week);
    expect(
      v.validate({
        'intent': 'add_expense',
        'data': {'amount': -5},
      }).rejection,
      ActionRejection.outOfRange,
    );
    expect(
      v.validate({
        'intent': 'add_expense',
        'data': {'amount': 1e15},
      }).rejection,
      ActionRejection.outOfRange,
    );
    expect(v.validate({'intent': 'add_expense', 'data': {}}).rejection, ActionRejection.missingField);
    expect(
      v.validate({
        'intent': 'add_expense',
        'data': {'amount': '250,50'},
      }).isValid,
      isTrue,
    );
  });

  test('missing or oversized text rejected', () {
    expect(v.validate({'intent': 'create_task', 'data': {}}).rejection, ActionRejection.missingField);
    expect(
      v.validate({
        'intent': 'create_task',
        'data': {'title': 'x' * 500},
      }).rejection,
      ActionRejection.outOfRange,
    );
    expect(
      v.validate({
        'intent': 'create_task',
        'data': {'title': 7},
      }).rejection,
      ActionRejection.invalidValue,
    );
  });

  test('dates far in the past/future rejected', () {
    expect(
      v.validate({
        'intent': 'create_task',
        'data': {'title': 'a', 'date': '1999-01-01'},
      }).rejection,
      ActionRejection.outOfRange,
    );
    expect(
      v.validate({
        'intent': 'create_task',
        'data': {'title': 'a', 'date': 'tomorrow'},
      }).rejection,
      ActionRejection.invalidValue,
    );
  });

  test('shopping items are cleaned and deduplicated', () {
    final a =
        v.validate({
              'intent': 'add_shopping_items',
              'data': {
                'items': ['Milk', 'Milk', '', 5, 'Eggs'],
              },
            }).action!
            as AddShoppingItemsAction;
    expect(a.items, ['Milk', 'Eggs']);
  });

  test('mood must be 1–5; memory needs valid category', () {
    expect(
      v.validate({
        'intent': 'log_mood',
        'data': {'mood': 6},
      }).rejection,
      ActionRejection.outOfRange,
    );
    expect(
      v.validate({
        'intent': 'log_mood',
        'data': {'mood': 4},
      }).isValid,
      isTrue,
    );
    expect(
      v.validate({
        'intent': 'save_memory',
        'data': {'category': 'secrets', 'content': 'x'},
      }).isValid,
      isFalse,
    );
    final m = v.validate({
      'intent': 'save_memory',
      'data': {'category': 'food', 'content': 'Vegetarian'},
    });
    expect((m.action! as SaveMemoryAction).category, MemoryCategory.food);
  });

  test('snake_case enum values accepted', () {
    final a = v.validate({
      'intent': 'add_expense',
      'data': {'amount': 10, 'category': 'food'},
    }).action!;
    expect((a as AddExpenseAction).category, ExpenseCategory.food);
  });

  test('validateAll drops invalid entries and caps count', () {
    final list = [
      for (var i = 0; i < 8; i++)
        {
          'intent': 'log_mood',
          'data': {'mood': 3},
        },
      {'intent': 'hack'},
    ];
    expect(v.validateAll(list).length, 5);
    expect(v.validateAll('nope'), isEmpty);
  });
}
