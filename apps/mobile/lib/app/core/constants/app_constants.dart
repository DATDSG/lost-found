import '../config/environment_config.dart';

/// Application constants and configuration values
///
/// This class contains all the constant values used throughout the app,
/// including API configuration, storage keys, UI constants, and messages.
class AppConstants {
  /// Private constructor to prevent instantiation
  AppConstants._();

  // API Configuration
  /// Base URL for the API endpoints - dynamically configured based on environment
  static String get baseUrl => EnvironmentConfig.baseUrl;

  /// API version string
  static const String apiVersion = 'v1';

  /// Default timeout duration for API requests - dynamically configured based on environment
  static Duration get apiTimeout => EnvironmentConfig.apiTimeout;

  // Storage Keys
  /// Key for storing authentication token
  static const String authTokenKey = 'auth_token';

  /// Key for storing user data
  static const String userDataKey = 'user_data';

  /// Key for storing remember me preference
  static const String rememberMeKey = 'remember_me';

  /// Key for storing saved email
  static const String savedEmailKey = 'saved_email';

  /// Key for storing saved password (encrypted)
  static const String savedPasswordKey = 'saved_password';

  /// Key for storing theme mode preference
  static const String themeKey = 'theme_mode';

  /// Key for storing language preference
  static const String languageKey = 'language';

  /// Key for storing onboarding completion status
  static const String onboardingKey = 'onboarding_completed';

  // Cache Keys
  /// Key for caching reports data
  static const String reportsCacheKey = 'reports_cache';

  /// Key for caching matches data
  static const String matchesCacheKey = 'matches_cache';

  /// Key for caching user data
  static const String userCacheKey = 'user_cache';

  // Pagination
  /// Default number of items per page
  static const int defaultPageSize = 20;

  /// Maximum number of items per page
  static const int maxPageSize = 100;

  // File Upload
  /// Maximum allowed image file size in bytes (5MB)
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  /// List of allowed image file extensions
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  // Location
  /// Default search radius in kilometers
  static const double defaultSearchRadius = 10; // km
  /// Maximum search radius in kilometers
  static const double maxSearchRadius = 100; // km

  // UI Constants
  /// Default padding value
  static const double defaultPadding = 16;

  /// Small padding value
  static const double smallPadding = 8;

  /// Large padding value
  static const double largePadding = 24;

  /// Default border radius
  static const double borderRadius = 12;

  /// Standard button height
  static const double buttonHeight = 48;

  // Animation Durations
  /// Duration for short animations
  static const Duration shortAnimation = Duration(milliseconds: 200);

  /// Duration for medium animations
  static const Duration mediumAnimation = Duration(milliseconds: 300);

  /// Duration for long animations
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Error Messages
  /// Message for network connection errors
  static const String networkErrorMessage = 'Network connection error';

  /// Message for server errors
  static const String serverErrorMessage = 'Server error occurred';

  /// Message for unknown errors
  static const String unknownErrorMessage = 'An unknown error occurred';

  /// Message for request timeout errors
  static const String timeoutErrorMessage = 'Request timeout';

  // Success Messages
  /// Message for successful report creation
  static const String reportCreatedMessage = 'Report created successfully';

  /// Message for successful report update
  static const String reportUpdatedMessage = 'Report updated successfully';

  /// Message when a potential match is found
  static const String matchFoundMessage = 'Potential match found';

  /// Message for successful message sending
  static const String messageSentMessage = 'Message sent successfully';
}
