/// Exception thrown when encryption operations are attempted
/// while the encryption is locked (DEK not available).
class EncryptionLockedException implements Exception {
  final String message;

  const EncryptionLockedException([this.message = 'Encryption is locked']);

  @override
  String toString() => 'EncryptionLockedException: $message';
}

/// Exception thrown when decryption fails due to invalid key or corrupted data.
class DecryptionFailedException implements Exception {
  final String message;

  const DecryptionFailedException([this.message = 'Decryption failed']);

  @override
  String toString() => 'DecryptionFailedException: $message';
}

/// Exception thrown when a recovery code is invalid or already used.
class InvalidRecoveryCodeException implements Exception {
  final String message;

  const InvalidRecoveryCodeException([this.message = 'Invalid recovery code']);

  @override
  String toString() => 'InvalidRecoveryCodeException: $message';
}

/// Exception thrown when encryption is not set up for a user.
class EncryptionNotInitializedException implements Exception {
  final String message;

  const EncryptionNotInitializedException([
    this.message = 'Encryption not initialized for user',
  ]);

  @override
  String toString() => 'EncryptionNotInitializedException: $message';
}
