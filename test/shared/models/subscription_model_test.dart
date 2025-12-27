import 'package:bill_buddy/shared/models/subscription_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionModel', () {
    group('monthlyAmount', () {
      test('weekly subscription: amount * 4.33', () {
        final subscription = SubscriptionModel(
          id: '1',
          name: 'Weekly',
          amount: 10.0,
          frequency: SubscriptionFrequency.weekly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Entertainment',
        );

        expect(subscription.monthlyAmount, closeTo(43.3, 0.01));
      });

      test('monthly subscription: unchanged', () {
        final subscription = SubscriptionModel(
          id: '1',
          name: 'Monthly',
          amount: 15.99,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Entertainment',
        );

        expect(subscription.monthlyAmount, equals(15.99));
      });

      test('quarterly subscription: amount / 3', () {
        final subscription = SubscriptionModel(
          id: '1',
          name: 'Quarterly',
          amount: 90.0,
          frequency: SubscriptionFrequency.quarterly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Entertainment',
        );

        expect(subscription.monthlyAmount, equals(30.0));
      });

      test('yearly subscription: amount / 12', () {
        final subscription = SubscriptionModel(
          id: '1',
          name: 'Yearly',
          amount: 120.0,
          frequency: SubscriptionFrequency.yearly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Entertainment',
        );

        expect(subscription.monthlyAmount, equals(10.0));
      });
    });

    group('yearlyAmount', () {
      test('weekly subscription: amount * 52', () {
        final subscription = SubscriptionModel(
          id: '1',
          name: 'Weekly',
          amount: 10.0,
          frequency: SubscriptionFrequency.weekly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Entertainment',
        );

        expect(subscription.yearlyAmount, equals(520.0));
      });

      test('monthly subscription: amount * 12', () {
        final subscription = SubscriptionModel(
          id: '1',
          name: 'Monthly',
          amount: 15.0,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Entertainment',
        );

        expect(subscription.yearlyAmount, equals(180.0));
      });

      test('quarterly subscription: amount * 4', () {
        final subscription = SubscriptionModel(
          id: '1',
          name: 'Quarterly',
          amount: 90.0,
          frequency: SubscriptionFrequency.quarterly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Entertainment',
        );

        expect(subscription.yearlyAmount, equals(360.0));
      });

      test('yearly subscription: unchanged', () {
        final subscription = SubscriptionModel(
          id: '1',
          name: 'Yearly',
          amount: 120.0,
          frequency: SubscriptionFrequency.yearly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Entertainment',
        );

        expect(subscription.yearlyAmount, equals(120.0));
      });
    });

    group('serialization', () {
      test('toMap and fromMap round-trip correctly', () {
        final original = SubscriptionModel(
          id: '1',
          name: 'Netflix',
          amount: 15.99,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Entertainment',
          status: SubscriptionStatus.active,
          notes: 'Family plan',
          logoUrl: 'https://example.com/logo.png',
        );

        final map = original.toMap();
        final restored = SubscriptionModel.fromMap(map, '1');

        expect(restored, equals(original));
      });

      test('handles null optional fields', () {
        final subscription = SubscriptionModel(
          id: '1',
          name: 'Simple',
          amount: 10.0,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Other',
        );

        final map = subscription.toMap();
        expect(map['notes'], isNull);
        expect(map['logoUrl'], isNull);

        final restored = SubscriptionModel.fromMap(map, '1');
        expect(restored.notes, isNull);
        expect(restored.logoUrl, isNull);
      });

      test('defaults to monthly frequency if unknown', () {
        final map = {
          'name': 'Test',
          'amount': 10.0,
          'frequency': 'unknown_frequency',
          'nextBillingDate': '2024-01-15T00:00:00.000',
          'category': 'Other',
          'status': 'active',
        };

        final subscription = SubscriptionModel.fromMap(map, '1');
        expect(subscription.frequency, equals(SubscriptionFrequency.monthly));
      });

      test('defaults to active status if unknown', () {
        final map = {
          'name': 'Test',
          'amount': 10.0,
          'frequency': 'monthly',
          'nextBillingDate': '2024-01-15T00:00:00.000',
          'category': 'Other',
          'status': 'unknown_status',
        };

        final subscription = SubscriptionModel.fromMap(map, '1');
        expect(subscription.status, equals(SubscriptionStatus.active));
      });
    });

    group('copyWith', () {
      test('creates new instance with changed fields', () {
        final original = SubscriptionModel(
          id: '1',
          name: 'Netflix',
          amount: 15.99,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Entertainment',
        );

        final updated = original.copyWith(
          amount: 19.99,
          name: 'Netflix Premium',
        );

        expect(updated.amount, equals(19.99));
        expect(updated.name, equals('Netflix Premium'));
        expect(updated.id, equals(original.id));
        expect(updated.frequency, equals(original.frequency));
      });

      test('preserves unchanged fields', () {
        final original = SubscriptionModel(
          id: '1',
          name: 'Netflix',
          amount: 15.99,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: DateTime(2024, 1, 15),
          category: 'Entertainment',
          notes: 'Some notes',
        );

        final updated = original.copyWith(amount: 19.99);

        expect(updated.notes, equals('Some notes'));
      });
    });

    group('equality', () {
      test('equal subscriptions are equal', () {
        final date = DateTime(2024, 1, 15);
        final sub1 = SubscriptionModel(
          id: '1',
          name: 'Netflix',
          amount: 15.99,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: date,
          category: 'Entertainment',
        );
        final sub2 = SubscriptionModel(
          id: '1',
          name: 'Netflix',
          amount: 15.99,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: date,
          category: 'Entertainment',
        );

        expect(sub1, equals(sub2));
        expect(sub1.hashCode, equals(sub2.hashCode));
      });

      test('different subscriptions are not equal', () {
        final date = DateTime(2024, 1, 15);
        final sub1 = SubscriptionModel(
          id: '1',
          name: 'Netflix',
          amount: 15.99,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: date,
          category: 'Entertainment',
        );
        final sub2 = SubscriptionModel(
          id: '2',
          name: 'Spotify',
          amount: 9.99,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: date,
          category: 'Entertainment',
        );

        expect(sub1, isNot(equals(sub2)));
      });
    });
  });
}
