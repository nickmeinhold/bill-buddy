import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/encryption/encryption_provider.dart';
import '../../../core/encryption/encryption_service.dart';
import '../../../shared/models/bill_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../../subscriptions/domain/subscriptions_provider.dart';

final billsProvider = StreamProvider.autoDispose<List<BillModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final encryptionState = ref.watch(encryptionProvider);

  // Wait for both auth and encryption to be ready
  if (user == null || !encryptionState.isUnlocked) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  final encryptionService = ref.watch(encryptionServiceProvider);
  final dek = encryptionState.dek!;

  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('bills')
      .orderBy('dueDate')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());

          // Decrypt sensitive fields
          data['name'] = encryptionService.decryptField(
            data['name'] as String,
            dek,
          );
          data['amount'] = encryptionService.decryptAmount(
            data['amount'] as String,
            dek,
          );
          if (data['notes'] != null) {
            data['notes'] = encryptionService.decryptField(
              data['notes'] as String,
              dek,
            );
          }

          return BillModel.fromMap(data, doc.id);
        }).toList(),
      );
});

final billServiceProvider = Provider<BillService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final firestore = ref.watch(firestoreProvider);
  final encryptionState = ref.watch(encryptionProvider);
  final encryptionService = ref.watch(encryptionServiceProvider);
  return BillService(
    firestore,
    user?.uid,
    encryptionService,
    encryptionState.dek,
  );
});

class BillService {
  final FirebaseFirestore _firestore;
  final String? _userId;
  final EncryptionService _encryptionService;
  final Uint8List? _dek;

  BillService(
    this._firestore,
    this._userId,
    this._encryptionService,
    this._dek,
  );

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('bills');
  }

  Map<String, dynamic> _encryptData(Map<String, dynamic> data) {
    if (_dek == null) return data;

    final encrypted = Map<String, dynamic>.from(data);

    // Encrypt sensitive fields
    encrypted['name'] = _encryptionService.encryptField(
      data['name'] as String,
      _dek,
    );
    encrypted['amount'] = _encryptionService.encryptAmount(
      data['amount'] as double,
      _dek,
    );
    if (data['notes'] != null) {
      encrypted['notes'] = _encryptionService.encryptField(
        data['notes'] as String,
        _dek,
      );
    }

    encrypted['_encrypted'] = true;
    return encrypted;
  }

  Future<void> addBill(BillModel bill) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');

    final data = _encryptData(bill.toMap());
    await collection.add(data);
  }

  Future<void> updateBill(BillModel bill) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');

    final data = _encryptData(bill.toMap());
    await collection.doc(bill.id).update(data);
  }

  Future<void> deleteBill(String id) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.doc(id).delete();
  }

  Future<void> markAsPaid(BillModel bill) async {
    await updateBill(bill.copyWith(isPaid: true));
  }

  Future<void> markAsUnpaid(BillModel bill) async {
    await updateBill(bill.copyWith(isPaid: false));
  }
}
