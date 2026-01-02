import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/encryption/encryption_provider.dart';
import '../../../core/encryption/encryption_service.dart';
import '../../../shared/models/account_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../../subscriptions/domain/subscriptions_provider.dart';

final accountsProvider = StreamProvider.autoDispose<List<AccountModel>>((ref) {
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
      .collection('accounts')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());

          // Decrypt sensitive fields
          data['name'] = encryptionService.decryptField(
            data['name'] as String,
            dek,
          );

          return AccountModel.fromMap(data, doc.id);
        }).toList(),
      );
});

final accountServiceProvider = Provider<AccountService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final firestore = ref.watch(firestoreProvider);
  final encryptionState = ref.watch(encryptionProvider);
  final encryptionService = ref.watch(encryptionServiceProvider);
  return AccountService(
    firestore,
    user?.uid,
    encryptionService,
    encryptionState.dek,
  );
});

class AccountService {
  final FirebaseFirestore _firestore;
  final String? _userId;
  final EncryptionService _encryptionService;
  final Uint8List? _dek;

  AccountService(
    this._firestore,
    this._userId,
    this._encryptionService,
    this._dek,
  );

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('accounts');
  }

  Map<String, dynamic> _encryptData(Map<String, dynamic> data) {
    if (_dek == null) return data;

    final encrypted = Map<String, dynamic>.from(data);

    // Encrypt sensitive fields
    encrypted['name'] = _encryptionService.encryptField(
      data['name'] as String,
      _dek,
    );

    encrypted['_encrypted'] = true;
    return encrypted;
  }

  Future<void> addAccount(AccountModel account) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');

    final data = _encryptData(account.toMap());
    await collection.add(data);
  }

  Future<void> updateAccount(AccountModel account) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');

    final data = _encryptData(account.toMap());
    await collection.doc(account.id).update(data);
  }

  Future<void> deleteAccount(String id) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');
    await collection.doc(id).delete();
  }
}
