import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/location_models.dart';
import '../services/api_service.dart';
import '../core/error/error_handler.dart';
import '../core/error/api_error_handler.dart';

/// Location service state enum
enum LocationState {
  initial,
  loading,
  loaded,
  error,
  geocoding,
  reverseGeocoding,
  searching,
  saving,
  updating,
  deleting,
}

/// Comprehensive Location Provider
class LocationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State management
  LocationState _state = LocationState.initial;
  String? _error;

  // Current location
  LocationData? _currentLocation;

  // Location history
  List<LocationHistoryEntry> _locationHistory = [];
  bool _hasMoreHistory = true;
  int _historyCurrentPage = 1;
  static const int _historyPageSize = 20;

  // Search results
  List<LocationSearchResult> _searchResults = [];
  List<LocationSuggestion> _autocompleteSuggestions = [];
  String? _lastSearchQuery;

  // Nearby locations
  List<LocationSearchResult> _nearbyLocations = [];

  // Statistics
  LocationStats? _locationStats;

  // Distance calculations
  Map<String, DistanceResult> _distanceCache = {};

  // Location bounds
  LocationBounds? _currentBounds;

  // Getters
  LocationState get state => _state;
  String? get error => _error;
  LocationData? get currentLocation => _currentLocation;
  List<LocationHistoryEntry> get locationHistory => _locationHistory;
  List<LocationSearchResult> get searchResults => _searchResults;
  List<LocationSuggestion> get autocompleteSuggestions =>
      _autocompleteSuggestions;
  String? get lastSearchQuery => _lastSearchQuery;
  List<LocationSearchResult> get nearbyLocations => _nearbyLocations;
  LocationStats? get locationStats => _locationStats;
  LocationBounds? get currentBounds => _currentBounds;

  bool get isLoading => _state == LocationState.loading;
  bool get isGeocoding => _state == LocationState.geocoding;
  bool get isReverseGeocoding => _state == LocationState.reverseGeocoding;
  bool get isSearching => _state == LocationState.searching;
  bool get isSaving => _state == LocationState.saving;
  bool get isUpdating => _state == LocationState.updating;
  bool get isDeleting => _state == LocationState.deleting;
  bool get hasError => _state == LocationState.error;
  bool get isLoaded => _state == LocationState.loaded;

  bool get hasMoreHistory => _hasMoreHistory;
  bool get hasCurrentLocation => _currentLocation != null;
  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get hasAutocompleteSuggestions => _autocompleteSuggestions.isNotEmpty;
  bool get hasNearbyLocations => _nearbyLocations.isNotEmpty;

  /// Initialize location provider
  Future<void> initialize() async {
    _state = LocationState.loading;
    _error = null;
    notifyListeners();

    try {
      // Load current location and stats in parallel
      await Future.wait([loadCurrentLocation(), loadLocationStats()]);

      _state = LocationState.loaded;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Initialize location');
      _state = LocationState.error;
      notifyListeners();
    }
  }

  /// Load current user's location
  Future<void> loadCurrentLocation() async {
    try {
      final locationData = await _apiService.getCurrentLocation();
      if (locationData != null) {
        _currentLocation = LocationData.fromJson(locationData);
      }
      notifyListeners();
    } catch (e) {
      final error = ApiErrorHandler.handleApiError(
        e,
        context: 'Load current location',
      );
      debugPrint('Error loading current location: $error');
      ApiErrorHandler.logError(e, context: 'Load current location');

      // Don't set global error for location loading failures
      // as it's not critical for app functionality
    }
  }

  /// Update current location
  Future<bool> updateCurrentLocation({
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? country,
  }) async {
    _state = LocationState.updating;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateCurrentLocation(
        latitude: latitude,
        longitude: longitude,
        address: address,
        city: city,
        country: country,
      );

      _currentLocation = LocationData(
        latitude: latitude,
        longitude: longitude,
        address: address,
        city: city,
        country: country,
        timestamp: DateTime.now(),
      );

      _state = LocationState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Update current location');
      _state = LocationState.error;
      notifyListeners();
      return false;
    }
  }

  /// Geocode an address to coordinates
  Future<LocationData?> geocodeAddress(String address) async {
    _state = LocationState.geocoding;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.geocodeAddress(address);
      final location = LocationData.fromJson(result);

      _state = LocationState.loaded;
      notifyListeners();
      return location;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Geocode address');
      _state = LocationState.error;
      notifyListeners();
      return null;
    }
  }

  /// Reverse geocode coordinates to address
  Future<LocationData?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    _state = LocationState.reverseGeocoding;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );
      final location = LocationData.fromJson(result);

      _state = LocationState.loaded;
      notifyListeners();
      return location;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Reverse geocode');
      _state = LocationState.error;
      notifyListeners();
      return null;
    }
  }

  /// Search for locations
  Future<void> searchLocations({
    required String query,
    String? country,
    String? city,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 10,
  }) async {
    _state = LocationState.searching;
    _error = null;
    _lastSearchQuery = query;
    notifyListeners();

    try {
      final results = await _apiService.searchLocations(
        query: query,
        country: country,
        city: city,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );

      _searchResults = results
          .map((json) => LocationSearchResult.fromJson(json))
          .toList();

      _state = LocationState.loaded;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Search locations');
      _state = LocationState.error;
      notifyListeners();
    }
  }

  /// Get location autocomplete suggestions
  Future<void> getLocationAutocomplete({
    required String query,
    String? country,
    String? city,
    int limit = 5,
  }) async {
    try {
      final suggestions = await _apiService.getLocationAutocomplete(
        query: query,
        country: country,
        city: city,
        limit: limit,
      );

      _autocompleteSuggestions = suggestions
          .map((json) => LocationSuggestion.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error getting autocomplete suggestions: $e');
    }
  }

  /// Get nearby locations
  Future<void> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? type,
    int limit = 20,
  }) async {
    try {
      final results = await _apiService.getNearbyLocations(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        type: type,
        limit: limit,
      );

      _nearbyLocations = results
          .map((json) => LocationSearchResult.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error getting nearby locations: $e');
    }
  }

  /// Get detailed location information
  Future<LocationSearchResult?> getLocationDetails(String placeId) async {
    try {
      final result = await _apiService.getLocationDetails(placeId);
      return LocationSearchResult.fromJson(result);
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Get location details');
      notifyListeners();
      return null;
    }
  }

  /// Calculate distance between two points
  Future<DistanceResult?> calculateDistance({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
    String unit = 'km',
    bool useCache = true,
  }) async {
    final cacheKey =
        '${fromLatitude}_${fromLongitude}_${toLatitude}_${toLongitude}_$unit';

    if (useCache && _distanceCache.containsKey(cacheKey)) {
      return _distanceCache[cacheKey];
    }

    try {
      final result = await _apiService.calculateDistance(
        fromLatitude: fromLatitude,
        fromLongitude: fromLongitude,
        toLatitude: toLatitude,
        toLongitude: toLongitude,
        unit: unit,
      );

      final distanceResult = DistanceResult.fromJson(result);
      _distanceCache[cacheKey] = distanceResult;

      return distanceResult;
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return null;
    }
  }

  /// Get location bounds for a region
  Future<LocationBounds?> getLocationBounds({
    required String query,
    String? country,
  }) async {
    try {
      final result = await _apiService.getLocationBounds(
        query: query,
        country: country,
      );

      _currentBounds = LocationBounds.fromJson(result);
      notifyListeners();
      return _currentBounds;
    } catch (e) {
      debugPrint('Error getting location bounds: $e');
      return null;
    }
  }

  /// Validate location coordinates
  Future<bool> validateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      return await _apiService.validateLocation(
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      debugPrint('Error validating location: $e');
      return false;
    }
  }

  /// Load location history
  Future<void> loadLocationHistory({
    bool loadMore = false,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (loadMore) {
      _historyCurrentPage++;
    } else {
      _historyCurrentPage = 1;
      _locationHistory.clear();
      _hasMoreHistory = true;
    }

    if (!_hasMoreHistory) return;

    try {
      final historyData = await _apiService.getLocationHistory(
        page: _historyCurrentPage,
        pageSize: _historyPageSize,
        startDate: startDate,
        endDate: endDate,
      );

      final entries = historyData
          .map((json) => LocationHistoryEntry.fromJson(json))
          .toList();

      if (loadMore) {
        _locationHistory.addAll(entries);
      } else {
        _locationHistory = entries;
      }

      _hasMoreHistory = entries.length == _historyPageSize;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading location history: $e');
      if (loadMore) {
        _historyCurrentPage--; // Revert page increment on error
      }
    }
  }

  /// Save location to history
  Future<bool> saveLocationToHistory({
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? country,
    Map<String, dynamic>? metadata,
  }) async {
    _state = LocationState.saving;
    _error = null;
    notifyListeners();

    try {
      await _apiService.saveLocationToHistory(
        latitude: latitude,
        longitude: longitude,
        address: address,
        city: city,
        country: country,
        metadata: metadata,
      );

      // Add to local history
      final entry = LocationHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        location: LocationData(
          latitude: latitude,
          longitude: longitude,
          address: address,
          city: city,
          country: country,
          metadata: metadata,
          timestamp: DateTime.now(),
        ),
        timestamp: DateTime.now(),
      );

      _locationHistory.insert(0, entry);

      _state = LocationState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Save location');
      _state = LocationState.error;
      notifyListeners();
      return false;
    }
  }

  /// Clear location history
  Future<bool> clearLocationHistory() async {
    _state = LocationState.deleting;
    _error = null;
    notifyListeners();

    try {
      await _apiService.clearLocationHistory();

      _locationHistory.clear();
      _hasMoreHistory = true;
      _historyCurrentPage = 1;

      _state = LocationState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Clear location history');
      _state = LocationState.error;
      notifyListeners();
      return false;
    }
  }

  /// Load location statistics
  Future<void> loadLocationStats() async {
    try {
      final statsData = await _apiService.getLocationStats();
      _locationStats = LocationStats.fromJson(statsData);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading location stats: $e');
    }
  }

  /// Load more location history
  Future<void> loadMoreHistory() async {
    if (!_hasMoreHistory || isLoading) return;
    await loadLocationHistory(loadMore: true);
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults.clear();
    _lastSearchQuery = null;
    notifyListeners();
  }

  /// Clear autocomplete suggestions
  void clearAutocompleteSuggestions() {
    _autocompleteSuggestions.clear();
    notifyListeners();
  }

  /// Clear nearby locations
  void clearNearbyLocations() {
    _nearbyLocations.clear();
    notifyListeners();
  }

  /// Clear distance cache
  void clearDistanceCache() {
    _distanceCache.clear();
  }

  /// Refresh all location data
  Future<void> refresh() async {
    await initialize();
  }

  /// Clear all location data
  void clearAllData() {
    _currentLocation = null;
    _locationHistory.clear();
    _searchResults.clear();
    _autocompleteSuggestions.clear();
    _nearbyLocations.clear();
    _locationStats = null;
    _distanceCache.clear();
    _currentBounds = null;
    _lastSearchQuery = null;
    _hasMoreHistory = true;
    _historyCurrentPage = 1;
    _state = LocationState.initial;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    if (_state == LocationState.error) {
      _state = LocationState.initial;
    }
    notifyListeners();
  }

  /// Get distance from current location to target
  Future<DistanceResult?> getDistanceToLocation(LocationData target) async {
    if (_currentLocation == null) return null;

    return await calculateDistance(
      fromLatitude: _currentLocation!.latitude,
      fromLongitude: _currentLocation!.longitude,
      toLatitude: target.latitude,
      toLongitude: target.longitude,
    );
  }

  /// Check if location is within current bounds
  bool isLocationInBounds(LocationData location) {
    if (_currentBounds == null) return true;
    return _currentBounds!.contains(location);
  }

  /// Get formatted distance string
  String getFormattedDistance(LocationData from, LocationData to) {
    final distance = _calculateHaversineDistance(from, to);
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  /// Calculate haversine distance between two points (in km)
  double _calculateHaversineDistance(LocationData from, LocationData to) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double lat1Rad = from.latitude * (math.pi / 180);
    final double lat2Rad = to.latitude * (math.pi / 180);
    final double deltaLatRad = (to.latitude - from.latitude) * (math.pi / 180);
    final double deltaLngRad =
        (to.longitude - from.longitude) * (math.pi / 180);

    final double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get most visited cities
  List<MapEntry<String, int>> getMostVisitedCities({int limit = 5}) {
    if (_locationStats == null) return [];
    return _locationStats!.cityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(limit);
  }

  /// Get most visited countries
  List<MapEntry<String, int>> getMostVisitedCountries({int limit = 5}) {
    if (_locationStats == null) return [];
    return _locationStats!.countryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(limit);
  }

  /// Get recent locations
  List<LocationHistoryEntry> getRecentLocations({int limit = 10}) {
    return _locationHistory.take(limit).toList();
  }

  /// Get locations by date range
  List<LocationHistoryEntry> getLocationsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _locationHistory
        .where(
          (entry) =>
              entry.timestamp.isAfter(startDate) &&
              entry.timestamp.isBefore(endDate),
        )
        .toList();
  }
}
