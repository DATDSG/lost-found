import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline operation types
enum OfflineOperationType {
  createReport,
  updateReport,
  deleteReport,
  sendMessage,
  createConversation,
  uploadMedia,
  updateProfile,
  createMatch,
  confirmMatch,
  rejectMatch,
}

/// Offline operation priority
enum OfflineOperationPriority { low, normal, high, critical }

/// Offline operation model
class OfflineOperation {
  final String id;
  final OfflineOperationType type;
  final OfflineOperationPriority priority;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? error;
  final Map<String, dynamic>? metadata;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.priority,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.error,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'data': jsonEncode(data),
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'error': error,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'],
      type: OfflineOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OfflineOperationType.createReport,
      ),
      priority: OfflineOperationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => OfflineOperationPriority.normal,
      ),
      data: jsonDecode(json['data']),
      createdAt: DateTime.parse(json['created_at']),
      retryCount: json['retry_count'] ?? 0,
      error: json['error'],
      metadata: json['metadata'] != null ? jsonDecode(json['metadata']) : null,
    );
  }

  OfflineOperation copyWith({
    String? id,
    OfflineOperationType? type,
    OfflineOperationPriority? priority,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return OfflineOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Offline queue service for managing operations when offline
class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  static const String _queueKey = 'offline_queue';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(minutes: 5);

  final List<OfflineOperation> _operations = [];
  final StreamController<List<OfflineOperation>> _queueController =
      StreamController<List<OfflineOperation>>.broadcast();

  Timer? _retryTimer;
  bool _isProcessing = false;

  // Getters
  List<OfflineOperation> get operations => List.unmodifiable(_operations);
  Stream<List<OfflineOperation>> get queueStream => _queueController.stream;
  bool get isEmpty => _operations.isEmpty;
  bool get isNotEmpty => _operations.isNotEmpty;
  int get operationCount => _operations.length;

  /// Initialize the offline queue service
  Future<void> initialize() async {
    try {
      await _loadOperations();
      _startRetryTimer();
      debugPrint(
        '✅ OfflineQueueService initialized with ${_operations.length} operations',
      );
    } catch (e) {
      debugPrint('❌ Failed to initialize OfflineQueueService: $e');
    }
  }

  /// Add operation to offline queue
  Future<void> addOperation({
    required OfflineOperationType type,
    required Map<String, dynamic> data,
    OfflineOperationPriority priority = OfflineOperationPriority.normal,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final operation = OfflineOperation(
        id: _generateOperationId(),
        type: type,
        priority: priority,
        data: data,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      _operations.add(operation);
      await _saveOperations();
      _notifyQueueChanged();

      debugPrint(
        '📝 Added offline operation: ${type.name} (priority: ${priority.name})',
      );
    } catch (e) {
      debugPrint('❌ Failed to add offline operation: $e');
    }
  }

  /// Process all operations in the queue
  Future<void> processQueue() async {
    if (_isProcessing || _operations.isEmpty) return;

    _isProcessing = true;
    debugPrint('🔄 Processing ${_operations.length} offline operations...');

    try {
      // Sort operations by priority and creation time
      _operations.sort((a, b) {
        final priorityComparison = b.priority.index.compareTo(a.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        return a.createdAt.compareTo(b.createdAt);
      });

      final operationsToProcess = List<OfflineOperation>.from(_operations);

      for (final operation in operationsToProcess) {
        try {
          final success = await _executeOperation(operation);

          if (success) {
            _operations.removeWhere((op) => op.id == operation.id);
            debugPrint('✅ Processed operation: ${operation.type.name}');
          } else {
            _incrementRetryCount(operation);
            debugPrint('❌ Failed to process operation: ${operation.type.name}');
          }
        } catch (e) {
          _incrementRetryCount(operation, error: e.toString());
          debugPrint('❌ Error processing operation ${operation.type.name}: $e');
        }
      }

      await _saveOperations();
      _notifyQueueChanged();
    } finally {
      _isProcessing = false;
    }
  }

  /// Execute a single operation
  Future<bool> _executeOperation(OfflineOperation operation) async {
    try {
      switch (operation.type) {
        case OfflineOperationType.createReport:
          return await _executeCreateReport(operation);
        case OfflineOperationType.updateReport:
          return await _executeUpdateReport(operation);
        case OfflineOperationType.deleteReport:
          return await _executeDeleteReport(operation);
        case OfflineOperationType.sendMessage:
          return await _executeSendMessage(operation);
        case OfflineOperationType.createConversation:
          return await _executeCreateConversation(operation);
        case OfflineOperationType.uploadMedia:
          return await _executeUploadMedia(operation);
        case OfflineOperationType.updateProfile:
          return await _executeUpdateProfile(operation);
        case OfflineOperationType.createMatch:
          return await _executeCreateMatch(operation);
        case OfflineOperationType.confirmMatch:
          return await _executeConfirmMatch(operation);
        case OfflineOperationType.rejectMatch:
          return await _executeRejectMatch(operation);
      }
    } catch (e) {
      debugPrint('Error executing operation ${operation.type}: $e');
      return false;
    }
  }

  /// Execute create report operation
  Future<bool> _executeCreateReport(OfflineOperation operation) async {
    // This would integrate with the actual API service
    // For now, we'll simulate success
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Execute update report operation
  Future<bool> _executeUpdateReport(OfflineOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  /// Execute delete report operation
  Future<bool> _executeDeleteReport(OfflineOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  /// Execute send message operation
  Future<bool> _executeSendMessage(OfflineOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return true;
  }

  /// Execute create conversation operation
  Future<bool> _executeCreateConversation(OfflineOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  /// Execute upload media operation
  Future<bool> _executeUploadMedia(OfflineOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return true;
  }

  /// Execute update profile operation
  Future<bool> _executeUpdateProfile(OfflineOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  /// Execute create match operation
  Future<bool> _executeCreateMatch(OfflineOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  /// Execute confirm match operation
  Future<bool> _executeConfirmMatch(OfflineOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  /// Execute reject match operation
  Future<bool> _executeRejectMatch(OfflineOperation operation) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  /// Increment retry count for an operation
  void _incrementRetryCount(OfflineOperation operation, {String? error}) {
    final index = _operations.indexWhere((op) => op.id == operation.id);
    if (index != -1) {
      final updatedOperation = operation.copyWith(
        retryCount: operation.retryCount + 1,
        error: error,
      );

      if (updatedOperation.retryCount >= _maxRetries) {
        _operations.removeAt(index);
        debugPrint(
          '🗑️ Removed operation ${operation.type.name} after ${_maxRetries} retries',
        );
      } else {
        _operations[index] = updatedOperation;
        debugPrint(
          '🔄 Incremented retry count for ${operation.type.name}: ${updatedOperation.retryCount}',
        );
      }
    }
  }

  /// Remove operation from queue
  Future<void> removeOperation(String operationId) async {
    _operations.removeWhere((op) => op.id == operationId);
    await _saveOperations();
    _notifyQueueChanged();
  }

  /// Clear all operations
  Future<void> clearQueue() async {
    _operations.clear();
    await _saveOperations();
    _notifyQueueChanged();
    debugPrint('🗑️ Cleared offline queue');
  }

  /// Get operations by type
  List<OfflineOperation> getOperationsByType(OfflineOperationType type) {
    return _operations.where((op) => op.type == type).toList();
  }

  /// Get operations by priority
  List<OfflineOperation> getOperationsByPriority(
    OfflineOperationPriority priority,
  ) {
    return _operations.where((op) => op.priority == priority).toList();
  }

  /// Get failed operations
  List<OfflineOperation> getFailedOperations() {
    return _operations.where((op) => op.error != null).toList();
  }

  /// Load operations from storage
  Future<void> _loadOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operationsJson = prefs.getString(_queueKey);

      if (operationsJson != null) {
        final List<dynamic> operationsList = jsonDecode(operationsJson);
        _operations.clear();
        _operations.addAll(
          operationsList.map((json) => OfflineOperation.fromJson(json)),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to load offline operations: $e');
    }
  }

  /// Save operations to storage
  Future<void> _saveOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operationsJson = jsonEncode(
        _operations.map((op) => op.toJson()).toList(),
      );
      await prefs.setString(_queueKey, operationsJson);
    } catch (e) {
      debugPrint('❌ Failed to save offline operations: $e');
    }
  }

  /// Start retry timer
  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryDelay, (_) {
      if (_operations.isNotEmpty) {
        processQueue();
      }
    });
  }

  /// Notify queue changes
  void _notifyQueueChanged() {
    _queueController.add(List.unmodifiable(_operations));
  }

  /// Generate unique operation ID
  String _generateOperationId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_operations.length}';
  }

  /// Get queue statistics
  Map<String, dynamic> getQueueStats() {
    final stats = <String, dynamic>{
      'total_operations': _operations.length,
      'by_type': <String, int>{},
      'by_priority': <String, int>{},
      'failed_operations': 0,
      'oldest_operation': null,
      'newest_operation': null,
    };

    if (_operations.isNotEmpty) {
      // Count by type
      for (final type in OfflineOperationType.values) {
        stats['by_type'][type.name] = _operations
            .where((op) => op.type == type)
            .length;
      }

      // Count by priority
      for (final priority in OfflineOperationPriority.values) {
        stats['by_priority'][priority.name] = _operations
            .where((op) => op.priority == priority)
            .length;
      }

      // Count failed operations
      stats['failed_operations'] = _operations
          .where((op) => op.error != null)
          .length;

      // Find oldest and newest operations
      _operations.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      stats['oldest_operation'] = _operations.first.createdAt.toIso8601String();
      stats['newest_operation'] = _operations.last.createdAt.toIso8601String();
    }

    return stats;
  }

  /// Dispose resources
  void dispose() {
    _retryTimer?.cancel();
    _queueController.close();
  }
}
