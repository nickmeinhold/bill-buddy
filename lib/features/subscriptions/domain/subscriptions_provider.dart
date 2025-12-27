import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/encryption/encryption_provider.dart';
import '../../../core/encryption/encryption_service.dart';
import '../../../shared/models/subscription_model.dart';
import '../../auth/domain/auth_provider.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final subscriptionsProvider =
    StreamProvider.autoDispose<List<SubscriptionModel>>((ref) {
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
      .collection('subscriptions')
      .orderBy('nextBillingDate')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
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

            return SubscriptionModel.fromMap(data, doc.id);
          }).toList());
});

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final firestore = ref.watch(firestoreProvider);
  final encryptionState = ref.watch(encryptionProvider);
  final encryptionService = ref.watch(encryptionServiceProvider);
  return SubscriptionService(
    firestore,
    user?.uid,
    encryptionService,
    encryptionState.dek,
  );
});

class SubscriptionService {
  final FirebaseFirestore _firestore;
  final String? _userId;
  final EncryptionService _encryptionService;
  final Uint8List? _dek;

  SubscriptionService(
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
        .collection('subscriptions');
  }

  Map<String, dynamic> _encryptData(Map<String, dynamic> data) {
    if (_dek == null) return data;

    final encrypted = Map<String, dynamic>.from(data);

    // Encrypt sensitive fields
    encrypted['name'] = _encryptionService.encryptField(
      data['name'] as String,
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

  Future<void> addSubscription(SubscriptionModel subscription) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');

    final data = _encryptData(subscription.toMap());
    await collection.add(data);
  }

  Future<void> updateSubscription(SubscriptionModel subscription) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');

    final data = _encryptData(subscription.toMap());
    await collection.doc(subscription.id).update(data);
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
