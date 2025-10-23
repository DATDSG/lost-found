/// Custom exceptions for API operations
class ApiException implements Exception {
  /// Creates a new [ApiException] instance
  ApiException(this.message, [this.statusCode, this.errorCode]);

  /// The error message
  final String message;

  /// The HTTP status code, if applicable
  final int? statusCode;

  /// The error code for programmatic handling
  final String? errorCode;

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Network-related exceptions
class NetworkException extends ApiException {
  /// Creates a new [NetworkException] instance
  NetworkException(String message) : super(message, 0, 'NETWORK_ERROR');
}

/// Authentication exceptions
class AuthenticationException extends ApiException {
  /// Creates a new [AuthenticationException] instance
  AuthenticationException(String message) : super(message, 401, 'AUTH_ERROR');
}

/// Authorization exceptions
class AuthorizationException extends ApiException {
  /// Creates a new [AuthorizationException] instance
  AuthorizationException(String message)
    : super(message, 403, 'AUTHORIZATION_ERROR');
}

/// Validation exceptions
class ValidationException extends ApiException {
  /// Creates a new [ValidationException] instance
  ValidationException(String message, [this.fieldErrors])
    : super(message, 400, 'VALIDATION_ERROR');

  /// Field-specific validation errors
  final Map<String, List<String>>? fieldErrors;
}

/// Not found exceptions
class NotFoundException extends ApiException {
  /// Creates a new [NotFoundException] instance
  NotFoundException(String message) : super(message, 404, 'NOT_FOUND');
}

/// Server exceptions
class ServerException extends ApiException {
  /// Creates a new [ServerException] instance
  ServerException(String message) : super(message, 500, 'SERVER_ERROR');
}

/// Timeout exceptions
class TimeoutException extends ApiException {
  /// Creates a new [TimeoutException] instance
  TimeoutException(String message) : super(message, 408, 'TIMEOUT');
}
