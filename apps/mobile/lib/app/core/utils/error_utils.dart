import '../exceptions/api_exceptions.dart';

/// Centralized error handling utilities for the lost-found app

/// Handles and converts various error types to appropriate exceptions
Exception handleError(Object error) {
  if (error is Exception) {
    return error;
  }

  if (error is String) {
    return ApiException(error);
  }

  return ApiException('An unexpected error occurred: ${error.toString()}');
}
