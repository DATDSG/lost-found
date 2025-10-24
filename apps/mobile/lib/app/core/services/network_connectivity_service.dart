import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Network connectivity service for detecting online/offline status
class NetworkConnectivityService {
  /// Factory constructor for singleton instance
  factory NetworkConnectivityService() => _instance;

  /// Private constructor for singleton pattern
  NetworkConnectivityService._internal() {
    _checkConnectivity();
    _startPeriodicCheck();
  }

  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();

  /// Stream controller for connectivity changes
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool _isConnected = true;

  /// Get the current connectivity status
  bool get isConnected => _isConnected;

  /// Timer for periodic connectivity checks
  Timer? _connectivityTimer;

  /// Start periodic connectivity checks
  void _startPeriodicCheck() {
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  /// Check current connectivity status with multiple methods
  Future<void> _checkConnectivity() async {
    try {
      // Try multiple connectivity checks for better reliability
      var isConnected = false;

      // Method 1: Try to lookup a reliable DNS
      try {
        final result = await InternetAddress.lookup(
          'google.com',
        ).timeout(const Duration(seconds: 5));
        isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on Exception catch (e) {
        if (kDebugMode) {
          print('DNS lookup failed: $e');
        }
      }

      // Method 2: If DNS fails, try a different approach
      if (!isConnected) {
        try {
          final result = await InternetAddress.lookup(
            '8.8.8.8',
          ).timeout(const Duration(seconds: 5));
          isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        } on Exception catch (e) {
          if (kDebugMode) {
            print('IP lookup failed: $e');
          }
        }
      }

      if (_isConnected != isConnected) {
        _isConnected = isConnected;
        _connectivityController.add(_isConnected);

        if (kDebugMode) {
          print(
            'Network connectivity changed: ${_isConnected ? 'Online' : 'Offline'}',
          );
        }
      }
    } on Exception catch (e) {
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(_isConnected);

        if (kDebugMode) {
          print('Network connectivity check failed: $e');
        }
      }
    }
  }

  /// Check connectivity status manually with detailed result
  Future<Map<String, dynamic>> checkConnectivityDetailed() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Try to lookup a reliable DNS
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 10));

      stopwatch.stop();

      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      return {
        'isConnected': isConnected,
        'responseTime': stopwatch.elapsedMilliseconds,
        'method': 'dns_lookup',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } on Exception catch (e) {
      return {
        'isConnected': false,
        'error': e.toString(),
        'method': 'dns_lookup',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check connectivity status manually
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Test connectivity to a specific host
  Future<bool> testConnectivityToHost(String host) async {
    try {
      final result = await InternetAddress.lookup(
        host,
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on Exception {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
  }
}
