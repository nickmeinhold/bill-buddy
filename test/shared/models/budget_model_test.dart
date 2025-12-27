import 'package:bill_buddy/shared/models/budget_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetModel', () {
    group('remaining', () {
      test('calculates correct remaining amount', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Food',
          limit: 500.0,
          spent: 200.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.remaining, equals(300.0));
      });

      test('handles over-budget (negative remaining)', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Shopping',
          limit: 200.0,
          spent: 250.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.remaining, equals(-50.0));
      });

      test('handles zero spent', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Entertainment',
          limit: 100.0,
          spent: 0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.remaining, equals(100.0));
      });
    });

    group('percentUsed', () {
      test('calculates correct percentage', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Food',
          limit: 500.0,
          spent: 250.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.percentUsed, equals(50.0));
      });

      test('returns 0 when limit is 0', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Empty',
          limit: 0,
          spent: 0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.percentUsed, equals(0.0));
      });

      test('clamps to 100 when over budget', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Shopping',
          limit: 100.0,
          spent: 150.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.percentUsed, equals(100.0));
      });

      test('clamps to 0 for negative values', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Test',
          limit: 100.0,
          spent: -50.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.percentUsed, greaterThanOrEqualTo(0.0));
      });
    });

    group('isOverBudget', () {
      test('returns true when spent exceeds limit', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Shopping',
          limit: 200.0,
          spent: 250.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.isOverBudget, isTrue);
      });

      test('returns false when under budget', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Food',
          limit: 500.0,
          spent: 250.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.isOverBudget, isFalse);
      });

      test('returns false when exactly at limit', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Entertainment',
          limit: 100.0,
          spent: 100.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.isOverBudget, isFalse);
      });
    });

    group('isNearLimit', () {
      test('returns true when between 80% and 99%', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Entertainment',
          limit: 100.0,
          spent: 85.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.isNearLimit, isTrue);
      });

      test('returns true at exactly 80%', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Entertainment',
          limit: 100.0,
          spent: 80.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.isNearLimit, isTrue);
      });

      test('returns false when under 80%', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Food',
          limit: 500.0,
          spent: 300.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.isNearLimit, isFalse);
      });

      test('returns false when at or over 100%', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Shopping',
          limit: 100.0,
          spent: 100.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.isNearLimit, isFalse);
      });

      test('returns false when over budget', () {
        final budget = BudgetModel(
          id: '1',
          category: 'Shopping',
          limit: 100.0,
          spent: 150.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(budget.isNearLimit, isFalse);
      });
    });

    group('serialization', () {
      test('toMap and fromMap round-trip correctly', () {
        final original = BudgetModel(
          id: '1',
          category: 'Food & Dining',
          limit: 500.0,
          spent: 250.0,
          period: BudgetPeriod.monthly,
          startDate: DateTime(2024, 1, 1),
        );

        final map = original.toMap();
        final restored = BudgetModel.fromMap(map, '1');

        expect(restored, equals(original));
      });

      test('defaults to monthly period if unknown', () {
        final map = {
          'category': 'Test',
          'limit': 100.0,
          'spent': 50.0,
          'period': 'unknown_period',
          'startDate': '2024-01-01T00:00:00.000',
        };

        final budget = BudgetModel.fromMap(map, '1');
        expect(budget.period, equals(BudgetPeriod.monthly));
      });

      test('defaults spent to 0 if null', () {
        final map = {
          'category': 'Test',
          'limit': 100.0,
          'period': 'monthly',
          'startDate': '2024-01-01T00:00:00.000',
        };

        final budget = BudgetModel.fromMap(map, '1');
        expect(budget.spent, equals(0.0));
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final original = BudgetModel(
          id: '1',
          category: 'Food',
          limit: 500.0,
          spent: 100.0,
          startDate: DateTime(2024, 1, 1),
        );

        final updated = original.copyWith(spent: 200.0);

        expect(updated.spent, equals(200.0));
        expect(updated.limit, equals(original.limit));
        expect(updated.category, equals(original.category));
      });
    });

    group('equality', () {
      test('equal budgets are equal', () {
        final date = DateTime(2024, 1, 1);
        final budget1 = BudgetModel(
          id: '1',
          category: 'Food',
          limit: 500.0,
          spent: 250.0,
          startDate: date,
        );
        final budget2 = BudgetModel(
          id: '1',
          category: 'Food',
          limit: 500.0,
          spent: 250.0,
          startDate: date,
        );

        expect(budget1, equals(budget2));
        expect(budget1.hashCode, equals(budget2.hashCode));
      });
    });
  });
}
