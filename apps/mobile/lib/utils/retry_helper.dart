import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Retry configuration
class RetryConfig {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool exponentialBackoff;

  const RetryConfig({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.exponentialBackoff = true,
  });
}

/// Retry helper utility
class RetryHelper {
  /// Execute a function with retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig? config,
    bool Function(Exception)? shouldRetry,
  }) async {
    final retryConfig = config ?? const RetryConfig();
    Exception? lastException;

    for (int attempt = 1; attempt <= retryConfig.maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e as Exception;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(lastException)) {
          rethrow;
        }

        // Don't retry on the last attempt
        if (attempt == retryConfig.maxAttempts) {
          break;
        }

        // Calculate delay for next attempt
        final delay = _calculateDelay(attempt, retryConfig);

        if (kDebugMode) {
          debugPrint(
            '🔄 Retry attempt $attempt/${retryConfig.maxAttempts} after ${delay.inMilliseconds}ms',
          );
        }

        await Future.delayed(delay);
      }
    }

    throw lastException ??
        Exception('Operation failed after ${retryConfig.maxAttempts} attempts');
  }

  /// Calculate delay between retry attempts
  static Duration _calculateDelay(int attempt, RetryConfig config) {
    if (!config.exponentialBackoff) {
      return config.baseDelay;
    }

    final delayMs =
        config.baseDelay.inMilliseconds *
        math.pow(config.backoffMultiplier, attempt - 1);

    final delay = Duration(milliseconds: delayMs.round());

    // Cap the delay at maxDelay
    return delay > config.maxDelay ? config.maxDelay : delay;
  }

  /// Default retry condition for network operations
  static bool defaultShouldRetry(Exception error) {
    // Retry on network errors, timeouts, and server errors
    return error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('HttpException') ||
        error.toString().contains('500') ||
        error.toString().contains('502') ||
        error.toString().contains('503') ||
        error.toString().contains('504');
  }

  /// Retry configuration for API calls
  static const RetryConfig apiRetryConfig = RetryConfig(
    maxAttempts: 3,
    baseDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 10),
    backoffMultiplier: 2.0,
    exponentialBackoff: true,
  );

  /// Retry configuration for file operations
  static const RetryConfig fileRetryConfig = RetryConfig(
    maxAttempts: 5,
    baseDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 5),
    backoffMultiplier: 1.5,
    exponentialBackoff: true,
  );

  /// Retry configuration for database operations
  static const RetryConfig dbRetryConfig = RetryConfig(
    maxAttempts: 3,
    baseDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 2),
    backoffMultiplier: 2.0,
    exponentialBackoff: true,
  );
}


