// Riverpod providers for profile functionality

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/auth_service.dart';
import '../../domain/models/profile_models.dart';

/// Provider for profile statistics
final profileStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final authService = ref.read(authServiceProvider);

  try {
    final statsData = await authService.getProfileStats();
    return ProfileStats.fromJson(statsData);
  } on Exception catch (_) {
    // Return default stats if API fails
    return ProfileStats(
      totalReports: 0,
      activeReports: 0,
      resolvedReports: 0,
      draftReports: 0,
      matchesFound: 0,
      successfulMatches: 0,
    );
  }
});

/// Provider for complete profile data
final profileDataProvider = FutureProvider<ProfileData>((ref) async {
  final authState = ref.watch(authStateProvider);
  final statsAsync = ref.watch(profileStatsProvider);

  if (authState.user == null) {
    throw Exception('User not authenticated');
  }

  return statsAsync.when(
    data: (stats) => ProfileData(
      user: authState.user!,
      stats: stats,
      state: ProfileState.loaded,
    ),
    loading: () => ProfileData(
      user: authState.user!,
      stats: ProfileStats(
        totalReports: 0,
        activeReports: 0,
        resolvedReports: 0,
        draftReports: 0,
        matchesFound: 0,
        successfulMatches: 0,
      ),
    ),
    error: (error, stackTrace) => ProfileData(
      user: authState.user!,
      stats: ProfileStats(
        totalReports: 0,
        activeReports: 0,
        resolvedReports: 0,
        draftReports: 0,
        matchesFound: 0,
        successfulMatches: 0,
      ),
      state: ProfileState.updateFailed,
      error: error.toString(),
    ),
  );
});

/// Provider for profile update state
final profileUpdateProvider =
    StateNotifierProvider<ProfileUpdateNotifier, ProfileUpdateState>((ref) {
      final authNotifier = ref.read(authStateProvider.notifier);
      return ProfileUpdateNotifier(authNotifier);
    });

/// Profile update state
class ProfileUpdateState {
  /// Creates a new [ProfileUpdateState] instance
  ProfileUpdateState({
    this.isUpdating = false,
    this.isSuccess = false,
    this.error,
  });

  /// Whether profile update is in progress
  final bool isUpdating;

  /// Whether profile update was successful
  final bool isSuccess;

  /// Error message if update failed
  final String? error;

  /// Creates a copy of this state with updated values
  ProfileUpdateState copyWith({
    bool? isUpdating,
    bool? isSuccess,
    String? error,
  }) => ProfileUpdateState(
    isUpdating: isUpdating ?? this.isUpdating,
    isSuccess: isSuccess ?? this.isSuccess,
    error: error ?? this.error,
  );
}

/// Profile update notifier
class ProfileUpdateNotifier extends StateNotifier<ProfileUpdateState> {
  /// Creates a new [ProfileUpdateNotifier] instance
  ProfileUpdateNotifier(this._authNotifier) : super(ProfileUpdateState());
  final AuthNotifier _authNotifier;

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? location,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    state = state.copyWith(isUpdating: true, isSuccess: false);

    try {
      await _authNotifier.updateProfile(
        displayName: displayName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        bio: bio,
        location: location,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );
      state = state.copyWith(isUpdating: false, isSuccess: true);
    } on Exception catch (e) {
      state = state.copyWith(
        isUpdating: false,
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isUpdating: true, isSuccess: false);

    try {
      await _authNotifier.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isUpdating: false, isSuccess: true);
    } on Exception catch (e) {
      state = state.copyWith(
        isUpdating: false,
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  /// Clear success state
  void clearSuccess() {
    state = state.copyWith(isSuccess: false);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith();
  }
}

/// Provider for password change state
final passwordChangeProvider =
    StateNotifierProvider<PasswordChangeNotifier, PasswordChangeState>((ref) {
      final authNotifier = ref.read(authStateProvider.notifier);
      return PasswordChangeNotifier(authNotifier);
    });

/// Password change state
class PasswordChangeState {
  /// Creates a new [PasswordChangeState] instance
  PasswordChangeState({
    this.isChanging = false,
    this.isSuccess = false,
    this.error,
  });

  /// Whether password change is in progress
  final bool isChanging;

  /// Whether password change was successful
  final bool isSuccess;

  /// Error message if change failed
  final String? error;

  /// Creates a copy of this state with updated values
  PasswordChangeState copyWith({
    bool? isChanging,
    bool? isSuccess,
    String? error,
  }) => PasswordChangeState(
    isChanging: isChanging ?? this.isChanging,
    isSuccess: isSuccess ?? this.isSuccess,
    error: error ?? this.error,
  );
}

/// Password change notifier
class PasswordChangeNotifier extends StateNotifier<PasswordChangeState> {
  /// Creates a new [PasswordChangeNotifier] instance
  PasswordChangeNotifier(this._authNotifier) : super(PasswordChangeState());
  final AuthNotifier _authNotifier;

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isChanging: true, isSuccess: false);

    try {
      await _authNotifier.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isChanging: false, isSuccess: true);
    } on Exception catch (e) {
      state = state.copyWith(
        isChanging: false,
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  /// Clear success state
  void clearSuccess() {
    state = state.copyWith(isSuccess: false);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith();
  }
}
