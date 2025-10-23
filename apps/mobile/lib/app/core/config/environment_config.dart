/// Environment configuration for the Lost & Found mobile app
///
/// This file manages different environments (development, staging, production)
/// and provides the appropriate API endpoints for each environment.
library;

/// Available environments for the application
enum Environment {
  /// Development environment for local testing
  development,

  /// Staging environment for testing before production
  staging,

  /// Production environment for live deployment
  production,
}

/// Configuration class for managing environment-specific settings
class EnvironmentConfig {
  /// Private constructor to prevent instantiation
  EnvironmentConfig._();

  /// Current environment - change this to switch environments
  static const Environment currentEnvironment = Environment.development;

  /// Get the base URL for the current environment
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return _getDevelopmentUrl();
      case Environment.staging:
        return 'https://staging-api.lostfound.com';
      case Environment.production:
        return 'https://api.lostfound.com';
    }
  }

  /// Get development URL dynamically
  static String _getDevelopmentUrl() => 'http://10.0.2.2:8000';

  /// Get API timeout for current environment
  static Duration get apiTimeout {
    switch (currentEnvironment) {
      case Environment.development:
        return const Duration(seconds: 60); // Longer timeout for development
      case Environment.staging:
        return const Duration(seconds: 30);
      case Environment.production:
        return const Duration(seconds: 15); // Shorter timeout for production
    }
  }

  /// Get debug settings for current environment
  static bool get enableDebugLogging {
    switch (currentEnvironment) {
      case Environment.development:
        return true;
      case Environment.staging:
        return true;
      case Environment.production:
        return false;
    }
  }

  /// Get cache settings for current environment
  static Duration get cacheTimeout {
    switch (currentEnvironment) {
      case Environment.development:
        return const Duration(minutes: 5); // Short cache for development
      case Environment.staging:
        return const Duration(minutes: 15);
      case Environment.production:
        return const Duration(hours: 1); // Longer cache for production
    }
  }

  /// Environment-specific configuration summary
  static Map<String, dynamic> get config => {
    'environment': currentEnvironment.name,
    'baseUrl': baseUrl,
    'apiTimeout': apiTimeout.inSeconds,
    'enableDebugLogging': enableDebugLogging,
    'cacheTimeout': cacheTimeout.inMinutes,
  };
}
