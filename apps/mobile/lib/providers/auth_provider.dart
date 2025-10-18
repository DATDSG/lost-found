import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Authentication state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  /// Check if user is logged in
  bool get isLoggedIn => isAuthenticated && user != null;
}

/// Authentication provider
class AuthProvider extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthProvider(this._apiService, this._storageService)
      : super(const AuthState()) {
    _initialize();
  }

  void _initialize() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      // Check if user is already authenticated
      final token = await _storageService.getToken();
      if (token != null) {
        // Try to get user profile
        final userData = await _apiService.getProfile();
        if (userData != null) {
          final user = User.fromJson(userData);
          state = state.copyWith(
            user: user,
            isAuthenticated: true,
            isLoading: false,
          );
        } else {
          // Token is invalid, clear it
          await _storageService.clearTokens();
          state = state.copyWith(
            isAuthenticated: false,
            isLoading: false,
          );
        }
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  /// Login user
  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.login(email: email, password: password);
      // Get user profile
      final userData = await _apiService.getProfile();
      if (userData != null) {
        final user = User.fromJson(userData);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(
        error: 'Login failed',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Register user
  Future<bool> register(
      {required String email,
      required String password,
      required String displayName}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.register(
          email: email, password: password, displayName: displayName);
      // Get user profile
      final userData = await _apiService.getProfile();
      if (userData != null) {
        final user = User.fromJson(userData);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(
        error: 'Registration failed',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
    }

    // Clear local state
    await _storageService.clearTokens();
    state = state.copyWith(
      user: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,
    );
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedUserData = await _apiService.updateProfile(profileData);
      if (updatedUserData != null) {
        final updatedUser = User.fromJson(updatedUserData);
        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(
        error: 'Profile update failed',
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword(
      {required String currentPassword, required String newPassword}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.changePassword(
          currentPassword: currentPassword, newPassword: newPassword);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Check authentication status
  Future<void> checkAuth() async {
    await _checkAuth();
  }

  /// Get current user
  User? get user => state.user;

  /// Check if authenticated
  bool get isAuthenticated => state.isAuthenticated;

  /// Check if loading
  bool get isLoading => state.isLoading;

  /// Get current error
  String? get error => state.error;

  /// Get access token
  String? get accessToken {
    // This would need to be implemented based on your token storage
    // For now, returning null as we don't have direct access to token
    return null;
  }
}

/// Auth provider instance
final authProvider = StateNotifierProvider<AuthProvider, AuthState>((ref) {
  final apiService = ApiService();
  final storageService = StorageService();
  return AuthProvider(apiService, storageService);
});
