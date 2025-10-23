import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../exceptions/api_exceptions.dart';
import 'cache_service.dart';
import 'network_connectivity_service.dart';

/// Offline-aware API service with caching and retry mechanisms
class OfflineAwareApiService {
  /// Factory constructor for singleton instance
  factory OfflineAwareApiService() => _instance;

  /// Private constructor for singleton pattern
  OfflineAwareApiService._internal() {
    _baseUrl = ApiConfig.baseUrl;
    if (kDebugMode) {
      print('Offline-Aware API Service initialized with base URL: $_baseUrl');
    }
  }

  static final OfflineAwareApiService _instance =
      OfflineAwareApiService._internal();

  late String _baseUrl;
  final CacheService _cacheService = CacheService();
  final NetworkConnectivityService _connectivityService =
      NetworkConnectivityService();

  /// Authentication token for API requests
  String? authToken;

  /// Maximum number of retry attempts
  static const int _maxRetries = 3;

  /// Retry delay in milliseconds
  static const int _retryDelayMs = 1000;

  /// Initialize the API service with base URL (optional override)
  void initialize({String? baseUrl}) {
    if (baseUrl != null) {
      _baseUrl = baseUrl;
      if (kDebugMode) {
        print('Offline-Aware API Service base URL updated to: $_baseUrl');
      }
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => authToken != null && authToken!.isNotEmpty;

  /// Build full URL for endpoint
  String _buildUrl(String endpoint) => '$_baseUrl$endpoint';

  /// Get headers for requests
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);

    if (includeAuth && authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  /// Enhanced HTTP request with retry mechanism and offline support
  Future<http.Response> _makeRequest(
    String method,
    String url,
    Map<String, String> headers, {
    String? body,
  }) async {
    // Check connectivity first
    if (!_connectivityService.isConnected) {
      throw ApiException(
        'No internet connection. Please check your network and try again.',
      );
    }

    var attempts = 0;
    Exception? lastException;

    while (attempts < _maxRetries) {
      try {
        if (kDebugMode) {
          print('API Request: $method $url (attempt ${attempts + 1})');
        }

        http.Response response;
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http
                .get(Uri.parse(url), headers: headers)
                .timeout(ApiConfig.timeout);
            break;
          case 'POST':
            response = await http
                .post(Uri.parse(url), headers: headers, body: body)
                .timeout(ApiConfig.timeout);
            break;
          case 'PUT':
            response = await http
                .put(Uri.parse(url), headers: headers, body: body)
                .timeout(ApiConfig.timeout);
            break;
          case 'DELETE':
            response = await http
                .delete(Uri.parse(url), headers: headers)
                .timeout(ApiConfig.timeout);
            break;
          default:
            throw ApiException('Unsupported HTTP method: $method');
        }

        // If successful, return response
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        // If it's a client error (4xx), don't retry
        if (response.statusCode >= 400 && response.statusCode < 500) {
          return response;
        }

        // For server errors (5xx), retry
        lastException = ApiException(
          'Server error: ${response.statusCode}',
          response.statusCode,
        );
      } on Exception catch (e) {
        if (e is SocketException) {
          lastException = ApiException('Network error: ${e.message}');
        } else if (e is HttpException) {
          lastException = ApiException('HTTP error: ${e.message}');
        } else if (e is FormatException) {
          lastException = ApiException('Format error: ${e.message}');
        } else {
          lastException = ApiException('Unexpected error: $e');
        }
      }

      attempts++;
      if (attempts < _maxRetries) {
        if (kDebugMode) {
          print('Request failed, retrying in ${_retryDelayMs}ms...');
        }
        await Future<void>.delayed(
          Duration(milliseconds: _retryDelayMs * attempts),
        );
      }
    }

    // If all retries failed, throw the last exception
    throw lastException ??
        ApiException('Request failed after $_maxRetries attempts');
  }

  /// Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('API Response: ${response.statusCode} - ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      return json.decode(response.body);
    } else {
      throw _handleError(response);
    }
  }

  /// Handle HTTP errors with enhanced error messages
  Exception _handleError(http.Response response) {
    if (kDebugMode) {
      print('API Error: ${response.statusCode} - ${response.body}');
    }

    try {
      final errorData = json.decode(response.body) as Map<String, dynamic>;
      final message =
          errorData['message'] ??
          errorData['detail'] ??
          errorData['error'] ??
          'Unknown error';
      return ApiException(message.toString(), response.statusCode);
    } on FormatException {
      // Return user-friendly error messages based on status code
      switch (response.statusCode) {
        case 400:
          return ApiException('Invalid request. Please check your input.', 400);
        case 401:
          return ApiException(
            'Authentication failed. Please log in again.',
            401,
          );
        case 403:
          return ApiException("Access denied. You don't have permission.", 403);
        case 404:
          return ApiException('Resource not found.', 404);
        case 422:
          return ApiException(
            'Validation error. Please check your input.',
            422,
          );
        case 429:
          return ApiException(
            'Too many requests. Please try again later.',
            429,
          );
        case 500:
          return ApiException('Server error. Please try again later.', 500);
        case 502:
        case 503:
        case 504:
          return ApiException(
            'Service temporarily unavailable. Please try again later.',
            response.statusCode,
          );
        default:
          return ApiException(
            'Server error: ${response.statusCode}',
            response.statusCode,
          );
      }
    }
  }

  /// Get data with offline support (tries cache first, then API)
  Future<List<Map<String, dynamic>>> getDataWithOfflineSupport(
    String endpoint,
    String cacheKey,
    Duration cacheDuration,
  ) async {
    try {
      // Try to get data from API first
      final response = await _makeRequest(
        'GET',
        _buildUrl(endpoint),
        _getHeaders(),
      );

      final data = _handleResponse(response);
      final listData = data is List
          ? data.map((item) => item as Map<String, dynamic>).toList()
          : <Map<String, dynamic>>[];

      // Cache the data
      await _cacheService.setCachedListData(cacheKey, listData);

      return listData;
    } catch (e) {
      if (kDebugMode) {
        print('API request failed, trying cache: $e');
      }

      // If API fails, try to get data from cache
      final cachedData = await _cacheService.getCachedListData(
        cacheKey,
        cacheDuration,
      );
      if (cachedData != null) {
        if (kDebugMode) {
          print('Using cached data for $cacheKey');
        }
        return cachedData;
      }

      // If no cached data available, rethrow the original error
      rethrow;
    }
  }

  /// Get single data with offline support
  Future<Map<String, dynamic>> getSingleDataWithOfflineSupport(
    String endpoint,
    String cacheKey,
    Duration cacheDuration,
  ) async {
    try {
      // Try to get data from API first
      final response = await _makeRequest(
        'GET',
        _buildUrl(endpoint),
        _getHeaders(),
      );

      final data = _handleResponse(response) as Map<String, dynamic>;

      // Cache the data
      await _cacheService.setCachedData(cacheKey, data);

      return data;
    } catch (e) {
      if (kDebugMode) {
        print('API request failed, trying cache: $e');
      }

      // If API fails, try to get data from cache
      final cachedData = await _cacheService.getCachedData(
        cacheKey,
        cacheDuration,
      );
      if (cachedData != null) {
        if (kDebugMode) {
          print('Using cached data for $cacheKey');
        }
        return cachedData;
      }

      // If no cached data available, rethrow the original error
      rethrow;
    }
  }

  // Authentication endpoints

  /// Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = _buildUrl(ApiConfig.loginEndpoint);
    final body = json.encode({'email': email, 'password': password});

    if (kDebugMode) {
      print('Login request URL: $url');
    }

    try {
      final response = await _makeRequest(
        'POST',
        url,
        _getHeaders(includeAuth: false),
        body: body,
      );
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      rethrow;
    }
  }

  /// Get current user profile with offline support
  Future<Map<String, dynamic>> getCurrentUser() async =>
      getSingleDataWithOfflineSupport(
        '${ApiConfig.authEndpoint}/me',
        'user_data',
        const Duration(hours: 1),
      );

  /// Get reports with offline support
  Future<List<Map<String, dynamic>>> getReports({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? type,
    String? category,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final uri = Uri.parse(
      _buildUrl(ApiConfig.reportsEndpoint),
    ).replace(queryParameters: queryParams);

    return getDataWithOfflineSupport(
      '${ApiConfig.reportsEndpoint}?${uri.query}',
      'reports',
      const Duration(minutes: 30),
    );
  }

  /// Get categories with offline support
  Future<List<Map<String, dynamic>>> getCategories({
    bool activeOnly = true,
  }) async {
    final queryParams = <String, String>{'active_only': activeOnly.toString()};

    final uri = Uri.parse(
      _buildUrl(ApiConfig.getCategoriesEndpoint),
    ).replace(queryParameters: queryParams);

    return getDataWithOfflineSupport(
      '${ApiConfig.getCategoriesEndpoint}?${uri.query}',
      'categories',
      const Duration(hours: 24),
    );
  }

  /// Get colors with offline support
  Future<List<Map<String, dynamic>>> getColors({bool activeOnly = true}) async {
    final queryParams = <String, String>{'active_only': activeOnly.toString()};

    final uri = Uri.parse(
      _buildUrl(ApiConfig.getColorsEndpoint),
    ).replace(queryParameters: queryParams);

    return getDataWithOfflineSupport(
      '${ApiConfig.getColorsEndpoint}?${uri.query}',
      'colors',
      const Duration(hours: 24),
    );
  }

  /// Clear user cache when logging out
  Future<void> clearUserCache() async {
    await _cacheService.clearUserCache();
  }

  /// Dispose resources
  void dispose() {
    _connectivityService.dispose();
  }
}
