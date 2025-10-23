// Import the User model from core models
import '../../../../core/models/api_models.dart';

/// Profile domain models for the lost-found app

/// Profile update request model
class ProfileUpdateRequest {
  /// Creates a new [ProfileUpdateRequest] instance
  ProfileUpdateRequest({this.displayName, this.phoneNumber, this.avatarUrl});

  /// Creates a [ProfileUpdateRequest] instance from JSON
  factory ProfileUpdateRequest.fromJson(Map<String, dynamic> json) =>
      ProfileUpdateRequest(
        displayName: json['display_name'] as String?,
        phoneNumber: json['phone_number'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  /// User's display name
  final String? displayName;

  /// User's phone number
  final String? phoneNumber;

  /// URL to user's avatar image
  final String? avatarUrl;

  /// Converts this [ProfileUpdateRequest] instance to a JSON map
  Map<String, dynamic> toJson() => {
    if (displayName != null) 'display_name': displayName,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };
}

/// Password change request model
class PasswordChangeRequest {
  /// Creates a new [PasswordChangeRequest] instance
  PasswordChangeRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  /// Creates a [PasswordChangeRequest] instance from JSON
  factory PasswordChangeRequest.fromJson(Map<String, dynamic> json) =>
      PasswordChangeRequest(
        currentPassword: json['current_password'] as String,
        newPassword: json['new_password'] as String,
      );

  /// Current password
  final String currentPassword;

  /// New password
  final String newPassword;

  /// Converts this [PasswordChangeRequest] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'current_password': currentPassword,
    'new_password': newPassword,
  };
}

/// Profile statistics model
class ProfileStats {
  /// Creates a new [ProfileStats] instance
  ProfileStats({
    required this.totalReports,
    required this.activeReports,
    required this.resolvedReports,
    required this.draftReports,
    required this.matchesFound,
    required this.successfulMatches,
  });

  /// Creates a [ProfileStats] instance from JSON
  factory ProfileStats.fromJson(Map<String, dynamic> json) => ProfileStats(
    totalReports: json['total_reports'] as int? ?? 0,
    activeReports: json['active_reports'] as int? ?? 0,
    resolvedReports: json['resolved_reports'] as int? ?? 0,
    draftReports: json['draft_reports'] as int? ?? 0,
    matchesFound: json['matches_found'] as int? ?? 0,
    successfulMatches: json['successful_matches'] as int? ?? 0,
  );

  /// Total number of reports created by user
  final int totalReports;

  /// Number of active reports
  final int activeReports;

  /// Number of resolved reports
  final int resolvedReports;

  /// Number of draft reports
  final int draftReports;

  /// Number of matches found for user's reports
  final int matchesFound;

  /// Number of successful matches (resolved)
  final int successfulMatches;

  /// Converts this [ProfileStats] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'total_reports': totalReports,
    'active_reports': activeReports,
    'resolved_reports': resolvedReports,
    'draft_reports': draftReports,
    'matches_found': matchesFound,
    'successful_matches': successfulMatches,
  };
}

/// Profile state enum
enum ProfileState {
  /// Profile is loading
  loading,

  /// Profile is loaded successfully
  loaded,

  /// Profile update is in progress
  updating,

  /// Profile update failed
  updateFailed,

  /// Profile update succeeded
  updateSuccess,
}

/// Profile data model
class ProfileData {
  /// Creates a new [ProfileData] instance
  ProfileData({
    required this.user,
    required this.stats,
    this.state = ProfileState.loading,
    this.error,
  });

  /// Creates a [ProfileData] instance from JSON
  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
    user: User.fromJson(json['user'] as Map<String, dynamic>),
    stats: ProfileStats.fromJson(json['stats'] as Map<String, dynamic>),
    state: ProfileState.values.firstWhere(
      (e) => e.name == json['state'],
      orElse: () => ProfileState.loading,
    ),
    error: json['error'] as String?,
  );

  /// User information
  final User user;

  /// Profile statistics
  final ProfileStats stats;

  /// Current profile state
  final ProfileState state;

  /// Error message if any
  final String? error;

  /// Creates a copy of this [ProfileData] instance with updated values
  ProfileData copyWith({
    User? user,
    ProfileStats? stats,
    ProfileState? state,
    String? error,
  }) => ProfileData(
    user: user ?? this.user,
    stats: stats ?? this.stats,
    state: state ?? this.state,
    error: error ?? this.error,
  );

  /// Converts this [ProfileData] instance to a JSON map
  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'stats': stats.toJson(),
    'state': state.name,
    if (error != null) 'error': error,
  };
}
