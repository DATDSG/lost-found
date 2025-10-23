import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Simple encryption utility for storing sensitive data
class EncryptionUtils {
  /// Private constructor to prevent instantiation
  EncryptionUtils._();

  /// Simple encryption key (in production, this should be more secure)
  static const String _encryptionKey = 'lost_found_app_key_2024';

  /// Encrypt a string using simple XOR encryption
  static String encrypt(String plainText) {
    if (plainText.isEmpty) {
      return plainText;
    }

    final keyBytes = utf8.encode(_encryptionKey);
    final textBytes = utf8.encode(plainText);
    final encrypted = <int>[];

    for (int i = 0; i < textBytes.length; i++) {
      encrypted.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64.encode(encrypted);
  }

  /// Decrypt a string using simple XOR decryption
  static String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) {
      return encryptedText;
    }

    try {
      final keyBytes = utf8.encode(_encryptionKey);
      final encryptedBytes = base64.decode(encryptedText);
      final decrypted = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } on Exception {
      return encryptedText; // Return original if decryption fails
    }
  }

  /// Hash a password for secure storage (one-way)
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a password against its hash
  static bool verifyPassword(String password, String hash) =>
      hashPassword(password) == hash;
}
