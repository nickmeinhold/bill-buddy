import 'package:bill_buddy/shared/models/bill_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillModel', () {
    group('isOverdue', () {
      test('returns true when due date is past and not paid', () {
        final bill = BillModel(
          id: '1',
          name: 'Electricity',
          amount: 100.0,
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
          isPaid: false,
        );

        expect(bill.isOverdue, isTrue);
      });

      test('returns false when paid even if past due', () {
        final bill = BillModel(
          id: '1',
          name: 'Electricity',
          amount: 100.0,
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
          isPaid: true,
        );

        expect(bill.isOverdue, isFalse);
      });

      test('returns false when due date is in future', () {
        final bill = BillModel(
          id: '1',
          name: 'Electricity',
          amount: 100.0,
          dueDate: DateTime.now().add(const Duration(days: 5)),
          isPaid: false,
        );

        expect(bill.isOverdue, isFalse);
      });
    });

    group('isDueSoon', () {
      test('returns true when within remindDaysBefore window', () {
        final bill = BillModel(
          id: '1',
          name: 'Internet',
          amount: 80.0,
          dueDate: DateTime.now().add(const Duration(days: 2)),
          remindDaysBefore: 3,
          isPaid: false,
        );

        expect(bill.isDueSoon, isTrue);
      });

      test('returns true when due today', () {
        final now = DateTime.now();
        final bill = BillModel(
          id: '1',
          name: 'Internet',
          amount: 80.0,
          dueDate: DateTime(now.year, now.month, now.day, 23, 59),
          remindDaysBefore: 3,
          isPaid: false,
        );

        expect(bill.isDueSoon, isTrue);
      });

      test('returns false when paid', () {
        final bill = BillModel(
          id: '1',
          name: 'Internet',
          amount: 80.0,
          dueDate: DateTime.now().add(const Duration(days: 2)),
          remindDaysBefore: 3,
          isPaid: true,
        );

        expect(bill.isDueSoon, isFalse);
      });

      test('returns false when overdue (past due date)', () {
        final bill = BillModel(
          id: '1',
          name: 'Internet',
          amount: 80.0,
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          remindDaysBefore: 3,
          isPaid: false,
        );

        expect(bill.isDueSoon, isFalse);
      });

      test('returns false when due date is far in future', () {
        final bill = BillModel(
          id: '1',
          name: 'Internet',
          amount: 80.0,
          dueDate: DateTime.now().add(const Duration(days: 30)),
          remindDaysBefore: 3,
          isPaid: false,
        );

        expect(bill.isDueSoon, isFalse);
      });
    });

    group('daysUntilDue', () {
      test('returns positive value for future due date', () {
        final bill = BillModel(
          id: '1',
          name: 'Rent',
          amount: 1500.0,
          dueDate: DateTime.now().add(const Duration(days: 10)),
        );

        expect(bill.daysUntilDue, greaterThanOrEqualTo(9));
        expect(bill.daysUntilDue, lessThanOrEqualTo(10));
      });

      test('returns negative value for past due date', () {
        final bill = BillModel(
          id: '1',
          name: 'Rent',
          amount: 1500.0,
          dueDate: DateTime.now().subtract(const Duration(days: 5)),
        );

        expect(bill.daysUntilDue, lessThan(0));
      });

      test('returns 0 for today', () {
        final now = DateTime.now();
        final bill = BillModel(
          id: '1',
          name: 'Rent',
          amount: 1500.0,
          dueDate: DateTime(now.year, now.month, now.day),
        );

        expect(bill.daysUntilDue, equals(0));
      });
    });

    group('nextDueDate', () {
      test('returns same date if not paid', () {
        final dueDate = DateTime(2024, 1, 15);
        final bill = BillModel(
          id: '1',
          name: 'Bill',
          amount: 100.0,
          dueDate: dueDate,
          frequency: BillFrequency.monthly,
          isPaid: false,
        );

        expect(bill.nextDueDate, equals(dueDate));
      });

      test('one-time bill returns same date even when paid', () {
        final dueDate = DateTime(2024, 1, 15);
        final bill = BillModel(
          id: '1',
          name: 'One Time',
          amount: 100.0,
          dueDate: dueDate,
          frequency: BillFrequency.oneTime,
          isPaid: true,
        );

        expect(bill.nextDueDate, equals(dueDate));
      });

      test('weekly bill adds 7 days when paid', () {
        final dueDate = DateTime(2024, 1, 15);
        final bill = BillModel(
          id: '1',
          name: 'Weekly',
          amount: 100.0,
          dueDate: dueDate,
          frequency: BillFrequency.weekly,
          isPaid: true,
        );

        expect(bill.nextDueDate, equals(DateTime(2024, 1, 22)));
      });

      test('biWeekly bill adds 14 days when paid', () {
        final dueDate = DateTime(2024, 1, 15);
        final bill = BillModel(
          id: '1',
          name: 'Bi-Weekly',
          amount: 100.0,
          dueDate: dueDate,
          frequency: BillFrequency.biWeekly,
          isPaid: true,
        );

        expect(bill.nextDueDate, equals(DateTime(2024, 1, 29)));
      });

      test('monthly bill adds 1 month when paid', () {
        final dueDate = DateTime(2024, 1, 15);
        final bill = BillModel(
          id: '1',
          name: 'Monthly',
          amount: 100.0,
          dueDate: dueDate,
          frequency: BillFrequency.monthly,
          isPaid: true,
        );

        expect(bill.nextDueDate, equals(DateTime(2024, 2, 15)));
      });

      test('quarterly bill adds 3 months when paid', () {
        final dueDate = DateTime(2024, 1, 15);
        final bill = BillModel(
          id: '1',
          name: 'Quarterly',
          amount: 100.0,
          dueDate: dueDate,
          frequency: BillFrequency.quarterly,
          isPaid: true,
        );

        expect(bill.nextDueDate, equals(DateTime(2024, 4, 15)));
      });

      test('yearly bill adds 1 year when paid', () {
        final dueDate = DateTime(2024, 1, 15);
        final bill = BillModel(
          id: '1',
          name: 'Yearly',
          amount: 100.0,
          dueDate: dueDate,
          frequency: BillFrequency.yearly,
          isPaid: true,
        );

        expect(bill.nextDueDate, equals(DateTime(2025, 1, 15)));
      });
    });

    group('serialization', () {
      test('toMap and fromMap round-trip correctly', () {
        final original = BillModel(
          id: '1',
          name: 'Electricity',
          amount: 150.0,
          dueDate: DateTime(2024, 1, 20),
          frequency: BillFrequency.monthly,
          isPaid: false,
          remindDaysBefore: 5,
          category: 'Utilities',
          notes: 'Pay before due',
        );

        final map = original.toMap();
        final restored = BillModel.fromMap(map, '1');

        expect(restored, equals(original));
      });

      test('handles null optional fields', () {
        final bill = BillModel(
          id: '1',
          name: 'Simple',
          amount: 100.0,
          dueDate: DateTime(2024, 1, 15),
        );

        final map = bill.toMap();
        final restored = BillModel.fromMap(map, '1');

        expect(restored.category, isNull);
        expect(restored.notes, isNull);
      });

      test('defaults to monthly frequency if unknown', () {
        final map = {
          'name': 'Test',
          'amount': 100.0,
          'dueDate': '2024-01-15T00:00:00.000',
          'frequency': 'unknown_frequency',
          'isPaid': false,
          'remindDaysBefore': 3,
        };

        final bill = BillModel.fromMap(map, '1');
        expect(bill.frequency, equals(BillFrequency.monthly));
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final original = BillModel(
          id: '1',
          name: 'Electricity',
          amount: 150.0,
          dueDate: DateTime(2024, 1, 20),
        );

        final updated = original.copyWith(isPaid: true);

        expect(updated.isPaid, isTrue);
        expect(updated.name, equals(original.name));
        expect(updated.amount, equals(original.amount));
      });
    });

    group('equality', () {
      test('equal bills are equal', () {
        final date = DateTime(2024, 1, 15);
        final bill1 = BillModel(
          id: '1',
          name: 'Electric',
          amount: 100.0,
          dueDate: date,
        );
        final bill2 = BillModel(
          id: '1',
          name: 'Electric',
          amount: 100.0,
          dueDate: date,
        );

        expect(bill1, equals(bill2));
        expect(bill1.hashCode, equals(bill2.hashCode));
      });
    });
  });
}
