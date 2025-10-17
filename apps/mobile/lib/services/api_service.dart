import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import '../config/api_config.dart';
import '../models/auth_token.dart';
import '../models/user.dart';
import '../models/report.dart';
import '../models/search_models.dart';
import '../models/chat_models.dart';
import '../models/match.dart';
import '../models/notification.dart';
import '../models/media.dart';
import '../core/error/error_handler.dart';
import 'offline_manager.dart';
import 'offline_queue_service.dart';
import 'api_response_handler.dart';

/// API Response wrapper
class ApiResponse {
  final int statusCode;
  final dynamic data;

  ApiResponse({required this.statusCode, required this.data});
}

/// API Service for backend communication with comprehensive error handling
class ApiService {
  String? _accessToken;
  String? _refreshToken;
  final OfflineManager _offlineManager = OfflineManager();
  final ApiResponseHandler _responseHandler = ApiResponseHandler();

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  bool get isAuthenticated => _accessToken != null;
  String? get accessToken => _accessToken;

  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // ========== Generic HTTP Methods ==========

  /// Generic GET request with error handling
  Future<ApiResponse> _get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers ?? _getHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);

      return ApiResponse(
        statusCode: response.statusCode,
        data: response.body.isNotEmpty ? jsonDecode(response.body) : null,
      );
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'GET $endpoint'));
    }
  }

  /// Generic POST request with error handling
  Future<ApiResponse> _post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers ?? _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectionTimeout);

      return ApiResponse(
        statusCode: response.statusCode,
        data: response.body.isNotEmpty ? jsonDecode(response.body) : null,
      );
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'POST $endpoint'));
    }
  }

  /// Generic PATCH request with error handling
  Future<ApiResponse> _patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers ?? _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectionTimeout);

      return ApiResponse(
        statusCode: response.statusCode,
        data: response.body.isNotEmpty ? jsonDecode(response.body) : null,
      );
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'PATCH $endpoint'));
    }
  }

  /// Generic PUT request with error handling
  Future<ApiResponse> _put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers ?? _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectionTimeout);

      return ApiResponse(
        statusCode: response.statusCode,
        data: response.body.isNotEmpty ? jsonDecode(response.body) : null,
      );
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'PUT $endpoint'));
    }
  }

  /// Generic DELETE request with error handling
  Future<ApiResponse> _delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: headers ?? _getHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);

      return ApiResponse(
        statusCode: response.statusCode,
        data: response.body.isNotEmpty ? jsonDecode(response.body) : null,
      );
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'DELETE $endpoint'));
    }
  }

  // ========== Authentication ==========

  /// Register a new user
  Future<AuthToken> register({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    final response = await _post(
      ApiConfig.authRegister,
      body: {
        'email': email,
        'password': password,
        'display_name': displayName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      },
    );

    if (response.statusCode == 201) {
      final token = AuthToken.fromJson(response.data);
      setTokens(token.accessToken, token.refreshToken);
      return token;
    } else {
      throw Exception(
        'Registration failed: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Login user with validation and transformation
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      ApiConfig.authLogin,
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final token = _responseHandler.handleAuthResponse(response.data);
      if (token != null) {
        setTokens(token.accessToken, token.refreshToken);
        return token;
      } else {
        throw Exception('Failed to parse authentication token');
      }
    } else {
      final errorData = _responseHandler.handleErrorResponse(response.data);
      throw Exception(
        'Login failed: ${errorData?['detail'] ?? 'Invalid credentials'}',
      );
    }
  }

  /// Refresh access token
  Future<AuthToken> refreshToken() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await _post(
      ApiConfig.authRefresh,
      body: {'refresh_token': _refreshToken!},
    );

    if (response.statusCode == 200) {
      final token = AuthToken.fromJson(response.data);
      setTokens(token.accessToken, token.refreshToken);
      return token;
    } else {
      clearTokens();
      throw Exception(
        'Token refresh failed: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get current user profile with validation and transformation
  Future<User> getCurrentUser() async {
    final response = await _get(ApiConfig.authMe);

    if (response.statusCode == 200) {
      final user = _responseHandler.handleUserResponse(response.data);
      if (user != null) {
        return user;
      } else {
        throw Exception('Failed to parse user profile');
      }
    } else {
      final errorData = _responseHandler.handleErrorResponse(response.data);
      throw Exception(
        'Failed to get user profile: ${errorData?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Change user password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _post(
      ApiConfig.authChangePassword,
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to change password: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Logout user (invalidate tokens on server)
  Future<void> logout() async {
    try {
      await _post(ApiConfig.authLogout);
    } catch (e) {
      // Don't throw error for logout - tokens will be cleared locally anyway
      debugPrint('Logout request failed: $e');
    } finally {
      clearTokens();
    }
  }

  /// Verify if current token is valid
  Future<bool> verifyToken() async {
    try {
      await getCurrentUser();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Request password reset (if backend supports it)
  Future<void> requestPasswordReset(String email) async {
    final response = await _post(
      '/api/v1/auth/forgot-password',
      body: {'email': email},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to request password reset: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Reset password with token (if backend supports it)
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _post(
      '/api/v1/auth/reset-password',
      body: {'token': token, 'new_password': newPassword},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to reset password: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  // ========== Reports ==========

  /// Get all reports with offline support and validation
  Future<List<Report>> getReports() async {
    return await _offlineManager.executeWithOfflineSupport<List<Report>>(
          'reports_list',
          () async {
            final response = await _get(ApiConfig.reports);

            if (response.statusCode == 200) {
              final reports = _responseHandler.handleReportsResponse(
                response.data,
              );
              return reports;
            } else {
              final errorData = _responseHandler.handleErrorResponse(
                response.data,
              );
              throw Exception(
                'Failed to load reports: ${errorData?['detail'] ?? 'Unknown error'}',
              );
            }
          },
          cacheExpiry: const Duration(minutes: 15),
          cacheTag: 'reports',
        ) ??
        [];
  }

  /// Get user's own reports
  Future<List<Report>> getMyReports() async {
    final response = await _get(ApiConfig.myReports);

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load my reports: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get a specific report by ID
  Future<Report> getReport(String reportId) async {
    final response = await _get('${ApiConfig.reports}/$reportId');

    if (response.statusCode == 200) {
      return Report.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to load report: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Create a new report with offline support and validation
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
    final reportData = {
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

    return await _offlineManager.executeWithOfflineSupport<Report>(
          'create_report_${DateTime.now().millisecondsSinceEpoch}',
          () async {
            final response = await _post(ApiConfig.reports, body: reportData);

            if (response.statusCode == 201) {
              final report = _responseHandler.handleReportResponse(
                response.data,
              );
              if (report != null) {
                return report;
              } else {
                throw Exception('Failed to parse created report');
              }
            } else {
              final errorData = _responseHandler.handleErrorResponse(
                response.data,
              );
              throw Exception(
                'Failed to create report: ${errorData?['detail'] ?? 'Unknown error'}',
              );
            }
          },
          offlineOperationType: OfflineOperationType.createReport,
          offlineData: reportData,
          offlinePriority: OfflineOperationPriority.high,
          cacheExpiry: const Duration(hours: 1),
          cacheTag: 'reports',
        ) ??
        Report(
          id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
          type: type,
          title: title,
          description: description,
          category: category,
          city: city,
          status: 'draft',
          createdAt: DateTime.now(),
          occurredAt: occurredAt,
          colors: colors ?? [],
          locationAddress: locationAddress,
          latitude: latitude,
          longitude: longitude,
          rewardOffered: rewardOffered ?? false,
          media: [],
        );
  }

  /// Update an existing report
  Future<Report> updateReport(
    String reportId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _put(
      '${ApiConfig.reports}/$reportId',
      body: updates,
    );

    if (response.statusCode == 200) {
      return Report.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to update report: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Delete a report
  Future<bool> deleteReport(String reportId) async {
    final response = await _delete('${ApiConfig.reports}/$reportId');

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception(
        'Failed to delete report: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get reports with advanced filtering and pagination
  Future<Map<String, dynamic>> getReportsWithFilters({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? type,
    String? category,
    String? status,
    String? city,
    double? latitude,
    double? longitude,
    double? radiusKm,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? colors,
    bool? rewardOffered,
    String? sortBy = 'created_at',
    String? sortOrder = 'desc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'sort_by': sortBy ?? 'created_at',
      'sort_order': sortOrder ?? 'desc',
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
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }
    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
      if (radiusKm != null) {
        queryParams['radius_km'] = radiusKm.toString();
      }
    }
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }
    if (colors != null && colors.isNotEmpty) {
      queryParams['colors'] = colors.join(',');
    }
    if (rewardOffered != null) {
      queryParams['reward_offered'] = rewardOffered.toString();
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.reports}?$queryString');

    if (response.statusCode == 200) {
      final data = response.data;
      return {
        'reports': (data as List<dynamic>)
            .map((json) => Report.fromJson(json))
            .toList(),
        'pagination': {
          'page': page,
          'page_size': pageSize,
          'total': data.length,
          'has_more': data.length == pageSize,
        },
      };
    } else {
      throw Exception(
        'Failed to load reports: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get nearby reports based on location
  Future<List<Report>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 50,
    String? type,
    String? category,
  }) async {
    final queryParams = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius_km': radiusKm.toString(),
      'limit': limit.toString(),
    };

    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.nearbyReports}?$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load nearby reports: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Resolve a report (mark as resolved)
  Future<bool> resolveReport(String reportId) async {
    final response = await _patch(
      '${ApiConfig.reports}/$reportId/resolve',
      body: {'is_resolved': true},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to resolve report: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get report statistics
  Future<Map<String, dynamic>> getReportStats() async {
    final response = await _get(ApiConfig.reportStats);

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to load report stats: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get report analytics
  Future<Map<String, dynamic>> getReportAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy = 'day',
  }) async {
    final queryParams = <String, String>{'group_by': groupBy ?? 'day'};

    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.reportAnalytics}?$queryString');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to load report analytics: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Create report with media upload
  Future<Report> createReportWithMedia({
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
    List<String>? imagePaths,
    Function(double)? onProgress,
  }) async {
    // Step 1: Create the report
    final report = await createReport(
      type: type,
      title: title,
      description: description,
      category: category,
      city: city,
      occurredAt: occurredAt,
      colors: colors,
      locationAddress: locationAddress,
      latitude: latitude,
      longitude: longitude,
      rewardOffered: rewardOffered,
    );

    // Step 2: Upload images if provided
    if (imagePaths != null && imagePaths.isNotEmpty) {
      try {
        final uploadedUrls = await uploadReportImages(report.id, imagePaths);

        // Update report with media URLs
        final updatedReport = await updateReport(report.id, {
          'media_urls': uploadedUrls,
        });

        return updatedReport;
      } catch (e) {
        debugPrint('Failed to upload images for report: $e');
        // Return the report without images rather than failing completely
        return report;
      }
    }

    return report;
  }

  /// Get user's report statistics
  Future<Map<String, dynamic>> getMyReportStats() async {
    final response = await _get('${ApiConfig.myReports}/stats');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to load my report stats: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Duplicate a report
  Future<Report> duplicateReport(String reportId) async {
    final response = await _post('${ApiConfig.reports}/$reportId/duplicate');

    if (response.statusCode == 201) {
      return Report.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to duplicate report: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Archive a report
  Future<bool> archiveReport(String reportId) async {
    final response = await _patch(
      '${ApiConfig.reports}/$reportId/archive',
      body: {'archived': true},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to archive report: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Restore an archived report
  Future<bool> restoreReport(String reportId) async {
    final response = await _patch(
      '${ApiConfig.reports}/$reportId/restore',
      body: {'archived': false},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to restore report: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  // ========== Enhanced Reports ==========

  /// Upload images for a report
  Future<List<String>> uploadReportImages(
    String reportId,
    List<String> imagePaths,
  ) async {
    final uploadedUrls = <String>[];

    for (final imagePath in imagePaths) {
      try {
        final file = File(imagePath);
        final bytes = await file.readAsBytes();
        final fileName = imagePath.split('/').last;

        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/api/v1/media/upload'),
        );

        request.headers.addAll(_getHeaders());
        request.fields['report_id'] = reportId;
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
            contentType: http_parser.MediaType('image', 'jpeg'),
          ),
        );

        final streamedResponse = await request.send().timeout(
          ApiConfig.connectionTimeout,
        );
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          uploadedUrls.add(data['url'] ?? '');
        } else {
          throw Exception('Failed to upload image: ${response.body}');
        }
      } catch (e) {
        throw Exception(ErrorHandler.handleError(e, context: 'Upload image'));
      }
    }

    return uploadedUrls;
  }

  // ========== Search & Filter ==========

  /// Search reports with comprehensive filtering
  Future<List<Report>> searchReports({
    required SearchFilters filters,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{};

    // Map search filters to backend parameters
    if (filters.search != null && filters.search!.isNotEmpty) {
      queryParams['search'] = filters.search!;
    }
    if (filters.type != null && filters.type!.isNotEmpty) {
      queryParams['type'] = filters.type!;
    }
    if (filters.category != null && filters.category!.isNotEmpty) {
      queryParams['category'] = filters.category!;
    }
    if (filters.status != null && filters.status!.isNotEmpty) {
      queryParams['status'] = filters.status!;
    }

    // Add pagination parameters
    queryParams['page'] = page.toString();
    queryParams['page_size'] = pageSize.toString();

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await _get('${ApiConfig.searchReports}$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['results'] ?? response.data);
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to search reports: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get search suggestions
  Future<List<SearchSuggestion>> getSearchSuggestions(String query) async {
    final response = await _get(
      '${ApiConfig.searchSuggestions}?q=${Uri.encodeComponent(query)}',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => SearchSuggestion.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to get search suggestions: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Perform semantic search
  Future<List<SearchResult>> semanticSearch(String query) async {
    final response = await _post(
      ApiConfig.semanticSearch,
      body: {'query': query},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['results'] ?? response.data;
      return data.map((json) => SearchResult.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to perform semantic search: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get popular searches
  Future<List<SearchSuggestion>> getPopularSearches() async {
    final response = await _get(ApiConfig.popularSearches);

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => SearchSuggestion.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to get popular searches: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get recent searches
  Future<List<SearchSuggestion>> getRecentSearches() async {
    final response = await _get(ApiConfig.recentSearches);

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => SearchSuggestion.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to get recent searches: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Save search query for suggestions
  Future<void> saveSearchQuery(String query) async {
    await _post('${ApiConfig.recentSearches}/save', body: {'query': query});
  }

  /// Get search analytics
  Future<SearchAnalytics> getSearchAnalytics() async {
    final response = await _get('${ApiConfig.searchReports}/analytics');

    if (response.statusCode == 200) {
      return SearchAnalytics.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to get search analytics: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get search trends
  Future<Map<String, dynamic>> getSearchTrends({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await _get(
      '${ApiConfig.searchReports}/trends$queryString',
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to get search trends: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get filter options for UI
  Future<Map<String, List<FilterOption>>> getFilterOptions() async {
    final response = await _get('${ApiConfig.searchReports}/filter-options');

    if (response.statusCode == 200) {
      final data = response.data;
      return {
        'categories':
            (data['categories'] as List<dynamic>?)
                ?.map(
                  (c) => FilterOption(
                    value: c['value'],
                    label: c['label'],
                    count: c['count'],
                  ),
                )
                .toList() ??
            [],
        'cities':
            (data['cities'] as List<dynamic>?)
                ?.map(
                  (c) => FilterOption(
                    value: c['value'],
                    label: c['label'],
                    count: c['count'],
                  ),
                )
                .toList() ??
            [],
        'colors':
            (data['colors'] as List<dynamic>?)
                ?.map(
                  (c) => FilterOption(
                    value: c['value'],
                    label: c['label'],
                    count: c['count'],
                  ),
                )
                .toList() ??
            [],
      };
    } else {
      throw Exception(
        'Failed to get filter options: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Advanced search with complex filters
  Future<List<Report>> advancedSearch({
    required SearchFilters filters,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = filters.toQueryParams();
    queryParams['page'] = page.toString();
    queryParams['page_size'] = pageSize.toString();

    final queryString =
        '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

    final response = await _get(
      '${ApiConfig.searchReports}/advanced$queryString',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['results'] ?? response.data);
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to perform advanced search: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Search by location with radius
  Future<List<Report>> searchByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    SearchFilters? additionalFilters,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius': radiusKm.toString(),
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (additionalFilters != null) {
      queryParams.addAll(additionalFilters.toQueryParams());
    }

    final queryString =
        '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

    final response = await _get(
      '${ApiConfig.searchReports}/location$queryString',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['results'] ?? response.data);
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to search by location: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Search by image similarity
  Future<List<Report>> searchByImage({
    required String imageUrl,
    double threshold = 0.7,
    SearchFilters? additionalFilters,
    int page = 1,
    int pageSize = 20,
  }) async {
    final body = <String, dynamic>{
      'image_url': imageUrl,
      'threshold': threshold,
      'page': page,
      'page_size': pageSize,
    };

    if (additionalFilters != null) {
      body.addAll(additionalFilters.toQueryParams());
    }

    final response = await _post(
      '${ApiConfig.searchReports}/image-similarity',
      body: body,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['results'] ?? response.data);
      return data.map((json) => Report.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to search by image: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  // ========== Chat & Messaging ==========

  /// Get chat conversations
  Future<List<ChatConversation>> getChatConversations() async {
    try {
      final response = await _get('/api/v1/messages/conversations');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ChatConversation.fromJson(json)).toList();
      } else {
        print(
          'Chat conversations API error: ${response.statusCode} - ${response.data}',
        );
        throw Exception(
          'Failed to get chat conversations: ${response.data?['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('Chat conversations API exception: $e');
      rethrow;
    }
  }

  /// Get chat messages for a conversation
  Future<List<ChatMessage>> getChatMessages(String conversationId) async {
    final response = await _get(
      '/api/v1/messages/conversations/$conversationId/messages',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to get chat messages: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Create new chat conversation
  Future<ChatConversation> createChatConversation({
    required String participantId,
    String? matchId,
    String? reportId,
  }) async {
    final response = await _post(
      '/api/v1/messages/conversations',
      body: {
        'participant_id': participantId,
        'match_id': matchId,
        'report_id': reportId,
      },
    );

    if (response.statusCode == 201) {
      return ChatConversation.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to create conversation: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get chat notifications
  Future<List<ChatNotification>> getChatNotifications() async {
    try {
      final response = await _get('/api/v1/notifications/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ChatNotification.fromJson(json)).toList();
      } else {
        print(
          'Chat notifications API error: ${response.statusCode} - ${response.data}',
        );
        throw Exception(
          'Failed to get chat notifications: ${response.data?['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('Chat notifications API exception: $e');
      rethrow;
    }
  }

  // ========== Geographic Features ==========

  /// Get nearby reports within radius
  /// Calculate distance between two points (local calculation)
  double calculateDistanceLocal(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // ========== User Profile ==========

  /// Update user profile
  Future<User> updateProfile(Map<String, dynamic> updates) async {
    final response = await _put(ApiConfig.authUpdateProfile, body: updates);

    if (response.statusCode == 200) {
      return User.fromJson(response.data['user']);
    } else {
      throw Exception(
        'Failed to update profile: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Upload user avatar
  Future<String> uploadAvatar(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final fileName = imagePath.split('/').last;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usersMeAvatar}'),
      );

      request.headers.addAll(_getHeaders());
      request.files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: fileName,
          contentType: http_parser.MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send().timeout(
        ApiConfig.connectionTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['avatar_url'] ?? '';
      } else {
        throw Exception('Failed to upload avatar: ${response.body}');
      }
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'Upload avatar'));
    }
  }

  /// Get user profile statistics
  Future<Map<String, dynamic>> getUserStats() async {
    final response = await _get(ApiConfig.usersMeStats);

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to load user stats: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    final response = await _get(ApiConfig.usersMePreferences);

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to load user preferences: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Update user preferences
  Future<Map<String, dynamic>> updateUserPreferences(
    Map<String, dynamic> preferences,
  ) async {
    final response = await _put(
      ApiConfig.usersMePreferences,
      body: preferences,
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to update user preferences: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get user activity log
  Future<List<Map<String, dynamic>>> getUserActivity({
    int page = 1,
    int pageSize = 20,
    String? activityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (activityType != null && activityType.isNotEmpty) {
      queryParams['activity_type'] = activityType;
    }
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.usersMeActivity}?$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to load user activity: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get user's reports with pagination
  Future<Map<String, dynamic>> getUserReports({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? type,
    String? sortBy = 'created_at',
    String? sortOrder = 'desc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'sort_by': sortBy ?? 'created_at',
      'sort_order': sortOrder ?? 'desc',
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.usersMeReports}?$queryString');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to load user reports: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get user's matches
  Future<List<Map<String, dynamic>>> getUserMatches({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? sortBy = 'created_at',
    String? sortOrder = 'desc',
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'sort_by': sortBy ?? 'created_at',
      'sort_order': sortOrder ?? 'desc',
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.usersMeMatches}?$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to load user matches: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get user's notifications
  Future<List<Map<String, dynamic>>> getUserNotifications({
    int page = 1,
    int pageSize = 20,
    bool? unreadOnly,
    String? type,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (unreadOnly != null) {
      queryParams['unread_only'] = unreadOnly.toString();
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get(
      '${ApiConfig.usersMeNotifications}?$queryString',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to load user notifications: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get user settings
  Future<Map<String, dynamic>> getUserSettings() async {
    final response = await _get(ApiConfig.usersMeSettings);

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to load user settings: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Update user settings
  Future<Map<String, dynamic>> updateUserSettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await _put(ApiConfig.usersMeSettings, body: settings);

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to update user settings: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Delete user account
  Future<bool> deleteUserAccount({
    required String password,
    String? reason,
  }) async {
    final response = await _post(
      '${ApiConfig.usersMe}/delete',
      body: {'password': password, if (reason != null) 'reason': reason},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to delete user account: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Export user data
  Future<Map<String, dynamic>> exportUserData({
    String? format = 'json',
    bool includeReports = true,
    bool includeMatches = true,
    bool includeMessages = true,
    bool includeNotifications = true,
  }) async {
    final queryParams = <String, String>{
      'format': format ?? 'json',
      'include_reports': includeReports.toString(),
      'include_matches': includeMatches.toString(),
      'include_messages': includeMessages.toString(),
      'include_notifications': includeNotifications.toString(),
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.usersMe}/export?$queryString');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to export user data: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Update user profile with validation
  Future<User> updateProfileWithValidation({
    required String displayName,
    String? phoneNumber,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    // Validate input
    if (displayName.trim().isEmpty) {
      throw Exception('Display name cannot be empty');
    }

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Basic phone number validation
      if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phoneNumber)) {
        throw Exception('Invalid phone number format');
      }
    }

    final updates = <String, dynamic>{'display_name': displayName.trim()};

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      updates['phone_number'] = phoneNumber.trim();
    }
    if (bio != null && bio.isNotEmpty) {
      updates['bio'] = bio.trim();
    }
    if (preferences != null) {
      updates['preferences'] = preferences;
    }

    return await updateProfile(updates);
  }

  // ========== Messages ==========

  /// Get conversations
  Future<List<Map<String, dynamic>>> getConversations() async {
    final response = await _get(ApiConfig.conversations);

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to load conversations: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get messages for a conversation
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final response = await _get(
      '${ApiConfig.messages}/$conversationId/messages',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to load messages: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Send a message
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final response = await _post(
      '${ApiConfig.messages}/$conversationId/messages',
      body: {'content': content},
    );

    if (response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception(
        'Failed to send message: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Create a new conversation
  Future<Map<String, dynamic>> createConversation(String participantId) async {
    final response = await _post(
      ApiConfig.conversationCreate,
      body: {'participant_id': participantId},
    );

    if (response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception(
        'Failed to create conversation: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get conversation details
  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    final response = await _get(
      '${ApiConfig.conversationDetail}/$conversationId',
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to load conversation: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get messages for a conversation with pagination
  Future<List<Map<String, dynamic>>> getConversationMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get(
      '${ApiConfig.conversationMessages}/$conversationId/messages?$queryString',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to load messages: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Mark a message as read
  Future<Map<String, dynamic>> markMessageAsRead(String messageId) async {
    final response = await _patch('${ApiConfig.messageRead}/$messageId/read');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to mark message as read: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Mark all messages in a conversation as read
  Future<bool> markConversationAsRead(String conversationId) async {
    final response = await _patch(
      '${ApiConfig.conversationRead}/$conversationId/read',
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to mark conversation as read: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Archive a conversation
  Future<bool> archiveConversation(String conversationId) async {
    final response = await _patch(
      '${ApiConfig.conversationArchive}/$conversationId/archive',
      body: {'archived': true},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to archive conversation: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Unarchive a conversation
  Future<bool> unarchiveConversation(String conversationId) async {
    final response = await _patch(
      '${ApiConfig.conversationArchive}/$conversationId/archive',
      body: {'archived': false},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to unarchive conversation: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    final response = await _delete(
      '${ApiConfig.conversationDelete}/$conversationId',
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception(
        'Failed to delete conversation: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String messageId) async {
    final response = await _delete('${ApiConfig.messageDelete}/$messageId');

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception(
        'Failed to delete message: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Mute a conversation
  Future<bool> muteConversation(String conversationId) async {
    final response = await _patch(
      '${ApiConfig.conversationMute}/$conversationId/mute',
      body: {'muted': true},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to mute conversation: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Unmute a conversation
  Future<bool> unmuteConversation(String conversationId) async {
    final response = await _patch(
      '${ApiConfig.conversationMute}/$conversationId/mute',
      body: {'muted': false},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to unmute conversation: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Block a user in conversation
  Future<bool> blockUserInConversation(String conversationId) async {
    final response = await _patch(
      '${ApiConfig.conversationBlock}/$conversationId/block',
      body: {'blocked': true},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to block user: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Unblock a user in conversation
  Future<bool> unblockUserInConversation(String conversationId) async {
    final response = await _patch(
      '${ApiConfig.conversationBlock}/$conversationId/block',
      body: {'blocked': false},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to unblock user: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get conversation statistics
  Future<Map<String, dynamic>> getConversationStats() async {
    final response = await _get('${ApiConfig.conversations}/stats');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to load conversation stats: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Search messages
  Future<List<Map<String, dynamic>>> searchMessages({
    required String query,
    String? conversationId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'q': query,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (conversationId != null && conversationId.isNotEmpty) {
      queryParams['conversation_id'] = conversationId;
    }
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.messages}/search?$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to search messages: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get message by ID
  Future<Map<String, dynamic>> getMessage(String messageId) async {
    final response = await _get('${ApiConfig.messages}/$messageId');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to load message: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Update message content
  Future<Map<String, dynamic>> updateMessage(
    String messageId,
    String content,
  ) async {
    final response = await _put(
      '${ApiConfig.messages}/$messageId',
      body: {'content': content},
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to update message: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Send message with media attachment
  Future<Map<String, dynamic>> sendMessageWithMedia({
    required String conversationId,
    required String content,
    List<String>? imagePaths,
    List<String>? filePaths,
  }) async {
    // For now, just send the text content
    // Media attachment would require multipart form data
    return await sendMessage(conversationId: conversationId, content: content);
  }

  /// Get conversation participants
  Future<List<Map<String, dynamic>>> getConversationParticipants(
    String conversationId,
  ) async {
    final response = await _get(
      '${ApiConfig.conversationDetail}/$conversationId/participants',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to load participants: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Add participant to conversation (for group chats)
  Future<bool> addParticipantToConversation(
    String conversationId,
    String participantId,
  ) async {
    final response = await _post(
      '${ApiConfig.conversationDetail}/$conversationId/participants',
      body: {'participant_id': participantId},
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      throw Exception(
        'Failed to add participant: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Remove participant from conversation
  Future<bool> removeParticipantFromConversation(
    String conversationId,
    String participantId,
  ) async {
    final response = await _delete(
      '${ApiConfig.conversationDetail}/$conversationId/participants/$participantId',
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception(
        'Failed to remove participant: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  // ========== Location Service ==========

  /// Geocode an address to coordinates
  Future<Map<String, dynamic>> geocodeAddress(String address) async {
    final response = await _get(
      '${ApiConfig.locationGeocode}?address=${Uri.encodeComponent(address)}',
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to geocode address: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Reverse geocode coordinates to address
  Future<Map<String, dynamic>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _get(
      '${ApiConfig.locationReverseGeocode}?lat=$latitude&lng=$longitude',
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to reverse geocode: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Search for locations
  Future<List<Map<String, dynamic>>> searchLocations({
    required String query,
    String? country,
    String? city,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{'q': query, 'limit': limit.toString()};

    if (country != null && country.isNotEmpty) {
      queryParams['country'] = country;
    }
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }
    if (latitude != null) {
      queryParams['lat'] = latitude.toString();
    }
    if (longitude != null) {
      queryParams['lng'] = longitude.toString();
    }
    if (radiusKm != null) {
      queryParams['radius'] = radiusKm.toString();
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.locationSearch}?$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to search locations: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get nearby locations
  Future<List<Map<String, dynamic>>> getNearbyLocations({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? type,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      'radius': radiusKm.toString(),
      'limit': limit.toString(),
    };

    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.locationNearby}?$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to get nearby locations: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get location autocomplete suggestions
  Future<List<Map<String, dynamic>>> getLocationAutocomplete({
    required String query,
    String? country,
    String? city,
    int limit = 5,
  }) async {
    final queryParams = <String, String>{'q': query, 'limit': limit.toString()};

    if (country != null && country.isNotEmpty) {
      queryParams['country'] = country;
    }
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get(
      '${ApiConfig.locationAutocomplete}?$queryString',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to get autocomplete suggestions: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get detailed location information
  Future<Map<String, dynamic>> getLocationDetails(String placeId) async {
    final response = await _get('${ApiConfig.locationDetails}/$placeId');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to get location details: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Calculate distance between two points
  Future<Map<String, dynamic>> calculateDistance({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
    String unit = 'km',
  }) async {
    final queryParams = <String, String>{
      'from_lat': fromLatitude.toString(),
      'from_lng': fromLongitude.toString(),
      'to_lat': toLatitude.toString(),
      'to_lng': toLongitude.toString(),
      'unit': unit,
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.locationDistance}?$queryString');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to calculate distance: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get location bounds for a region
  Future<Map<String, dynamic>> getLocationBounds({
    required String query,
    String? country,
  }) async {
    final queryParams = <String, String>{'q': query};

    if (country != null && country.isNotEmpty) {
      queryParams['country'] = country;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.locationBounds}?$queryString');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to get location bounds: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Validate location coordinates
  Future<bool> validateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final queryParams = <String, String>{
      'lat': latitude.toString(),
      'lng': longitude.toString(),
    };

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.locationValidate}?$queryString');

    if (response.statusCode == 200) {
      return response.data['valid'] as bool? ?? false;
    } else {
      throw Exception(
        'Failed to validate location: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get user's location history
  Future<List<Map<String, dynamic>>> getLocationHistory({
    int page = 1,
    int pageSize = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await _get('${ApiConfig.locationHistory}?$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception(
        'Failed to get location history: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Save location to history
  Future<bool> saveLocationToHistory({
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? country,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _post(
      ApiConfig.locationHistory,
      body: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (metadata != null) 'metadata': metadata,
      },
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      throw Exception(
        'Failed to save location: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get current user's location
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final response = await _get('${ApiConfig.locationHistory}/current');

      if (response.statusCode == 200) {
        return response.data;
      } else if (response.statusCode == 404) {
        return null; // No current location
      } else {
        throw Exception(
          'Failed to get current location: ${response.data?['detail'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  /// Update current user's location
  Future<bool> updateCurrentLocation({
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? country,
  }) async {
    final response = await _put(
      '${ApiConfig.locationHistory}/current',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
        'Failed to update current location: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Clear location history
  Future<bool> clearLocationHistory() async {
    final response = await _delete(ApiConfig.locationHistory);

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception(
        'Failed to clear location history: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get location statistics
  Future<Map<String, dynamic>> getLocationStats() async {
    final response = await _get('${ApiConfig.locationHistory}/stats');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(
        'Failed to get location stats: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get matches for a specific report
  Future<List<MatchCandidate>> getMatchesForReport(
    String reportId, {
    int maxResults = 20,
  }) async {
    final response = await _get(
      '${ApiConfig.matchesReport}/$reportId?max_results=$maxResults',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => MatchCandidate.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to get matches: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Confirm a match
  Future<MatchCandidate> confirmMatch(String matchId, {String? notes}) async {
    final response = await _post(
      '${ApiConfig.matchesConfirm}/$matchId/confirm',
      body: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );

    if (response.statusCode == 200) {
      return MatchCandidate.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to confirm match: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Reject a match
  Future<MatchCandidate> rejectMatch(String matchId, {String? reason}) async {
    final response = await _post(
      '${ApiConfig.matchesConfirm}/$matchId/reject',
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );

    if (response.statusCode == 200) {
      return MatchCandidate.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to reject match: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get match analytics for dashboard
  Future<MatchAnalytics> getMatchAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};

    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await _get(
      '${ApiConfig.matchesAnalytics}/analytics$queryString',
    );

    if (response.statusCode == 200) {
      return MatchAnalytics.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to get match analytics: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get all matches for current user
  Future<List<MatchCandidate>> getAllMatches({
    MatchStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (status != null) {
      queryParams['status'] = status.value;
    }

    final queryString =
        '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

    final response = await _get('${ApiConfig.matches}$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => MatchCandidate.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to get all matches: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get match details by ID
  Future<MatchCandidate> getMatchDetails(String matchId) async {
    final response = await _get('${ApiConfig.matches}/$matchId');

    if (response.statusCode == 200) {
      return MatchCandidate.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to get match details: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Update match notes
  Future<MatchCandidate> updateMatchNotes(String matchId, String notes) async {
    final response = await _put(
      '${ApiConfig.matches}/$matchId',
      body: {'notes': notes},
    );

    if (response.statusCode == 200) {
      return MatchCandidate.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to update match notes: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  // ========== Notifications Service ==========

  /// Get user notifications
  Future<List<AppNotification>> getNotifications({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (unreadOnly) 'unread_only': 'true',
    };

    final queryString =
        '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

    final response = await _get('${ApiConfig.notifications}$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to get notifications: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final response = await _post(
      '${ApiConfig.notifications}/$notificationId/read',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to mark notification as read: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final response = await _post('${ApiConfig.notifications}/read-all');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to mark all notifications as read: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    final response = await _get('${ApiConfig.notifications}/unread-count');

    if (response.statusCode == 200) {
      return response.data['unread_count'] ?? 0;
    } else {
      throw Exception(
        'Failed to get unread count: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    final response = await _delete(
      '${ApiConfig.notifications}/$notificationId',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete notification: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get notification statistics
  Future<NotificationStats> getNotificationStats() async {
    final response = await _get('${ApiConfig.notifications}/stats');

    if (response.statusCode == 200) {
      return NotificationStats.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to get notification stats: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  // ========== Media Service ==========

  /// Upload single media file
  Future<Media> uploadMedia({
    required String filePath,
    String? reportId,
    Function(double)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final fileName = filePath.split('/').last;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.mediaUpload}'),
      );

      request.headers.addAll(_getHeaders());
      if (reportId != null) {
        request.fields['report_id'] = reportId;
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: http_parser.MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send().timeout(
        ApiConfig.connectionTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Media.fromJson(data);
      } else {
        throw Exception('Failed to upload media: ${response.body}');
      }
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e, context: 'Upload media'));
    }
  }

  /// Upload multiple media files
  Future<List<Media>> uploadMultipleMedia({
    required List<String> filePaths,
    String? reportId,
    Function(int, double)? onProgress,
  }) async {
    final List<Media> uploadedMedia = [];

    for (int i = 0; i < filePaths.length; i++) {
      try {
        onProgress?.call(i, (i / filePaths.length));

        final media = await uploadMedia(
          filePath: filePaths[i],
          reportId: reportId,
        );
        uploadedMedia.add(media);
      } catch (e) {
        throw Exception(
          'Failed to upload file ${filePaths[i]}: ${e.toString()}',
        );
      }
    }

    onProgress?.call(filePaths.length, 1.0);
    return uploadedMedia;
  }

  /// Get media by ID
  Future<Media> getMedia(String mediaId) async {
    final response = await _get('${ApiConfig.media}/$mediaId');

    if (response.statusCode == 200) {
      return Media.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to get media: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// List media files
  Future<List<Media>> listMedia({String? reportId}) async {
    final queryParams = <String, String>{};
    if (reportId != null) {
      queryParams['report_id'] = reportId;
    }

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await _get('${ApiConfig.media}$queryString');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Media.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to list media: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Delete media file
  Future<void> deleteMedia(String mediaId) async {
    final response = await _delete('${ApiConfig.media}/$mediaId');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete media: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get media statistics
  Future<MediaStats> getMediaStats() async {
    final response = await _get('${ApiConfig.media}/stats');

    if (response.statusCode == 200) {
      return MediaStats.fromJson(response.data);
    } else {
      throw Exception(
        'Failed to get media stats: ${response.data?['detail'] ?? 'Unknown error'}',
      );
    }
  }

  /// Get media URLs for a report (legacy method for compatibility)
  Future<List<String>> getMediaUrlsForReport(String reportId) async {
    try {
      final mediaList = await listMedia(reportId: reportId);
      return mediaList.map((media) => media.url).toList();
    } catch (e) {
      throw Exception(
        ErrorHandler.handleError(e, context: 'Get media URLs for report'),
      );
    }
  }

  /// Upload images for report (legacy method for compatibility)
  Future<List<String>> uploadImagesForReport({
    required String reportId,
    required List<String> imagePaths,
  }) async {
    try {
      final mediaList = await uploadMultipleMedia(
        filePaths: imagePaths,
        reportId: reportId,
      );
      return mediaList.map((media) => media.url).toList();
    } catch (e) {
      throw Exception(
        ErrorHandler.handleError(e, context: 'Upload images for report'),
      );
    }
  }
}
