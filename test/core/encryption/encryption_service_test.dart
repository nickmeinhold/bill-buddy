import 'dart:typed_data';

import 'package:bill_buddy/core/encryption/encryption_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EncryptionService encryptionService;

  setUp(() {
    encryptionService = EncryptionService();
  });

  group('DEK Generation', () {
    test('generates 32-byte DEK (256 bits)', () {
      final dek = encryptionService.generateDEK();
      expect(dek.length, equals(32));
      expect(dek, isA<Uint8List>());
    });

    test('generates unique DEKs on each call', () {
      final dek1 = encryptionService.generateDEK();
      final dek2 = encryptionService.generateDEK();
      expect(dek1, isNot(equals(dek2)));
    });
  });

  group('Salt Generation', () {
    test('generates 32-byte salt', () {
      final salt = encryptionService.generateSalt();
      expect(salt.length, equals(32));
    });

    test('generates unique salts on each call', () {
      final salt1 = encryptionService.generateSalt();
      final salt2 = encryptionService.generateSalt();
      expect(salt1, isNot(equals(salt2)));
    });
  });

  group('KEK Derivation', () {
    test('derives consistent KEK for same password and salt', () {
      final salt = encryptionService.generateSalt();
      const password = 'testPassword123';

      final kek1 = encryptionService.deriveKEK(password, salt);
      final kek2 = encryptionService.deriveKEK(password, salt);

      expect(kek1, equals(kek2));
    });

    test('derives different KEKs for different passwords', () {
      final salt = encryptionService.generateSalt();

      final kek1 = encryptionService.deriveKEK('password1', salt);
      final kek2 = encryptionService.deriveKEK('password2', salt);

      expect(kek1, isNot(equals(kek2)));
    });

    test('derives different KEKs for different salts', () {
      const password = 'samePassword';
      final salt1 = encryptionService.generateSalt();
      final salt2 = encryptionService.generateSalt();

      final kek1 = encryptionService.deriveKEK(password, salt1);
      final kek2 = encryptionService.deriveKEK(password, salt2);

      expect(kek1, isNot(equals(kek2)));
    });

    test('derives 32-byte KEK', () {
      final salt = encryptionService.generateSalt();
      final kek = encryptionService.deriveKEK('password', salt);
      expect(kek.length, equals(32));
    });
  });

  group('DEK Wrapping/Unwrapping', () {
    test('wraps and unwraps DEK correctly', () {
      final dek = encryptionService.generateDEK();
      const password = 'securePassword123';

      final wrapped = encryptionService.wrapDEK(dek, password);
      final unwrapped = encryptionService.unwrapDEK(wrapped, password);

      expect(unwrapped, equals(dek));
    });

    test('wrapped DEK is a base64 string', () {
      final dek = encryptionService.generateDEK();
      final wrapped = encryptionService.wrapDEK(dek, 'password');

      expect(wrapped, isA<String>());
      expect(wrapped.isNotEmpty, isTrue);
      // Base64 should only contain valid characters
      expect(RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(wrapped), isTrue);
    });

    test('throws exception with wrong password', () {
      final dek = encryptionService.generateDEK();
      final wrapped = encryptionService.wrapDEK(dek, 'correctPassword');

      expect(
        () => encryptionService.unwrapDEK(wrapped, 'wrongPassword'),
        throwsA(isA<Exception>()),
      );
    });

    test('produces different wrapped output each time (due to random salt/IV)', () {
      final dek = encryptionService.generateDEK();
      const password = 'password';

      final wrapped1 = encryptionService.wrapDEK(dek, password);
      final wrapped2 = encryptionService.wrapDEK(dek, password);

      expect(wrapped1, isNot(equals(wrapped2)));
    });
  });

  group('DEK Rewrapping', () {
    test('rewraps DEK with new password', () {
      final dek = encryptionService.generateDEK();
      const oldPassword = 'oldPassword';
      const newPassword = 'newPassword';

      final wrapped = encryptionService.wrapDEK(dek, oldPassword);
      final rewrapped =
          encryptionService.rewrapDEK(wrapped, oldPassword, newPassword);

      final unwrapped = encryptionService.unwrapDEK(rewrapped, newPassword);
      expect(unwrapped, equals(dek));
    });

    test('old password no longer works after rewrap', () {
      final dek = encryptionService.generateDEK();
      const oldPassword = 'oldPassword';
      const newPassword = 'newPassword';

      final wrapped = encryptionService.wrapDEK(dek, oldPassword);
      final rewrapped =
          encryptionService.rewrapDEK(wrapped, oldPassword, newPassword);

      expect(
        () => encryptionService.unwrapDEK(rewrapped, oldPassword),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Field Encryption/Decryption', () {
    test('encrypts and decrypts string correctly', () {
      final dek = encryptionService.generateDEK();
      const plaintext = 'Sensitive data here';

      final encrypted = encryptionService.encryptField(plaintext, dek);
      final decrypted = encryptionService.decryptField(encrypted, dek);

      expect(decrypted, equals(plaintext));
    });

    test('encrypted field starts with marker', () {
      final dek = encryptionService.generateDEK();
      final encrypted = encryptionService.encryptField('test', dek);

      expect(encrypted, startsWith('ENC:v1:'));
    });

    test('returns original value if not encrypted', () {
      final dek = encryptionService.generateDEK();
      const plaintext = 'Not encrypted text';

      final result = encryptionService.decryptField(plaintext, dek);
      expect(result, equals(plaintext));
    });

    test('handles empty string', () {
      final dek = encryptionService.generateDEK();
      const plaintext = '';

      final encrypted = encryptionService.encryptField(plaintext, dek);
      final decrypted = encryptionService.decryptField(encrypted, dek);

      expect(decrypted, equals(plaintext));
    });

    test('handles unicode characters', () {
      final dek = encryptionService.generateDEK();
      const plaintext = 'Hello 世界 🌍 émojis';

      final encrypted = encryptionService.encryptField(plaintext, dek);
      final decrypted = encryptionService.decryptField(encrypted, dek);

      expect(decrypted, equals(plaintext));
    });

    test('produces different ciphertext each time (random IV)', () {
      final dek = encryptionService.generateDEK();
      const plaintext = 'Same text';

      final encrypted1 = encryptionService.encryptField(plaintext, dek);
      final encrypted2 = encryptionService.encryptField(plaintext, dek);

      expect(encrypted1, isNot(equals(encrypted2)));
    });
  });

  group('Amount Encryption/Decryption', () {
    test('encrypts and decrypts positive amount', () {
      final dek = encryptionService.generateDEK();
      const amount = 123.45;

      final encrypted = encryptionService.encryptAmount(amount, dek);
      final decrypted = encryptionService.decryptAmount(encrypted, dek);

      expect(decrypted, equals(amount));
    });

    test('encrypts and decrypts negative amount', () {
      final dek = encryptionService.generateDEK();
      const amount = -99.99;

      final encrypted = encryptionService.encryptAmount(amount, dek);
      final decrypted = encryptionService.decryptAmount(encrypted, dek);

      expect(decrypted, equals(amount));
    });

    test('encrypts and decrypts zero', () {
      final dek = encryptionService.generateDEK();
      const amount = 0.0;

      final encrypted = encryptionService.encryptAmount(amount, dek);
      final decrypted = encryptionService.decryptAmount(encrypted, dek);

      expect(decrypted, equals(amount));
    });

    test('preserves decimal precision', () {
      final dek = encryptionService.generateDEK();
      const amount = 1234.56789;

      final encrypted = encryptionService.encryptAmount(amount, dek);
      final decrypted = encryptionService.decryptAmount(encrypted, dek);

      expect(decrypted, equals(amount));
    });
  });

  group('isEncrypted', () {
    test('returns true for encrypted value', () {
      final dek = encryptionService.generateDEK();
      final encrypted = encryptionService.encryptField('test', dek);

      expect(encryptionService.isEncrypted(encrypted), isTrue);
    });

    test('returns false for plain text', () {
      expect(encryptionService.isEncrypted('plain text'), isFalse);
    });

    test('returns false for similar but incorrect prefix', () {
      expect(encryptionService.isEncrypted('ENC:v2:data'), isFalse);
      expect(encryptionService.isEncrypted('ENCRYPTED:data'), isFalse);
    });
  });

  group('Recovery Codes', () {
    test('generates 8 recovery codes', () {
      final codes = encryptionService.generateRecoveryCodes();
      expect(codes.length, equals(8));
    });

    test('codes are in XXXX-XXXX format', () {
      final codes = encryptionService.generateRecoveryCodes();
      final format = RegExp(r'^[A-Z2-9]{4}-[A-Z2-9]{4}$');

      for (final code in codes) {
        expect(format.hasMatch(code), isTrue, reason: 'Code "$code" is invalid');
      }
    });

    test('codes do not contain ambiguous characters (0, 1, I, O)', () {
      final codes = encryptionService.generateRecoveryCodes();
      final ambiguous = RegExp(r'[01IO]');

      for (final code in codes) {
        expect(
          ambiguous.hasMatch(code),
          isFalse,
          reason: 'Code "$code" contains ambiguous characters',
        );
      }
    });

    test('generates unique codes each time', () {
      final codes1 = encryptionService.generateRecoveryCodes();
      final codes2 = encryptionService.generateRecoveryCodes();

      expect(codes1, isNot(equals(codes2)));
    });

    test('all codes in a batch are unique', () {
      final codes = encryptionService.generateRecoveryCodes();
      final uniqueCodes = codes.toSet();
      expect(uniqueCodes.length, equals(codes.length));
    });
  });

  group('Recovery Code Hashing', () {
    test('hash is deterministic', () {
      const code = 'ABCD-EFGH';
      final hash1 = encryptionService.hashRecoveryCode(code);
      final hash2 = encryptionService.hashRecoveryCode(code);
      expect(hash1, equals(hash2));
    });

    test('different codes produce different hashes', () {
      final hash1 = encryptionService.hashRecoveryCode('ABCD-EFGH');
      final hash2 = encryptionService.hashRecoveryCode('WXYZ-1234');
      expect(hash1, isNot(equals(hash2)));
    });

    test('hash is case insensitive', () {
      final hash1 = encryptionService.hashRecoveryCode('ABCD-EFGH');
      final hash2 = encryptionService.hashRecoveryCode('abcd-efgh');
      expect(hash1, equals(hash2));
    });

    test('hash ignores dashes', () {
      final hash1 = encryptionService.hashRecoveryCode('ABCD-EFGH');
      final hash2 = encryptionService.hashRecoveryCode('ABCDEFGH');
      expect(hash1, equals(hash2));
    });
  });

  group('Recovery Code Verification', () {
    test('verifies correct code', () {
      const code = 'ABCD-EFGH';
      final hash = encryptionService.hashRecoveryCode(code);

      expect(encryptionService.verifyRecoveryCode(code, hash), isTrue);
    });

    test('rejects incorrect code', () {
      const code = 'ABCD-EFGH';
      final hash = encryptionService.hashRecoveryCode(code);

      expect(encryptionService.verifyRecoveryCode('WRONG-CODE', hash), isFalse);
    });

    test('verification is case insensitive', () {
      const code = 'ABCD-EFGH';
      final hash = encryptionService.hashRecoveryCode(code);

      expect(encryptionService.verifyRecoveryCode('abcd-efgh', hash), isTrue);
    });
  });

  group('Recovery Code DEK Operations', () {
    test('wraps and unwraps DEK with recovery code', () {
      final dek = encryptionService.generateDEK();
      const recoveryCode = 'ABCD-EFGH';

      final wrapped =
          encryptionService.wrapDEKWithRecoveryCode(dek, recoveryCode);
      final unwrapped =
          encryptionService.unwrapDEKWithRecoveryCode(wrapped, recoveryCode);

      expect(unwrapped, equals(dek));
    });

    test('recovery code wrapping is case insensitive', () {
      final dek = encryptionService.generateDEK();

      final wrapped =
          encryptionService.wrapDEKWithRecoveryCode(dek, 'ABCD-EFGH');
      final unwrapped =
          encryptionService.unwrapDEKWithRecoveryCode(wrapped, 'abcd-efgh');

      expect(unwrapped, equals(dek));
    });

    test('wrong recovery code fails to unwrap', () {
      final dek = encryptionService.generateDEK();
      final wrapped =
          encryptionService.wrapDEKWithRecoveryCode(dek, 'ABCD-EFGH');

      expect(
        () => encryptionService.unwrapDEKWithRecoveryCode(wrapped, 'WRONG-CODE'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
