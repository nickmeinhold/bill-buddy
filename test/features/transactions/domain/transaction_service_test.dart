import 'dart:typed_data';

import 'package:bill_buddy/core/encryption/encryption_service.dart';
import 'package:bill_buddy/features/transactions/domain/transactions_provider.dart';
import 'package:bill_buddy/shared/models/transaction_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransactionService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late EncryptionService encryptionService;
    late Uint8List dek;
    late TransactionService service;
    const userId = 'test_user_123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      encryptionService = EncryptionService();
      dek = encryptionService.generateDEK();
      service = TransactionService(
        fakeFirestore,
        userId,
        encryptionService,
        dek,
      );
    });

    group('addTransaction', () {
      test('adds encrypted transaction to Firestore', () async {
        final transaction = TransactionModel(
          id: 'txn_1',
          amount: -45.99,
          date: DateTime(2024, 1, 15),
          merchantName: 'Grocery Store',
          category: 'Groceries',
        );

        await service.addTransaction(transaction);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .get();

        expect(snapshot.docs.length, equals(1));
        final data = snapshot.docs.first.data();

        // Verify sensitive fields are encrypted
        expect(data['merchantName'], startsWith('ENC:v1:'));
        expect(data['amount'], startsWith('ENC:v1:'));
        expect(data['_encrypted'], isTrue);

        // Verify non-sensitive fields are not encrypted
        expect(data['category'], equals('Groceries'));
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = TransactionService(
          fakeFirestore,
          null,
          encryptionService,
          dek,
        );
        final transaction = TransactionModel(
          id: 'txn_1',
          amount: -10.0,
          date: DateTime.now(),
          merchantName: 'Test',
          category: 'Other',
        );

        expect(
          () => noAuthService.addTransaction(transaction),
          throwsA(isA<Exception>()),
        );
      });

      test('encrypts notes when provided', () async {
        final transaction = TransactionModel(
          id: 'txn_1',
          amount: -25.00,
          date: DateTime(2024, 1, 15),
          merchantName: 'Restaurant',
          category: 'Food & Dining',
          notes: 'Lunch with client',
        );

        await service.addTransaction(transaction);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .get();

        final data = snapshot.docs.first.data();
        expect(data['notes'], startsWith('ENC:v1:'));
      });
    });

    group('updateTransaction', () {
      test('updates transaction with encrypted data', () async {
        // First add a transaction
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc('txn_1')
            .set({
              'merchantName': encryptionService.encryptField(
                'Old Merchant',
                dek,
              ),
              'amount': encryptionService.encryptAmount(-50.0, dek),
              'date': '2024-01-15T00:00:00.000',
              'category': 'Other',
              '_encrypted': true,
            });

        // Update it
        final updated = TransactionModel(
          id: 'txn_1',
          amount: -100.0,
          date: DateTime(2024, 2, 1),
          merchantName: 'New Merchant',
          category: 'Shopping',
        );

        await service.updateTransaction(updated);

        final doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc('txn_1')
            .get();

        // Decrypt and verify
        final decryptedMerchant = encryptionService.decryptField(
          doc.data()!['merchantName'] as String,
          dek,
        );
        final decryptedAmount = encryptionService.decryptAmount(
          doc.data()!['amount'] as String,
          dek,
        );

        expect(decryptedMerchant, equals('New Merchant'));
        expect(decryptedAmount, equals(-100.0));
        expect(doc.data()!['category'], equals('Shopping'));
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = TransactionService(
          fakeFirestore,
          null,
          encryptionService,
          dek,
        );
        final transaction = TransactionModel(
          id: 'txn_1',
          amount: -10.0,
          date: DateTime.now(),
          merchantName: 'Test',
          category: 'Other',
        );

        expect(
          () => noAuthService.updateTransaction(transaction),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteTransaction', () {
      test('deletes transaction from Firestore', () async {
        // First add a transaction
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc('txn_to_delete')
            .set({
              'merchantName': 'Test',
              'amount': -10.0,
              'date': '2024-01-15T00:00:00.000',
              'category': 'Other',
            });

        // Verify it exists
        var doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc('txn_to_delete')
            .get();
        expect(doc.exists, isTrue);

        // Delete it
        await service.deleteTransaction('txn_to_delete');

        // Verify it's gone
        doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc('txn_to_delete')
            .get();
        expect(doc.exists, isFalse);
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = TransactionService(
          fakeFirestore,
          null,
          encryptionService,
          dek,
        );

        expect(
          () => noAuthService.deleteTransaction('txn_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('encryption edge cases', () {
      test('skips encryption when DEK is null', () async {
        final noEncryptionService = TransactionService(
          fakeFirestore,
          userId,
          encryptionService,
          null,
        );

        final transaction = TransactionModel(
          id: 'txn_1',
          amount: -75.0,
          date: DateTime(2024, 1, 15),
          merchantName: 'Unencrypted Merchant',
          category: 'Other',
        );

        await noEncryptionService.addTransaction(transaction);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .get();

        final data = snapshot.docs.first.data();
        // Data should NOT be encrypted when DEK is null
        expect(data['merchantName'], equals('Unencrypted Merchant'));
        expect(data['amount'], equals(-75.0));
      });
    });
  });
}
