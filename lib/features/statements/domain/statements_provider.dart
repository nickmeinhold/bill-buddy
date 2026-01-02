import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/statement_model.dart';
import '../../auth/domain/auth_provider.dart';
import '../../subscriptions/domain/subscriptions_provider.dart';

final storageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final statementsProvider = StreamProvider.autoDispose<List<StatementModel>>((
  ref,
) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('users')
      .doc(user.uid)
      .collection('statements')
      .orderBy('uploadedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => StatementModel.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

final statementServiceProvider = Provider<StatementService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final firestore = ref.watch(firestoreProvider);
  final storage = ref.watch(storageProvider);
  return StatementService(firestore, storage, user?.uid);
});

class StatementService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String? _userId;

  StatementService(this._firestore, this._storage, this._userId);

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (_userId == null) return null;
    return _firestore.collection('users').doc(_userId).collection('statements');
  }

  Reference? get _storageRef {
    if (_userId == null) return null;
    return _storage.ref().child('users').child(_userId).child('statements');
  }

  /// Uploads a PDF file and creates a statement document.
  /// Returns the created statement ID.
  Future<String> uploadStatement({
    required String fileName,
    required Uint8List fileBytes,
    String? accountId,
  }) async {
    final collection = _collection;
    final storageRef = _storageRef;
    if (collection == null || storageRef == null) {
      throw Exception('User not authenticated');
    }

    // Generate unique filename with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$timestamp-$fileName';
    final fileRef = storageRef.child(storagePath);

    // Upload file to Storage
    await fileRef.putData(
      fileBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );

    // Create statement document in Firestore
    final statement = StatementModel(
      id: '',
      fileName: fileName,
      uploadedAt: DateTime.now(),
      status: StatementStatus.processing,
      storagePath: 'users/$_userId/statements/$storagePath',
      accountId: accountId,
    );

    final docRef = await collection.add(statement.toMap());
    return docRef.id;
  }

  Future<void> deleteStatement(StatementModel statement) async {
    final collection = _collection;
    if (collection == null) throw Exception('User not authenticated');

    // Delete from Storage
    try {
      await _storage.ref(statement.storagePath).delete();
    } catch (e) {
      // File might already be deleted, continue with Firestore deletion
    }

    // Delete from Firestore
    await collection.doc(statement.id).delete();
  }
}
