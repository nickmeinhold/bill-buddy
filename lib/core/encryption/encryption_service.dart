import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Handles all cryptographic operations for the application.
///
/// Key Hierarchy:
/// - User Password -> PBKDF2 -> KEK (Key Encryption Key)
/// - Random 256-bit -> DEK (Data Encryption Key)
/// - DEK encrypted by KEK -> Wrapped DEK (stored in Firestore)
/// - DEK used for AES-256-GCM encryption of sensitive fields
class EncryptionService {
  // Constants
  static const int _keyLength = 32; // 256 bits for AES-256
  static const int _ivLength = 12; // 96 bits for GCM (recommended)
  static const int _saltLength = 32; // 256 bits for PBKDF2 salt
  static const int _pbkdf2Iterations = 100000; // OWASP recommended minimum
  static const int _tagLength = 16; // 128 bits for GCM auth tag
  static const int _recoveryCodeCount = 8;
  static const int _recoveryCodeLength = 8; // 8 characters per code

  // Encryption marker prefix to identify encrypted data
  static const String _encryptionMarker = 'ENC:v1:';

  final SecureRandom _secureRandom;

  EncryptionService() : _secureRandom = _createSecureRandom();

  static SecureRandom _createSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  /// Generate a cryptographically secure random DEK (Data Encryption Key)
  Uint8List generateDEK() {
    return _secureRandom.nextBytes(_keyLength);
  }

  /// Generate a cryptographically secure salt for PBKDF2
  Uint8List generateSalt() {
    return _secureRandom.nextBytes(_saltLength);
  }

  /// Generate a random IV for AES-GCM
  Uint8List _generateIV() {
    return _secureRandom.nextBytes(_ivLength);
  }

  /// Derive KEK (Key Encryption Key) from password using PBKDF2-HMAC-SHA256
  Uint8List deriveKEK(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyLength));

    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Wrap (encrypt) the DEK using the KEK with AES-256-GCM
  /// Returns: base64(salt + iv + encryptedDEK + authTag)
  String wrapDEK(Uint8List dek, String password) {
    final salt = generateSalt();
    final kek = deriveKEK(password, salt);
    final iv = _generateIV();

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true, // encrypt
        AEADParameters(
          KeyParameter(kek),
          _tagLength * 8, // tag length in bits
          iv,
          Uint8List(0), // no additional authenticated data
        ),
      );

    final cipherText = Uint8List(dek.length + _tagLength);
    final len = cipher.processBytes(dek, 0, dek.length, cipherText, 0);
    cipher.doFinal(cipherText, len);

    // Combine: salt + iv + cipherText (includes auth tag)
    final combined = Uint8List(_saltLength + _ivLength + cipherText.length);
    combined.setRange(0, _saltLength, salt);
    combined.setRange(_saltLength, _saltLength + _ivLength, iv);
    combined.setRange(_saltLength + _ivLength, combined.length, cipherText);

    return base64.encode(combined);
  }

  /// Unwrap (decrypt) the DEK using the password
  /// Input: base64(salt + iv + encryptedDEK + authTag)
  Uint8List unwrapDEK(String wrappedDEK, String password) {
    final combined = base64.decode(wrappedDEK);

    // Extract components
    final salt = Uint8List.sublistView(combined, 0, _saltLength);
    final iv =
        Uint8List.sublistView(combined, _saltLength, _saltLength + _ivLength);
    final cipherText = Uint8List.sublistView(combined, _saltLength + _ivLength);

    // Derive KEK from password
    final kek = deriveKEK(password, salt);

    // Decrypt
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false, // decrypt
        AEADParameters(
          KeyParameter(kek),
          _tagLength * 8,
          iv,
          Uint8List(0),
        ),
      );

    final dek = Uint8List(cipherText.length - _tagLength);
    final len = cipher.processBytes(cipherText, 0, cipherText.length, dek, 0);
    cipher.doFinal(dek, len);

    return dek;
  }

  /// Re-wrap DEK with new password (for password changes)
  String rewrapDEK(String oldWrappedDEK, String oldPassword, String newPassword) {
    final dek = unwrapDEK(oldWrappedDEK, oldPassword);
    return wrapDEK(dek, newPassword);
  }

  /// Encrypt a string value using AES-256-GCM
  /// Returns: ENC:v1:base64(iv + ciphertext + authTag)
  String encryptField(String plaintext, Uint8List dek) {
    final iv = _generateIV();
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(dek),
          _tagLength * 8,
          iv,
          Uint8List(0),
        ),
      );

    final cipherText = Uint8List(plaintextBytes.length + _tagLength);
    final len = cipher.processBytes(
        plaintextBytes, 0, plaintextBytes.length, cipherText, 0);
    cipher.doFinal(cipherText, len);

    // Combine: iv + cipherText (includes auth tag)
    final combined = Uint8List(_ivLength + cipherText.length);
    combined.setRange(0, _ivLength, iv);
    combined.setRange(_ivLength, combined.length, cipherText);

    return '$_encryptionMarker${base64.encode(combined)}';
  }

  /// Decrypt a string value
  /// Returns plaintext or original value if not encrypted
  String decryptField(String ciphertext, Uint8List dek) {
    if (!isEncrypted(ciphertext)) {
      return ciphertext; // Return as-is if not encrypted
    }

    final encoded = ciphertext.substring(_encryptionMarker.length);
    final combined = base64.decode(encoded);

    final iv = Uint8List.sublistView(combined, 0, _ivLength);
    final encryptedData = Uint8List.sublistView(combined, _ivLength);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(dek),
          _tagLength * 8,
          iv,
          Uint8List(0),
        ),
      );

    final plaintext = Uint8List(encryptedData.length - _tagLength);
    final len =
        cipher.processBytes(encryptedData, 0, encryptedData.length, plaintext, 0);
    cipher.doFinal(plaintext, len);

    return utf8.decode(plaintext);
  }

  /// Encrypt a double value (for amounts)
  String encryptAmount(double amount, Uint8List dek) {
    return encryptField(amount.toString(), dek);
  }

  /// Decrypt a double value
  /// Returns the decrypted amount, or parses directly if not encrypted
  double decryptAmount(dynamic encryptedAmount, Uint8List dek) {
    if (encryptedAmount is num) {
      return encryptedAmount.toDouble(); // Legacy unencrypted data
    }
    if (encryptedAmount is String) {
      if (isEncrypted(encryptedAmount)) {
        final decrypted = decryptField(encryptedAmount, dek);
        return double.parse(decrypted);
      }
      return double.parse(encryptedAmount); // Unencrypted string number
    }
    throw ArgumentError('Invalid amount type: ${encryptedAmount.runtimeType}');
  }

  /// Check if a field is encrypted (starts with marker)
  bool isEncrypted(String value) {
    return value.startsWith(_encryptionMarker);
  }

  /// Generate recovery codes for password reset
  /// Returns list of 8 human-readable codes
  List<String> generateRecoveryCodes() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 0, 1
    final codes = <String>[];

    for (var i = 0; i < _recoveryCodeCount; i++) {
      final code = StringBuffer();
      for (var j = 0; j < _recoveryCodeLength; j++) {
        final randomByte = _secureRandom.nextBytes(1)[0];
        code.write(chars[randomByte % chars.length]);
      }
      // Format as XXXX-XXXX for readability
      final codeStr = code.toString();
      codes.add('${codeStr.substring(0, 4)}-${codeStr.substring(4)}');
    }

    return codes;
  }

  /// Hash a recovery code for storage (one-way)
  String hashRecoveryCode(String code) {
    // Remove formatting and normalize
    final normalized = code.replaceAll('-', '').toUpperCase();
    final bytes = utf8.encode(normalized);
    final digest = SHA256Digest().process(Uint8List.fromList(bytes));
    return base64.encode(digest);
  }

  /// Verify a recovery code against its hash
  bool verifyRecoveryCode(String code, String hash) {
    return hashRecoveryCode(code) == hash;
  }

  /// Wrap DEK with a recovery code (same algorithm as password)
  String wrapDEKWithRecoveryCode(Uint8List dek, String recoveryCode) {
    final normalized = recoveryCode.replaceAll('-', '').toUpperCase();
    return wrapDEK(dek, normalized);
  }

  /// Unwrap DEK with a recovery code
  Uint8List unwrapDEKWithRecoveryCode(String wrappedDEK, String recoveryCode) {
    final normalized = recoveryCode.replaceAll('-', '').toUpperCase();
    return unwrapDEK(wrappedDEK, normalized);
  }
}
