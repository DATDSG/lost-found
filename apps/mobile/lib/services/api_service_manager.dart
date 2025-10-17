import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_token.dart';
import '../models/user.dart';
import '../models/report.dart';
import '../models/chat_models.dart';
import '../models/media.dart';
import 'api_request_builder.dart';
import 'api_response_interceptor.dart';
import 'storage_service.dart';

/// API service manager that coordinates all API operations
class ApiServiceManager {
  static final ApiServiceManager _instance = ApiServiceManager._internal();
  factory ApiServiceManager() => _instance;
  ApiServiceManager._internal();

  final ApiRequestBuilder _requestBuilder = ApiRequestBuilder();
  final ApiResponseInterceptor _responseInterceptor = ApiResponseInterceptor();
  final StorageService _storageService = StorageService();

  String? _accessToken;
  String? _refreshToken;

  /// Initialize the API service manager
  Future<void> initialize() async {
    try {
      // Load stored tokens from AuthToken
      final token = await _storageService.getToken();
      if (token != null) {
        _accessToken = token.accessToken;
        _refreshToken = token.refreshToken;
      }

      if (kDebugMode) {
        debugPrint('✅ API Service Manager initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to initialize API Service Manager: $e');
      }
    }
  }

  /// Set authentication tokens
  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    // Store tokens as AuthToken object
    final token = AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: 'Bearer',
    );
    _storageService.saveToken(token);
  }

  /// Clear authentication tokens
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;

    // Clear stored tokens
    _storageService.clearTokens();
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null;

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Get current refresh token
  String? get refreshToken => _refreshToken;

  // ==================== AUTHENTICATION METHODS ====================

  /// Register new user
  Future<AuthToken> register({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    final data = {
      'email': email,
      'password': password,
      'display_name': displayName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };

    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: ApiConfig.authRegister,
        method: HttpMethod.post,
        body: data,
        requiresAuth: false,
        validateInput: true,
      ),
    );

    if (response.statusCode == 201) {
      final token = await _responseInterceptor.processResponseData<AuthToken>(
        response,
        'auth_token',
      );
      if (token != null) {
        setTokens(token.accessToken, token.refreshToken);
        return token;
      } else {
        throw Exception('Failed to parse authentication token');
      }
    } else {
      throw _handleErrorResponse(response, 'Registration failed');
    }
  }

  /// Login user
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    final data = {'email': email, 'password': password};

    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: ApiConfig.authLogin,
        method: HttpMethod.post,
        body: data,
        requiresAuth: false,
        validateInput: true,
      ),
    );

    if (response.statusCode == 200) {
      final token = await _responseInterceptor.processResponseData<AuthToken>(
        response,
        'auth_token',
      );
      if (token != null) {
        setTokens(token.accessToken, token.refreshToken);
        return token;
      } else {
        throw Exception('Failed to parse authentication token');
      }
    } else {
      throw _handleErrorResponse(response, 'Login failed');
    }
  }

  /// Refresh authentication token
  Future<AuthToken> refreshAuthToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final data = {'refresh_token': _refreshToken};

    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: ApiConfig.authRefresh,
        method: HttpMethod.post,
        body: data,
        requiresAuth: false,
        validateInput: true,
      ),
    );

    if (response.statusCode == 200) {
      final token = await _responseInterceptor.processResponseData<AuthToken>(
        response,
        'auth_token',
      );
      if (token != null) {
        setTokens(token.accessToken, token.refreshToken);
        return token;
      } else {
        throw Exception('Failed to parse authentication token');
      }
    } else {
      throw _handleErrorResponse(response, 'Token refresh failed');
    }
  }

  /// Get current user profile
  Future<User> getCurrentUser() async {
    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: ApiConfig.authMe,
        method: HttpMethod.get,
        requiresAuth: true,
      ),
    );

    if (response.statusCode == 200) {
      final user = await _responseInterceptor.processResponseData<User>(
        response,
        'user',
      );
      if (user != null) {
        return user;
      } else {
        throw Exception('Failed to parse user profile');
      }
    } else {
      throw _handleErrorResponse(response, 'Failed to get user profile');
    }
  }

  /// Update user profile
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: ApiConfig.authUpdateProfile,
        method: HttpMethod.patch,
        body: data,
        requiresAuth: true,
        validateInput: true,
      ),
    );

    if (response.statusCode == 200) {
      final user = await _responseInterceptor.processResponseData<User>(
        response,
        'user',
      );
      if (user != null) {
        return user;
      } else {
        throw Exception('Failed to parse updated user profile');
      }
    } else {
      throw _handleErrorResponse(response, 'Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final data = {
      'current_password': currentPassword,
      'new_password': newPassword,
    };

    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: ApiConfig.authChangePassword,
        method: HttpMethod.post,
        body: data,
        requiresAuth: true,
        validateInput: true,
      ),
    );

    if (response.statusCode != 200) {
      throw _handleErrorResponse(response, 'Failed to change password');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      final response = await _executeRequest(
        ApiRequestConfig(
          endpoint: ApiConfig.authLogout,
          method: HttpMethod.post,
          requiresAuth: true,
        ),
      );

      if (response.statusCode != 200) {
        throw _handleErrorResponse(response, 'Logout failed');
      }
    } finally {
      // Always clear tokens locally
      clearTokens();
    }
  }

  // ==================== REPORTS METHODS ====================

  /// Get all reports
  Future<List<Report>> getReports({
    Map<String, dynamic>? filters,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = {
      'page': page,
      'page_size': pageSize,
      if (filters != null) ...filters,
    };

    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: ApiConfig.reports,
        method: HttpMethod.get,
        queryParams: queryParams,
        requiresAuth: true,
      ),
    );

    if (response.statusCode == 200) {
      final reports = await _responseInterceptor
          .processResponseData<List<Report>>(response, 'reports_list');
      return reports ?? [];
    } else {
      throw _handleErrorResponse(response, 'Failed to load reports');
    }
  }

  /// Create new report
  Future<Report> createReport({
    required String type,
    required String title,
    required String description,
    required String category,
    required String city,
    required DateTime occurredAt,
    List<String>? colors,
    String? locationAddress,
    double? latitude,
    double? longitude,
    bool? rewardOffered,
  }) async {
    final data = {
      'type': type,
      'title': title,
      'description': description,
      'category': category,
      'city': city,
      'occurred_at': occurredAt.toIso8601String(),
      if (colors != null) 'colors': colors,
      if (locationAddress != null) 'location_address': locationAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (rewardOffered != null) 'reward_offered': rewardOffered,
    };

    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: ApiConfig.reports,
        method: HttpMethod.post,
        body: data,
        requiresAuth: true,
        validateInput: true,
      ),
    );

    if (response.statusCode == 201) {
      final report = await _responseInterceptor.processResponseData<Report>(
        response,
        'report',
      );
      if (report != null) {
        return report;
      } else {
        throw Exception('Failed to parse created report');
      }
    } else {
      throw _handleErrorResponse(response, 'Failed to create report');
    }
  }

  /// Get report by ID
  Future<Report> getReport(String reportId) async {
    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: '${ApiConfig.reports}/$reportId',
        method: HttpMethod.get,
        requiresAuth: true,
      ),
    );

    if (response.statusCode == 200) {
      final report = await _responseInterceptor.processResponseData<Report>(
        response,
        'report',
      );
      if (report != null) {
        return report;
      } else {
        throw Exception('Failed to parse report');
      }
    } else {
      throw _handleErrorResponse(response, 'Failed to get report');
    }
  }

  /// Update report
  Future<Report> updateReport(
    String reportId,
    Map<String, dynamic> data,
  ) async {
    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: '${ApiConfig.reports}/$reportId',
        method: HttpMethod.patch,
        body: data,
        requiresAuth: true,
        validateInput: true,
      ),
    );

    if (response.statusCode == 200) {
      final report = await _responseInterceptor.processResponseData<Report>(
        response,
        'report',
      );
      if (report != null) {
        return report;
      } else {
        throw Exception('Failed to parse updated report');
      }
    } else {
      throw _handleErrorResponse(response, 'Failed to update report');
    }
  }

  /// Delete report
  Future<void> deleteReport(String reportId) async {
    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: '${ApiConfig.reports}/$reportId',
        method: HttpMethod.delete,
        requiresAuth: true,
      ),
    );

    if (response.statusCode != 204) {
      throw _handleErrorResponse(response, 'Failed to delete report');
    }
  }

  // ==================== MESSAGING METHODS ====================

  /// Get conversations
  Future<List<ChatConversation>> getConversations({
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = {'page': page, 'page_size': pageSize};

    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: ApiConfig.conversations,
        method: HttpMethod.get,
        queryParams: queryParams,
        requiresAuth: true,
      ),
    );

    if (response.statusCode == 200) {
      final conversations = await _responseInterceptor
          .processResponseData<List<ChatConversation>>(
            response,
            'conversations_list',
          );
      return conversations ?? [];
    } else {
      throw _handleErrorResponse(response, 'Failed to load conversations');
    }
  }

  /// Get messages for conversation
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParams = {'page': page, 'page_size': pageSize};

    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: '${ApiConfig.conversations}/$conversationId/messages',
        method: HttpMethod.get,
        queryParams: queryParams,
        requiresAuth: true,
      ),
    );

    if (response.statusCode == 200) {
      final messages = await _responseInterceptor
          .processResponseData<List<ChatMessage>>(response, 'messages_list');
      return messages ?? [];
    } else {
      throw _handleErrorResponse(response, 'Failed to load messages');
    }
  }

  /// Send message
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final data = {'conversation_id': conversationId, 'content': content};

    final response = await _executeRequest(
      ApiRequestConfig(
        endpoint: ApiConfig.messagesCreate,
        method: HttpMethod.post,
        body: data,
        requiresAuth: true,
        validateInput: true,
      ),
    );

    if (response.statusCode == 201) {
      final message = await _responseInterceptor
          .processResponseData<ChatMessage>(response, 'message');
      if (message != null) {
        return message;
      } else {
        throw Exception('Failed to parse sent message');
      }
    } else {
      throw _handleErrorResponse(response, 'Failed to send message');
    }
  }

  // ==================== MEDIA METHODS ====================

  /// Upload media file
  Future<Media> uploadMedia({
    required File file,
    required String reportId,
    String? fileType,
  }) async {
    final fields = {
      'report_id': reportId,
      if (fileType != null) 'file_type': fileType,
    };

    final files = {'file': file};

    final request = await _requestBuilder.buildMultipartRequest(
      endpoint: ApiConfig.mediaUpload,
      fields: fields,
      files: files,
      requiresAuth: true,
    );

    // Add authorization header
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    final response = await _responseInterceptor.interceptResponse(
      () => request.send().then(
        (streamedResponse) => http.Response.fromStream(streamedResponse),
      ),
      const ResponseInterceptorConfig(),
    );

    if (response.statusCode == 201) {
      final media = await _responseInterceptor.processResponseData<Media>(
        response,
        'media',
      );
      if (media != null) {
        return media;
      } else {
        throw Exception('Failed to parse uploaded media');
      }
    } else {
      throw _handleErrorResponse(response, 'Failed to upload media');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Execute API request with full processing
  Future<http.Response> _executeRequest(ApiRequestConfig config) async {
    // Add authorization header if required
    if (config.requiresAuth && _accessToken != null) {
      config = ApiRequestConfig(
        endpoint: config.endpoint,
        method: config.method,
        headers: {...?config.headers, 'Authorization': 'Bearer $_accessToken'},
        queryParams: config.queryParams,
        body: config.body,
        timeout: config.timeout,
        requiresAuth: config.requiresAuth,
        validateInput: config.validateInput,
        contentType: config.contentType,
      );
    }

    // Build request
    final request = await _requestBuilder.buildRequest(config);

    // Execute request with interceptor
    return await _responseInterceptor.interceptResponseWithRetry(
      () => request.send().then(
        (streamedResponse) => http.Response.fromStream(streamedResponse),
      ),
      const ResponseInterceptorConfig(),
    );
  }

  /// Handle error response
  Exception _handleErrorResponse(http.Response response, String context) {
    _responseInterceptor.handleResponseError(response, context);

    try {
      final data = jsonDecode(response.body);
      final message = data['detail'] ?? data['message'] ?? 'Unknown error';
      return Exception('$context: $message');
    } catch (e) {
      return Exception('$context: HTTP ${response.statusCode}');
    }
  }

  /// Get request statistics
  Map<String, dynamic> getRequestStats() {
    return {
      'is_authenticated': isAuthenticated,
      'has_access_token': _accessToken != null,
      'has_refresh_token': _refreshToken != null,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
