import 'dart:typed_data';

import 'package:bill_buddy/core/encryption/encryption_service.dart';
import 'package:bill_buddy/features/bills/domain/bills_provider.dart';
import 'package:bill_buddy/shared/models/bill_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late EncryptionService encryptionService;
    late Uint8List dek;
    late BillService billService;
    const userId = 'test_user_123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      encryptionService = EncryptionService();
      dek = encryptionService.generateDEK();
      billService = BillService(fakeFirestore, userId, encryptionService, dek);
    });

    group('addBill', () {
      test('adds encrypted bill to Firestore', () async {
        final bill = BillModel(
          id: 'bill_1',
          name: 'Electricity',
          amount: 150.0,
          dueDate: DateTime(2024, 2, 15),
          frequency: BillFrequency.monthly,
          isPaid: false,
          remindDaysBefore: 3,
          category: 'Utilities',
        );

        await billService.addBill(bill);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .get();

        expect(snapshot.docs.length, equals(1));
        final data = snapshot.docs.first.data();

        // Verify fields are encrypted (should start with ENC:v1:)
        expect(data['name'], startsWith('ENC:v1:'));
        expect(data['amount'], startsWith('ENC:v1:'));
        expect(data['_encrypted'], isTrue);

        // Verify non-sensitive fields are not encrypted
        expect(data['frequency'], equals('monthly'));
        expect(data['isPaid'], isFalse);
        expect(data['category'], equals('Utilities'));
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = BillService(
          fakeFirestore,
          null,
          encryptionService,
          dek,
        );
        final bill = BillModel(
          id: 'bill_1',
          name: 'Test',
          amount: 100.0,
          dueDate: DateTime.now(),
        );

        expect(() => noAuthService.addBill(bill), throwsA(isA<Exception>()));
      });

      test('encrypts notes when provided', () async {
        final bill = BillModel(
          id: 'bill_1',
          name: 'Internet',
          amount: 79.99,
          dueDate: DateTime(2024, 2, 20),
          notes: 'Auto-pay enabled',
        );

        await billService.addBill(bill);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .get();

        final data = snapshot.docs.first.data();
        expect(data['notes'], startsWith('ENC:v1:'));
      });
    });

    group('updateBill', () {
      test('updates bill with encrypted data', () async {
        // First add a bill
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc('bill_1')
            .set({
              'name': encryptionService.encryptField('Old Name', dek),
              'amount': encryptionService.encryptAmount(100.0, dek),
              'dueDate': '2024-02-15T00:00:00.000',
              'frequency': 'monthly',
              'isPaid': false,
              'remindDaysBefore': 3,
              '_encrypted': true,
            });

        // Update it
        final updatedBill = BillModel(
          id: 'bill_1',
          name: 'New Name',
          amount: 200.0,
          dueDate: DateTime(2024, 2, 20),
          frequency: BillFrequency.monthly,
        );

        await billService.updateBill(updatedBill);

        final doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc('bill_1')
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
        expect(decryptedAmount, equals(200.0));
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = BillService(
          fakeFirestore,
          null,
          encryptionService,
          dek,
        );
        final bill = BillModel(
          id: 'bill_1',
          name: 'Test',
          amount: 100.0,
          dueDate: DateTime.now(),
        );

        expect(() => noAuthService.updateBill(bill), throwsA(isA<Exception>()));
      });
    });

    group('deleteBill', () {
      test('deletes bill from Firestore', () async {
        // First add a bill
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc('bill_to_delete')
            .set({
              'name': 'Test Bill',
              'amount': 50.0,
              'dueDate': '2024-02-15T00:00:00.000',
              'frequency': 'monthly',
              'isPaid': false,
            });

        // Verify it exists
        var doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc('bill_to_delete')
            .get();
        expect(doc.exists, isTrue);

        // Delete it
        await billService.deleteBill('bill_to_delete');

        // Verify it's gone
        doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc('bill_to_delete')
            .get();
        expect(doc.exists, isFalse);
      });

      test('throws when user is not authenticated', () async {
        final noAuthService = BillService(
          fakeFirestore,
          null,
          encryptionService,
          dek,
        );

        expect(
          () => noAuthService.deleteBill('bill_1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('markAsPaid', () {
      test('updates isPaid to true', () async {
        // First add a bill
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc('bill_1')
            .set({
              'name': encryptionService.encryptField('Electric', dek),
              'amount': encryptionService.encryptAmount(100.0, dek),
              'dueDate': '2024-02-15T00:00:00.000',
              'frequency': 'monthly',
              'isPaid': false,
              'remindDaysBefore': 3,
              '_encrypted': true,
            });

        final bill = BillModel(
          id: 'bill_1',
          name: 'Electric',
          amount: 100.0,
          dueDate: DateTime(2024, 2, 15),
          isPaid: false,
        );

        await billService.markAsPaid(bill);

        final doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc('bill_1')
            .get();

        expect(doc.data()!['isPaid'], isTrue);
      });
    });

    group('markAsUnpaid', () {
      test('updates isPaid to false', () async {
        // First add a paid bill
        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc('bill_1')
            .set({
              'name': encryptionService.encryptField('Water', dek),
              'amount': encryptionService.encryptAmount(50.0, dek),
              'dueDate': '2024-02-15T00:00:00.000',
              'frequency': 'monthly',
              'isPaid': true,
              'remindDaysBefore': 3,
              '_encrypted': true,
            });

        final bill = BillModel(
          id: 'bill_1',
          name: 'Water',
          amount: 50.0,
          dueDate: DateTime(2024, 2, 15),
          isPaid: true,
        );

        await billService.markAsUnpaid(bill);

        final doc = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .doc('bill_1')
            .get();

        expect(doc.data()!['isPaid'], isFalse);
      });
    });

    group('_encryptData', () {
      test('skips encryption when DEK is null', () async {
        final noEncryptionService = BillService(
          fakeFirestore,
          userId,
          encryptionService,
          null,
        );

        final bill = BillModel(
          id: 'bill_1',
          name: 'Unencrypted Bill',
          amount: 75.0,
          dueDate: DateTime(2024, 2, 15),
        );

        await noEncryptionService.addBill(bill);

        final snapshot = await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('bills')
            .get();

        final data = snapshot.docs.first.data();
        // Data should NOT be encrypted when DEK is null
        expect(data['name'], equals('Unencrypted Bill'));
        expect(data['amount'], equals(75.0));
      });
    });
  });
}
