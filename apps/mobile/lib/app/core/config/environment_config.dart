/// Environment configuration for the Lost & Found mobile app
///
/// This file manages different environments (development, staging, production)
/// and provides the appropriate API endpoints for each environment.
///
/// IMPORTANT: For real device testing:
/// 1. Set forceEmulatorMode = false (default)
/// 2. Ensure your development machine's IP is accessible from the mobile device
/// 3. The app will automatically use the server URL (172.104.40.189:8000) for real devices
/// 4. For emulator testing, set forceEmulatorMode = true
///
/// Network troubleshooting:
/// - Emulator: Uses 10.0.2.2:8000 (maps to host localhost)
/// - Real device: Uses 172.104.40.189:8000 (server IP)
/// - Local development: Uses localhost:8000
library;

import 'package:flutter/foundation.dart';

/// Available environments for the application
enum Environment {
  /// Development environment for local testing
  development,

  /// Local environment for localhost testing
  local,

  /// Server environment for server testing
  server,

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

  /// Force emulator mode - set to true if running on emulator, false for real device
  /// This can be overridden for testing purposes
  static const bool forceEmulatorMode = false;

  /// Get the base URL for the current environment
  static String get baseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return _getDevelopmentUrl();
      case Environment.local:
        return _getLocalUrl();
      case Environment.server:
        return _getServerUrl();
      case Environment.staging:
        return 'https://staging-api.lostfound.com';
      case Environment.production:
        return 'https://api.lostfound.com';
    }
  }

  /// Get development URL dynamically based on device type
  static String _getDevelopmentUrl() {
    // Check if running on emulator or real device
    if (_isRunningOnEmulator()) {
      return emulatorUrl; // Use 10.0.2.2 for emulator
    } else {
      return serverUrl; // Use server IP for real device
    }
  }

  static String _getLocalUrl() => localhostUrl;
  static String _getServerUrl() => serverUrl;

  /// Check if the app is running on an emulator
  static bool _isRunningOnEmulator() {
    // Use force override if set
    if (forceEmulatorMode) {
      return true;
    }

    // For release builds, always use server URL for real devices
    // Debug builds can use emulator detection
    if (kReleaseMode) {
      return false; // Always use server URL in release builds
    }

    // For debug builds, default to real device (server URL)
    // In a production app, you would implement proper device detection here
    // using platform-specific APIs to detect emulator vs real device
    return false;
  }

  /// Get alternative development URLs
  static Map<String, String> get developmentUrls => {
    'emulator': 'http://10.0.2.2:8000',
    'server': 'http://172.104.40.189:8000',
    'localhost': 'http://localhost:8000',
  };

  /// Get server URL specifically (for real devices)
  static String get serverUrl => 'http://172.104.40.189:8000';

  /// Get emulator URL specifically (for Android emulator)
  static String get emulatorUrl => 'http://10.0.2.2:8000';

  /// Get localhost URL specifically (for local development)
  static String get localhostUrl => 'http://localhost:8000';

  /// Get the current device type being used
  static String get deviceType =>
      _isRunningOnEmulator() ? 'emulator' : 'real_device';

  /// Get the current API endpoint being used
  static String get currentApiEndpoint => baseUrl;

  /// Get API timeout for current environment
  static Duration get apiTimeout {
    switch (currentEnvironment) {
      case Environment.development:
        return const Duration(seconds: 60); // Longer timeout for development
      case Environment.local:
        return const Duration(seconds: 60); // Longer timeout for local testing
      case Environment.server:
        return const Duration(seconds: 45); // Medium timeout for server testing
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
      case Environment.local:
        return true; // Enable debug logging for local testing
      case Environment.server:
        return true; // Enable debug logging for server testing
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
      case Environment.local:
        return const Duration(minutes: 5); // Short cache for local testing
      case Environment.server:
        return const Duration(minutes: 10); // Medium cache for server testing
      case Environment.staging:
        return const Duration(minutes: 15);
      case Environment.production:
        return const Duration(hours: 1); // Longer cache for production
    }
  }

  /// Environment-specific configuration summary
  static Map<String, dynamic> get config => {
    'environment': currentEnvironment.name,
    'deviceType': deviceType,
    'baseUrl': baseUrl,
    'currentApiEndpoint': currentApiEndpoint,
    'serverUrl': serverUrl,
    'emulatorUrl': emulatorUrl,
    'localhostUrl': localhostUrl,
    'developmentUrls': developmentUrls,
    'apiTimeout': apiTimeout.inSeconds,
    'enableDebugLogging': enableDebugLogging,
    'cacheTimeout': cacheTimeout.inMinutes,
    'forceEmulatorMode': forceEmulatorMode,
  };
}
