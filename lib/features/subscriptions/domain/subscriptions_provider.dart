import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/subscription_model.dart';
import '../../auth/domain/auth_provider.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final subscriptionsProvider =
    StreamProvider.autoDispose<List<SubscriptionModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('subscriptions')
      .orderBy('nextBillingDate')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => SubscriptionModel.fromMap(doc.data(), doc.id))
          .toList());
});

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final firestore = ref.watch(firestoreProvider);
  return SubscriptionService(firestore, user?.uid);
});

class SubscriptionService {
  final FirebaseFirestore _firestore;
  final String? _userId;

  SubscriptionService(this._firestore, this._userId);

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (_userId == null) return null;
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('subscriptions');
  }

  Future<void> addSubscription(SubscriptionModel subscription) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.add(subscription.toMap());
  }

  Future<void> updateSubscription(SubscriptionModel subscription) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.doc(subscription.id).update(subscription.toMap());
  }

  Future<void> deleteSubscription(String id) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.doc(id).delete();
  }

  Future<void> toggleStatus(SubscriptionModel subscription) async {
    final newStatus = subscription.status == SubscriptionStatus.active
        ? SubscriptionStatus.paused
        : SubscriptionStatus.active;
    await updateSubscription(subscription.copyWith(status: newStatus));
  }
}
