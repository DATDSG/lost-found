import 'dart:async';
import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';
import 'cache_service.dart';
import 'offline_queue_service.dart';

/// Offline manager that coordinates all offline functionality
class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final CacheService _cacheService = CacheService();
  final OfflineQueueService _offlineQueueService = OfflineQueueService();

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isInitialized = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOnline => _connectivityService.isOnline;
  bool get isOffline => _connectivityService.isOffline;
  ConnectivityService get connectivityService => _connectivityService;
  CacheService get cacheService => _cacheService;
  OfflineQueueService get offlineQueueService => _offlineQueueService;

  /// Initialize offline manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Initializing OfflineManager...');

      // Initialize all services
      await Future.wait([
        _connectivityService.initialize(),
        _cacheService.initialize(),
        _offlineQueueService.initialize(),
      ]);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivityService.connectivityStream
          .listen(
            _onConnectivityChanged,
            onError: (error) {
              debugPrint('Connectivity stream error: $error');
            },
          );

      _isInitialized = true;
      debugPrint('✅ OfflineManager initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize OfflineManager: $e');
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(bool isOnline) {
    if (isOnline) {
      debugPrint('🌐 Back online - processing offline queue...');
      _processOfflineQueue();
    } else {
      debugPrint('📴 Gone offline - operations will be queued');
    }
  }

  /// Process offline queue when back online
  Future<void> _processOfflineQueue() async {
    try {
      await _offlineQueueService.processQueue();
    } catch (e) {
      debugPrint('❌ Error processing offline queue: $e');
    }
  }

  /// Execute operation with offline support
  Future<T?> executeWithOfflineSupport<T>(
    String operationKey,
    Future<T> Function() onlineOperation, {
    Duration? cacheExpiry,
    String? cacheTag,
    OfflineOperationType? offlineOperationType,
    OfflineOperationPriority offlinePriority = OfflineOperationPriority.normal,
    Map<String, dynamic>? offlineData,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      debugPrint('OfflineManager not initialized');
      return null;
    }

    try {
      // If online, try to execute operation
      if (isOnline) {
        try {
          final result = await onlineOperation();

          // Cache the result if successful
          if (result != null) {
            await _cacheService.store(
              operationKey,
              result,
              expiry: cacheExpiry,
              tag: cacheTag,
              metadata: metadata,
            );
          }

          return result;
        } catch (e) {
          debugPrint('Online operation failed: $e');

          // Try to return cached data as fallback
          final cachedResult = await _cacheService.retrieve<T>(operationKey);
          if (cachedResult != null) {
            debugPrint('📦 Returning cached data for $operationKey');
            return cachedResult;
          }

          rethrow;
        }
      } else {
        // Offline - try cached data first
        final cachedResult = await _cacheService.retrieve<T>(operationKey);
        if (cachedResult != null) {
          debugPrint('📦 Offline: Returning cached data for $operationKey');
          return cachedResult;
        }

        // If no cached data and operation can be queued, add to offline queue
        if (offlineOperationType != null && offlineData != null) {
          await _offlineQueueService.addOperation(
            type: offlineOperationType,
            data: offlineData,
            priority: offlinePriority,
            metadata: metadata,
          );
          debugPrint('📝 Offline: Queued operation $offlineOperationType');
        }

        return null;
      }
    } catch (e) {
      debugPrint('❌ Error in executeWithOfflineSupport: $e');
      return null;
    }
  }

  /// Get cached data with fallback
  Future<T?> getCachedData<T>(String key, {Duration? maxAge}) async {
    if (!_isInitialized) return null;

    try {
      final cachedData = await _cacheService.retrieve<T>(key);

      if (cachedData != null) {
        // Check if data is within max age if specified
        if (maxAge != null) {
          final entry = await _cacheService.getAllEntries();
          final relevantEntry = entry.where((e) => e.key == key).firstOrNull;

          if (relevantEntry != null) {
            final age = DateTime.now().difference(relevantEntry.createdAt);
            if (age > maxAge) {
              debugPrint(
                '📦 Cached data for $key is too old (${age.inMinutes}m)',
              );
              return null;
            }
          }
        }

        debugPrint('📦 Retrieved cached data for $key');
        return cachedData;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error retrieving cached data: $e');
      return null;
    }
  }

  /// Store data in cache
  Future<void> storeData(
    String key,
    dynamic data, {
    Duration? expiry,
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) return;

    try {
      await _cacheService.store(
        key,
        data,
        expiry: expiry,
        tag: tag,
        metadata: metadata,
      );
      debugPrint('📦 Stored data in cache: $key');
    } catch (e) {
      debugPrint('❌ Error storing data in cache: $e');
    }
  }

  /// Add operation to offline queue
  Future<void> queueOfflineOperation({
    required OfflineOperationType type,
    required Map<String, dynamic> data,
    OfflineOperationPriority priority = OfflineOperationPriority.normal,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) return;

    try {
      await _offlineQueueService.addOperation(
        type: type,
        data: data,
        priority: priority,
        metadata: metadata,
      );
      debugPrint('📝 Queued offline operation: ${type.name}');
    } catch (e) {
      debugPrint('❌ Error queuing offline operation: $e');
    }
  }

  /// Process offline queue manually
  Future<void> processOfflineQueue() async {
    if (!_isInitialized) return;

    try {
      await _offlineQueueService.processQueue();
    } catch (e) {
      debugPrint('❌ Error processing offline queue: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    if (!_isInitialized) return;

    try {
      await _cacheService.clear();
      debugPrint('🗑️ Cleared all cached data');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Clear offline queue
  Future<void> clearOfflineQueue() async {
    if (!_isInitialized) return;

    try {
      await _offlineQueueService.clearQueue();
      debugPrint('🗑️ Cleared offline queue');
    } catch (e) {
      debugPrint('❌ Error clearing offline queue: $e');
    }
  }

  /// Get comprehensive offline status
  Future<Map<String, dynamic>> getOfflineStatus() async {
    if (!_isInitialized) {
      return {
        'is_initialized': false,
        'is_online': false,
        'cache_stats': null,
        'queue_stats': null,
        'connectivity_status': null,
      };
    }

    try {
      final cacheStats = await _cacheService.getStats();
      final queueStats = _offlineQueueService.getQueueStats();
      final connectivityStatus = _connectivityService.getConnectivityStatus();

      return {
        'is_initialized': _isInitialized,
        'is_online': isOnline,
        'is_offline': isOffline,
        'cache_stats': cacheStats,
        'queue_stats': queueStats,
        'connectivity_status': connectivityStatus,
      };
    } catch (e) {
      debugPrint('❌ Error getting offline status: $e');
      return {
        'is_initialized': _isInitialized,
        'is_online': false,
        'error': e.toString(),
      };
    }
  }

  /// Wait for internet connection
  Future<void> waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized) return;

    try {
      await _connectivityService.waitForConnection(timeout: timeout);
    } catch (e) {
      debugPrint('❌ Error waiting for connection: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _offlineQueueService.dispose();
    _cacheService.close();
    _isInitialized = false;
    debugPrint('🔒 OfflineManager disposed');
  }
}

