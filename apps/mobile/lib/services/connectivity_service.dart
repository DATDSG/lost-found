import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Connectivity service for monitoring network status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Current connectivity state
  List<ConnectivityResult> _currentConnectivity = [ConnectivityResult.none];
  bool _isOnline = false;

  // Stream controllers for connectivity changes
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  final StreamController<List<ConnectivityResult>>
  _connectivityResultsController =
      StreamController<List<ConnectivityResult>>.broadcast();

  // Getters
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  List<ConnectivityResult> get currentConnectivity =>
      List.unmodifiable(_currentConnectivity);

  // Streams
  Stream<bool> get connectivityStream => _connectivityController.stream;
  Stream<List<ConnectivityResult>> get connectivityResultsStream =>
      _connectivityResultsController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Get initial connectivity state
      _currentConnectivity = await _connectivity.checkConnectivity();
      _updateConnectivityState(_currentConnectivity);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectivityState,
        onError: (error) {
          debugPrint('Connectivity error: $error');
        },
      );

      debugPrint('✅ ConnectivityService initialized - Online: $_isOnline');
    } catch (e) {
      debugPrint('❌ Failed to initialize ConnectivityService: $e');
    }
  }

  /// Update connectivity state based on results
  void _updateConnectivityState(List<ConnectivityResult> results) {
    _currentConnectivity = results;
    final wasOnline = _isOnline;
    _isOnline = _hasInternetConnection(results);

    // Notify listeners if connectivity state changed
    if (wasOnline != _isOnline) {
      _connectivityController.add(_isOnline);
      debugPrint(
        '🌐 Connectivity changed: ${_isOnline ? "Online" : "Offline"}',
      );
    }

    // Always notify about connectivity results
    _connectivityResultsController.add(List.unmodifiable(results));
  }

  /// Check if any of the connectivity results indicate internet access
  bool _hasInternetConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.bluetooth ||
          result == ConnectivityResult.other,
    );
  }

  /// Check current connectivity status
  Future<List<ConnectivityResult>> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectivityState(results);
      return results;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return [ConnectivityResult.none];
    }
  }

  /// Wait for internet connection
  Future<void> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (_isOnline) return;

    try {
      await connectivityStream
          .where((isOnline) => isOnline)
          .first
          .timeout(timeout);
    } catch (e) {
      debugPrint('Timeout waiting for connection: $e');
    }
  }

  /// Get connectivity status summary
  Map<String, dynamic> getConnectivityStatus() {
    return {
      'isOnline': _isOnline,
      'isOffline': !_isOnline,
      'connectivityResults': _currentConnectivity.map((r) => r.name).toList(),
      'hasWifi': _currentConnectivity.contains(ConnectivityResult.wifi),
      'hasMobile': _currentConnectivity.contains(ConnectivityResult.mobile),
      'hasEthernet': _currentConnectivity.contains(ConnectivityResult.ethernet),
      'hasVpn': _currentConnectivity.contains(ConnectivityResult.vpn),
      'hasBluetooth': _currentConnectivity.contains(
        ConnectivityResult.bluetooth,
      ),
      'hasOther': _currentConnectivity.contains(ConnectivityResult.other),
    };
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    _connectivityResultsController.close();
  }
}



