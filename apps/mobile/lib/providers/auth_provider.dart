import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service_manager.dart';
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
  final ApiServiceManager _apiService;
  final StorageService _storageService;

  AuthProvider(this._apiService, this._storageService)
      : super(const AuthState()) {
    _initialize();
  }

  void _initialize() async {
    state = state.copyWith(isLoading: true);
    try {
      // Check if user is already authenticated
      final token = await _storageService.getToken();
      if (token != null) {
        // Try to get user profile
        final user = await _apiService.getProfile();
        if (user != null) {
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
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _apiService.login(email, password);
      if (token != null) {
        // Get user profile
        final user = await _apiService.getProfile();
        if (user != null) {
          state = state.copyWith(
            user: user,
            isAuthenticated: true,
            isLoading: false,
          );
          return true;
        }
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
  Future<bool> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _apiService.register(email, password, name);
      if (token != null) {
        // Get user profile
        final user = await _apiService.getProfile();
        if (user != null) {
          state = state.copyWith(
            user: user,
            isAuthenticated: true,
            isLoading: false,
          );
          return true;
        }
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
      final updatedUser = await _apiService.updateProfile(profileData);
      if (updatedUser != null) {
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
      String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.changePassword(currentPassword, newPassword);
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

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Check authentication status
  Future<void> checkAuth() async {
    await _initialize();
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
  final apiService = ApiServiceManager();
  final storageService = StorageService();
  return AuthProvider(apiService, storageService);
});
