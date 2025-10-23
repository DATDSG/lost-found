import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../models/api_models.dart';

/// Main API service for handling all API requests
class ApiService {
  /// Private constructor for singleton pattern
  ApiService._internal() {
    _baseUrl = ApiConfig.baseUrl;
    if (kDebugMode) {
      print('API Service initialized with base URL: $_baseUrl');
    }
  }

  /// Factory constructor for singleton pattern
  factory ApiService() => _instance;

  /// Static instance for singleton pattern
  static final ApiService _instance = ApiService._internal();

  late String _baseUrl;
  String? authToken;

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
            throw Exception('Unsupported HTTP method: $method');
        }

        if (kDebugMode) {
          print('API Response: ${response.statusCode} - ${response.body}');
        }

        return response;
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          if (kDebugMode) {
            print('API Error: $e');
          }
          rethrow;
        }
        await Future<void>.delayed(Duration(seconds: attempts));
      }
    }

    throw Exception('Max retries exceeded');
  }

  /// Handle API response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }
      return json.decode(response.body);
    } else {
      final errorBody = response.body.isNotEmpty
          ? json.decode(response.body) as Map<String, dynamic>
          : <String, dynamic>{'message': 'Unknown error'};
      throw Exception('API Error: ${response.statusCode} - $errorBody');
    }
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = _buildUrl('${ApiConfig.authEndpoint}/login');
      final body = json.encode({'email': email, 'password': password});

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
    } catch (e) {
      if (kDebugMode) {
        print('Register error: $e');
      }
      rethrow;
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final url = _buildUrl('${ApiConfig.authEndpoint}/me');
      if (kDebugMode) {
        print('GetCurrentUser request URL: $url');
      }

      final response = await _makeRequest('GET', url, _getHeaders());

      final data = _handleResponse(response) as Map<String, dynamic>;
      return User.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('GetCurrentUser error: $e');
      }
      rethrow;
    }
  }

  // Profile methods
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
    } catch (e) {
      if (kDebugMode) {
        print('UpdateProfile error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfileStats() async {
    try {
      final url = _buildUrl('/v1/mobile/users/stats');
      if (kDebugMode) {
        print('GetProfileStats request URL: $url');
      }

      final response = await _makeRequest('GET', url, _getHeaders());

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('GetProfileStats error: $e');
      }
      rethrow;
    }
  }

  // Reports methods
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

      return _handleResponse(response) as List<Map<String, dynamic>>;
    } catch (e) {
      if (kDebugMode) {
        print('GetReports error: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserReports() async {
    try {
      final url = _buildUrl('${ApiConfig.reportsEndpoint}/user/my-reports');
      final response = await _makeRequest('GET', url, _getHeaders());
      return _handleResponse(response) as List<Map<String, dynamic>>;
    } catch (e) {
      if (kDebugMode) {
        print('GetUserReports error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createReport(
    Map<String, dynamic> reportData,
  ) async {
    try {
      final url = _buildUrl(ApiConfig.createReportEndpoint);
      final body = json.encode(reportData);

      final response = await _makeRequest(
        'POST',
        url,
        _getHeaders(),
        body: body,
      );

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('CreateReport error: $e');
      }
      rethrow;
    }
  }

  // Media methods
  Future<Map<String, dynamic>> uploadMedia(File file) async {
    try {
      final url = _buildUrl(ApiConfig.uploadMediaEndpoint);

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_getHeaders());
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('UploadMedia error: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteMedia(String mediaId) async {
    try {
      final url = _buildUrl(
        ApiConfig.deleteMediaEndpoint.replaceAll('{id}', mediaId),
      );

      final response = await _makeRequest('DELETE', url, _getHeaders());

      _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('DeleteMedia error: $e');
      }
      rethrow;
    }
  }

  // Privacy and account methods
  Future<Map<String, dynamic>> getPrivacySettings() async {
    try {
      final url = _buildUrl(ApiConfig.privacySettingsEndpoint);
      final response = await _makeRequest('GET', url, _getHeaders());
      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('GetPrivacySettings error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updatePrivacySettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final url = _buildUrl(ApiConfig.privacySettingsEndpoint);
      final body = json.encode(settings);

      final response = await _makeRequest(
        'PUT',
        url,
        _getHeaders(),
        body: body,
      );

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('UpdatePrivacySettings error: $e');
      }
      rethrow;
    }
  }

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
    } catch (e) {
      if (kDebugMode) {
        print('DeleteAccount error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestDataDownload() async {
    try {
      final url = _buildUrl(ApiConfig.downloadDataEndpoint);
      final body = json.encode({
        'format': 'json',
        'include_reports': true,
        'include_matches': true,
        'include_messages': false,
        'include_analytics': false,
      });

      final response = await _makeRequest(
        'POST',
        url,
        _getHeaders(),
        body: body,
      );

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('RequestDataDownload error: $e');
      }
      rethrow;
    }
  }

  // Categories and other data methods
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

      return _handleResponse(response) as List<Map<String, dynamic>>;
    } catch (e) {
      if (kDebugMode) {
        print('GetCategories error: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getColors({bool activeOnly = true}) async {
    try {
      final queryParams = <String, String>{
        'active_only': activeOnly.toString(),
      };
      final uri = Uri.parse(
        _buildUrl(ApiConfig.colorsEndpoint),
      ).replace(queryParameters: queryParams);

      final response = await _makeRequest('GET', uri.toString(), _getHeaders());

      return _handleResponse(response) as List<Map<String, dynamic>>;
    } catch (e) {
      if (kDebugMode) {
        print('GetColors error: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getReportsStats() async {
    try {
      final url = _buildUrl('${ApiConfig.reportsEndpoint}/stats');
      final response = await _makeRequest('GET', url, _getHeaders());

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
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
    } catch (e) {
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

      return _handleResponse(response) as List<Map<String, dynamic>>;
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      if (kDebugMode) {
        print('ChangePassword error: $e');
      }
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      final url = _buildUrl('${ApiConfig.authEndpoint}/logout');
      await _makeRequest('POST', url, _getHeaders());

      // Clear auth token
      authToken = null;
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
      // Clear auth token even if logout fails
      authToken = null;
      rethrow;
    }
  }
}
