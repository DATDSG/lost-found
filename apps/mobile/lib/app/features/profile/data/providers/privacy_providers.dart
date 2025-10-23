import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/auth_service.dart';
import '../../domain/models/privacy_models.dart';

/// Provider for privacy settings state
final privacySettingsProvider =
    StateNotifierProvider<PrivacySettingsNotifier, PrivacySettingsState>(
      (ref) => PrivacySettingsNotifier(ref.read(authServiceProvider)),
    );

/// State for privacy settings
class PrivacySettingsState {
  /// Creates a new privacy settings state
  const PrivacySettingsState({
    this.isLoading = false,
    this.isSaving = false,
    this.isSuccess = false,
    this.error,
    this.settings,
  });

  /// Whether the settings are currently loading
  final bool isLoading;

  /// Whether the settings are currently being saved
  final bool isSaving;

  /// Whether the last operation was successful
  final bool isSuccess;

  /// Error message if any operation failed
  final String? error;

  /// Current privacy settings
  final PrivacySettings? settings;

  /// Creates a copy of this state with updated values
  PrivacySettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isSuccess,
    String? error,
    PrivacySettings? settings,
  }) => PrivacySettingsState(
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    isSuccess: isSuccess ?? this.isSuccess,
    error: error,
    settings: settings ?? this.settings,
  );
}

/// Notifier for managing privacy settings
class PrivacySettingsNotifier extends StateNotifier<PrivacySettingsState> {
  /// Creates a new privacy settings notifier
  PrivacySettingsNotifier(this._authService)
    : super(const PrivacySettingsState());

  final AuthService _authService;

  /// Loads privacy settings from the server
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);

    try {
      // Get privacy settings from the server
      final response = await _authService.getPrivacySettings();
      final settings = PrivacySettings.fromJson(response);

      state = state.copyWith(isLoading: false, settings: settings);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Saves privacy settings to the server
  Future<void> saveSettings(PrivacySettings settings) async {
    state = state.copyWith(isSaving: true);

    try {
      // Update privacy settings on the server
      await _authService.updatePrivacySettings(settings.toJson());

      state = state.copyWith(
        isSaving: false,
        isSuccess: true,
        settings: settings,
      );

      // Clear success state after 3 seconds
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(isSuccess: false);
        }
      });
    } on Exception catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  /// Clears the success state
  void clearSuccess() {
    state = state.copyWith(isSuccess: false);
  }
}
