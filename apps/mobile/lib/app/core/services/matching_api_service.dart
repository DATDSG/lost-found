import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../shared/models/matching_models.dart';
import '../constants/api_config.dart';
import '../exceptions/api_exceptions.dart';

/// API service for handling matching-related requests
class MatchingApiService {
  /// Factory constructor for singleton instance
  factory MatchingApiService() => _instance;

  /// Private constructor for singleton pattern
  MatchingApiService._internal();
  static final MatchingApiService _instance = MatchingApiService._internal();

  late String _baseUrl;

  /// Initialize the API service with base URL
  void initialize({String? baseUrl, String? authToken}) {
    _baseUrl = baseUrl ?? ApiConfig.baseUrl;
    this.authToken = authToken;
    if (kDebugMode) {
      print('MatchingApiService initialized with base URL: $_baseUrl');
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

  /// Handle HTTP response
  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      print('Matching API Response: ${response.statusCode} - ${response.body}');
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

  /// Get user's reports with their matches
  Future<List<ReportWithMatches>> getUserReportsWithMatches() async {
    try {
      // Use the existing matches endpoint
      final url = _buildUrl('${ApiConfig.matchesEndpoint}/');

      if (kDebugMode) {
        print('Getting user reports with matches from: $url');
      }

      final response = await http
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(ApiConfig.timeout);

      final data = _handleResponse(response);

      if (data is Map<String, dynamic> && data['matches'] != null) {
        final matchesData = data['matches'] as List<dynamic>;

        if (matchesData.isEmpty) {
          if (kDebugMode) {
            print('No matches found');
          }
          return [];
        }

        return matchesData
            .map(
              (reportData) =>
                  _parseReportWithMatches(reportData as Map<String, dynamic>),
            )
            .toList();
      }

      // Return empty list if no matches found
      return [];
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error getting user reports with matches: $e');
      }
      rethrow;
    }
  }

  /// Get matches for a specific report
  Future<List<Match>> getMatchesForReport(String reportId) async {
    try {
      final url = _buildUrl('${ApiConfig.matchesEndpoint}/report/$reportId');

      if (kDebugMode) {
        print('Getting matches for report $reportId from: $url');
      }

      final response = await http
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(ApiConfig.timeout);

      final data = _handleResponse(response);

      if (data is Map<String, dynamic> && data['matches'] != null) {
        final matchesData = data['matches'] as List<dynamic>;
        return matchesData
            .map((matchData) => _parseMatch(matchData as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error getting matches for report $reportId: $e');
      }
      rethrow;
    }
  }

  /// Accept a match
  Future<bool> acceptMatch(String matchId) async {
    try {
      final url = _buildUrl('${ApiConfig.matchesEndpoint}/$matchId/accept');

      if (kDebugMode) {
        print('Accepting match $matchId at: $url');
      }

      final response = await http
          .post(Uri.parse(url), headers: _getHeaders())
          .timeout(ApiConfig.timeout);

      _handleResponse(response);
      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error accepting match $matchId: $e');
      }
      return false;
    }
  }

  /// Reject a match
  Future<bool> rejectMatch(String matchId) async {
    try {
      final url = _buildUrl('${ApiConfig.matchesEndpoint}/$matchId/reject');

      if (kDebugMode) {
        print('Rejecting match $matchId at: $url');
      }

      final response = await http
          .post(Uri.parse(url), headers: _getHeaders())
          .timeout(ApiConfig.timeout);

      _handleResponse(response);
      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error rejecting match $matchId: $e');
      }
      return false;
    }
  }

  /// Mark a match as viewed
  Future<bool> markMatchAsViewed(String matchId) async {
    try {
      final url = _buildUrl('${ApiConfig.matchesEndpoint}/$matchId/view');

      if (kDebugMode) {
        print('Marking match $matchId as viewed at: $url');
      }

      final response = await http
          .post(Uri.parse(url), headers: _getHeaders())
          .timeout(ApiConfig.timeout);

      _handleResponse(response);
      return true;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error marking match $matchId as viewed: $e');
      }
      return false;
    }
  }

  /// Get match statistics for user
  Future<Map<String, int>> getMatchStatistics() async {
    try {
      final url = _buildUrl('${ApiConfig.matchesEndpoint}/statistics');

      if (kDebugMode) {
        print('Getting match statistics from: $url');
      }

      final response = await http
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(ApiConfig.timeout);

      final data = _handleResponse(response);

      if (data is Map<String, dynamic>) {
        return {
          'totalMatches': (data['total_matches'] as num?)?.toInt() ?? 0,
          'pendingMatches': (data['pending_matches'] as num?)?.toInt() ?? 0,
          'acceptedMatches': (data['accepted_matches'] as num?)?.toInt() ?? 0,
          'rejectedMatches': (data['rejected_matches'] as num?)?.toInt() ?? 0,
        };
      }

      return {
        'totalMatches': 0,
        'pendingMatches': 0,
        'acceptedMatches': 0,
        'rejectedMatches': 0,
      };
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error getting match statistics: $e');
      }
      return {
        'totalMatches': 0,
        'pendingMatches': 0,
        'acceptedMatches': 0,
        'rejectedMatches': 0,
      };
    }
  }

  /// Parse ReportWithMatches from API response
  ReportWithMatches _parseReportWithMatches(Map<String, dynamic> data) {
    final report = _parseUserReport(data['report'] as Map<String, dynamic>);
    final matches =
        (data['matches'] as List<dynamic>?)
            ?.map((matchData) => _parseMatch(matchData as Map<String, dynamic>))
            .toList() ??
        [];

    return ReportWithMatches(report: report, matches: matches);
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

  /// Parse Match from API response
  Match _parseMatch(Map<String, dynamic> data) => Match(
    id: data['id'] as String,
    sourceReportId: data['source_report_id'] as String,
    targetReportId: data['target_report_id'] as String,
    score: _parseMatchScore(data['score'] as Map<String, dynamic>),
    status: _parseMatchStatus(data['status'] as String),
    createdAt: DateTime.parse(data['created_at'] as String),
    reviewedAt: data['reviewed_at'] != null
        ? DateTime.parse(data['reviewed_at'] as String)
        : null,
    notes: data['notes'] as String?,
    isViewed: data['is_viewed'] as bool? ?? false,
    sourceReport: _parseUserReport(
      data['source_report'] as Map<String, dynamic>,
    ),
    targetReport: _parseUserReport(
      data['target_report'] as Map<String, dynamic>,
    ),
  );

  /// Parse MatchScore from API response
  MatchScore _parseMatchScore(Map<String, dynamic> data) => MatchScore(
    textSimilarity: (data['text_similarity'] as num).toDouble(),
    imageSimilarity: (data['image_similarity'] as num).toDouble(),
    locationProximity: (data['location_proximity'] as num).toDouble(),
    totalScore: (data['total_score'] as num).toDouble(),
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

  /// Parse MatchStatus from string
  MatchStatus _parseMatchStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return MatchStatus.pending;
      case 'accepted':
        return MatchStatus.accepted;
      case 'rejected':
        return MatchStatus.rejected;
      case 'under_review':
        return MatchStatus.underReview;
      default:
        return MatchStatus.pending;
    }
  }
}
