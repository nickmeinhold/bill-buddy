import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/subscriptions/domain/subscriptions_provider.dart';
import 'encryption_exceptions.dart';
import 'encryption_service.dart';

/// Encryption service provider (singleton)
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// Holds the current encryption state for the session
class EncryptionState extends Equatable {
  /// Decrypted DEK (null if not authenticated or locked)
  final Uint8List? dek;

  /// True after encryption state has been checked/initialized
  final bool isInitialized;

  /// True if user has encryption set up in Firestore
  final bool hasEncryption;

  /// True if user needs to enter passphrase (social auth)
  final bool requiresPassphrase;

  const EncryptionState({
    this.dek,
    this.isInitialized = false,
    this.hasEncryption = false,
    this.requiresPassphrase = false,
  });

  /// Whether the encryption is unlocked and ready to use
  bool get isUnlocked => dek != null;

  EncryptionState copyWith({
    Uint8List? dek,
    bool? isInitialized,
    bool? hasEncryption,
    bool? requiresPassphrase,
    bool clearDek = false,
  }) {
    return EncryptionState(
      dek: clearDek ? null : (dek ?? this.dek),
      isInitialized: isInitialized ?? this.isInitialized,
      hasEncryption: hasEncryption ?? this.hasEncryption,
      requiresPassphrase: requiresPassphrase ?? this.requiresPassphrase,
    );
  }

  @override
  List<Object?> get props => [dek, isInitialized, hasEncryption, requiresPassphrase];
}

/// Notifier for managing encryption state
class EncryptionNotifier extends StateNotifier<EncryptionState> {
  final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService;

  EncryptionNotifier(this._firestore, this._encryptionService)
      : super(const EncryptionState());

  /// Initialize DEK for a new user during signup
  /// Generates DEK, wraps it with password-derived KEK, stores in Firestore
  /// Returns recovery codes for user to save
  Future<List<String>> initializeForNewUser(
    String userId,
    String password,
  ) async {
    debugPrint('ENCRYPTION: initializeForNewUser for $userId');
    try {
    // Generate new DEK
    final dek = _encryptionService.generateDEK();
    debugPrint('ENCRYPTION: Generated DEK');

    // Wrap DEK with password
    final wrappedDEK = _encryptionService.wrapDEK(dek, password);
    debugPrint('ENCRYPTION: Wrapped DEK');

    // Generate recovery codes
    final recoveryCodes = _encryptionService.generateRecoveryCodes();
    debugPrint('ENCRYPTION: Generated ${recoveryCodes.length} recovery codes');

    // Hash recovery codes for storage
    final hashedCodes = recoveryCodes.map((code) => {
          'hash': _encryptionService.hashRecoveryCode(code),
          'used': false,
        }).toList();

    // Also wrap DEK with first recovery code for recovery purposes
    final recoveryWrappedDEK = _encryptionService.wrapDEKWithRecoveryCode(
      dek,
      recoveryCodes.first,
    );
    debugPrint('ENCRYPTION: Wrapped DEK with recovery code');

    // Store in Firestore
    debugPrint('ENCRYPTION: Writing to Firestore...');
    await _firestore.collection('users').doc(userId).set({
      'encryption': {
        'wrappedDEK': wrappedDEK,
        'recoveryWrappedDEK': recoveryWrappedDEK,
        'version': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'recoveryCodes': hashedCodes,
      },
    }, SetOptions(merge: true));
    debugPrint('ENCRYPTION: Firestore write complete');

    // Update state
    state = state.copyWith(
      dek: dek,
      isInitialized: true,
      hasEncryption: true,
      requiresPassphrase: false,
    );
    debugPrint('ENCRYPTION: State updated, returning codes');

    return recoveryCodes;
    } catch (e, stack) {
      debugPrint('ENCRYPTION: Error in initializeForNewUser: $e');
      debugPrint('ENCRYPTION: Stack: $stack');
      rethrow;
    }
  }

  /// Check if user has encryption set up
  Future<bool> checkEncryptionStatus(String userId) async {
    debugPrint('ENCRYPTION: checkEncryptionStatus for $userId');
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      debugPrint('ENCRYPTION: Got doc, exists=${doc.exists}');
      final data = doc.data();
      final hasEncryption = data?['encryption']?['wrappedDEK'] != null;
      debugPrint('ENCRYPTION: hasEncryption=$hasEncryption');

      state = state.copyWith(
        isInitialized: true,
        hasEncryption: hasEncryption,
      );

      return hasEncryption;
    } catch (e, stack) {
      debugPrint('ENCRYPTION: Error in checkEncryptionStatus: $e');
      debugPrint('ENCRYPTION: Stack: $stack');
      rethrow;
    }
  }

  /// Unlock encryption for existing user during login
  /// Retrieves wrapped DEK, derives KEK from password, unwraps DEK
  Future<void> unlockForUser(String userId, String password) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();

    if (data == null || data['encryption']?['wrappedDEK'] == null) {
      throw EncryptionNotInitializedException();
    }

    final wrappedDEK = data['encryption']['wrappedDEK'] as String;

    try {
      final dek = _encryptionService.unwrapDEK(wrappedDEK, password);

      state = state.copyWith(
        dek: dek,
        isInitialized: true,
        hasEncryption: true,
        requiresPassphrase: false,
      );
    } catch (e) {
      throw DecryptionFailedException('Failed to unlock encryption: $e');
    }
  }

  /// Set that user requires passphrase (for social auth)
  void setRequiresPassphrase(bool requires) {
    state = state.copyWith(requiresPassphrase: requires);
  }

  /// Lock encryption on logout
  void lock() {
    state = const EncryptionState(); // Reset to initial state
  }

  /// Recover DEK using a recovery code
  Future<void> recoverWithCode(
    String userId,
    String recoveryCode,
    String newPassword,
  ) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();

    if (data == null || data['encryption'] == null) {
      throw EncryptionNotInitializedException();
    }

    final recoveryCodes =
        (data['encryption']['recoveryCodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    // Find matching unused recovery code
    int? matchingIndex;
    for (var i = 0; i < recoveryCodes.length; i++) {
      final codeData = recoveryCodes[i];
      if (codeData['used'] == false &&
          _encryptionService.verifyRecoveryCode(
              recoveryCode, codeData['hash'] as String)) {
        matchingIndex = i;
        break;
      }
    }

    if (matchingIndex == null) {
      throw InvalidRecoveryCodeException('Invalid or already used recovery code');
    }

    // Unwrap DEK with recovery code
    final recoveryWrappedDEK = data['encryption']['recoveryWrappedDEK'] as String?;
    if (recoveryWrappedDEK == null) {
      throw EncryptionNotInitializedException('No recovery backup found');
    }

    final dek = _encryptionService.unwrapDEKWithRecoveryCode(
      recoveryWrappedDEK,
      recoveryCode,
    );

    // Re-wrap DEK with new password
    final newWrappedDEK = _encryptionService.wrapDEK(dek, newPassword);

    // Mark recovery code as used
    recoveryCodes[matchingIndex]['used'] = true;

    // Update Firestore
    await _firestore.collection('users').doc(userId).update({
      'encryption.wrappedDEK': newWrappedDEK,
      'encryption.recoveryCodes': recoveryCodes,
      'encryption.lastRecovered': DateTime.now().toIso8601String(),
    });

    // Update state
    state = state.copyWith(
      dek: dek,
      isInitialized: true,
      hasEncryption: true,
    );
  }

  /// Change password - re-wrap DEK with new password
  Future<void> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();

    if (data == null || data['encryption']?['wrappedDEK'] == null) {
      throw EncryptionNotInitializedException();
    }

    final oldWrappedDEK = data['encryption']['wrappedDEK'] as String;

    // Re-wrap with new password
    final newWrappedDEK = _encryptionService.rewrapDEK(
      oldWrappedDEK,
      oldPassword,
      newPassword,
    );

    // Update Firestore
    await _firestore.collection('users').doc(userId).update({
      'encryption.wrappedDEK': newWrappedDEK,
      'encryption.lastPasswordChange': DateTime.now().toIso8601String(),
    });
  }
}

/// Main encryption state provider
final encryptionProvider =
    StateNotifierProvider<EncryptionNotifier, EncryptionState>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final encryptionService = ref.watch(encryptionServiceProvider);
  return EncryptionNotifier(firestore, encryptionService);
});

/// Convenience provider for getting DEK (throws if not unlocked)
final dekProvider = Provider<Uint8List>((ref) {
  final state = ref.watch(encryptionProvider);
  if (!state.isUnlocked) {
    throw EncryptionLockedException('Encryption not unlocked');
  }
  return state.dek!;
});

/// Provider to check if encryption is ready for use
final isEncryptionReadyProvider = Provider<bool>((ref) {
  final state = ref.watch(encryptionProvider);
  return state.isUnlocked;
});
