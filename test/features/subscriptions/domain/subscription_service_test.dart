import 'dart:typed_data';

import 'package:bill_buddy/core/encryption/encryption_service.dart';
import 'package:bill_buddy/features/subscriptions/domain/subscriptions_provider.dart';
import 'package:bill_buddy/shared/models/subscription_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late EncryptionService encryptionService;
    late Uint8List dek;
    late SubscriptionService service;
    const userId = 'test_user_123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      encryptionService = EncryptionService();
      dek = encryptionService.generateDEK();
      service = SubscriptionService(
        fakeFirestore,
        userId,
        encryptionService,
        dek,
      );
    });

    group('addSubscription', () {
      test('adds encrypted subscription to Firestore', () async {
        final subscription = SubscriptionModel(
          id: 'sub_1',
          name: 'Netflix',
          amount: 15.99,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: DateTime(2024, 2, 15),
          category: 'Entertainment',
        );

        await service.addSubscription(subscription);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .get();

        expect(snapshot.docs.length, equals(1));
        final data = snapshot.docs.first.data();

        // Verify sensitive fields are encrypted
        expect(data['name'], startsWith('ENC:v1:'));
        expect(data['amount'], startsWith('ENC:v1:'));
        expect(data['_encrypted'], isTrue);

        // Verify non-sensitive fields are not encrypted
        expect(data['frequency'], equals('monthly'));
        expect(data['category'], equals('Entertainment'));
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = SubscriptionService(
          fakeFirestore,
          null,
          encryptionService,
          dek,
        );
        final subscription = SubscriptionModel(
          id: 'sub_1',
          name: 'Test',
          amount: 10.0,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: DateTime.now(),
          category: 'Other',
        );

        expect(
          () => noAuthService.addSubscription(subscription),
          throwsA(isA<Exception>()),
        );
      });

      test('encrypts notes when provided', () async {
        final subscription = SubscriptionModel(
          id: 'sub_1',
          name: 'Spotify',
          amount: 9.99,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: DateTime(2024, 2, 20),
          category: 'Entertainment',
          notes: 'Family plan',
        );

        await service.addSubscription(subscription);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .get();

        final data = snapshot.docs.first.data();
        expect(data['notes'], startsWith('ENC:v1:'));
      });
    });

    group('updateSubscription', () {
      test('updates subscription with encrypted data', () async {
        // First add a subscription
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .doc('sub_1')
            .set({
              'name': encryptionService.encryptField('Old Name', dek),
              'amount': encryptionService.encryptAmount(10.0, dek),
              'frequency': 'monthly',
              'nextBillingDate': '2024-02-15T00:00:00.000',
              'category': 'Entertainment',
              '_encrypted': true,
            });

        // Update it
        final updated = SubscriptionModel(
          id: 'sub_1',
          name: 'New Name',
          amount: 20.0,
          frequency: SubscriptionFrequency.yearly,
          nextBillingDate: DateTime(2024, 12, 1),
          category: 'Productivity',
        );

        await service.updateSubscription(updated);

        final doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .doc('sub_1')
            .get();

        // Decrypt and verify
        final decryptedName = encryptionService.decryptField(
          doc.data()!['name'] as String,
          dek,
        );
        final decryptedAmount = encryptionService.decryptAmount(
          doc.data()!['amount'] as String,
          dek,
        );

        expect(decryptedName, equals('New Name'));
        expect(decryptedAmount, equals(20.0));
        expect(doc.data()!['frequency'], equals('yearly'));
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = SubscriptionService(
          fakeFirestore,
          null,
          encryptionService,
          dek,
        );
        final subscription = SubscriptionModel(
          id: 'sub_1',
          name: 'Test',
          amount: 10.0,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: DateTime.now(),
          category: 'Other',
        );

        expect(
          () => noAuthService.updateSubscription(subscription),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteSubscription', () {
      test('deletes subscription from Firestore', () async {
        // First add a subscription
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .doc('sub_to_delete')
            .set({
              'name': 'Test Sub',
              'amount': 10.0,
              'frequency': 'monthly',
              'nextBillingDate': '2024-02-15T00:00:00.000',
              'category': 'Other',
            });

        // Verify it exists
        var doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .doc('sub_to_delete')
            .get();
        expect(doc.exists, isTrue);

        // Delete it
        await service.deleteSubscription('sub_to_delete');

        // Verify it's gone
        doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .doc('sub_to_delete')
            .get();
        expect(doc.exists, isFalse);
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = SubscriptionService(
          fakeFirestore,
          null,
          encryptionService,
          dek,
        );

        expect(
          () => noAuthService.deleteSubscription('sub_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('encryption edge cases', () {
      test('skips encryption when DEK is null', () async {
        final noEncryptionService = SubscriptionService(
          fakeFirestore,
          userId,
          encryptionService,
          null,
        );

        final subscription = SubscriptionModel(
          id: 'sub_1',
          name: 'Unencrypted Sub',
          amount: 15.0,
          frequency: SubscriptionFrequency.monthly,
          nextBillingDate: DateTime(2024, 2, 15),
          category: 'Other',
        );

        await noEncryptionService.addSubscription(subscription);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('subscriptions')
            .get();

        final data = snapshot.docs.first.data();
        // Data should NOT be encrypted when DEK is null
        expect(data['name'], equals('Unencrypted Sub'));
        expect(data['amount'], equals(15.0));
      });
    });
  });
}
