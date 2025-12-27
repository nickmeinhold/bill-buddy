import 'package:bill_buddy/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConstants', () {
    group('appName', () {
      test('is Bill Buddy', () {
        expect(AppConstants.appName, equals('Bill Buddy'));
      });
    });

    group('defaultCategories', () {
      test('is a non-empty list', () {
        expect(AppConstants.defaultCategories, isNotEmpty);
      });

      test('contains expected categories', () {
        expect(
          AppConstants.defaultCategories,
          containsAll([
            'Food & Dining',
            'Shopping',
            'Transportation',
            'Entertainment',
            'Bills & Utilities',
            'Health & Fitness',
            'Income',
            'Other',
          ]),
        );
      });

      test('has 12 categories', () {
        expect(AppConstants.defaultCategories.length, equals(12));
      });

      test('includes Subscriptions category', () {
        expect(AppConstants.defaultCategories, contains('Subscriptions'));
      });

      test('includes Travel category', () {
        expect(AppConstants.defaultCategories, contains('Travel'));
      });

      test('includes Education category', () {
        expect(AppConstants.defaultCategories, contains('Education'));
      });

      test('includes Personal Care category', () {
        expect(AppConstants.defaultCategories, contains('Personal Care'));
      });

      test('has no duplicate categories', () {
        final uniqueCategories = AppConstants.defaultCategories.toSet();
        expect(
          uniqueCategories.length,
          equals(AppConstants.defaultCategories.length),
        );
      });
    });

    group('subscriptionFrequencies', () {
      test('is a non-empty list', () {
        expect(AppConstants.subscriptionFrequencies, isNotEmpty);
      });

      test('contains all expected frequencies', () {
        expect(
          AppConstants.subscriptionFrequencies,
          containsAll(['Weekly', 'Monthly', 'Quarterly', 'Yearly']),
        );
      });

      test('has 4 frequencies', () {
        expect(AppConstants.subscriptionFrequencies.length, equals(4));
      });

      test('has no duplicate frequencies', () {
        final uniqueFrequencies = AppConstants.subscriptionFrequencies.toSet();
        expect(
          uniqueFrequencies.length,
          equals(AppConstants.subscriptionFrequencies.length),
        );
      });
    });

    group('billFrequencies', () {
      test('is a non-empty list', () {
        expect(AppConstants.billFrequencies, isNotEmpty);
      });

      test('contains all expected frequencies', () {
        expect(
          AppConstants.billFrequencies,
          containsAll([
            'One-time',
            'Weekly',
            'Bi-weekly',
            'Monthly',
            'Quarterly',
            'Yearly',
          ]),
        );
      });

      test('has 6 frequencies', () {
        expect(AppConstants.billFrequencies.length, equals(6));
      });

      test('includes One-time option not in subscriptions', () {
        expect(AppConstants.billFrequencies, contains('One-time'));
        expect(
          AppConstants.subscriptionFrequencies,
          isNot(contains('One-time')),
        );
      });

      test('includes Bi-weekly option not in subscriptions', () {
        expect(AppConstants.billFrequencies, contains('Bi-weekly'));
        expect(
          AppConstants.subscriptionFrequencies,
          isNot(contains('Bi-weekly')),
        );
      });

      test('has no duplicate frequencies', () {
        final uniqueFrequencies = AppConstants.billFrequencies.toSet();
        expect(
          uniqueFrequencies.length,
          equals(AppConstants.billFrequencies.length),
        );
      });
    });

    group('frequency overlap', () {
      test('Weekly exists in both subscription and bill frequencies', () {
        expect(AppConstants.subscriptionFrequencies, contains('Weekly'));
        expect(AppConstants.billFrequencies, contains('Weekly'));
      });

      test('Monthly exists in both subscription and bill frequencies', () {
        expect(AppConstants.subscriptionFrequencies, contains('Monthly'));
        expect(AppConstants.billFrequencies, contains('Monthly'));
      });

      test('Quarterly exists in both subscription and bill frequencies', () {
        expect(AppConstants.subscriptionFrequencies, contains('Quarterly'));
        expect(AppConstants.billFrequencies, contains('Quarterly'));
      });

      test('Yearly exists in both subscription and bill frequencies', () {
        expect(AppConstants.subscriptionFrequencies, contains('Yearly'));
        expect(AppConstants.billFrequencies, contains('Yearly'));
      });
    });
  });
}
