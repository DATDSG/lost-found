import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Service for handling location operations
class LocationService {
  /// Factory constructor for singleton instance
  factory LocationService() => _instance;

  /// Private constructor for singleton pattern
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();

  /// Current position cache
  Position? _currentPosition;
  DateTime? _lastPositionUpdate;

  /// Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error checking location service: $e');
      }
      return false;
    }
  }

  /// Check location permissions
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error checking permission: $e');
      }
      return LocationPermission.denied;
    }
  }

  /// Request location permissions
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error requesting permission: $e');
      }
      return LocationPermission.denied;
    }
  }

  /// Get current position with caching and improved accuracy
  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    try {
      // Check if we have a cached position that's still valid
      if (!forceRefresh &&
          _currentPosition != null &&
          _lastPositionUpdate != null &&
          DateTime.now().difference(_lastPositionUpdate!) < _cacheDuration) {
        return _currentPosition;
      }

      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('Location services are disabled');
        }
        return null;
      }

      // Check permissions
      var permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('Location permissions are denied');
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('Location permissions are permanently denied');
        }
        return null;
      }

      // Get current position with improved accuracy settings
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 15),
      );

      // Cache the position
      _currentPosition = position;
      _lastPositionUpdate = DateTime.now();

      if (kDebugMode) {
        print(
          'Location obtained: Lat: ${position.latitude}, Lng: ${position.longitude}, Accuracy: ${position.accuracy}m',
        );
      }

      return position;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error getting current position: $e');
      }
      return null;
    }
  }

  /// Get latitude and longitude coordinates
  Future<({double? latitude, double? longitude})> getCoordinates({
    bool forceRefresh = false,
  }) async {
    final position = await getCurrentPosition(forceRefresh: forceRefresh);
    if (position != null) {
      return (latitude: position.latitude, longitude: position.longitude);
    }
    return (latitude: null, longitude: null);
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final addressParts = <String>[];

        if (placemark.street != null && placemark.street!.isNotEmpty) {
          addressParts.add(placemark.street!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          addressParts.add(placemark.locality!);
        }
        if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          addressParts.add(placemark.administrativeArea!);
        }
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          addressParts.add(placemark.country!);
        }

        return addressParts.isNotEmpty ? addressParts.join(', ') : null;
      }
      return null;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error getting address from coordinates: $e');
      }
      // Fallback to coordinates if reverse geocoding fails
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    }
  }

  /// Calculate distance between two coordinates
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) => Geolocator.distanceBetween(
    startLatitude,
    startLongitude,
    endLatitude,
    endLongitude,
  );

  /// Format distance in a human-readable format
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      final kilometers = distanceInMeters / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    }
  }

  /// Clear cached position
  void clearCache() {
    _currentPosition = null;
    _lastPositionUpdate = null;
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final permission = await checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get permission status message
  String getPermissionStatusMessage(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Location permission is denied. Please enable it in settings.';
      case LocationPermission.deniedForever:
        return 'Location permission is permanently denied. Please enable it in app settings.';
      case LocationPermission.whileInUse:
        return 'Location permission granted for app usage.';
      case LocationPermission.always:
        return 'Location permission granted for always.';
      case LocationPermission.unableToDetermine:
        return 'Unable to determine location permission status.';
    }
  }

  /// Get the most accurate position possible with multiple attempts
  Future<Position?> getMostAccuratePosition({int maxAttempts = 3}) async {
    Position? bestPosition;
    var bestAccuracy = double.infinity;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (kDebugMode) {
          print('Location attempt $attempt of $maxAttempts');
        }

        final position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 20),
        );

        if (kDebugMode) {
          print('Attempt $attempt: Accuracy ${position.accuracy}m');
        }

        // If this position is more accurate than our best, update it
        if (position.accuracy < bestAccuracy) {
          bestPosition = position;
          bestAccuracy = position.accuracy;
        }

        // If we get a very accurate position (within 10 meters), use it
        if (position.accuracy <= 10) {
          if (kDebugMode) {
            print('High accuracy position found: ${position.accuracy}m');
          }
          return position;
        }

        // Wait a bit before the next attempt
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      } on Exception catch (e) {
        if (kDebugMode) {
          print('Location attempt $attempt failed: $e');
        }
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }

    if (kDebugMode && bestPosition != null) {
      debugPrint('Best position found: Accuracy ${bestPosition.accuracy}m');
    }

    return bestPosition;
  }

  /// Get position with specific accuracy requirements
  Future<Position?> getPositionWithAccuracy({
    required double maxAccuracyMeters,
    int maxAttempts = 5,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 15),
        );

        if (position.accuracy <= maxAccuracyMeters) {
          if (kDebugMode) {
            print(
              'Position with required accuracy found: ${position.accuracy}m',
            );
          }
          return position;
        }

        if (kDebugMode) {
          print(
            'Attempt $attempt: Accuracy ${position.accuracy}m (required: ${maxAccuracyMeters}m)',
          );
        }

        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(seconds: 3));
        }
      } on Exception catch (e) {
        if (kDebugMode) {
          print('Location attempt $attempt failed: $e');
        }
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(seconds: 3));
        }
      }
    }

    if (kDebugMode) {
      print('Could not achieve required accuracy of ${maxAccuracyMeters}m');
    }
    return null;
  }

  /// Check if location accuracy is good enough for reports
  bool isLocationAccurateEnough(
    Position position, {
    double maxAccuracyMeters = 50,
  }) => position.accuracy <= maxAccuracyMeters;

  /// Get location accuracy status message
  String getAccuracyStatusMessage(Position position) {
    if (position.accuracy <= 10) {
      return 'Excellent accuracy (${position.accuracy.toStringAsFixed(1)}m)';
    } else if (position.accuracy <= 30) {
      return 'Good accuracy (${position.accuracy.toStringAsFixed(1)}m)';
    } else if (position.accuracy <= 100) {
      return 'Fair accuracy (${position.accuracy.toStringAsFixed(1)}m)';
    } else {
      return 'Poor accuracy (${position.accuracy.toStringAsFixed(1)}m) - Consider moving to an open area';
    }
  }
}
