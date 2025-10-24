import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/environment_config.dart';
import 'network_connectivity_service.dart';

/// Log levels for debug service
enum LogLevel {
  /// Debug level for detailed information
  debug,

  /// Info level for general information
  info,

  /// Warning level for potential issues
  warning,

  /// Error level for errors
  error,

  /// Critical level for severe issues
  critical,
}

/// Debug log entry containing log information
class DebugLog {
  /// Creates a new debug log entry
  DebugLog({
    required this.level,
    required this.message,
    required this.timestamp,
    this.category,
    this.data,
    this.stackTrace,
  });

  /// The log level
  final LogLevel level;

  /// The log message
  final String message;

  /// When the log was created
  final DateTime timestamp;

  /// Optional category for the log
  final String? category;

  /// Optional additional data
  final Map<String, dynamic>? data;

  /// Optional stack trace
  final StackTrace? stackTrace;

  /// Converts the debug log to JSON format
  Map<String, dynamic> toJson() => {
    'level': level.name,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'category': category,
    'data': data,
    'stackTrace': stackTrace?.toString(),
  };
}

/// Debug service for comprehensive logging and diagnostics
class DebugService {
  /// Factory constructor for singleton instance
  factory DebugService() => _instance;

  /// Private constructor for singleton pattern
  DebugService._internal();

  static final DebugService _instance = DebugService._internal();

  /// Network connectivity service
  final NetworkConnectivityService _connectivityService =
      NetworkConnectivityService();

  /// Debug logs storage
  final List<DebugLog> _logs = [];

  /// Maximum number of logs to keep in memory
  static const int _maxLogs = 1000;

  /// Log a debug message
  void debug(String message, {String? category, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, category: category, data: data);
  }

  /// Log an info message
  void info(String message, {String? category, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, category: category, data: data);
  }

  /// Log a warning message
  void warning(String message, {String? category, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, category: category, data: data);
  }

  /// Log an error message
  void error(
    String message, {
    String? category,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      category: category,
      data: data,
      stackTrace: stackTrace,
    );
  }

  /// Log a critical message
  void critical(
    String message, {
    String? category,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.critical,
      message,
      category: category,
      data: data,
      stackTrace: stackTrace,
    );
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    String? category,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    if (!EnvironmentConfig.enableDebugLogging && level == LogLevel.debug) {
      return;
    }

    final log = DebugLog(
      level: level,
      message: message,
      timestamp: DateTime.now(),
      category: category,
      data: data,
      stackTrace: stackTrace,
    );

    _logs.add(log);

    // Keep only the most recent logs
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Print to console in debug mode
    if (kDebugMode) {
      final levelColor = _getLevelColor(level);
      final timestamp = log.timestamp.toIso8601String().substring(11, 19);
      final categoryStr = category != null ? '[$category] ' : '';

      print('$levelColor[$timestamp] $categoryStr$message');

      if (data != null) {
        print('  Data: ${json.encode(data)}');
      }

      if (stackTrace != null) {
        print('  Stack: $stackTrace');
      }
    }
  }

  /// Get color for log level
  String _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[37m'; // White
      case LogLevel.info:
        return '\x1B[36m'; // Cyan
      case LogLevel.warning:
        return '\x1B[33m'; // Yellow
      case LogLevel.error:
        return '\x1B[31m'; // Red
      case LogLevel.critical:
        return '\x1B[35m'; // Magenta
    }
  }

  /// Get all logs
  List<DebugLog> getLogs() => List.unmodifiable(_logs);

  /// Get logs by level
  List<DebugLog> getLogsByLevel(LogLevel level) =>
      _logs.where((log) => log.level == level).toList();

  /// Get logs by category
  List<DebugLog> getLogsByCategory(String category) =>
      _logs.where((log) => log.category == category).toList();

  /// Clear all logs
  void clearLogs() {
    _logs.clear();
  }

  /// Export logs to JSON
  String exportLogs() {
    final logsJson = _logs.map((log) => log.toJson()).toList();
    return json.encode(logsJson);
  }

  /// Save logs to SharedPreferences
  Future<void> saveLogsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = exportLogs();
      await prefs.setString('debug_logs', logsJson);
    } on Exception catch (e) {
      error('Failed to save logs to storage', data: {'error': e.toString()});
    }
  }

  /// Load logs from SharedPreferences
  Future<void> loadLogsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString('debug_logs');

      if (logsJson != null) {
        final logsList = json.decode(logsJson) as List<dynamic>;
        _logs.clear();

        for (final logData in logsList) {
          final logMap = logData as Map<String, dynamic>;
          final log = DebugLog(
            level: LogLevel.values.firstWhere(
              (level) => level.name == logMap['level'],
              orElse: () => LogLevel.info,
            ),
            message: logMap['message'] as String,
            timestamp: DateTime.parse(logMap['timestamp'] as String),
            category: logMap['category'] as String?,
            data: logMap['data'] as Map<String, dynamic>?,
            stackTrace: logMap['stackTrace'] != null
                ? StackTrace.fromString(logMap['stackTrace'] as String)
                : null,
          );
          _logs.add(log);
        }
      }
    } on Exception catch (e) {
      error('Failed to load logs from storage', data: {'error': e.toString()});
    }
  }

  /// Get system diagnostics
  Future<Map<String, dynamic>> getSystemDiagnostics() async {
    try {
      final connectivity = await _connectivityService
          .checkConnectivityDetailed();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'environment': EnvironmentConfig.currentEnvironment.name,
        'baseUrl': EnvironmentConfig.baseUrl,
        'apiTimeout': EnvironmentConfig.apiTimeout.inSeconds,
        'connectivity': connectivity,
        'platform': Platform.operatingSystem,
        'platformVersion': Platform.operatingSystemVersion,
        'logCount': _logs.length,
        'memoryUsage': _getMemoryUsage(),
      };
    } on Exception catch (e) {
      error('Failed to get system diagnostics', data: {'error': e.toString()});
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// Get memory usage (simplified)
  Map<String, dynamic> _getMemoryUsage() => {
    'logsInMemory': _logs.length,
    'maxLogs': _maxLogs,
    'memoryPressure': _logs.length > _maxLogs * 0.8 ? 'high' : 'normal',
  };

  /// Test API connectivity
  Future<Map<String, dynamic>> testApiConnectivity() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Test basic connectivity
      final basicConnectivity = await _connectivityService.checkConnectivity();

      // Test API endpoint connectivity
      final apiConnectivity = await _connectivityService.testConnectivityToHost(
        Uri.parse(EnvironmentConfig.baseUrl).host,
      );

      stopwatch.stop();

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'basicConnectivity': basicConnectivity,
        'apiConnectivity': apiConnectivity,
        'responseTime': stopwatch.elapsedMilliseconds,
        'apiHost': Uri.parse(EnvironmentConfig.baseUrl).host,
        'apiPort': Uri.parse(EnvironmentConfig.baseUrl).port,
      };
    } on Exception catch (e) {
      error('API connectivity test failed', data: {'error': e.toString()});
      return {
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// Log API request
  void logApiRequest(
    String method,
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? body,
  }) {
    debug(
      'API Request',
      category: 'api',
      data: {'method': method, 'url': url, 'headers': headers, 'body': body},
    );
  }

  /// Log API response
  void logApiResponse(int statusCode, String body, {Duration? duration}) {
    final level = statusCode >= 200 && statusCode < 300
        ? LogLevel.info
        : LogLevel.error;
    _log(
      level,
      'API Response',
      category: 'api',
      data: {
        'statusCode': statusCode,
        'body': body.length > 500 ? '${body.substring(0, 500)}...' : body,
        'duration': duration?.inMilliseconds,
      },
    );
  }

  /// Log authentication events
  void logAuthEvent(String event, {Map<String, dynamic>? data}) {
    info('Auth Event: $event', category: 'auth', data: data);
  }

  /// Log user actions
  void logUserAction(String action, {Map<String, dynamic>? data}) {
    info('User Action: $action', category: 'user', data: data);
  }

  /// Log performance metrics
  void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? data,
  }) {
    final level = duration.inMilliseconds > 1000
        ? LogLevel.warning
        : LogLevel.info;
    _log(
      level,
      'Performance: $operation',
      category: 'performance',
      data: {'duration': duration.inMilliseconds, ...?data},
    );
  }
}
