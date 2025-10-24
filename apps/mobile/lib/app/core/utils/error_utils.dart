import '../exceptions/api_exceptions.dart';
import '../services/debug_service.dart';

/// Centralized error handling utilities for the lost-found app

/// Handles and converts various error types to appropriate exceptions
Exception handleError(Object error) {
  final debugService = DebugService();

  if (error is Exception) {
    debugService.error(
      'Exception caught',
      category: 'error_handling',
      data: {'error': error.toString()},
    );
    return error;
  }

  if (error is String) {
    debugService.error(
      'String error caught',
      category: 'error_handling',
      data: {'error': error},
    );
    return ApiException(error);
  }

  debugService.error(
    'Unknown error type caught',
    category: 'error_handling',
    data: {'error': error.toString(), 'type': error.runtimeType.toString()},
  );
  return ApiException('An unexpected error occurred: ${error.toString()}');
}

/// Enhanced error handling with context
Exception handleErrorWithContext(Object error, String context) {
  final debugService = DebugService();

  debugService.error(
    'Error in context: $context',
    category: 'error_handling',
    data: {
      'context': context,
      'error': error.toString(),
      'type': error.runtimeType.toString(),
    },
  );

  return handleError(error);
}

/// Convert HTTP status codes to user-friendly messages
String getErrorMessageFromStatusCode(int statusCode) {
  switch (statusCode) {
    case 400:
      return 'Invalid request. Please check your input and try again.';
    case 401:
      return 'Authentication failed. Please log in again.';
    case 403:
      return "Access denied. You don't have permission to perform this action.";
    case 404:
      return 'The requested resource was not found.';
    case 422:
      return 'Validation error. Please check your input.';
    case 429:
      return 'Too many requests. Please try again later.';
    case 500:
      return 'Server error. Please try again later.';
    case 502:
    case 503:
    case 504:
      return 'Service temporarily unavailable. Please try again later.';
    default:
      return 'An error occurred. Please try again.';
  }
}

/// Check if error is network-related
bool isNetworkError(Object error) {
  final errorString = error.toString().toLowerCase();
  return errorString.contains('socket') ||
      errorString.contains('network') ||
      errorString.contains('connection') ||
      errorString.contains('timeout') ||
      errorString.contains('handshake');
}

/// Check if error is authentication-related
bool isAuthError(Object error) {
  final errorString = error.toString().toLowerCase();
  return errorString.contains('401') ||
      errorString.contains('unauthorized') ||
      errorString.contains('authentication') ||
      errorString.contains('token');
}

/// Get user-friendly error message
String getUserFriendlyErrorMessage(Object error) {
  if (isNetworkError(error)) {
    return 'Network connection error. Please check your internet connection and try again.';
  }

  if (isAuthError(error)) {
    return 'Authentication error. Please log in again.';
  }

  if (error is ApiException) {
    return error.message;
  }

  return 'An unexpected error occurred. Please try again.';
}
