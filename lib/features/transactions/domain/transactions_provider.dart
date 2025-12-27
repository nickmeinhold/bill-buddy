import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/encryption/encryption_provider.dart';
import '../../../core/encryption/encryption_service.dart';
import '../../../shared/models/transaction_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../../subscriptions/domain/subscriptions_provider.dart';

final transactionsProvider =
    StreamProvider.autoDispose<List<TransactionModel>>((ref) {
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
      .collection('transactions')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());

            // Decrypt fields if encrypted
            if (data['_encrypted'] == true) {
              data['merchantName'] = encryptionService.decryptField(
                data['merchantName'] as String,
                dek,
              );
              data['amount'] = encryptionService.decryptAmount(
                data['amount'],
                dek,
              );
              if (data['notes'] != null) {
                data['notes'] = encryptionService.decryptField(
                  data['notes'] as String,
                  dek,
                );
              }
            }

            return TransactionModel.fromMap(data, doc.id);
          }).toList());
});

enum TransactionFilter { all, income, expenses, subscriptions }

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => TransactionFilter.all);

final filteredTransactionsProvider =
    Provider.autoDispose<AsyncValue<List<TransactionModel>>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final filter = ref.watch(transactionFilterProvider);

  return transactionsAsync.whenData((transactions) {
    switch (filter) {
      case TransactionFilter.all:
        return transactions;
      case TransactionFilter.income:
        return transactions.where((t) => t.isIncome).toList();
      case TransactionFilter.expenses:
        return transactions.where((t) => t.isExpense).toList();
      case TransactionFilter.subscriptions:
        return transactions.where((t) => t.isSubscription).toList();
    }
  });
});

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final firestore = ref.watch(firestoreProvider);
  final encryptionState = ref.watch(encryptionProvider);
  final encryptionService = ref.watch(encryptionServiceProvider);
  return TransactionService(
    firestore,
    user?.uid,
    encryptionService,
    encryptionState.dek,
  );
});

class TransactionService {
  final FirebaseFirestore _firestore;
  final String? _userId;
  final EncryptionService _encryptionService;
  final Uint8List? _dek;

  TransactionService(
    this._firestore,
    this._userId,
    this._encryptionService,
    this._dek,
  );

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (_userId == null) return null;
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions');
  }

  Map<String, dynamic> _encryptData(Map<String, dynamic> data) {
    if (_dek == null) return data;

    final encrypted = Map<String, dynamic>.from(data);

    // Encrypt sensitive fields
    encrypted['merchantName'] = _encryptionService.encryptField(
      data['merchantName'] as String,
      _dek!,
    );
    encrypted['amount'] = _encryptionService.encryptAmount(
      data['amount'] as double,
      _dek!,
    );
    if (data['notes'] != null) {
      encrypted['notes'] = _encryptionService.encryptField(
        data['notes'] as String,
        _dek!,
      );
    }

    encrypted['_encrypted'] = true;
    return encrypted;
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');

    final data = _encryptData(transaction.toMap());
    await collection.add(data);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');

    final data = _encryptData(transaction.toMap());
    await collection.doc(transaction.id).update(data);
  }

  Future<void> deleteTransaction(String id) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.doc(id).delete();
  }
}
