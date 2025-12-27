import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/budget_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../../subscriptions/domain/subscriptions_provider.dart';

final budgetsProvider = StreamProvider.autoDispose<List<BudgetModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('budgets')
      .orderBy('category')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => BudgetModel.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

final budgetServiceProvider = Provider<BudgetService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final firestore = ref.watch(firestoreProvider);
  return BudgetService(firestore, user?.uid);
});

class BudgetService {
  final FirebaseFirestore _firestore;
  final String? _userId;

  BudgetService(this._firestore, this._userId);

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('budgets');
  }

  Future<void> addBudget(BudgetModel budget) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.add(budget.toMap());
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.doc(budget.id).update(budget.toMap());
  }

  Future<void> deleteBudget(String id) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.doc(id).delete();
  }

  Future<void> updateSpent(String id, double spent) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.doc(id).update({'spent': spent});
  }

  Future<void> resetSpent(String id) async {
    await updateSpent(id, 0);
  }
}
