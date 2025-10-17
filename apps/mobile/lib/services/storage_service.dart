import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/auth_token.dart';
import '../models/user.dart';
import 'cache_service.dart';

/// Enhanced Local Storage Service with caching support
class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _settingsKey = 'app_settings';
  static const String _preferencesKey = 'user_preferences';

  final CacheService _cacheService = CacheService();

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Initialize storage service
  Future<void> initialize() async {
    await _cacheService.initialize();
  }

  Future<void> saveToken(AuthToken token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, jsonEncode(token.toJson()));
  }

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  /// Get access token
  String? getAccessToken() {
    // Note: This is synchronous for compatibility, but SharedPreferences is async
    // In a real implementation, you'd need to handle this differently
    return null; // Placeholder - would need async implementation
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', token);
  }

  /// Get refresh token
  String? getRefreshToken() {
    // Note: This is synchronous for compatibility, but SharedPreferences is async
    // In a real implementation, you'd need to handle this differently
    return null; // Placeholder - would need async implementation
  }

  /// Clear authentication tokens
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove(_tokenKey);
  }

  Future<AuthToken?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenStr = prefs.getString(_tokenKey);
    if (tokenStr != null) {
      return AuthToken.fromJson(jsonDecode(tokenStr));
    }
    return null;
  }

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return User.fromJson(jsonDecode(userStr));
    }
    return null;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_settingsKey);
    await prefs.remove(_preferencesKey);

    // Clear cache as well
    await _cacheService.clear();
  }

  // ========== Enhanced Storage Methods ==========

  /// Save app settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));

    // Also cache for quick access
    await _cacheService.store(
      'app_settings',
      settings,
      tag: 'settings',
      expiry: const Duration(days: 30),
    );
  }

  /// Get app settings
  Future<Map<String, dynamic>?> getSettings() async {
    // Try cache first
    final cachedSettings = await _cacheService.retrieve<Map<String, dynamic>>(
      'app_settings',
    );
    if (cachedSettings != null) {
      return cachedSettings;
    }

    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final settingsStr = prefs.getString(_settingsKey);
    if (settingsStr != null) {
      final settings = jsonDecode(settingsStr) as Map<String, dynamic>;

      // Cache for next time
      await _cacheService.store(
        'app_settings',
        settings,
        tag: 'settings',
        expiry: const Duration(days: 30),
      );

      return settings;
    }
    return null;
  }

  /// Save user preferences
  Future<void> savePreferences(Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferencesKey, jsonEncode(preferences));

    // Also cache for quick access
    await _cacheService.store(
      'user_preferences',
      preferences,
      tag: 'preferences',
      expiry: const Duration(days: 7),
    );
  }

  /// Get user preferences
  Future<Map<String, dynamic>?> getPreferences() async {
    // Try cache first
    final cachedPreferences = await _cacheService
        .retrieve<Map<String, dynamic>>('user_preferences');
    if (cachedPreferences != null) {
      return cachedPreferences;
    }

    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final preferencesStr = prefs.getString(_preferencesKey);
    if (preferencesStr != null) {
      final preferences = jsonDecode(preferencesStr) as Map<String, dynamic>;

      // Cache for next time
      await _cacheService.store(
        'user_preferences',
        preferences,
        tag: 'preferences',
        expiry: const Duration(days: 7),
      );

      return preferences;
    }
    return null;
  }

  /// Save any data with caching
  Future<void> saveData(
    String key,
    dynamic data, {
    Duration? expiry,
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    await _cacheService.store(
      key,
      data,
      expiry: expiry,
      tag: tag,
      metadata: metadata,
    );
  }

  /// Get any cached data
  Future<T?> getData<T>(String key) async {
    return await _cacheService.retrieve<T>(key);
  }

  /// Check if data exists in cache
  Future<bool> hasData(String key) async {
    return await _cacheService.exists(key);
  }

  /// Remove specific data
  Future<void> removeData(String key) async {
    await _cacheService.remove(key);
  }

  /// Clear data by tag
  Future<void> clearDataByTag(String tag) async {
    await _cacheService.removeByTag(tag);
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final cacheStats = await _cacheService.getStats();

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    return {
      'cache_stats': cacheStats,
      'shared_preferences_keys': keys.length,
      'shared_preferences_keys_list': keys.toList(),
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _cacheService.close();
  }
}
