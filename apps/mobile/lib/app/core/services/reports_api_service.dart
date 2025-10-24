import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../shared/models/matching_models.dart';
import '../constants/api_config.dart';
import '../exceptions/api_exceptions.dart';

/// API service for handling report-related requests
class ReportsApiService {
  /// Factory constructor for singleton instance
  factory ReportsApiService() => _instance;

  /// Private constructor for singleton pattern
  ReportsApiService._internal();
  static final ReportsApiService _instance = ReportsApiService._internal();

  late String _baseUrl;

  /// Initialize the API service with base URL and auth token
  void initialize({String? baseUrl, String? authToken}) {
    _baseUrl = baseUrl ?? ApiConfig.baseUrl;
    this.authToken = authToken;
    if (kDebugMode) {
      print('ReportsApiService initialized with base URL: $_baseUrl');
      print(
        'ReportsApiService auth token: ${authToken != null ? '${authToken.substring(0, 10)}...' : 'null'}',
      );
    }
  }

  /// Authentication token
  String? authToken;

  /// Build full URL for endpoint
  String _buildUrl(String endpoint) => '$_baseUrl$endpoint';

  /// Get headers for requests
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  /// Get headers for multipart requests
  Map<String, String> _getMultipartHeaders({bool includeAuth = true}) {
    final headers = <String, String>{};

    if (includeAuth && authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  /// Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('Reports API Response: ${response.statusCode} - ${response.body}');
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

  /// Handle HTTP errors
  Exception _handleError(http.Response response) {
    try {
      final errorData = json.decode(response.body) as Map<String, dynamic>;
      final message =
          errorData['message'] ?? errorData['detail'] ?? 'Unknown error';

      if (kDebugMode) {
        print('API Error ${response.statusCode}: $message');
      }

      // Provide user-friendly error messages
      String userMessage;
      switch (response.statusCode) {
        case 401:
          userMessage = 'Authentication required. Please log in again.';
          break;
        case 403:
          userMessage =
              "Access denied. You don't have permission to perform this action.";
          break;
        case 404:
          userMessage = 'The requested data was not found.';
          break;
        case 422:
          userMessage = 'Invalid data provided. Please check your input.';
          break;
        case 500:
          userMessage = 'Server error. Please try again later.';
          break;
        default:
          userMessage = message.toString();
      }

      return ApiException(userMessage, response.statusCode);
    } on FormatException {
      final errorMessage = 'Server error: ${response.statusCode}';
      if (kDebugMode) {
        print('API Error: $errorMessage');
      }
      return ApiException(errorMessage, response.statusCode);
    }
  }

  /// Create a new report
  Future<UserReport> createReport({
    required String title,
    required String description,
    required ReportType type,
    required String category,
    required String location,
    required DateTime occurredAt,
    List<String>? colors,
    bool isUrgent = false,
    bool rewardOffered = false,
    String? rewardAmount,
    List<File>? images,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final url = _buildUrl('/v1/mobile/reports/quick');

      if (kDebugMode) {
        print('Creating report at: $url');
      }

      // Prepare the request data
      final requestData = {
        'title': title,
        'description': description,
        'type': type.name,
        'category': category,
        'location_city': location,
        'occurred_at': occurredAt.toIso8601String(),
        'colors': colors ?? [],
        'is_urgent': isUrgent,
        'reward_offered': rewardOffered,
        'reward_amount': rewardAmount,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      http.Response response;

      if (images != null && images.isNotEmpty) {
        // Use multipart request for file uploads
        final request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers.addAll(_getMultipartHeaders());

        // Add form fields
        requestData.forEach((key, value) {
          if (value is List) {
            request.fields[key] = json.encode(value);
          } else {
            request.fields[key] = value.toString();
          }
        });

        // Add image files
        for (var i = 0; i < images.length; i++) {
          final file = images[i];
          final multipartFile = await http.MultipartFile.fromPath(
            'images',
            file.path,
            filename: 'image_$i.jpg',
          );
          request.files.add(multipartFile);
        }

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Use regular JSON request
        final body = json.encode(requestData);
        response = await http
            .post(Uri.parse(url), headers: _getHeaders(), body: body)
            .timeout(ApiConfig.timeout);
      }

      final data = _handleResponse(response);
      return _parseUserReport(data as Map<String, dynamic>);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error creating report: $e');
      }
      rethrow;
    }
  }

  /// Get user's reports
  Future<List<UserReport>> getUserReports({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (type != null) {
        queryParams['type'] = type;
      }
      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse(
        _buildUrl('/v1/mobile/reports/my/reports'),
      ).replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('Getting user reports from: $uri');
      }

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(ApiConfig.timeout);

      final data = _handleResponse(response);

      if (data is List) {
        return data
            .map(
              (reportData) =>
                  _parseUserReport(reportData as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error getting user reports: $e');
      }
      rethrow;
    }
  }

  /// Get a specific report by ID
  Future<UserReport> getReport(String reportId) async {
    try {
      final url = _buildUrl('${ApiConfig.reportsEndpoint}/$reportId');

      if (kDebugMode) {
        print('Getting report $reportId from: $url');
      }

      final response = await http
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(ApiConfig.timeout);

      final data = _handleResponse(response);
      return _parseUserReport(data as Map<String, dynamic>);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error getting report $reportId: $e');
      }
      rethrow;
    }
  }

  /// Update a report
  Future<UserReport> updateReport(
    String reportId, {
    String? title,
    String? description,
    String? category,
    String? location,
    List<String>? colors,
    bool? isUrgent,
    bool? rewardOffered,
    String? rewardAmount,
  }) async {
    try {
      final url = _buildUrl('${ApiConfig.reportsEndpoint}/$reportId');

      if (kDebugMode) {
        print('Updating report $reportId at: $url');
      }

      final requestData = <String, dynamic>{};
      if (title != null) {
        requestData['title'] = title;
      }
      if (description != null) {
        requestData['description'] = description;
      }
      if (category != null) {
        requestData['category'] = category;
      }
      if (location != null) {
        requestData['location_city'] = location;
      }
      if (colors != null) {
        requestData['colors'] = colors;
      }
      if (isUrgent != null) {
        requestData['is_urgent'] = isUrgent;
      }
      if (rewardOffered != null) {
        requestData['reward_offered'] = rewardOffered;
      }
      if (rewardAmount != null) {
        requestData['reward_amount'] = rewardAmount;
      }

      final body = json.encode(requestData);
      final response = await http
          .put(Uri.parse(url), headers: _getHeaders(), body: body)
          .timeout(ApiConfig.timeout);

      final data = _handleResponse(response);
      return _parseUserReport(data as Map<String, dynamic>);
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error updating report $reportId: $e');
      }
      rethrow;
    }
  }

  /// Delete a report
  Future<bool> deleteReport(String reportId) async {
    try {
      final url = _buildUrl('${ApiConfig.reportsEndpoint}/$reportId');

      if (kDebugMode) {
        print('Deleting report $reportId at: $url');
      }

      final response = await http
          .delete(Uri.parse(url), headers: _getHeaders())
          .timeout(ApiConfig.timeout);

      _handleResponse(response);
      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error deleting report $reportId: $e');
      }
      return false;
    }
  }

  /// Search reports
  Future<List<UserReport>> searchReports({
    String? query,
    String? type,
    String? category,
    String? location,
    double? latitude,
    double? longitude,
    double? radius,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (query != null) {
        queryParams['q'] = query;
      }
      if (type != null) {
        queryParams['type'] = type;
      }
      if (category != null) {
        queryParams['category'] = category;
      }
      if (location != null) {
        queryParams['location'] = location;
      }
      if (latitude != null) {
        queryParams['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        queryParams['longitude'] = longitude.toString();
      }
      if (radius != null) {
        queryParams['radius'] = radius.toString();
      }

      final uri = Uri.parse(
        _buildUrl('/v1/mobile/reports/search'),
      ).replace(queryParameters: queryParams);

      if (kDebugMode) {
        print('Searching reports from: $uri');
      }

      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(ApiConfig.timeout);

      final data = _handleResponse(response);

      if (data is List) {
        return data
            .map(
              (reportData) =>
                  _parseUserReport(reportData as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error searching reports: $e');
      }
      rethrow;
    }
  }

  /// Parse UserReport from API response
  UserReport _parseUserReport(Map<String, dynamic> data) => UserReport(
    id: data['id'] as String,
    title: data['title'] as String,
    description: data['description'] as String? ?? '',
    type: _parseReportType(data['type'] as String),
    category: data['category'] as String,
    location:
        data['location_city'] as String? ??
        data['location_address'] as String? ??
        'Unknown location',
    createdAt: DateTime.parse(data['created_at'] as String),
    status: data['status'] as String? ?? 'pending',
    matchCount: data['match_count'] as int? ?? 0,
    imageUrl: data['images'] != null && (data['images'] as List).isNotEmpty
        ? (data['images'] as List).first as String
        : null,
    colors: (data['colors'] as List<dynamic>?)?.cast<String>() ?? [],
    isUrgent: data['is_urgent'] as bool? ?? false,
    rewardOffered: data['reward_offered'] as bool? ?? false,
    rewardAmount: data['reward_amount']?.toString(),
  );

  /// Parse ReportType from string
  ReportType _parseReportType(String type) {
    switch (type.toLowerCase()) {
      case 'lost':
        return ReportType.lost;
      case 'found':
        return ReportType.found;
      default:
        return ReportType.lost;
    }
  }
}
