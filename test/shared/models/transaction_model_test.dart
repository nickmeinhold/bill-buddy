import 'package:bill_buddy/shared/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionModel', () {
    group('isExpense', () {
      test('returns true for negative amount', () {
        final transaction = TransactionModel(
          id: '1',
          amount: -45.99,
          date: DateTime(2024, 1, 15),
          merchantName: 'Store',
          category: 'Shopping',
        );

        expect(transaction.isExpense, isTrue);
      });

      test('returns false for positive amount', () {
        final transaction = TransactionModel(
          id: '1',
          amount: 1000.0,
          date: DateTime(2024, 1, 15),
          merchantName: 'Employer',
          category: 'Income',
        );

        expect(transaction.isExpense, isFalse);
      });

      test('returns false for zero', () {
        final transaction = TransactionModel(
          id: '1',
          amount: 0.0,
          date: DateTime(2024, 1, 15),
          merchantName: 'Refund',
          category: 'Other',
        );

        expect(transaction.isExpense, isFalse);
      });
    });

    group('isIncome', () {
      test('returns true for positive amount', () {
        final transaction = TransactionModel(
          id: '1',
          amount: 2500.0,
          date: DateTime(2024, 1, 15),
          merchantName: 'Employer Inc',
          category: 'Income',
        );

        expect(transaction.isIncome, isTrue);
      });

      test('returns false for negative amount', () {
        final transaction = TransactionModel(
          id: '1',
          amount: -99.99,
          date: DateTime(2024, 1, 15),
          merchantName: 'Restaurant',
          category: 'Food & Dining',
        );

        expect(transaction.isIncome, isFalse);
      });

      test('returns false for zero', () {
        final transaction = TransactionModel(
          id: '1',
          amount: 0.0,
          date: DateTime(2024, 1, 15),
          merchantName: 'Transfer',
          category: 'Other',
        );

        expect(transaction.isIncome, isFalse);
      });
    });

    group('absoluteAmount', () {
      test('returns positive value for positive amount', () {
        final transaction = TransactionModel(
          id: '1',
          amount: 100.0,
          date: DateTime(2024, 1, 15),
          merchantName: 'Test',
          category: 'Other',
        );

        expect(transaction.absoluteAmount, equals(100.0));
      });

      test('returns positive value for negative amount', () {
        final transaction = TransactionModel(
          id: '1',
          amount: -75.50,
          date: DateTime(2024, 1, 15),
          merchantName: 'Store',
          category: 'Shopping',
        );

        expect(transaction.absoluteAmount, equals(75.50));
      });

      test('returns zero for zero amount', () {
        final transaction = TransactionModel(
          id: '1',
          amount: 0.0,
          date: DateTime(2024, 1, 15),
          merchantName: 'Zero',
          category: 'Other',
        );

        expect(transaction.absoluteAmount, equals(0.0));
      });
    });

    group('serialization', () {
      test('toMap and fromMap round-trip correctly', () {
        final original = TransactionModel(
          id: '1',
          accountId: 'acc_1',
          amount: -45.99,
          date: DateTime(2024, 1, 15),
          merchantName: 'Grocery Store',
          category: 'Groceries',
          isSubscription: false,
          notes: 'Weekly shopping',
          statementId: 'stmt_1',
        );

        final map = original.toMap();
        final restored = TransactionModel.fromMap(map, '1');

        expect(restored, equals(original));
      });

      test('handles null optional fields', () {
        final transaction = TransactionModel(
          id: '1',
          amount: -50.0,
          date: DateTime(2024, 1, 15),
          merchantName: 'Store',
          category: 'Shopping',
        );

        final map = transaction.toMap();
        final restored = TransactionModel.fromMap(map, '1');

        expect(restored.accountId, isNull);
        expect(restored.notes, isNull);
        expect(restored.statementId, isNull);
      });

      test('defaults isSubscription to false if null', () {
        final map = {
          'amount': -10.0,
          'date': '2024-01-15T00:00:00.000',
          'merchantName': 'Test',
          'category': 'Other',
        };

        final transaction = TransactionModel.fromMap(map, '1');
        expect(transaction.isSubscription, isFalse);
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final original = TransactionModel(
          id: '1',
          amount: -50.0,
          date: DateTime(2024, 1, 15),
          merchantName: 'Store',
          category: 'Shopping',
        );

        final updated = original.copyWith(
          category: 'Groceries',
          notes: 'Updated',
        );

        expect(updated.category, equals('Groceries'));
        expect(updated.notes, equals('Updated'));
        expect(updated.amount, equals(original.amount));
        expect(updated.merchantName, equals(original.merchantName));
      });

      test('preserves unchanged fields', () {
        final original = TransactionModel(
          id: '1',
          accountId: 'acc_1',
          amount: -50.0,
          date: DateTime(2024, 1, 15),
          merchantName: 'Store',
          category: 'Shopping',
          notes: 'Original notes',
        );

        final updated = original.copyWith(amount: -75.0);

        expect(updated.accountId, equals('acc_1'));
        expect(updated.notes, equals('Original notes'));
      });
    });

    group('equality', () {
      test('equal transactions are equal', () {
        final date = DateTime(2024, 1, 15);
        final txn1 = TransactionModel(
          id: '1',
          amount: -50.0,
          date: date,
          merchantName: 'Store',
          category: 'Shopping',
        );
        final txn2 = TransactionModel(
          id: '1',
          amount: -50.0,
          date: date,
          merchantName: 'Store',
          category: 'Shopping',
        );

        expect(txn1, equals(txn2));
        expect(txn1.hashCode, equals(txn2.hashCode));
      });

      test('different transactions are not equal', () {
        final date = DateTime(2024, 1, 15);
        final txn1 = TransactionModel(
          id: '1',
          amount: -50.0,
          date: date,
          merchantName: 'Store A',
          category: 'Shopping',
        );
        final txn2 = TransactionModel(
          id: '2',
          amount: -75.0,
          date: date,
          merchantName: 'Store B',
          category: 'Groceries',
        );

        expect(txn1, isNot(equals(txn2)));
      });
    });

    group('subscription flag', () {
      test('can mark transaction as subscription', () {
        final transaction = TransactionModel(
          id: '1',
          amount: -15.99,
          date: DateTime(2024, 1, 15),
          merchantName: 'Netflix',
          category: 'Entertainment',
          isSubscription: true,
        );

        expect(transaction.isSubscription, isTrue);
      });
    });
  });
}
