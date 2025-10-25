import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../constants/api_config.dart';
import '../models/api_models.dart';
import 'debug_service.dart';

/// Main API service for handling all API requests
class ApiService {
  /// Factory constructor for singleton pattern
  factory ApiService() => _instance;

  /// Private constructor for singleton pattern
  ApiService._internal() {
    _baseUrl = ApiConfig.baseUrl;
    if (kDebugMode) {
      print('API Service initialized with base URL: $_baseUrl');
    }
  }

  /// Static instance for singleton pattern
  static final ApiService _instance = ApiService._internal();

  late String _baseUrl;

  /// Authentication token for API requests
  String? authToken;

  /// Debug service for logging
  final DebugService _debugService = DebugService();

  /// Get the base URL
  String get baseUrl => _baseUrl;

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

  /// Enhanced HTTP request with retry mechanism
  Future<http.Response> _makeRequest(
    String method,
    String url,
    Map<String, String> headers, {
    String? body,
  }) async {
    var attempts = 0;
    const maxRetries = 3;

    while (attempts < maxRetries) {
      try {
        if (kDebugMode) {
          print('API Request: $method $url (attempt ${attempts + 1})');
        }

        // Log API request
        _debugService.logApiRequest(
          method,
          url,
          headers: headers,
          body: body != null
              ? json.decode(body) as Map<String, dynamic>?
              : null,
        );

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
          case 'PATCH':
            response = await http
                .patch(Uri.parse(url), headers: headers, body: body)
                .timeout(ApiConfig.timeout);
            break;
          case 'DELETE':
            response = await http
                .delete(Uri.parse(url), headers: headers)
                .timeout(ApiConfig.timeout);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

        if (kDebugMode) {
          print(
            'API Response: ${response.statusCode} - ${response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body}',
          );
        }

        // Log API response
        _debugService.logApiResponse(response.statusCode, response.body);

        // If successful, return response
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }

        // If it's a client error (4xx), don't retry
        if (response.statusCode >= 400 && response.statusCode < 500) {
          return response;
        }

        // For server errors (5xx), retry
        throw Exception('Server error: ${response.statusCode}');
      } on Exception catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          if (kDebugMode) {
            print('API Error: $e');
          }
          _debugService.error(
            'API request failed after $maxRetries attempts',
            category: 'api',
            data: {'method': method, 'url': url, 'error': e.toString()},
          );
          rethrow;
        }
        _debugService.warning(
          'API request failed, retrying',
          category: 'api',
          data: {
            'method': method,
            'url': url,
            'attempt': attempts,
            'error': e.toString(),
          },
        );
        await Future<void>.delayed(Duration(seconds: attempts));
      }
    }

    throw Exception('Max retries exceeded');
  }

  /// Handle API response with comprehensive error handling
  dynamic _handleResponse(http.Response response) {
    // Log API response
    _debugService.logApiResponse(response.statusCode, response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      try {
        return json.decode(response.body);
      } on FormatException catch (e) {
        _debugService.error(
          'JSON decode error',
          category: 'api',
          data: {'body': response.body, 'error': e.toString()},
        );
        throw Exception('Invalid response format from server');
      }
    } else {
      var errorMessage = 'API Error: ${response.statusCode}';
      Map<String, dynamic>? errorData;

      try {
        final errorBody = response.body.isNotEmpty
            ? json.decode(response.body) as Map<String, dynamic>
            : <String, dynamic>{'message': 'Unknown error'};

        errorData = errorBody;

        if (errorData.containsKey('error')) {
          final error = errorData['error'];
          if (error is Map<String, dynamic>) {
            errorMessage = '${error['message'] ?? errorMessage}';
          } else if (error is String) {
            errorMessage = error;
          }
        } else if (errorData.containsKey('detail')) {
          errorMessage = errorData['detail'].toString();
        } else if (errorData.containsKey('message')) {
          errorMessage = errorData['message'].toString();
        }
      } on FormatException catch (e) {
        _debugService.warning(
          'Could not parse error response',
          category: 'api',
          data: {'body': response.body, 'error': e.toString()},
        );
        errorMessage = 'API Error: ${response.statusCode} - ${response.body}';
      }

      // Handle specific error cases
      if (response.statusCode == 401) {
        _debugService.warning(
          'Authentication failed - token may be expired',
          category: 'auth',
          data: {'statusCode': response.statusCode, 'message': errorMessage},
        );
        // Clear auth token on 401 errors
        authToken = null;
      }

      _debugService.error(
        'API request failed',
        category: 'api',
        data: {
          'statusCode': response.statusCode,
          'message': errorMessage,
          'body': response.body,
        },
      );

      throw Exception(errorMessage);
    }
  }

  // Authentication methods

  /// Login user with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _debugService.logAuthEvent('Login attempt', data: {'email': email});

      final url = _buildUrl('${ApiConfig.authEndpoint}/login');
      final body = json.encode({'email': email, 'password': password});

      final response = await _makeRequest(
        'POST',
        url,
        _getHeaders(includeAuth: false),
        body: body,
      );

      final result = _handleResponse(response) as Map<String, dynamic>;

      _debugService.logAuthEvent('Login successful', data: {'email': email});

      return result;
    } on Exception catch (e) {
      _debugService.error(
        'Login failed',
        category: 'auth',
        data: {'email': email, 'error': e.toString()},
      );
      if (kDebugMode) {
        print('Login error: $e');
      }
      rethrow;
    }
  }

  /// Register new user with email, password and optional display name
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final url = _buildUrl('${ApiConfig.authEndpoint}/register');
      final body = json.encode({
        'email': email,
        'password': password,
        if (displayName != null) 'display_name': displayName,
      });

      final response = await _makeRequest(
        'POST',
        url,
        _getHeaders(includeAuth: false),
        body: body,
      );

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Register error: $e');
      }
      rethrow;
    }
  }

  /// Get current authenticated user profile
  Future<User> getCurrentUser() async {
    try {
      final url = _buildUrl('${ApiConfig.authEndpoint}/me');
      if (kDebugMode) {
        print('GetCurrentUser request URL: $url');
      }

      final response = await _makeRequest('GET', url, _getHeaders());

      final data = _handleResponse(response) as Map<String, dynamic>;
      return User.fromJson(data);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('GetCurrentUser error: $e');
      }
      rethrow;
    }
  }

  // Profile methods

  /// Update user profile with provided fields
  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? location,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    try {
      final url = _buildUrl(ApiConfig.updateProfileEndpoint);
      final body = json.encode({
        if (displayName != null) 'display_name': displayName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location,
        if (gender != null) 'gender': gender,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
      });

      if (kDebugMode) {
        print('UpdateProfile request URL: $url');
      }

      final response = await _makeRequest(
        'PUT',
        url,
        _getHeaders(),
        body: body,
      );

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('UpdateProfile error: $e');
      }
      rethrow;
    }
  }

  /// Get user profile statistics
  Future<Map<String, dynamic>> getProfileStats() async {
    try {
      final url = _buildUrl(ApiConfig.profileStatsEndpoint);
      if (kDebugMode) {
        print('GetProfileStats request URL: $url');
      }

      final response = await _makeRequest('GET', url, _getHeaders());

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('GetProfileStats error: $e');
      }
      rethrow;
    }
  }

  // Reports methods

  /// Get reports with optional filtering and pagination
  Future<List<Map<String, dynamic>>> getReports({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? type,
    String? category,
    String? status,
  }) async {
    try {
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

      final response = await _makeRequest('GET', uri.toString(), _getHeaders());

      final result = _handleResponse(response);

      if (result is List) {
        return result.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('GetReports error: $e');
      }
      rethrow;
    }
  }

  /// Get reports created by the current user
  Future<List<Map<String, dynamic>>> getUserReports() async {
    try {
      final url = _buildUrl('/v1/mobile/reports/my/reports');
      final response = await _makeRequest('GET', url, _getHeaders());
      final result = _handleResponse(response);

      if (result is List) {
        return result.cast<Map<String, dynamic>>();
      } else if (result is Map<String, dynamic> && result['data'] != null) {
        return (result['data'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('GetUserReports error: $e');
      }
      rethrow;
    }
  }

  /// Create a new report
  Future<Map<String, dynamic>> createReport(
    Map<String, dynamic> reportData,
  ) async {
    try {
      final url = _buildUrl('/v1/mobile/reports/quick');
      final body = json.encode(reportData);

      final response = await _makeRequest(
        'POST',
        url,
        _getHeaders(),
        body: body,
      );

      final result = _handleResponse(response);
      if (result is Map<String, dynamic>) {
        return result;
      } else {
        throw Exception('Invalid response format');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('CreateReport error: $e');
      }
      rethrow;
    }
  }

  // Media methods

  /// Upload media file
  Future<Map<String, dynamic>> uploadMedia(File file) async {
    try {
      final url = _buildUrl(ApiConfig.uploadMediaEndpoint);

      if (kDebugMode) {
        print('UploadMedia request URL: $url');
        print('UploadMedia file path: ${file.path}');
      }

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_getHeaders());

      // Get file extension to determine content type
      final fileExtension = file.path.split('.').last.toLowerCase();
      String contentType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // Default to JPEG
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType(contentType, ''),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print(
          'UploadMedia response: ${response.statusCode} - ${response.body}',
        );
      }

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('UploadMedia error: $e');
      }
      rethrow;
    }
  }

  /// Delete media file by ID
  Future<void> deleteMedia(String mediaId) async {
    try {
      final url = _buildUrl(
        ApiConfig.deleteMediaEndpoint.replaceAll('{id}', mediaId),
      );

      final response = await _makeRequest('DELETE', url, _getHeaders());

      _handleResponse(response);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('DeleteMedia error: $e');
      }
      rethrow;
    }
  }

  // Account methods

  /// Delete user account with password confirmation
  Future<Map<String, dynamic>> deleteAccount({
    required String password,
    String? reason,
  }) async {
    try {
      final url = _buildUrl(ApiConfig.deleteAccountEndpoint);
      final body = json.encode({
        'password': password,
        if (reason != null) 'reason': reason,
        'confirm_deletion': true,
      });

      final response = await _makeRequest(
        'DELETE',
        url,
        _getHeaders(),
        body: body,
      );

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('DeleteAccount error: $e');
      }
      rethrow;
    }
  }

  /// Request user data download
  Future<Map<String, dynamic>> requestDataDownload() async {
    try {
      final url = _buildUrl(ApiConfig.downloadDataEndpoint);
      final body = json.encode({
        'format': 'json',
        'include_reports': true,
        'include_matches': true,
        'include_analytics': false,
      });

      final response = await _makeRequest(
        'POST',
        url,
        _getHeaders(),
        body: body,
      );

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('RequestDataDownload error: $e');
      }
      rethrow;
    }
  }

  // Categories and other data methods

  /// Get available categories
  Future<List<Map<String, dynamic>>> getCategories({
    bool activeOnly = true,
  }) async {
    try {
      final queryParams = <String, String>{
        'active_only': activeOnly.toString(),
      };
      final uri = Uri.parse(
        _buildUrl(ApiConfig.categoriesEndpoint),
      ).replace(queryParameters: queryParams);

      final response = await _makeRequest('GET', uri.toString(), _getHeaders());

      final result = _handleResponse(response);

      if (result is List) {
        return result.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('GetCategories error: $e');
      }
      rethrow;
    }
  }

  /// Get available colors
  Future<List<Map<String, dynamic>>> getColors({bool activeOnly = true}) async {
    try {
      final queryParams = <String, String>{
        'active_only': activeOnly.toString(),
      };
      final uri = Uri.parse(
        _buildUrl(ApiConfig.colorsEndpoint),
      ).replace(queryParameters: queryParams);

      final response = await _makeRequest('GET', uri.toString(), _getHeaders());

      final result = _handleResponse(response);

      if (result is List) {
        return result.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('GetColors error: $e');
      }
      rethrow;
    }
  }

  /// Get report statistics
  Future<Map<String, dynamic>> getReportsStats() async {
    try {
      final url = _buildUrl('/v1/mobile/stats');
      final response = await _makeRequest('GET', url, _getHeaders());

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('GetReportsStats error: $e');
      }
      rethrow;
    }
  }

  /// Get specific report by ID
  Future<Map<String, dynamic>> getReport(String reportId) async {
    try {
      final url = _buildUrl('${ApiConfig.reportsEndpoint}/$reportId');
      final response = await _makeRequest('GET', url, _getHeaders());

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('GetReport error: $e');
      }
      rethrow;
    }
  }

  /// Get report statistics
  Future<Map<String, dynamic>> getReportStatistics() async => getReportsStats();

  /// Get matches
  Future<List<Map<String, dynamic>>> getMatches({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse(
        _buildUrl('/v1/matches'),
      ).replace(queryParameters: queryParams);

      final response = await _makeRequest('GET', uri.toString(), _getHeaders());

      final result = _handleResponse(response);

      if (result is List) {
        return result.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('GetMatches error: $e');
      }
      rethrow;
    }
  }

  /// Accept a match
  Future<Map<String, dynamic>> acceptMatch(String matchId) async {
    try {
      final url = _buildUrl('/v1/matches/$matchId/accept');
      final response = await _makeRequest('POST', url, _getHeaders());

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('AcceptMatch error: $e');
      }
      rethrow;
    }
  }

  /// Reject a match
  Future<Map<String, dynamic>> rejectMatch(String matchId) async {
    try {
      final url = _buildUrl('/v1/matches/$matchId/reject');
      final response = await _makeRequest('POST', url, _getHeaders());

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('RejectMatch error: $e');
      }
      rethrow;
    }
  }

  /// Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final url = _buildUrl('${ApiConfig.authEndpoint}/forgot-password');
      final body = json.encode({'email': email});

      final response = await _makeRequest(
        'POST',
        url,
        _getHeaders(includeAuth: false),
        body: body,
      );

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('ForgotPassword error: $e');
      }
      rethrow;
    }
  }

  /// Reset password
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      final url = _buildUrl('${ApiConfig.authEndpoint}/reset-password');
      final body = json.encode({'token': token, 'password': password});

      final response = await _makeRequest(
        'POST',
        url,
        _getHeaders(includeAuth: false),
        body: body,
      );

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('ResetPassword error: $e');
      }
      rethrow;
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final url = _buildUrl('${ApiConfig.authEndpoint}/change-password');
      final body = json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
      });

      final response = await _makeRequest(
        'POST',
        url,
        _getHeaders(),
        body: body,
      );

      return _handleResponse(response) as Map<String, dynamic>;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('ChangePassword error: $e');
      }
      rethrow;
    }
  }

  /// Logout user (handles missing logout endpoint gracefully)
  Future<void> logout() async {
    try {
      final url = _buildUrl('${ApiConfig.authEndpoint}/logout');
      await _makeRequest('POST', url, _getHeaders());
      _debugService.info('Server logout successful', category: 'auth');
    } on Exception catch (e) {
      // Handle 404 or other logout errors gracefully
      if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        _debugService.info(
          'Logout endpoint not available - continuing with local logout',
          category: 'auth',
        );
      } else {
        _debugService.warning(
          'Server logout failed - continuing with local logout',
          category: 'auth',
          data: {'error': e.toString()},
        );
      }
      // Continue with local logout even if server logout fails
    } finally {
      // Always clear auth token
      authToken = null;
      _debugService.info('Local logout completed', category: 'auth');
    }
  }
}
