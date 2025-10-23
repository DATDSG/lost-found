import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache service for offline support and data persistence
class CacheService {
  /// Factory constructor for singleton instance
  factory CacheService() => _instance;

  /// Private constructor for singleton pattern
  CacheService._internal();

  static final CacheService _instance = CacheService._internal();

  /// Cache duration for different data types
  static const Duration _userDataCacheDuration = Duration(hours: 1);
  static const Duration _reportsCacheDuration = Duration(minutes: 30);
  static const Duration _categoriesCacheDuration = Duration(hours: 24);
  static const Duration _colorsCacheDuration = Duration(hours: 24);

  /// Cache keys
  static const String _userDataKey = 'user_data';
  static const String _reportsKey = 'reports';
  static const String _activeReportsKey = 'active_reports';
  static const String _draftReportsKey = 'draft_reports';
  static const String _resolvedReportsKey = 'resolved_reports';
  static const String _categoriesKey = 'categories';
  static const String _colorsKey = 'colors';
  static const String _matchesKey = 'matches';

  /// Get cached data with expiration check
  Future<Map<String, dynamic>?> getCachedData(
    String key,
    Duration cacheDuration,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(key);

      if (cachedData == null) {
        return null;
      }

      final data = json.decode(cachedData) as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int?;

      if (timestamp == null) {
        return null;
      }

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      if (now.difference(cacheTime) > cacheDuration) {
        // Cache expired, remove it
        await prefs.remove(key);
        return null;
      }

      return data['data'] as Map<String, dynamic>?;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error getting cached data for key $key: $e');
      }
      return null;
    }
  }

  /// Cache data with timestamp
  Future<void> setCachedData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(key, json.encode(cacheData));
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error setting cached data for key $key: $e');
      }
    }
  }

  /// Get cached list data with expiration check
  Future<List<Map<String, dynamic>>?> getCachedListData(
    String key,
    Duration cacheDuration,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(key);

      if (cachedData == null) {
        return null;
      }

      final data = json.decode(cachedData) as Map<String, dynamic>;
      final timestamp = data['timestamp'] as int?;

      if (timestamp == null) {
        return null;
      }

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      if (now.difference(cacheTime) > cacheDuration) {
        // Cache expired, remove it
        await prefs.remove(key);
        return null;
      }

      final listData = data['data'] as List<dynamic>?;
      return listData?.cast<Map<String, dynamic>>();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error getting cached list data for key $key: $e');
      }
      return null;
    }
  }

  /// Cache list data with timestamp
  Future<void> setCachedListData(
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(key, json.encode(cacheData));
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error setting cached list data for key $key: $e');
      }
    }
  }

  /// Clear specific cache entry
  Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error clearing cache for key $key: $e');
      }
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove(_reportsKey);
      await prefs.remove(_activeReportsKey);
      await prefs.remove(_draftReportsKey);
      await prefs.remove(_resolvedReportsKey);
      await prefs.remove(_categoriesKey);
      await prefs.remove(_colorsKey);
      await prefs.remove(_matchesKey);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error clearing all cache: $e');
      }
    }
  }

  // User data cache methods

  /// Get cached user data
  Future<Map<String, dynamic>?> getCachedUserData() async =>
      getCachedData(_userDataKey, _userDataCacheDuration);

  /// Cache user data
  Future<void> setCachedUserData(Map<String, dynamic> userData) async =>
      setCachedData(_userDataKey, userData);

  // Reports cache methods

  /// Get cached reports
  Future<List<Map<String, dynamic>>?> getCachedReports() async =>
      getCachedListData(_reportsKey, _reportsCacheDuration);

  /// Cache reports
  Future<void> setCachedReports(List<Map<String, dynamic>> reports) async =>
      setCachedListData(_reportsKey, reports);

  /// Get cached active reports
  Future<List<Map<String, dynamic>>?> getCachedActiveReports() async =>
      getCachedListData(_activeReportsKey, _reportsCacheDuration);

  /// Cache active reports
  Future<void> setCachedActiveReports(
    List<Map<String, dynamic>> reports,
  ) async {
    await setCachedListData(_activeReportsKey, reports);
  }

  /// Get cached draft reports
  Future<List<Map<String, dynamic>>?> getCachedDraftReports() async =>
      getCachedListData(_draftReportsKey, _reportsCacheDuration);

  /// Cache draft reports
  Future<void> setCachedDraftReports(
    List<Map<String, dynamic>> reports,
  ) async => setCachedListData(_draftReportsKey, reports);

  /// Get cached resolved reports
  Future<List<Map<String, dynamic>>?> getCachedResolvedReports() async =>
      getCachedListData(_resolvedReportsKey, _reportsCacheDuration);

  /// Cache resolved reports
  Future<void> setCachedResolvedReports(
    List<Map<String, dynamic>> reports,
  ) async {
    await setCachedListData(_resolvedReportsKey, reports);
  }

  // Categories and colors cache methods

  /// Get cached categories
  Future<List<Map<String, dynamic>>?> getCachedCategories() async =>
      getCachedListData(_categoriesKey, _categoriesCacheDuration);

  /// Cache categories
  Future<void> setCachedCategories(
    List<Map<String, dynamic>> categories,
  ) async {
    await setCachedListData(_categoriesKey, categories);
  }

  /// Get cached colors
  Future<List<Map<String, dynamic>>?> getCachedColors() async =>
      getCachedListData(_colorsKey, _colorsCacheDuration);

  /// Cache colors
  Future<void> setCachedColors(List<Map<String, dynamic>> colors) async =>
      setCachedListData(_colorsKey, colors);

  // Matches cache methods

  /// Get cached matches
  Future<List<Map<String, dynamic>>?> getCachedMatches() async =>
      getCachedListData(_matchesKey, _reportsCacheDuration);

  /// Cache matches
  Future<void> setCachedMatches(List<Map<String, dynamic>> matches) async =>
      setCachedListData(_matchesKey, matches);

  /// Clear user-related cache
  Future<void> clearUserCache() async {
    await clearCache(_userDataKey);
    await clearCache(_activeReportsKey);
    await clearCache(_draftReportsKey);
    await clearCache(_resolvedReportsKey);
    await clearCache(_matchesKey);
  }

  /// Clear reports cache
  Future<void> clearReportsCache() async {
    await clearCache(_reportsKey);
    await clearCache(_activeReportsKey);
    await clearCache(_draftReportsKey);
    await clearCache(_resolvedReportsKey);
  }
}
