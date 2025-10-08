import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app preferences using shared_preferences
class PreferencesService {
  static const String _keyLanguage = 'app_language';
  static const String _keyFilterType = 'filter_type';
  static const String _keyFilterTime = 'filter_time';
  static const String _keyFilterDistance = 'filter_distance';
  static const String _keyFilterCategory = 'filter_category';
  static const String _keyFilterLocation = 'filter_location';
  static const String _keyLastLatitude = 'last_latitude';
  static const String _keyLastLongitude = 'last_longitude';

  late SharedPreferences _prefs;

  /// Initialize the preferences service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ Language Preferences ============

  /// Get saved language code (e.g., 'en', 'es', 'fr')
  String getLanguage() {
    return _prefs.getString(_keyLanguage) ?? 'en';
  }

  /// Save language preference
  Future<bool> setLanguage(String languageCode) async {
    return await _prefs.setString(_keyLanguage, languageCode);
  }

  // ============ Filter Preferences ============

  /// Get saved filter type ('lost' or 'found')
  String? getFilterType() {
    return _prefs.getString(_keyFilterType);
  }

  /// Save filter type
  Future<bool> setFilterType(String? type) async {
    if (type == null) {
      return await _prefs.remove(_keyFilterType);
    }
    return await _prefs.setString(_keyFilterType, type);
  }

  /// Get saved time filter
  String? getFilterTime() {
    return _prefs.getString(_keyFilterTime);
  }

  /// Save time filter
  Future<bool> setFilterTime(String? time) async {
    if (time == null) {
      return await _prefs.remove(_keyFilterTime);
    }
    return await _prefs.setString(_keyFilterTime, time);
  }

  /// Get saved distance filter
  String? getFilterDistance() {
    return _prefs.getString(_keyFilterDistance);
  }

  /// Save distance filter
  Future<bool> setFilterDistance(String? distance) async {
    if (distance == null) {
      return await _prefs.remove(_keyFilterDistance);
    }
    return await _prefs.setString(_keyFilterDistance, distance);
  }

  /// Get saved category filter
  String? getFilterCategory() {
    return _prefs.getString(_keyFilterCategory);
  }

  /// Save category filter
  Future<bool> setFilterCategory(String? category) async {
    if (category == null) {
      return await _prefs.remove(_keyFilterCategory);
    }
    return await _prefs.setString(_keyFilterCategory, category);
  }

  /// Get saved location filter
  String? getFilterLocation() {
    return _prefs.getString(_keyFilterLocation);
  }

  /// Save location filter
  Future<bool> setFilterLocation(String? location) async {
    if (location == null) {
      return await _prefs.remove(_keyFilterLocation);
    }
    return await _prefs.setString(_keyFilterLocation, location);
  }

  /// Get all filter preferences as a map
  Map<String, String?> getAllFilters() {
    return {
      'type': getFilterType(),
      'time': getFilterTime(),
      'distance': getFilterDistance(),
      'category': getFilterCategory(),
      'location': getFilterLocation(),
    };
  }

  /// Save all filter preferences
  Future<void> saveAllFilters(Map<String, String?> filters) async {
    await setFilterType(filters['type']);
    await setFilterTime(filters['time']);
    await setFilterDistance(filters['distance']);
    await setFilterCategory(filters['category']);
    await setFilterLocation(filters['location']);
  }

  /// Clear all filter preferences
  Future<void> clearAllFilters() async {
    await _prefs.remove(_keyFilterType);
    await _prefs.remove(_keyFilterTime);
    await _prefs.remove(_keyFilterDistance);
    await _prefs.remove(_keyFilterCategory);
    await _prefs.remove(_keyFilterLocation);
  }

  // ============ Location Preferences ============

  /// Get last known latitude
  double? getLastLatitude() {
    return _prefs.getDouble(_keyLastLatitude);
  }

  /// Save last known latitude
  Future<bool> setLastLatitude(double? latitude) async {
    if (latitude == null) {
      return await _prefs.remove(_keyLastLatitude);
    }
    return await _prefs.setDouble(_keyLastLatitude, latitude);
  }

  /// Get last known longitude
  double? getLastLongitude() {
    return _prefs.getDouble(_keyLastLongitude);
  }

  /// Save last known longitude
  Future<bool> setLastLongitude(double? longitude) async {
    if (longitude == null) {
      return await _prefs.remove(_keyLastLongitude);
    }
    return await _prefs.setDouble(_keyLastLongitude, longitude);
  }

  /// Get last known location as map
  Map<String, double>? getLastLocation() {
    final lat = getLastLatitude();
    final lon = getLastLongitude();
    if (lat != null && lon != null) {
      return {'latitude': lat, 'longitude': lon};
    }
    return null;
  }

  /// Save last known location
  Future<void> setLastLocation(double latitude, double longitude) async {
    await setLastLatitude(latitude);
    await setLastLongitude(longitude);
  }

  // ============ Utility Methods ============

  /// Clear all preferences
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
