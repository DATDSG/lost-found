import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import '../config/api_config.dart';

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
  final String? contentType;

  const ApiRequestConfig({
    required this.endpoint,
    required this.method,
    this.headers,
    this.queryParams,
    this.body,
    this.timeout,
    this.requiresAuth = true,
    this.contentType,
  });
}

/// API request builder service
class ApiRequestBuilder {
  static final ApiRequestBuilder _instance = ApiRequestBuilder._internal();
  factory ApiRequestBuilder() => _instance;
  ApiRequestBuilder._internal();

  /// Build HTTP request with proper configuration
  Future<http.Request> buildRequest(ApiRequestConfig config) async {
    // Build URL with query parameters
    final uri = _buildUri(config.endpoint, config.queryParams);

    // Create request
    final request = http.Request(_getHttpMethodString(config.method), uri);

    // Set headers
    request.headers.addAll({
      'Content-Type': config.contentType ?? 'application/json',
      'Accept': 'application/json',
      ...?config.headers,
    });

    // Add body for POST/PUT/PATCH requests
    if (config.body != null && _hasBody(config.method)) {
      if (config.contentType == 'multipart/form-data') {
        // Handle multipart data
        final multipartRequest = http.MultipartRequest(
          _getHttpMethodString(config.method),
          uri,
        );
        multipartRequest.headers.addAll(request.headers);

        // Add form fields
        for (final entry in config.body!.entries) {
          if (entry.value is File) {
            multipartRequest.files.add(
              await http.MultipartFile.fromPath(
                  entry.key, (entry.value as File).path),
            );
          } else {
            multipartRequest.fields[entry.key] = entry.value.toString();
          }
        }

        return multipartRequest as http.Request;
      } else {
        // Handle JSON data
        request.body = jsonEncode(config.body);
      }
    }

    return request;
  }

  /// Build WebSocket URI
  String buildWebSocketUri(String endpoint,
      {Map<String, dynamic>? queryParams}) {
    final uri = _buildUri(endpoint, queryParams);
    return uri.toString().replaceFirst('http', 'ws');
  }

  /// Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    final baseUrl = ApiConfig.baseUrl;
    final fullUrl = '$baseUrl$endpoint';

    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = _buildQueryString(queryParams);
      return Uri.parse('$fullUrl?$queryString');
    }

    return Uri.parse(fullUrl);
  }

  /// Build query string from parameters
  String _buildQueryString(Map<String, dynamic> params) {
    final pairs = <String>[];
    params.forEach((key, value) {
      if (value != null) {
        pairs.add('$key=${Uri.encodeComponent(value.toString())}');
      }
    });
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

  /// Check if HTTP method has body
  bool _hasBody(HttpMethod method) {
    return method == HttpMethod.post ||
        method == HttpMethod.put ||
        method == HttpMethod.patch;
  }

  /// Get content type for file
  http_parser.MediaType? getContentTypeForFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

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
        return http_parser.MediaType('application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'txt':
        return http_parser.MediaType('text', 'plain');
      default:
        return http_parser.MediaType('application', 'octet-stream');
    }
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
  final List<String>? errors;

  ApiRequestException(this.message, [this.errors]);

  @override
  String toString() => 'ApiRequestException: $message';
}
