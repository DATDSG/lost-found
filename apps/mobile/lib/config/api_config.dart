/// Environment-based API Configuration for Flutter Mobile App
///
/// This file provides API configuration that can be changed based on
/// the build environment (development, staging, production)

class ApiConfig {
  // Private constructor
  ApiConfig._();

  // Environment detection
  static const String _env =
      String.fromEnvironment('ENV', defaultValue: 'development');

  /// Get base URL based on environment
  static String get baseUrl {
    switch (_env) {
      case 'production':
        return 'https://api.lostfound.com/api';
      case 'staging':
        return 'https://staging-api.lostfound.com/api';
      case 'development':
      default:
        // For local development
        // Android Emulator: http://10.0.2.2:8000/api
        // iOS Simulator: http://localhost:8000/api
        // Physical Device: http://YOUR_IP:8000/api
        return const String.fromEnvironment('API_URL',
            defaultValue: 'http://10.0.2.2:8000/api');
    }
  }

  /// API endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/me';
  static const String refreshToken = '/auth/refresh';

  static const String reports = '/reports';
  static const String items = '/items';
  static const String matches = '/matches';
  static const String notifications = '/notifications';
  static const String messages = '/messages';
  static const String media = '/media';

  // Auth endpoints
  static String get authLogin => login;
  static String get authRegister => register;
  static String get authRefresh => refreshToken;
  static String get authMe => profile;
  static String get authUpdateProfile => '/auth/profile';
  static String get authChangePassword => '/auth/change-password';
  static String get authLogout => logout;

  // Conversation endpoints
  static String get conversations => '/conversations';
  static String get messagesCreate => '/messages';

  // Media endpoints
  static String get mediaUpload => '/media/upload';

  /// Timeout duration
  static const Duration timeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// API versioning
  static const String apiVersion = 'v1';

  /// Debug mode
  static bool get isDebug => _env == 'development';

  /// Environment name
  static String get environment => _env;
}

/// Usage Instructions:
/// 
/// To build with different environments:
/// 
/// Development (default):
///   flutter run
///   OR
///   flutter run --dart-define=ENV=development --dart-define=API_URL=http://10.0.2.2:8000/api
/// 
/// Staging:
///   flutter build apk --dart-define=ENV=staging
/// 
/// Production:
///   flutter build apk --dart-define=ENV=production
/// 
/// Custom API URL:
///   flutter run --dart-define=API_URL=http://192.168.1.100:8000/api

