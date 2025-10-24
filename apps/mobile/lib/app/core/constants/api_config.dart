import 'app_constants.dart';

/// Configuration class for API endpoints and settings
class ApiConfig {
  // ignore: avoid_classes_with_only_static_members
  /// Private constructor to prevent instantiation
  ApiConfig._();

  /// Base URL for API requests
  static String get baseUrl => AppConstants.baseUrl;

  /// API version string
  static const String apiVersion = AppConstants.apiVersion;

  /// Request timeout duration
  static Duration get timeout => AppConstants.apiTimeout;

  // API Endpoints
  /// Authentication endpoint
  static const String authEndpoint = '/v1/auth';

  /// Users endpoint
  static const String usersEndpoint = '/v1/users';

  /// Reports endpoint
  static const String reportsEndpoint = '/v1/reports';

  /// Matches endpoint
  static const String matchesEndpoint = '/v1/matches';

  /// Media endpoint
  static const String mediaEndpoint = '/v1/media';

  /// Categories endpoint
  static const String categoriesEndpoint = '/v1/taxonomy/categories';

  /// Colors endpoint
  static const String colorsEndpoint = '/v1/taxonomy/colors';

  // Auth endpoints
  /// Login endpoint
  static const String loginEndpoint = '$authEndpoint/login';

  /// Register endpoint
  static const String registerEndpoint = '$authEndpoint/register';

  /// Forgot password endpoint
  static const String forgotPasswordEndpoint = '$authEndpoint/forgot-password';

  /// Reset password endpoint
  static const String resetPasswordEndpoint = '$authEndpoint/reset-password';

  // User endpoints
  /// Get user profile endpoint
  static const String profileEndpoint = '$usersEndpoint/me';

  /// Update user profile endpoint
  static const String updateProfileEndpoint = '$usersEndpoint/me';

  /// Change password endpoint
  static const String changePasswordEndpoint =
      '$usersEndpoint/me/change-password';

  /// Delete account endpoint
  static const String deleteAccountEndpoint = '$usersEndpoint/me';

  /// Privacy settings endpoint
  static const String privacySettingsEndpoint = '$usersEndpoint/me/privacy';

  /// Download user data endpoint
  static const String downloadDataEndpoint = '$usersEndpoint/me/export-data';

  /// Profile statistics endpoint
  static const String profileStatsEndpoint = '$usersEndpoint/me/stats';

  // Report endpoints
  /// Create report endpoint
  static const String createReportEndpoint = reportsEndpoint;

  /// Update report endpoint
  static const String updateReportEndpoint = '$reportsEndpoint/{id}';

  /// Delete report endpoint
  static const String deleteReportEndpoint = '$reportsEndpoint/{id}';

  /// Get report endpoint
  static const String getReportEndpoint = '$reportsEndpoint/{id}';

  /// Get user reports endpoint
  static const String getUserReportsEndpoint = '$reportsEndpoint/user';

  /// Search reports endpoint
  static const String searchReportsEndpoint = '$reportsEndpoint/search';

  // Match endpoints
  /// Get matches endpoint
  static const String getMatchesEndpoint = matchesEndpoint;

  /// Get match endpoint
  static const String getMatchEndpoint = '$matchesEndpoint/{id}';

  /// Accept match endpoint
  static const String acceptMatchEndpoint = '$matchesEndpoint/{id}/accept';

  /// Reject match endpoint
  static const String rejectMatchEndpoint = '$matchesEndpoint/{id}/reject';

  // Media endpoints
  /// Upload media endpoint
  static const String uploadMediaEndpoint = '$mediaEndpoint/upload';

  /// Delete media endpoint
  static const String deleteMediaEndpoint = '$mediaEndpoint/{id}';

  // Utility endpoints
  /// Get categories endpoint
  static const String getCategoriesEndpoint = categoriesEndpoint;

  /// Get colors endpoint
  static const String getColorsEndpoint = colorsEndpoint;

  // Headers
  /// Default HTTP headers for API requests
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get authorization headers with bearer token
  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}
