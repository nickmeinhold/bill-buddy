import 'dart:typed_data';

import 'package:bill_buddy/core/encryption/encryption_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EncryptionState', () {
    group('isUnlocked', () {
      test('returns false when DEK is null', () {
        const state = EncryptionState();
        expect(state.isUnlocked, isFalse);
      });

      test('returns true when DEK is present', () {
        final state = EncryptionState(
          dek: Uint8List.fromList(List.filled(32, 0)),
        );
        expect(state.isUnlocked, isTrue);
      });
    });

    group('default values', () {
      test('has correct default values', () {
        const state = EncryptionState();

        expect(state.dek, isNull);
        expect(state.isInitialized, isFalse);
        expect(state.hasEncryption, isFalse);
        expect(state.requiresPassphrase, isFalse);
      });
    });

    group('copyWith', () {
      test('creates new instance with changed dek', () {
        const original = EncryptionState();
        final dek = Uint8List.fromList(List.filled(32, 1));
        final updated = original.copyWith(dek: dek);

        expect(updated.dek, equals(dek));
        expect(updated.isInitialized, equals(original.isInitialized));
      });

      test('creates new instance with changed isInitialized', () {
        const original = EncryptionState();
        final updated = original.copyWith(isInitialized: true);

        expect(updated.isInitialized, isTrue);
        expect(updated.dek, isNull);
      });

      test('creates new instance with changed hasEncryption', () {
        const original = EncryptionState();
        final updated = original.copyWith(hasEncryption: true);

        expect(updated.hasEncryption, isTrue);
      });

      test('creates new instance with changed requiresPassphrase', () {
        const original = EncryptionState();
        final updated = original.copyWith(requiresPassphrase: true);

        expect(updated.requiresPassphrase, isTrue);
      });

      test('clearDek sets dek to null', () {
        final original = EncryptionState(
          dek: Uint8List.fromList(List.filled(32, 1)),
          isInitialized: true,
          hasEncryption: true,
        );
        final updated = original.copyWith(clearDek: true);

        expect(updated.dek, isNull);
        expect(updated.isUnlocked, isFalse);
        // Other fields preserved
        expect(updated.isInitialized, isTrue);
        expect(updated.hasEncryption, isTrue);
      });

      test('clearDek takes precedence over new dek', () {
        final original = EncryptionState(
          dek: Uint8List.fromList(List.filled(32, 1)),
        );
        final newDek = Uint8List.fromList(List.filled(32, 2));
        final updated = original.copyWith(dek: newDek, clearDek: true);

        expect(updated.dek, isNull);
      });

      test('preserves all unchanged fields', () {
        final original = EncryptionState(
          dek: Uint8List.fromList(List.filled(32, 1)),
          isInitialized: true,
          hasEncryption: true,
          requiresPassphrase: true,
        );
        final updated = original.copyWith();

        expect(updated.dek, equals(original.dek));
        expect(updated.isInitialized, equals(original.isInitialized));
        expect(updated.hasEncryption, equals(original.hasEncryption));
        expect(updated.requiresPassphrase, equals(original.requiresPassphrase));
      });

      test('can update multiple fields at once', () {
        const original = EncryptionState();
        final dek = Uint8List.fromList(List.filled(32, 1));
        final updated = original.copyWith(
          dek: dek,
          isInitialized: true,
          hasEncryption: true,
          requiresPassphrase: false,
        );

        expect(updated.dek, equals(dek));
        expect(updated.isInitialized, isTrue);
        expect(updated.hasEncryption, isTrue);
        expect(updated.requiresPassphrase, isFalse);
      });
    });

    group('equality', () {
      test('equal states are equal', () {
        final dek = Uint8List.fromList(List.filled(32, 1));
        final state1 = EncryptionState(
          dek: dek,
          isInitialized: true,
          hasEncryption: true,
          requiresPassphrase: false,
        );
        final state2 = EncryptionState(
          dek: dek,
          isInitialized: true,
          hasEncryption: true,
          requiresPassphrase: false,
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('states with different dek are not equal', () {
        final state1 = EncryptionState(
          dek: Uint8List.fromList(List.filled(32, 1)),
        );
        final state2 = EncryptionState(
          dek: Uint8List.fromList(List.filled(32, 2)),
        );

        expect(state1, isNot(equals(state2)));
      });

      test('states with different isInitialized are not equal', () {
        const state1 = EncryptionState(isInitialized: true);
        const state2 = EncryptionState(isInitialized: false);

        expect(state1, isNot(equals(state2)));
      });

      test('states with different hasEncryption are not equal', () {
        const state1 = EncryptionState(hasEncryption: true);
        const state2 = EncryptionState(hasEncryption: false);

        expect(state1, isNot(equals(state2)));
      });

      test('states with different requiresPassphrase are not equal', () {
        const state1 = EncryptionState(requiresPassphrase: true);
        const state2 = EncryptionState(requiresPassphrase: false);

        expect(state1, isNot(equals(state2)));
      });

      test('default states are equal', () {
        const state1 = EncryptionState();
        const state2 = EncryptionState();

        expect(state1, equals(state2));
      });
    });

    group('props', () {
      test('props contains all fields', () {
        final dek = Uint8List.fromList(List.filled(32, 1));
        final state = EncryptionState(
          dek: dek,
          isInitialized: true,
          hasEncryption: true,
          requiresPassphrase: true,
        );

        expect(state.props, hasLength(4));
        expect(state.props, contains(dek));
        expect(state.props, contains(true));
      });

      test('props for default state', () {
        const state = EncryptionState();

        expect(state.props, equals([null, false, false, false]));
      });
    });

    group('state transitions', () {
      test('simulate new user setup flow', () {
        // Initial state
        const state1 = EncryptionState();
        expect(state1.isUnlocked, isFalse);
        expect(state1.hasEncryption, isFalse);

        // After generating DEK and setting up encryption
        final dek = Uint8List.fromList(List.filled(32, 1));
        final state2 = state1.copyWith(
          dek: dek,
          isInitialized: true,
          hasEncryption: true,
        );
        expect(state2.isUnlocked, isTrue);
        expect(state2.hasEncryption, isTrue);
        expect(state2.isInitialized, isTrue);
      });

      test('simulate login flow', () {
        // Check status - user has encryption
        const state1 = EncryptionState(
          isInitialized: true,
          hasEncryption: true,
        );
        expect(state1.isUnlocked, isFalse);

        // After unlocking with password
        final state2 = state1.copyWith(
          dek: Uint8List.fromList(List.filled(32, 1)),
        );
        expect(state2.isUnlocked, isTrue);
      });

      test('simulate logout flow', () {
        // User is logged in with encryption unlocked
        final state1 = EncryptionState(
          dek: Uint8List.fromList(List.filled(32, 1)),
          isInitialized: true,
          hasEncryption: true,
        );
        expect(state1.isUnlocked, isTrue);

        // After logout - reset to initial state
        const state2 = EncryptionState();
        expect(state2.isUnlocked, isFalse);
        expect(state2.isInitialized, isFalse);
      });

      test('simulate social auth requiring passphrase', () {
        // After checking status - needs passphrase
        const state1 = EncryptionState(
          isInitialized: true,
          hasEncryption: true,
          requiresPassphrase: true,
        );
        expect(state1.requiresPassphrase, isTrue);
        expect(state1.isUnlocked, isFalse);

        // After entering passphrase
        final state2 = state1.copyWith(
          dek: Uint8List.fromList(List.filled(32, 1)),
          requiresPassphrase: false,
        );
        expect(state2.requiresPassphrase, isFalse);
        expect(state2.isUnlocked, isTrue);
      });
    });
  });
}
