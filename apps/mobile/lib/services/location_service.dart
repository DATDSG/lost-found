import 'package:geolocator/geolocator.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  LocationService._();

  Position? _currentPosition;
  bool _isLocationEnabled = false;

  Position? get currentPosition => _currentPosition;
  bool get isLocationEnabled => _isLocationEnabled;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permissions
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permissions
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position with high accuracy
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLocationEnabled = false;
        return null;
      }

      // Check location permissions
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          _isLocationEnabled = false;
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isLocationEnabled = false;
        return null;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout,
      );

      _isLocationEnabled = true;
      return _currentPosition;
    } catch (e) {
      _isLocationEnabled = false;
      return null;
    }
  }

  /// Calculate distance between two coordinates
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculate distance from current position to target coordinates
  Future<double?> calculateDistanceToTarget(double lat, double lon) async {
    if (_currentPosition == null) {
      await getCurrentPosition();
    }

    if (_currentPosition != null) {
      return calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lon,
      );
    }

    return null;
  }

  /// Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get formatted distance from current position to target
  Future<String?> getFormattedDistanceToTarget(double lat, double lon) async {
    final distance = await calculateDistanceToTarget(lat, lon);
    if (distance != null) {
      return formatDistance(distance);
    }
    return null;
  }

  /// Check if location permission is permanently denied
  Future<bool> isLocationPermissionPermanentlyDenied() async {
    final permission = await checkLocationPermission();
    return permission == LocationPermission.deniedForever;
  }

  /// Open app settings for location permissions
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings for location permissions
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Get location permission status
  Future<LocationPermissionStatus> getLocationPermissionStatus() async {
    final permission = await checkLocationPermission();

    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.always:
        return LocationPermissionStatus.always;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unableToDetermine;
    }
  }

  /// Request location permission with proper handling
  Future<bool> requestLocationPermissionWithHandling() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Check current permission status
      LocationPermission permission = await checkLocationPermission();

      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get location with permission handling
  Future<Position?> getLocationWithPermissionHandling() async {
    final hasPermission = await requestLocationPermissionWithHandling();
    if (hasPermission) {
      return await getCurrentPosition();
    }
    return null;
  }

  /// Start listening to location updates
  Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Stop listening to location updates
  void stopLocationStream() {
    // Stream will automatically stop when disposed
  }
}

enum LocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
  unableToDetermine,
}
