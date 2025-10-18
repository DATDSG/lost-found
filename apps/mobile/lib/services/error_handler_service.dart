import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service for handling API errors and providing user-friendly messages
class ErrorHandlerService {
  /// Get user-friendly error message from API error
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.sendTimeout:
          return 'Request timeout. Please try again.';
        case DioExceptionType.receiveTimeout:
          return 'Server took too long to respond. Please try again.';
        case DioExceptionType.badResponse:
          return _handleBadResponse(error);
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        case DioExceptionType.badCertificate:
          return 'Security error. Please contact support.';
        case DioExceptionType.unknown:
          return 'Network error occurred. Please try again.';
      }
    }

    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return 'An unexpected error occurred. Please try again.';
  }

  static String _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Try to extract error message from response
    String? message;
    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? data['detail'];
    }

    switch (statusCode) {
      case 400:
        return message ?? 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'Access denied. You don\'t have permission.';
      case 404:
        return message ?? 'Resource not found.';
      case 409:
        return message ?? 'Conflict. Resource already exists.';
      case 422:
        return message ?? 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please wait and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Server is temporarily unavailable.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. Please try again.';
      default:
        return message ??
            'Server error (${statusCode ?? 'unknown'}). Please try again.';
    }
  }

  /// Log error for debugging
  static void logError(String context, dynamic error,
      [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('=== ERROR in $context ===');
      print('Error: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
      print('=========================');
    }
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
    }
    return false;
  }

  /// Check if error is authentication-related
  static bool isAuthError(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return statusCode == 401 || statusCode == 403;
    }
    return false;
  }
}
