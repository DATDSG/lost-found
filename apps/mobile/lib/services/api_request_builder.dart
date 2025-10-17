import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import '../config/api_config.dart';
import 'api_input_validator.dart';

/// HTTP method types
enum HttpMethod { get, post, put, patch, delete }

/// API request configuration
class ApiRequestConfig {
  final String endpoint;
  final HttpMethod method;
  final Map<String, String>? headers;
  final Map<String, dynamic>? queryParams;
  final Map<String, dynamic>? body;
  final Duration? timeout;
  final bool requiresAuth;
  final bool validateInput;
  final String? contentType;

  const ApiRequestConfig({
    required this.endpoint,
    required this.method,
    this.headers,
    this.queryParams,
    this.body,
    this.timeout,
    this.requiresAuth = true,
    this.validateInput = true,
    this.contentType,
  });
}

/// API request builder service
class ApiRequestBuilder {
  static final ApiRequestBuilder _instance = ApiRequestBuilder._internal();
  factory ApiRequestBuilder() => _instance;
  ApiRequestBuilder._internal();

  final ApiInputValidator _validator = ApiInputValidator();

  /// Build HTTP request with proper configuration
  Future<http.Request> buildRequest(ApiRequestConfig config) async {
    // Validate input if required
    if (config.validateInput && config.body != null) {
      final validationResult = _validateRequestBody(
        config.body!,
        config.endpoint,
      );
      if (!validationResult.isValid) {
        throw ApiRequestException(
          'Input validation failed: ${validationResult.errors.join(', ')}',
          validationResult.errors,
        );
      }
    }

    // Build URL with query parameters
    final uri = _buildUri(config.endpoint, config.queryParams);

    // Create request
    final request = http.Request(_getHttpMethodString(config.method), uri);

    // Set headers
    _setHeaders(request, config);

    // Set body
    if (config.body != null) {
      _setBody(request, config);
    }

    return request;
  }

  /// Build multipart request for file uploads
  Future<http.MultipartRequest> buildMultipartRequest({
    required String endpoint,
    required Map<String, String> fields,
    required Map<String, File> files,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    Duration? timeout,
    bool requiresAuth = true,
  }) async {
    // Build URL with query parameters
    final uri = _buildUri(endpoint, queryParams);

    // Create multipart request
    final request = http.MultipartRequest('POST', uri);

    // Set headers
    if (headers != null) {
      request.headers.addAll(headers);
    }

    // Add fields
    request.fields.addAll(fields);

    // Add files
    for (final entry in files.entries) {
      final file = entry.value;
      final fieldName = entry.key;

      if (await file.exists()) {
        final fileName = file.path.split('/').last;
        final contentType = _getContentType(fileName);

        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            file.path,
            filename: fileName,
            contentType: contentType,
          ),
        );
      }
    }

    return request;
  }

  /// Build WebSocket URL
  String buildWebSocketUrl(
    String endpoint, {
    Map<String, String>? queryParams,
  }) {
    final uri = _buildUri(endpoint, queryParams);
    return uri.toString().replaceFirst('http', 'ws');
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    final baseUrl = ApiConfig.baseUrl;
    final fullUrl = endpoint.startsWith('http')
        ? endpoint
        : '$baseUrl$endpoint';

    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(fullUrl);
      final queryString = uri.queryParameters;

      // Add new query parameters
      for (final entry in queryParams.entries) {
        if (entry.value != null) {
          queryString[entry.key] = entry.value.toString();
        }
      }

      return uri.replace(queryParameters: queryString);
    }

    return Uri.parse(fullUrl);
  }

  /// Set request headers
  void _setHeaders(http.Request request, ApiRequestConfig config) {
    // Set content type
    if (config.contentType != null) {
      request.headers['Content-Type'] = config.contentType!;
    } else if (config.body != null) {
      request.headers['Content-Type'] = 'application/json';
    }

    // Set authorization header if required
    if (config.requiresAuth) {
      // This would typically get the token from storage
      // For now, we'll assume it's handled by the calling service
    }

    // Add custom headers
    if (config.headers != null) {
      request.headers.addAll(config.headers!);
    }

    // Set user agent
    request.headers['User-Agent'] = 'LostFinder-Mobile/1.0';
  }

  /// Set request body
  void _setBody(http.Request request, ApiRequestConfig config) {
    if (config.body != null) {
      if (config.contentType == 'application/json' ||
          (config.contentType == null && config.body is Map)) {
        request.body = jsonEncode(config.body);
      } else if (config.contentType == 'application/x-www-form-urlencoded') {
        request.body = _encodeFormData(config.body!);
      } else {
        request.body = config.body.toString();
      }
    }
  }

  /// Encode form data
  String _encodeFormData(Map<String, dynamic> data) {
    final pairs = <String>[];
    for (final entry in data.entries) {
      if (entry.value != null) {
        pairs.add(
          '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}',
        );
      }
    }
    return pairs.join('&');
  }

  /// Get HTTP method string
  String _getHttpMethodString(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.patch:
        return 'PATCH';
      case HttpMethod.delete:
        return 'DELETE';
    }
  }

  /// Get content type for file
  http_parser.MediaType _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return http_parser.MediaType('image', 'jpeg');
      case 'png':
        return http_parser.MediaType('image', 'png');
      case 'gif':
        return http_parser.MediaType('image', 'gif');
      case 'webp':
        return http_parser.MediaType('image', 'webp');
      case 'mp4':
        return http_parser.MediaType('video', 'mp4');
      case 'mov':
        return http_parser.MediaType('video', 'quicktime');
      case 'avi':
        return http_parser.MediaType('video', 'x-msvideo');
      case 'pdf':
        return http_parser.MediaType('application', 'pdf');
      case 'doc':
        return http_parser.MediaType('application', 'msword');
      case 'docx':
        return http_parser.MediaType(
          'application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      case 'txt':
        return http_parser.MediaType('text', 'plain');
      default:
        return http_parser.MediaType('application', 'octet-stream');
    }
  }

  /// Validate request body based on endpoint
  ValidationResult _validateRequestBody(
    Map<String, dynamic> body,
    String endpoint,
  ) {
    if (endpoint.contains('/auth/register')) {
      return _validateRegistrationData(body);
    } else if (endpoint.contains('/auth/login')) {
      return _validateLoginData(body);
    } else if (endpoint.contains('/reports')) {
      return _validator.validateReportData(body);
    } else if (endpoint.contains('/messages')) {
      return _validator.validateMessageData(body);
    } else if (endpoint.contains('/search')) {
      return _validator.validateSearchFilters(body);
    } else if (endpoint.contains('/media')) {
      return _validator.validateMediaUpload(body);
    } else if (endpoint.contains('/location')) {
      return _validator.validateLocationData(body);
    }

    // Default validation - check for common required fields
    return ValidationResult.success(data: body);
  }

  /// Validate registration data
  ValidationResult _validateRegistrationData(Map<String, dynamic> data) {
    final errors = <String>[];

    // Validate email
    final emailResult = _validator.validateEmail(
      data['email'] as String? ?? '',
    );
    if (!emailResult.isValid) {
      errors.addAll(emailResult.errors);
    }

    // Validate password
    final passwordResult = _validator.validatePassword(
      data['password'] as String? ?? '',
    );
    if (!passwordResult.isValid) {
      errors.addAll(passwordResult.errors);
    }

    // Validate display name
    final displayNameResult = _validator.validateDisplayName(
      data['display_name'] as String? ?? '',
    );
    if (!displayNameResult.isValid) {
      errors.addAll(displayNameResult.errors);
    }

    // Validate phone number (optional)
    if (data['phone_number'] != null) {
      final phoneResult = _validator.validatePhoneNumber(
        data['phone_number'] as String,
      );
      if (!phoneResult.isValid) {
        errors.addAll(phoneResult.errors);
      }
    }

    if (errors.isEmpty) {
      String? phoneNumber;
      if (data['phone_number'] != null) {
        final phoneResult = _validator.validatePhoneNumber(
          data['phone_number'] as String,
        );
        phoneNumber = phoneResult.sanitizedData?['phone_number'];
      }

      return ValidationResult.success(
        data: {
          'email': emailResult.sanitizedData?['email'],
          'password': passwordResult.sanitizedData?['password'],
          'display_name': displayNameResult.sanitizedData?['display_name'],
          'phone_number': phoneNumber,
        },
      );
    } else {
      return ValidationResult.failure(errors);
    }
  }

  /// Validate login data
  ValidationResult _validateLoginData(Map<String, dynamic> data) {
    final errors = <String>[];

    // Validate email
    final emailResult = _validator.validateEmail(
      data['email'] as String? ?? '',
    );
    if (!emailResult.isValid) {
      errors.addAll(emailResult.errors);
    }

    // Validate password
    if (data['password'] == null || (data['password'] as String).isEmpty) {
      errors.add('Password is required');
    }

    return errors.isEmpty
        ? ValidationResult.success(
            data: {
              'email': emailResult.sanitizedData?['email'],
              'password': data['password'],
            },
          )
        : ValidationResult.failure(errors);
  }

  /// Log request details for debugging
  void logRequest(ApiRequestConfig config) {
    if (kDebugMode) {
      debugPrint('🚀 API Request:');
      debugPrint('  Method: ${_getHttpMethodString(config.method)}');
      debugPrint('  Endpoint: ${config.endpoint}');
      if (config.queryParams != null) {
        debugPrint('  Query Params: ${config.queryParams}');
      }
      if (config.body != null) {
        debugPrint('  Body: ${config.body}');
      }
      if (config.headers != null) {
        debugPrint('  Headers: ${config.headers}');
      }
    }
  }
}

/// API request exception
class ApiRequestException implements Exception {
  final String message;
  final List<String> validationErrors;

  ApiRequestException(this.message, this.validationErrors);

  @override
  String toString() => 'ApiRequestException: $message';
}
