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

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;

      if (_isConnected != isConnected) {
        _isConnected = isConnected;
        _connectivityController.add(_isConnected);

        if (kDebugMode) {
          print(
            'Network connectivity changed: ${_isConnected ? 'Online' : 'Offline'}',
          );
        }
      }
    } on Exception catch (_) {
      if (_isConnected) {
        _isConnected = false;
        _connectivityController.add(_isConnected);

        if (kDebugMode) {
          print('Network connectivity changed: Offline');
        }
      }
    }
  }

  /// Check connectivity status manually
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityController.close();
  }
}
