import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../core/error/error_handler.dart';

/// User profile state enum
enum ProfileState {
  initial,
  loading,
  loaded,
  error,
  updating,
  uploading,
  deleting,
}

/// User activity model
class UserActivity {
  final String id;
  final String type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  UserActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }
}

/// User preferences model
class UserPreferences {
  final Map<String, dynamic> notifications;
  final Map<String, dynamic> privacy;
  final Map<String, dynamic> display;
  final Map<String, dynamic> language;
  final Map<String, dynamic> location;

  UserPreferences({
    required this.notifications,
    required this.privacy,
    required this.display,
    required this.language,
    required this.location,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notifications: json['notifications'] ?? {},
      privacy: json['privacy'] ?? {},
      display: json['display'] ?? {},
      language: json['language'] ?? {},
      location: json['location'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications,
      'privacy': privacy,
      'display': display,
      'language': language,
      'location': location,
    };
  }

  UserPreferences copyWith({
    Map<String, dynamic>? notifications,
    Map<String, dynamic>? privacy,
    Map<String, dynamic>? display,
    Map<String, dynamic>? language,
    Map<String, dynamic>? location,
  }) {
    return UserPreferences(
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      display: display ?? this.display,
      language: language ?? this.language,
      location: location ?? this.location,
    );
  }
}

/// User settings model
class UserSettings {
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final bool locationSharing;
  final bool profileVisibility;
  final String language;
  final String timezone;
  final Map<String, dynamic>? customSettings;

  UserSettings({
    required this.emailNotifications,
    required this.pushNotifications,
    required this.smsNotifications,
    required this.locationSharing,
    required this.profileVisibility,
    required this.language,
    required this.timezone,
    this.customSettings,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      emailNotifications: json['email_notifications'] ?? true,
      pushNotifications: json['push_notifications'] ?? true,
      smsNotifications: json['sms_notifications'] ?? false,
      locationSharing: json['location_sharing'] ?? true,
      profileVisibility: json['profile_visibility'] ?? true,
      language: json['language'] ?? 'en',
      timezone: json['timezone'] ?? 'UTC',
      customSettings: json['custom_settings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email_notifications': emailNotifications,
      'push_notifications': pushNotifications,
      'sms_notifications': smsNotifications,
      'location_sharing': locationSharing,
      'profile_visibility': profileVisibility,
      'language': language,
      'timezone': timezone,
      if (customSettings != null) 'custom_settings': customSettings,
    };
  }

  UserSettings copyWith({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    bool? locationSharing,
    bool? profileVisibility,
    String? language,
    String? timezone,
    Map<String, dynamic>? customSettings,
  }) {
    return UserSettings(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      locationSharing: locationSharing ?? this.locationSharing,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// Comprehensive User Profile Provider
class UserProfileProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State management
  User? _currentUser;
  ProfileState _state = ProfileState.initial;
  String? _error;
  double _uploadProgress = 0.0;

  // Profile data
  Map<String, dynamic>? _userStats;
  UserPreferences? _userPreferences;
  UserSettings? _userSettings;
  List<UserActivity> _userActivity = [];
  List<Map<String, dynamic>> _userReports = [];
  List<Map<String, dynamic>> _userMatches = [];
  List<Map<String, dynamic>> _userNotifications = [];

  // Pagination
  bool _hasMoreActivity = false;
  bool _hasMoreReports = false;
  bool _hasMoreMatches = false;
  bool _hasMoreNotifications = false;
  int _currentActivityPage = 1;
  int _currentReportsPage = 1;
  int _currentMatchesPage = 1;
  int _currentNotificationsPage = 1;
  static const int _pageSize = 20;

  // Getters
  User? get currentUser => _currentUser;
  ProfileState get state => _state;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;
  Map<String, dynamic>? get userStats => _userStats;
  UserPreferences? get userPreferences => _userPreferences;
  UserSettings? get userSettings => _userSettings;
  List<UserActivity> get userActivity => _userActivity;
  List<Map<String, dynamic>> get userReports => _userReports;
  List<Map<String, dynamic>> get userMatches => _userMatches;
  List<Map<String, dynamic>> get userNotifications => _userNotifications;

  bool get isLoading => _state == ProfileState.loading;
  bool get isUpdating => _state == ProfileState.updating;
  bool get isUploading => _state == ProfileState.uploading;
  bool get isDeleting => _state == ProfileState.deleting;
  bool get hasError => _state == ProfileState.error;
  bool get isLoaded => _state == ProfileState.loaded;

  bool get hasMoreActivity => _hasMoreActivity;
  bool get hasMoreReports => _hasMoreReports;
  bool get hasMoreMatches => _hasMoreMatches;
  bool get hasMoreNotifications => _hasMoreNotifications;

  /// Initialize profile provider
  Future<void> initialize() async {
    if (_currentUser == null) return;

    _state = ProfileState.loading;
    _error = null;
    notifyListeners();

    try {
      // Load all profile data in parallel
      await Future.wait([
        loadUserStats(),
        loadUserPreferences(),
        loadUserSettings(),
        loadUserActivity(),
        loadUserReports(),
        loadUserMatches(),
        loadUserNotifications(),
      ]);

      _state = ProfileState.loaded;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Initialize profile');
      _state = ProfileState.error;
      notifyListeners();
    }
  }

  /// Set current user
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Load user statistics
  Future<void> loadUserStats() async {
    try {
      _userStats = await _apiService.getUserStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user stats: $e');
    }
  }

  /// Load user preferences
  Future<void> loadUserPreferences() async {
    try {
      final data = await _apiService.getUserPreferences();
      _userPreferences = UserPreferences.fromJson(data!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user preferences: $e');
    }
  }

  /// Update user preferences
  Future<bool> updateUserPreferences(UserPreferences preferences) async {
    _state = ProfileState.updating;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateUserPreferences(preferences.toJson());
      _userPreferences = preferences;
      _state = ProfileState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Update preferences');
      _state = ProfileState.error;
      notifyListeners();
      return false;
    }
  }

  /// Load user settings
  Future<void> loadUserSettings() async {
    try {
      final data = await _apiService.getUserSettings();
      _userSettings = UserSettings.fromJson(data!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user settings: $e');
    }
  }

  /// Update user settings
  Future<bool> updateUserSettings(UserSettings settings) async {
    _state = ProfileState.updating;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateUserSettings(settings.toJson());
      _userSettings = settings;
      _state = ProfileState.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Update settings');
      _state = ProfileState.error;
      notifyListeners();
      return false;
    }
  }

  /// Load user activity
  Future<void> loadUserActivity({
    bool loadMore = false,
    String? activityType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (loadMore) {
      _currentActivityPage++;
    } else {
      _currentActivityPage = 1;
      _userActivity.clear();
    }

    try {
      final activities = await _apiService.getUserActivity();

      final activityList =
          activities.map((json) => UserActivity.fromJson(json)).toList();

      if (loadMore) {
        _userActivity.addAll(activityList);
      } else {
        _userActivity = activityList;
      }

      _hasMoreActivity = activityList.length == _pageSize;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user activity: $e');
      if (loadMore) {
        _currentActivityPage--; // Revert page increment on error
      }
    }
  }

  /// Load user reports
  Future<void> loadUserReports({
    bool loadMore = false,
    String? status,
    String? type,
  }) async {
    if (loadMore) {
      _currentReportsPage++;
    } else {
      _currentReportsPage = 1;
      _userReports.clear();
    }

    try {
      final reports = await _apiService.getUserReports();

      if (loadMore) {
        _userReports.addAll(reports);
      } else {
        _userReports = reports;
      }

      _hasMoreReports = reports.length == _pageSize;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user reports: $e');
      if (loadMore) {
        _currentReportsPage--; // Revert page increment on error
      }
    }
  }

  /// Load user matches
  Future<void> loadUserMatches({bool loadMore = false, String? status}) async {
    if (loadMore) {
      _currentMatchesPage++;
    } else {
      _currentMatchesPage = 1;
      _userMatches.clear();
    }

    try {
      final matches = await _apiService.getUserMatches();

      if (loadMore) {
        _userMatches.addAll(matches);
      } else {
        _userMatches = matches;
      }

      _hasMoreMatches = matches.length == _pageSize;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user matches: $e');
      if (loadMore) {
        _currentMatchesPage--; // Revert page increment on error
      }
    }
  }

  /// Load user notifications
  Future<void> loadUserNotifications({
    bool loadMore = false,
    bool? unreadOnly,
    String? type,
  }) async {
    if (loadMore) {
      _currentNotificationsPage++;
    } else {
      _currentNotificationsPage = 1;
      _userNotifications.clear();
    }

    try {
      final notifications = await _apiService.getUserNotifications();

      if (loadMore) {
        _userNotifications.addAll(notifications);
      } else {
        _userNotifications = notifications;
      }

      _hasMoreNotifications = notifications.length == _pageSize;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user notifications: $e');
      if (loadMore) {
        _currentNotificationsPage--; // Revert page increment on error
      }
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String displayName,
    String? phoneNumber,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    _state = ProfileState.updating;
    _error = null;
    notifyListeners();

    try {
      final profileData = {
        'display_name': displayName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (bio != null) 'bio': bio,
        if (preferences != null) 'preferences': preferences,
      };

      final rawUser =
          await _apiService.updateProfileWithValidation(profileData);

      if (rawUser != null) {
        _currentUser = User.fromJson(rawUser);
        _state = ProfileState.loaded;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update profile';
        _state = ProfileState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Update profile');
      _state = ProfileState.error;
      notifyListeners();
      return false;
    }
  }

  /// Upload user avatar
  Future<bool> uploadAvatar(File avatarFile) async {
    _state = ProfileState.uploading;
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      final avatarUrl = await _apiService.uploadAvatar(avatarFile.path);

      // Update user with new avatar URL
      final updatedUser = await _apiService.updateProfile({
        'avatar_url': avatarUrl,
      });

      _currentUser = User.fromJson(updatedUser!);
      _state = ProfileState.loaded;
      _uploadProgress = 0.0;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Upload avatar');
      _state = ProfileState.error;
      _uploadProgress = 0.0;
      notifyListeners();
      return false;
    }
  }

  /// Delete user account
  Future<bool> deleteAccount({required String password, String? reason}) async {
    _state = ProfileState.deleting;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteUserAccount();

      _currentUser = null;
      _state = ProfileState.initial;
      clearAllData();
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Delete account');
      _state = ProfileState.error;
      notifyListeners();
      return false;
    }
  }

  /// Export user data
  Future<Map<String, dynamic>?> exportData({
    String? format = 'json',
    bool includeReports = true,
    bool includeMatches = true,
    bool includeMessages = true,
    bool includeNotifications = true,
  }) async {
    try {
      return await _apiService.exportUserData();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Export data');
      notifyListeners();
      return null;
    }
  }

  /// Load more activity
  Future<void> loadMoreActivity() async {
    if (!_hasMoreActivity || isLoading) return;
    await loadUserActivity(loadMore: true);
  }

  /// Load more reports
  Future<void> loadMoreReports() async {
    if (!_hasMoreReports || isLoading) return;
    await loadUserReports(loadMore: true);
  }

  /// Load more matches
  Future<void> loadMoreMatches() async {
    if (!_hasMoreMatches || isLoading) return;
    await loadUserMatches(loadMore: true);
  }

  /// Load more notifications
  Future<void> loadMoreNotifications() async {
    if (!_hasMoreNotifications || isLoading) return;
    await loadUserNotifications(loadMore: true);
  }

  /// Refresh all profile data
  Future<void> refresh() async {
    await initialize();
  }

  /// Clear all profile data
  void clearAllData() {
    _currentUser = null;
    _userStats = null;
    _userPreferences = null;
    _userSettings = null;
    _userActivity.clear();
    _userReports.clear();
    _userMatches.clear();
    _userNotifications.clear();
    _state = ProfileState.initial;
    _error = null;
    _uploadProgress = 0.0;
    _hasMoreActivity = false;
    _hasMoreReports = false;
    _hasMoreMatches = false;
    _hasMoreNotifications = false;
    _currentActivityPage = 1;
    _currentReportsPage = 1;
    _currentMatchesPage = 1;
    _currentNotificationsPage = 1;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    if (_state == ProfileState.error) {
      _state = ProfileState.initial;
    }
    notifyListeners();
  }

  /// Get profile summary
  Map<String, dynamic> getProfileSummary() {
    return {
      'user_id': _currentUser?.id,
      'display_name': _currentUser?.displayName,
      'email': _currentUser?.email,
      'avatar_url': _currentUser?.avatarUrl,
      'phone_number': _currentUser?.phoneNumber,
      'role': _currentUser?.role,
      'is_active': _currentUser?.isActive,
      'created_at': _currentUser?.createdAt?.toIso8601String(),
      'stats': _userStats,
      'activity_count': _userActivity.length,
      'reports_count': _userReports.length,
      'matches_count': _userMatches.length,
      'notifications_count': _userNotifications.length,
      'has_preferences': _userPreferences != null,
      'has_settings': _userSettings != null,
    };
  }
}
