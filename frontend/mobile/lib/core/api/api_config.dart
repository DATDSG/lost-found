/// API Configuration for Lost & Found Mobile App
class ApiConfig {
  // Default API endpoints for different environments
  static const String _localAndroidEmulator = 'http://10.0.2.2:8000';
  // Alternative endpoints (uncomment and use as needed)
  // static const String _localIosSimulator = 'http://localhost:8000';
  // static const String _localPhysicalDevice = 'http://192.168.1.100:8000'; // Change to your computer's IP
  // static const String _production = 'https://your-production-api.com';
  
  /// Current API base URL
  /// For Android Emulator: http://10.0.2.2:8000
  /// For iOS Simulator: http://localhost:8000  
  /// For Physical Device: http://YOUR_COMPUTER_IP:8000
  /// For Production: https://your-production-api.com
  static const String baseUrl = _localAndroidEmulator;
  
  /// API endpoints
  static const String auth = '/auth';
  static const String items = '/items';
  static const String matches = '/matches';
  static const String claims = '/claims';
  static const String media = '/media';
  static const String health = '/health';
  
  /// Request timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  /// Supported languages
  static const List<String> supportedLanguages = ['en', 'si', 'ta'];
  
  /// Default language
  static const String defaultLanguage = 'en';
  
  /// Feature flags (should match API .env settings)
  static const bool nlpEnabled = false; // NLP_ON
  static const bool cvEnabled = true;   // CV_ON
  
  /// Map configuration
  static const double defaultLatitude = 6.9271;  // Colombo, Sri Lanka
  static const double defaultLongitude = 79.8612;
  static const double defaultZoom = 12.0;
  
  /// Search defaults
  static const double defaultSearchRadius = 5.0; // km
  static const int maxSearchResults = 20;
  
  /// Image upload limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
}
