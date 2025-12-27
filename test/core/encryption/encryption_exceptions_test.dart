import 'package:bill_buddy/core/encryption/encryption_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EncryptionLockedException', () {
    test('default message', () {
      const exception = EncryptionLockedException();
      expect(exception.message, equals('Encryption is locked'));
    });

    test('custom message', () {
      const exception = EncryptionLockedException('Custom message');
      expect(exception.message, equals('Custom message'));
    });

    test('toString includes class name and message', () {
      const exception = EncryptionLockedException('Test message');
      expect(
        exception.toString(),
        equals('EncryptionLockedException: Test message'),
      );
    });

    test('implements Exception', () {
      const exception = EncryptionLockedException();
      expect(exception, isA<Exception>());
    });
  });

  group('DecryptionFailedException', () {
    test('default message', () {
      const exception = DecryptionFailedException();
      expect(exception.message, equals('Decryption failed'));
    });

    test('custom message', () {
      const exception = DecryptionFailedException('Invalid key');
      expect(exception.message, equals('Invalid key'));
    });

    test('toString includes class name and message', () {
      const exception = DecryptionFailedException('Wrong password');
      expect(
        exception.toString(),
        equals('DecryptionFailedException: Wrong password'),
      );
    });

    test('implements Exception', () {
      const exception = DecryptionFailedException();
      expect(exception, isA<Exception>());
    });
  });

  group('InvalidRecoveryCodeException', () {
    test('default message', () {
      const exception = InvalidRecoveryCodeException();
      expect(exception.message, equals('Invalid recovery code'));
    });

    test('custom message', () {
      const exception = InvalidRecoveryCodeException('Code already used');
      expect(exception.message, equals('Code already used'));
    });

    test('toString includes class name and message', () {
      const exception = InvalidRecoveryCodeException('Expired code');
      expect(
        exception.toString(),
        equals('InvalidRecoveryCodeException: Expired code'),
      );
    });

    test('implements Exception', () {
      const exception = InvalidRecoveryCodeException();
      expect(exception, isA<Exception>());
    });
  });

  group('EncryptionNotInitializedException', () {
    test('default message', () {
      const exception = EncryptionNotInitializedException();
      expect(exception.message, equals('Encryption not initialized for user'));
    });

    test('custom message', () {
      const exception = EncryptionNotInitializedException('User not found');
      expect(exception.message, equals('User not found'));
    });

    test('toString includes class name and message', () {
      const exception = EncryptionNotInitializedException('No encryption data');
      expect(
        exception.toString(),
        equals('EncryptionNotInitializedException: No encryption data'),
      );
    });

    test('implements Exception', () {
      const exception = EncryptionNotInitializedException();
      expect(exception, isA<Exception>());
    });
  });

  group('exception throwing and catching', () {
    test('EncryptionLockedException can be thrown and caught', () {
      expect(
        () => throw const EncryptionLockedException('test'),
        throwsA(isA<EncryptionLockedException>()),
      );
    });

    test('DecryptionFailedException can be thrown and caught', () {
      expect(
        () => throw const DecryptionFailedException('test'),
        throwsA(isA<DecryptionFailedException>()),
      );
    });

    test('InvalidRecoveryCodeException can be thrown and caught', () {
      expect(
        () => throw const InvalidRecoveryCodeException('test'),
        throwsA(isA<InvalidRecoveryCodeException>()),
      );
    });

    test('EncryptionNotInitializedException can be thrown and caught', () {
      expect(
        () => throw const EncryptionNotInitializedException('test'),
        throwsA(isA<EncryptionNotInitializedException>()),
      );
    });
  });
}
