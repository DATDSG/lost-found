/// API Configuration for Lost & Found Platform
///
/// All endpoints use the /api/v1 prefix for consistency
class ApiConfig {
  // Change this to your backend URL
  // For Android Emulator: http://10.0.2.2:8000
  // For iOS Simulator: http://localhost:8000
  // For Physical Device: http://YOUR_COMPUTER_IP:8000
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Authentication Endpoints
  static const String authRegister = '/api/v1/auth/register';
  static const String authLogin = '/api/v1/auth/login';
  static const String authRefresh = '/api/v1/auth/refresh';
  static const String authMe = '/api/v1/auth/me';
  static const String authUpdateProfile = '/api/v1/auth/me';
  static const String authChangePassword = '/api/v1/auth/change-password';
  static const String authLogout = '/api/v1/auth/logout';

  // Reports Endpoints
  static const String reports = '/api/v1/reports';
  static const String myReports = '/api/v1/reports/me';
  static const String reportsCreate = '/api/v1/reports';
  static const String nearbyReports = '/api/v1/reports/nearby';
  static const String reportDetail = '/api/v1/reports';
  static const String reportUpdate = '/api/v1/reports';
  static const String reportDelete = '/api/v1/reports';
  static const String reportStatus = '/api/v1/reports';
  static const String reportResolve = '/api/v1/reports';
  static const String reportStats = '/api/v1/reports/stats';
  static const String reportAnalytics = '/api/v1/reports/analytics';

  // Matches Endpoints
  static const String matches = '/api/v1/matches';

  // Search Endpoints (using existing reports endpoint with search parameters)
  static const String searchReports = '/api/v1/reports';
  static const String searchSuggestions = '/api/v1/search/suggestions';
  static const String semanticSearch = '/api/v1/search/semantic';
  static const String recentSearches = '/api/v1/search/recent';
  static const String popularSearches = '/api/v1/search/popular';
  static const String matchesReport = '/api/v1/matches/report';
  static const String matchesConfirm = '/api/v1/matches';
  static const String matchesAnalytics = '/api/v1/matches';

  // Media Endpoints
  static const String media = '/api/v1/media';
  static const String mediaUpload = '/api/v1/media/upload';

  // Messages Endpoints
  static const String conversations = '/api/v1/messages/conversations';
  static const String messages = '/api/v1/messages';
  static const String messagesCreate = '/api/v1/messages';
  static const String conversationCreate = '/api/v1/messages/conversations';
  static const String conversationDetail = '/api/v1/messages/conversations';
  static const String conversationMessages = '/api/v1/messages/conversations';
  static const String messageRead = '/api/v1/messages';
  static const String conversationRead = '/api/v1/messages/conversations';
  static const String conversationArchive = '/api/v1/messages/conversations';
  static const String conversationDelete = '/api/v1/messages/conversations';
  static const String messageDelete = '/api/v1/messages';
  static const String conversationMute = '/api/v1/messages/conversations';
  static const String conversationBlock = '/api/v1/messages/conversations';

  // Notifications Endpoints
  static const String notifications = '/api/v1/notifications';
  static const String notificationsUnread = '/api/v1/notifications/unread';
  static const String notificationsMarkRead = '/api/v1/notifications';

  // User Profile Endpoints
  static const String usersMe = '/api/v1/users/me';
  static const String usersMeAvatar = '/api/v1/users/me/avatar';
  static const String usersMeStats = '/api/v1/users/me/stats';
  static const String usersMePreferences = '/api/v1/users/me/preferences';
  static const String usersMeActivity = '/api/v1/users/me/activity';
  static const String usersMeReports = '/api/v1/users/me/reports';
  static const String usersMeMatches = '/api/v1/users/me/matches';
  static const String usersMeNotifications = '/api/v1/users/me/notifications';
  static const String usersMeSettings = '/api/v1/users/me/settings';

  // Taxonomy Endpoints
  static const String categories = '/api/v1/taxonomy/categories';
  static const String colors = '/api/v1/taxonomy/colors';

  // Location Service Endpoints
  static const String locationGeocode = '/api/v1/location/geocode';
  static const String locationReverseGeocode =
      '/api/v1/location/reverse-geocode';
  static const String locationSearch = '/api/v1/location/search';
  static const String locationNearby = '/api/v1/location/nearby';
  static const String locationAutocomplete = '/api/v1/location/autocomplete';
  static const String locationDetails = '/api/v1/location/details';
  static const String locationDistance = '/api/v1/location/distance';
  static const String locationBounds = '/api/v1/location/bounds';
  static const String locationValidate = '/api/v1/location/validate';
  static const String locationHistory = '/api/v1/location/history';

  // WebSocket Endpoints
  static String get wsBaseUrl => baseUrl.replaceFirst('http', 'ws');
  static const String wsChat = '/ws/chat';
  static const String wsNotifications = '/ws/notifications';

  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
