import 'package:flutter/foundation.dart';

/// Standardized API error handling utility
class ApiErrorHandler {
  /// Handle API errors with standardized error messages
  static String handleApiError(dynamic error, {String? context}) {
    if (error == null) return 'An unknown error occurred';

    final errorString = error.toString().toLowerCase();
    final contextPrefix = context != null ? '$context: ' : '';

    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('handshakeexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable')) {
      return '${contextPrefix}Network connection failed. Please check your internet connection.';
    }

    // Timeout errors
    if (errorString.contains('timeout') ||
        errorString.contains('deadline exceeded')) {
      return '${contextPrefix}Request timed out. Please try again.';
    }

    // Authentication errors
    if (errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('not authenticated') ||
        errorString.contains('invalid token')) {
      return '${contextPrefix}Authentication failed. Please log in again.';
    }

    // Permission errors
    if (errorString.contains('forbidden') ||
        errorString.contains('403') ||
        errorString.contains('permission denied')) {
      return '${contextPrefix}You don\'t have permission to perform this action.';
    }

    // Not found errors
    if (errorString.contains('not found') || errorString.contains('404')) {
      return '${contextPrefix}Requested resource not found.';
    }

    // Server errors
    if (errorString.contains('internal server error') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504')) {
      return '${contextPrefix}Server error. Please try again later.';
    }

    // Validation errors
    if (errorString.contains('validation') ||
        errorString.contains('invalid input') ||
        errorString.contains('bad request') ||
        errorString.contains('400')) {
      return '${contextPrefix}Invalid input. Please check your data and try again.';
    }

    // Rate limiting
    if (errorString.contains('rate limit') ||
        errorString.contains('too many requests') ||
        errorString.contains('429')) {
      return '${contextPrefix}Too many requests. Please wait a moment and try again.';
    }

    // Generic error
    return '${contextPrefix}An error occurred. Please try again.';
  }

  /// Check if error is a network error
  static bool isNetworkError(dynamic error) {
    if (error == null) return false;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('handshakeexception') ||
        errorString.contains('connection refused') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('timeout');
  }

  /// Check if error is an authentication error
  static bool isAuthError(dynamic error) {
    if (error == null) return false;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        errorString.contains('not authenticated') ||
        errorString.contains('invalid token');
  }

  /// Check if error is a server error
  static bool isServerError(dynamic error) {
    if (error == null) return false;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('internal server error') ||
        errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('504');
  }

  /// Check if error is a client error (4xx)
  static bool isClientError(dynamic error) {
    if (error == null) return false;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('400') ||
        errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('404') ||
        errorString.contains('429');
  }

  /// Get error severity level
  static ErrorSeverity getErrorSeverity(dynamic error) {
    if (isAuthError(error)) return ErrorSeverity.high;
    if (isServerError(error)) return ErrorSeverity.medium;
    if (isNetworkError(error)) return ErrorSeverity.low;
    if (isClientError(error)) return ErrorSeverity.medium;
    return ErrorSeverity.low;
  }

  /// Check if error should be retried
  static bool shouldRetry(dynamic error) {
    if (isNetworkError(error)) return true;
    if (isServerError(error)) return true;
    if (isClientError(error)) {
      final errorString = error.toString().toLowerCase();
      // Don't retry auth errors or validation errors
      return !errorString.contains('401') &&
          !errorString.contains('403') &&
          !errorString.contains('400');
    }
    return false;
  }

  /// Get retry delay based on error type
  static Duration getRetryDelay(dynamic error, int attempt) {
    if (isNetworkError(error)) {
      return Duration(seconds: 2 * attempt); // Exponential backoff for network
    }
    if (isServerError(error)) {
      return Duration(seconds: 5 * attempt); // Longer delay for server errors
    }
    return Duration(seconds: 1 * attempt); // Default exponential backoff
  }

  /// Log error for debugging
  static void logError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint(
        '🚨 API Error${context != null ? ' in $context' : ''}: $error',
      );
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
}

/// Error severity levels
enum ErrorSeverity {
  low, // Minor issues, user can continue
  medium, // Moderate issues, may affect functionality
  high, // Critical issues, user action required
}

/// Error context for better error handling
class ErrorContext {
  final String operation;
  final String? userId;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  ErrorContext({
    required this.operation,
    this.userId,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'userId': userId,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

