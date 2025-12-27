import 'package:bill_buddy/features/budgets/domain/budgets_provider.dart';
import 'package:bill_buddy/shared/models/budget_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late BudgetService budgetService;
    const userId = 'test_user_123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      budgetService = BudgetService(fakeFirestore, userId);
    });

    group('addBudget', () {
      test('adds budget to Firestore', () async {
        final budget = BudgetModel(
          id: 'budget_1',
          category: 'Food & Dining',
          limit: 500.0,
          spent: 0,
          startDate: DateTime(2024, 1, 1),
        );

        await budgetService.addBudget(budget);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .get();

        expect(snapshot.docs.length, equals(1));
        expect(snapshot.docs.first.data()['category'], equals('Food & Dining'));
        expect(snapshot.docs.first.data()['limit'], equals(500.0));
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = BudgetService(fakeFirestore, null);
        final budget = BudgetModel(
          id: 'budget_1',
          category: 'Food',
          limit: 100.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(
          () => noAuthService.addBudget(budget),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateBudget', () {
      test('updates existing budget', () async {
        // First add a budget
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc('budget_1')
            .set({
              'category': 'Food',
              'limit': 500.0,
              'spent': 100.0,
              'period': 'monthly',
              'startDate': '2024-01-01T00:00:00.000',
            });

        // Update it
        final updatedBudget = BudgetModel(
          id: 'budget_1',
          category: 'Food & Dining',
          limit: 600.0,
          spent: 150.0,
          startDate: DateTime(2024, 1, 1),
        );

        await budgetService.updateBudget(updatedBudget);

        final doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc('budget_1')
            .get();

        expect(doc.data()!['category'], equals('Food & Dining'));
        expect(doc.data()!['limit'], equals(600.0));
        expect(doc.data()!['spent'], equals(150.0));
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = BudgetService(fakeFirestore, null);
        final budget = BudgetModel(
          id: 'budget_1',
          category: 'Food',
          limit: 100.0,
          startDate: DateTime(2024, 1, 1),
        );

        expect(
          () => noAuthService.updateBudget(budget),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteBudget', () {
      test('deletes budget from Firestore', () async {
        // First add a budget
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc('budget_to_delete')
            .set({
              'category': 'Entertainment',
              'limit': 100.0,
              'spent': 0.0,
              'period': 'monthly',
              'startDate': '2024-01-01T00:00:00.000',
            });

        // Verify it exists
        var doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc('budget_to_delete')
            .get();
        expect(doc.exists, isTrue);

        // Delete it
        await budgetService.deleteBudget('budget_to_delete');

        // Verify it's gone
        doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc('budget_to_delete')
            .get();
        expect(doc.exists, isFalse);
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = BudgetService(fakeFirestore, null);

        expect(
          () => noAuthService.deleteBudget('budget_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateSpent', () {
      test('updates spent amount', () async {
        // First add a budget
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc('budget_1')
            .set({
              'category': 'Food',
              'limit': 500.0,
              'spent': 100.0,
              'period': 'monthly',
              'startDate': '2024-01-01T00:00:00.000',
            });

        // Update spent
        await budgetService.updateSpent('budget_1', 250.0);

        final doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc('budget_1')
            .get();

        expect(doc.data()!['spent'], equals(250.0));
        // Other fields should remain unchanged
        expect(doc.data()!['limit'], equals(500.0));
        expect(doc.data()!['category'], equals('Food'));
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = BudgetService(fakeFirestore, null);

        expect(
          () => noAuthService.updateSpent('budget_1', 100.0),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('resetSpent', () {
      test('resets spent to zero', () async {
        // First add a budget with some spending
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc('budget_1')
            .set({
              'category': 'Shopping',
              'limit': 200.0,
              'spent': 150.0,
              'period': 'monthly',
              'startDate': '2024-01-01T00:00:00.000',
            });

        // Reset spent
        await budgetService.resetSpent('budget_1');

        final doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('budgets')
            .doc('budget_1')
            .get();

        expect(doc.data()!['spent'], equals(0));
      });
    });

    group('collection', () {
      test('returns null when userId is null', () {
        final noAuthService = BudgetService(fakeFirestore, null);
        // We can't directly test _collection as it's private,
        // but we can verify behavior through public methods
        expect(
          () => noAuthService.addBudget(
            BudgetModel(
              id: '1',
              category: 'Test',
              limit: 100.0,
              startDate: DateTime.now(),
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
