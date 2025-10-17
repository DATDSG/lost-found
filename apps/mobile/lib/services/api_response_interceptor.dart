import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/error/error_handler.dart';
import 'api_response_handler.dart';

/// Response interceptor configuration
class ResponseInterceptorConfig {
  final bool logRequests;
  final bool logResponses;
  final bool validateResponses;
  final bool transformResponses;
  final Duration? timeout;
  final int maxRetries;
  final Duration retryDelay;

  const ResponseInterceptorConfig({
    this.logRequests = true,
    this.logResponses = true,
    this.validateResponses = true,
    this.transformResponses = true,
    this.timeout,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });
}

/// API response interceptor service
class ApiResponseInterceptor {
  static final ApiResponseInterceptor _instance =
      ApiResponseInterceptor._internal();
  factory ApiResponseInterceptor() => _instance;
  ApiResponseInterceptor._internal();

  final ApiResponseHandler _responseHandler = ApiResponseHandler();
  // Using static ErrorHandler methods

  /// Intercept and process HTTP response
  Future<http.Response> interceptResponse(
    Future<http.Response> Function() requestFunction,
    ResponseInterceptorConfig config,
  ) async {
    try {
      // Execute request with timeout
      final response = await _executeWithTimeout(
        requestFunction,
        config.timeout,
      );

      // Log response if enabled
      if (config.logResponses) {
        _logResponse(response);
      }

      // Validate response if enabled
      if (config.validateResponses) {
        _validateResponse(response);
      }

      return response;
    } on SocketException catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'Network error'));
    } on HttpException catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'HTTP error'));
    } on FormatException catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'Format error'));
    } on TimeoutException catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'Timeout error'));
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'Generic error'));
    }
  }

  /// Intercept and process response with retry logic
  Future<http.Response> interceptResponseWithRetry(
    Future<http.Response> Function() requestFunction,
    ResponseInterceptorConfig config,
  ) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < config.maxRetries) {
      try {
        return await interceptResponse(requestFunction, config);
      } catch (e) {
        lastException = e as Exception;
        attempts++;

        if (attempts < config.maxRetries && _shouldRetry(e)) {
          if (kDebugMode) {
            debugPrint(
              '🔄 Retrying request (attempt $attempts/${config.maxRetries})',
            );
          }
          await Future.delayed(config.retryDelay);
          continue;
        } else {
          break;
        }
      }
    }

    throw lastException ??
        Exception('Request failed after ${config.maxRetries} attempts');
  }

  /// Process response data with validation and transformation
  Future<T?> processResponseData<T>(
    http.Response response,
    String responseType,
  ) async {
    try {
      // Parse JSON response
      final data = _parseJsonResponse(response);

      // Handle response based on type
      switch (responseType) {
        case 'auth_token':
          return _responseHandler.handleAuthResponse(data) as T?;
        case 'user':
          return _responseHandler.handleUserResponse(data) as T?;
        case 'reports_list':
          return _responseHandler.handleReportsResponse(data) as T?;
        case 'report':
          return _responseHandler.handleReportResponse(data) as T?;
        case 'conversations_list':
          return _responseHandler.handleConversationsResponse(data) as T?;
        case 'conversation':
          return _responseHandler.handleConversationResponse(data) as T?;
        case 'messages_list':
          return _responseHandler.handleMessagesResponse(data) as T?;
        case 'message':
          return _responseHandler.handleMessageResponse(data) as T?;
        case 'notifications_list':
          return _responseHandler.handleNotificationsResponse(data) as T?;
        case 'notification':
          return _responseHandler.handleNotificationResponse(data) as T?;
        case 'media_list':
          return _responseHandler.handleMediaResponse(data) as T?;
        case 'media':
          return _responseHandler.handleMediaResponse(data) as T?;
        case 'matches_list':
          return _responseHandler.handleMatchesResponse(data) as T?;
        case 'match':
          return _responseHandler.handleMatchResponse(data) as T?;
        case 'search_results':
          return _responseHandler.handleSearchResultsResponse(data) as T?;
        case 'location_data':
          return _responseHandler.handleLocationResponse(data) as T?;
        case 'error':
          return _responseHandler.handleErrorResponse(data) as T?;
        default:
          return data as T?;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to process response data: $e');
      }
      rethrow;
    }
  }

  /// Execute request with timeout
  Future<http.Response> _executeWithTimeout(
    Future<http.Response> Function() requestFunction,
    Duration? timeout,
  ) async {
    if (timeout != null) {
      return await requestFunction().timeout(timeout);
    } else {
      return await requestFunction();
    }
  }

  /// Parse JSON response
  dynamic _parseJsonResponse(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to parse JSON response: $e');
        debugPrint('Response body: ${response.body}');
      }
      throw FormatException('Invalid JSON response', response.body);
    }
  }

  /// Validate response structure
  void _validateResponse(http.Response response) {
    // Check status code
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        uri: response.request?.url,
      );
    }

    // Check content type for JSON responses
    final contentType = response.headers['content-type'];
    if (contentType != null &&
        contentType.contains('application/json') &&
        response.body.isNotEmpty) {
      try {
        jsonDecode(response.body);
      } catch (e) {
        throw FormatException('Invalid JSON in response body');
      }
    }
  }

  /// Log response details
  void _logResponse(http.Response response) {
    if (kDebugMode) {
      debugPrint('📥 API Response:');
      debugPrint('  Status: ${response.statusCode}');
      debugPrint('  Headers: ${response.headers}');

      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);
          debugPrint('  Body: ${jsonEncode(data)}');
        } catch (e) {
          debugPrint('  Body: ${response.body}');
        }
      }
    }
  }

  /// Determine if request should be retried
  bool _shouldRetry(Exception error) {
    if (error is SocketException) {
      return true; // Network errors should be retried
    }

    if (error is HttpException) {
      // Retry on server errors (5xx) but not client errors (4xx)
      final statusCode = _extractStatusCodeFromError(error);
      return statusCode != null && statusCode >= 500;
    }

    if (error is TimeoutException) {
      return true; // Timeout errors should be retried
    }

    return false; // Don't retry other errors
  }

  /// Extract status code from HTTP exception
  int? _extractStatusCodeFromError(HttpException error) {
    final message = error.message;
    final match = RegExp(r'HTTP (\d+)').firstMatch(message);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  /// Handle response errors
  void handleResponseError(http.Response response, String context) {
    if (kDebugMode) {
      debugPrint('❌ API Error in $context:');
      debugPrint('  Status: ${response.statusCode}');
      debugPrint('  Reason: ${response.reasonPhrase}');

      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);
          debugPrint('  Error: ${jsonEncode(data)}');
        } catch (e) {
          debugPrint('  Body: ${response.body}');
        }
      }
    }
  }

  /// Create standardized error response
  Map<String, dynamic> createErrorResponse(
    String message,
    String? code,
    Map<String, dynamic>? details,
  ) {
    return {
      'error': true,
      'message': message,
      'code': code,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create standardized success response
  Map<String, dynamic> createSuccessResponse(dynamic data, String? message) {
    return {
      'success': true,
      'data': data,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
