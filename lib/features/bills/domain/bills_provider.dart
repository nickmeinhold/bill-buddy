import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/bill_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../../subscriptions/domain/subscriptions_provider.dart';

final billsProvider = StreamProvider.autoDispose<List<BillModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('bills')
      .orderBy('dueDate')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => BillModel.fromMap(doc.data(), doc.id))
          .toList());
});

final billServiceProvider = Provider<BillService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final firestore = ref.watch(firestoreProvider);
  return BillService(firestore, user?.uid);
});

class BillService {
  final FirebaseFirestore _firestore;
  final String? _userId;

  BillService(this._firestore, this._userId);

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('bills');
  }

  Future<void> addBill(BillModel bill) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.add(bill.toMap());
  }

  Future<void> updateBill(BillModel bill) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.doc(bill.id).update(bill.toMap());
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
