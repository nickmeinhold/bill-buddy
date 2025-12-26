import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/transaction_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../../subscriptions/domain/subscriptions_provider.dart';

final transactionsProvider =
    StreamProvider.autoDispose<List<TransactionModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('transactions')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList());
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
  return TransactionService(firestore, user?.uid);
});

class TransactionService {
  final FirebaseFirestore _firestore;
  final String? _userId;

  TransactionService(this._firestore, this._userId);

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (_userId == null) return null;
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions');
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.add(transaction.toMap());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.doc(id).delete();
  }
}
