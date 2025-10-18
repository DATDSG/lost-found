import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/auth_token.dart';

/// Simple storage service for tokens
class StorageService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  /// Save authentication token
  Future<void> saveToken(AuthToken token) async {
    await _storage.write(key: _tokenKey, value: jsonEncode(token.toJson()));
  }

  /// Get authentication token
  Future<AuthToken?> getToken() async {
    final tokenJson = await _storage.read(key: _tokenKey);
    if (tokenJson != null) {
      try {
        return AuthToken.fromJson(jsonDecode(tokenJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Delete authentication token
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Clear all tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Delete user ID
  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
