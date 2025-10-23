/// Models for privacy settings functionality
library;

/// Privacy settings model
class PrivacySettings {

  /// Creates a new privacy settings instance
  const PrivacySettings({
    required this.profileVisibility,
    required this.showEmail,
    required this.showPhone,
    required this.allowMessages,
    required this.showLocation,
    required this.allowNotifications,
  });

  /// Creates from JSON
  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      PrivacySettings(
        profileVisibility: json['profile_visibility'] as bool? ?? true,
        showEmail: json['show_email'] as bool? ?? false,
        showPhone: json['show_phone'] as bool? ?? true,
        allowMessages: json['allow_messages'] as bool? ?? true,
        showLocation: json['show_location'] as bool? ?? true,
        allowNotifications: json['allow_notifications'] as bool? ?? true,
      );
  /// Whether the profile is visible to other users
  final bool profileVisibility;

  /// Whether to show email address on profile
  final bool showEmail;

  /// Whether to show phone number on profile
  final bool showPhone;

  /// Whether to allow messages from other users
  final bool allowMessages;

  /// Whether to show location in reports
  final bool showLocation;

  /// Whether to allow push notifications
  final bool allowNotifications;

  /// Converts to JSON
  Map<String, dynamic> toJson() => {
    'profile_visibility': profileVisibility,
    'show_email': showEmail,
    'show_phone': showPhone,
    'allow_messages': allowMessages,
    'show_location': showLocation,
    'allow_notifications': allowNotifications,
  };

  /// Creates a copy with updated values
  PrivacySettings copyWith({
    bool? profileVisibility,
    bool? showEmail,
    bool? showPhone,
    bool? allowMessages,
    bool? showLocation,
    bool? allowNotifications,
  }) => PrivacySettings(
    profileVisibility: profileVisibility ?? this.profileVisibility,
    showEmail: showEmail ?? this.showEmail,
    showPhone: showPhone ?? this.showPhone,
    allowMessages: allowMessages ?? this.allowMessages,
    showLocation: showLocation ?? this.showLocation,
    allowNotifications: allowNotifications ?? this.allowNotifications,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacySettings &&
          other.profileVisibility == profileVisibility &&
          other.showEmail == showEmail &&
          other.showPhone == showPhone &&
          other.allowMessages == allowMessages &&
          other.showLocation == showLocation &&
          other.allowNotifications == allowNotifications;

  @override
  int get hashCode => Object.hash(
    profileVisibility,
    showEmail,
    showPhone,
    allowMessages,
    showLocation,
    allowNotifications,
  );
}
