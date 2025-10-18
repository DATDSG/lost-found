import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PreferencesStorageService {
  static const String _keyLanguage = 'language';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyFilters = 'filters';
  static const String _keySearchHistory = 'search_history';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyLocationEnabled = 'location_enabled';
  static const String _keyAutoSync = 'auto_sync';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyUserPreferences = 'user_preferences';

  static PreferencesStorageService? _instance;
  static SharedPreferences? _prefs;

  PreferencesStorageService._();

  static Future<PreferencesStorageService> getInstance() async {
    _instance ??= PreferencesStorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Language preferences
  Future<String> getLanguage() async {
    return _prefs?.getString(_keyLanguage) ?? 'en';
  }

  Future<void> setLanguage(String languageCode) async {
    await _prefs?.setString(_keyLanguage, languageCode);
  }

  // Dark mode preferences
  Future<bool> getDarkMode() async {
    return _prefs?.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool enabled) async {
    await _prefs?.setBool(_keyDarkMode, enabled);
  }

  // Filter preferences
  Future<Map<String, dynamic>> getFilters() async {
    final filtersJson = _prefs?.getString(_keyFilters);
    if (filtersJson != null) {
      try {
        return Map<String, dynamic>.from(json.decode(filtersJson));
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  Future<void> setFilters(Map<String, dynamic> filters) async {
    await _prefs?.setString(_keyFilters, json.encode(filters));
  }

  Future<void> clearFilters() async {
    await _prefs?.remove(_keyFilters);
  }

  // Search history
  Future<List<String>> getSearchHistory() async {
    final historyJson = _prefs?.getStringList(_keySearchHistory) ?? [];
    return historyJson;
  }

  Future<void> addToSearchHistory(String query) async {
    final history = await getSearchHistory();
    if (query.isNotEmpty && !history.contains(query)) {
      history.insert(0, query);
      // Keep only last 20 searches
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }
      await _prefs?.setStringList(_keySearchHistory, history);
    }
  }

  Future<void> clearSearchHistory() async {
    await _prefs?.remove(_keySearchHistory);
  }

  // Notification preferences
  Future<bool> getNotificationsEnabled() async {
    return _prefs?.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyNotificationsEnabled, enabled);
  }

  // Location preferences
  Future<bool> getLocationEnabled() async {
    return _prefs?.getBool(_keyLocationEnabled) ?? true;
  }

  Future<void> setLocationEnabled(bool enabled) async {
    await _prefs?.setBool(_keyLocationEnabled, enabled);
  }

  // Auto sync preferences
  Future<bool> getAutoSync() async {
    return _prefs?.getBool(_keyAutoSync) ?? true;
  }

  Future<void> setAutoSync(bool enabled) async {
    await _prefs?.setBool(_keyAutoSync, enabled);
  }

  // Last sync time
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = _prefs?.getInt(_keyLastSyncTime);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await _prefs?.setInt(_keyLastSyncTime, time.millisecondsSinceEpoch);
  }

  // User preferences (general settings)
  Future<Map<String, dynamic>> getUserPreferences() async {
    final preferencesJson = _prefs?.getString(_keyUserPreferences);
    if (preferencesJson != null) {
      try {
        return Map<String, dynamic>.from(json.decode(preferencesJson));
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  Future<void> setUserPreferences(Map<String, dynamic> preferences) async {
    await _prefs?.setString(_keyUserPreferences, json.encode(preferences));
  }

  Future<void> updateUserPreference(String key, dynamic value) async {
    final preferences = await getUserPreferences();
    preferences[key] = value;
    await setUserPreferences(preferences);
  }

  // Clear all preferences
  Future<void> clearAllPreferences() async {
    await _prefs?.clear();
  }

  // Clear user-specific preferences (keep app settings)
  Future<void> clearUserPreferences() async {
    await _prefs?.remove(_keyFilters);
    await _prefs?.remove(_keySearchHistory);
    await _prefs?.remove(_keyUserPreferences);
    await _prefs?.remove(_keyLastSyncTime);
  }

  // Export preferences
  Future<Map<String, dynamic>> exportPreferences() async {
    return {
      'language': await getLanguage(),
      'darkMode': await getDarkMode(),
      'filters': await getFilters(),
      'searchHistory': await getSearchHistory(),
      'notificationsEnabled': await getNotificationsEnabled(),
      'locationEnabled': await getLocationEnabled(),
      'autoSync': await getAutoSync(),
      'lastSyncTime': await getLastSyncTime(),
      'userPreferences': await getUserPreferences(),
    };
  }

  // Import preferences
  Future<void> importPreferences(Map<String, dynamic> preferences) async {
    if (preferences.containsKey('language')) {
      await setLanguage(preferences['language']);
    }
    if (preferences.containsKey('darkMode')) {
      await setDarkMode(preferences['darkMode']);
    }
    if (preferences.containsKey('filters')) {
      await setFilters(preferences['filters']);
    }
    if (preferences.containsKey('searchHistory')) {
      await _prefs?.setStringList(
          _keySearchHistory, List<String>.from(preferences['searchHistory']));
    }
    if (preferences.containsKey('notificationsEnabled')) {
      await setNotificationsEnabled(preferences['notificationsEnabled']);
    }
    if (preferences.containsKey('locationEnabled')) {
      await setLocationEnabled(preferences['locationEnabled']);
    }
    if (preferences.containsKey('autoSync')) {
      await setAutoSync(preferences['autoSync']);
    }
    if (preferences.containsKey('lastSyncTime')) {
      final timestamp = preferences['lastSyncTime'];
      if (timestamp != null) {
        await setLastSyncTime(DateTime.fromMillisecondsSinceEpoch(timestamp));
      }
    }
    if (preferences.containsKey('userPreferences')) {
      await setUserPreferences(preferences['userPreferences']);
    }
  }
}
