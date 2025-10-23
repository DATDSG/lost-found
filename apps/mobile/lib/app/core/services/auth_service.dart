import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/api_models.dart';
import '../repositories/repositories.dart';
import '../utils/encryption_utils.dart';
import '../utils/error_utils.dart';
import 'api_service.dart';

/// Authentication state
class AuthState {
  /// Creates a new [AuthState] instance
  AuthState({this.user, this.isLoading = false, this.error});

  /// The current user, null if not authenticated
  final User? user;

  /// Whether an authentication operation is in progress
  final bool isLoading;

  /// Error message if authentication failed
  final String? error;

  /// Creates a copy of this state with updated values
  AuthState copyWith({User? user, bool? isLoading, String? error}) => AuthState(
    user: user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );

  /// Whether the user is currently authenticated
  bool get isAuthenticated => user != null;
}

/// Authentication service
class AuthService {
  /// Creates a new [AuthService] instance
  AuthService(this._authRepository, this._prefs, this._apiService);
  final AuthRepository _authRepository;
  final SharedPreferences? _prefs;
  final ApiService _apiService;

  /// Get current access token
  String? get accessToken => _apiService.authToken;

  /// Login user
  Future<void> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      // Log login attempt
      final authResponse = await _authRepository.login(email, password);

      // Store access token only
      await _prefs?.setString(
        AppConstants.authTokenKey,
        authResponse.accessToken,
      );

      // Set token in API service
      _apiService.authToken = authResponse.accessToken;

      // Get user profile
      final user = await _authRepository.getCurrentUser();
      await _prefs?.setString(
        AppConstants.userDataKey,
        json.encode(user.toJson()),
      );

      // Handle remember me functionality
      if (rememberMe) {
        await _saveCredentials(email, password);
      } else {
        await _clearSavedCredentials();
      }
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final authResponse = await _authRepository.register(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Store access token only
      await _prefs?.setString(
        AppConstants.authTokenKey,
        authResponse.accessToken,
      );

      // Set token in API service
      _apiService.authToken = authResponse.accessToken;

      // Get user profile
      final user = await _authRepository.getCurrentUser();
      await _prefs?.setString(
        AppConstants.userDataKey,
        json.encode(user.toJson()),
      );
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _authRepository.logout();
      await _prefs?.remove(AppConstants.authTokenKey);
      await _prefs?.remove(AppConstants.userDataKey);

      // Clear saved credentials when logging out
      await _clearSavedCredentials();

      // Clear token from API service
      _apiService.authToken = null;
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Get stored user data
  User? getStoredUser() {
    try {
      final userData = _prefs?.getString(AppConstants.userDataKey);
      if (userData != null) {
        final userJson = json.decode(userData) as Map<String, dynamic>;
        return User.fromJson(userJson);
      }
    } on Exception {
      // Handle parsing error - return null
    }
    return null;
  }

  /// Update user profile
  Future<User> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? location,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    try {
      final updatedUser = await _authRepository.updateProfile(
        displayName: displayName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        bio: bio,
        location: location,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );

      // Update stored user data
      await _prefs?.setString(
        AppConstants.userDataKey,
        json.encode(updatedUser.toJson()),
      );

      return updatedUser;
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Get user profile statistics
  Future<Map<String, dynamic>> getProfileStats() async {
    try {
      return await _authRepository.getProfileStats();
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Get user privacy settings
  Future<Map<String, dynamic>> getPrivacySettings() async {
    try {
      return await _authRepository.getPrivacySettings();
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Update user privacy settings
  Future<Map<String, dynamic>> updatePrivacySettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      return await _authRepository.updatePrivacySettings(settings);
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Delete user account
  Future<void> deleteAccount({required String password, String? reason}) async {
    try {
      await _authRepository.deleteAccount(password: password, reason: reason);

      // Clear stored user data after successful deletion
      await _prefs?.remove(AppConstants.userDataKey);
      await _prefs?.remove(AppConstants.authTokenKey);
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Request user data download
  Future<Map<String, dynamic>> requestDataDownload() async {
    try {
      return await _authRepository.requestDataDownload();
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Get stored access token
  String? getStoredToken() {
    if (kDebugMode) {
      print('Getting stored token...');
      print(
        'SharedPreferences instance: ${_prefs != null ? 'available' : 'null'}',
      );
    }
    final token = _prefs?.getString(AppConstants.authTokenKey);
    if (kDebugMode) {
      print(
        'Stored token: ${token != null ? '${token.substring(0, 10)}...' : 'null'}',
      );
    }
    return token;
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    final token = _prefs?.getString(AppConstants.authTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Initialize authentication from stored data
  Future<void> initializeAuth() async {
    try {
      if (kDebugMode) {
        print('AuthService.initializeAuth() called');
        print(
          'SharedPreferences instance: ${_prefs != null ? 'available' : 'null'}',
        );
      }
      final token = getStoredToken();
      if (token != null && token.isNotEmpty) {
        if (kDebugMode) {
          print('Token found, setting in API service');
        }
        // Set token in API service
        _apiService.authToken = token;

        // Verify token is still valid by getting current user
        try {
          await _authRepository.getCurrentUser();
          if (kDebugMode) {
            print('Token validation successful');
          }
        } on Exception catch (e) {
          // Token is invalid, logout user
          debugPrint('Token validation failed: $e');
          await logout();
        }
      } else {
        if (kDebugMode) {
          print('No token found, clearing API service');
        }
        // No token found, ensure API service is cleared
        _apiService.authToken = null;
      }
    } on Exception catch (e) {
      // If initialization fails, clear stored data
      debugPrint('Auth initialization failed: $e');
      await logout();
    }
  }

  /// Forgot password
  Future<void> forgotPassword(String email) async {
    try {
      await _authRepository.forgotPassword(email);
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Reset password
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _authRepository.resetPassword(token, newPassword);
    } on Exception catch (e) {
      throw handleError(e);
    }
  }

  /// Save credentials for remember me functionality
  Future<void> _saveCredentials(String email, String password) async {
    try {
      await _prefs?.setBool(AppConstants.rememberMeKey, true);
      await _prefs?.setString(AppConstants.savedEmailKey, email);
      await _prefs?.setString(
        AppConstants.savedPasswordKey,
        EncryptionUtils.encrypt(password),
      );
    } on Exception catch (e) {
      // If saving fails, just continue without throwing
      debugPrint('Failed to save credentials: $e');
    }
  }

  /// Clear saved credentials
  Future<void> _clearSavedCredentials() async {
    try {
      await _prefs?.remove(AppConstants.rememberMeKey);
      await _prefs?.remove(AppConstants.savedEmailKey);
      await _prefs?.remove(AppConstants.savedPasswordKey);
    } on Exception catch (e) {
      // If clearing fails, just continue without throwing
      debugPrint('Failed to clear credentials: $e');
    }
  }

  /// Get saved credentials for auto-login
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final rememberMe = _prefs?.getBool(AppConstants.rememberMeKey) ?? false;
      if (!rememberMe) {
        return null;
      }

      final email = _prefs?.getString(AppConstants.savedEmailKey);
      final encryptedPassword = _prefs?.getString(
        AppConstants.savedPasswordKey,
      );

      if (email == null || encryptedPassword == null) {
        return null;
      }

      final password = EncryptionUtils.decrypt(encryptedPassword);
      return {'email': email, 'password': password};
    } on Exception catch (e) {
      debugPrint('Failed to get saved credentials: $e');
      return null;
    }
  }

  /// Check if remember me is enabled
  bool get isRememberMeEnabled =>
      _prefs?.getBool(AppConstants.rememberMeKey) ?? false;

  /// Auto-login using saved credentials
  Future<bool> autoLogin() async {
    try {
      final credentials = await getSavedCredentials();
      if (credentials == null) {
        return false;
      }

      await login(
        credentials['email']!,
        credentials['password']!,
        rememberMe: true,
      );
      return true;
    } on Exception catch (e) {
      debugPrint('Auto-login failed: $e');
      // Clear invalid credentials
      await _clearSavedCredentials();
      return false;
    }
  }
}

/// Authentication state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Authentication service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final apiService = ref.watch(apiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(authRepository, prefs, apiService);
});

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized');
});

/// Authentication notifier
class AuthNotifier extends StateNotifier<AuthState> {
  /// Creates a new [AuthNotifier] instance
  AuthNotifier(this._authService) : super(AuthState()) {
    _initializeAuth();
  }
  final AuthService _authService;

  /// Initialize authentication from stored data
  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);

    try {
      if (kDebugMode) {
        print('Initializing authentication...');
      }

      await _authService.initializeAuth();

      if (_authService.isAuthenticated) {
        final user = _authService.getStoredUser();
        if (kDebugMode) {
          print('User authenticated: ${user?.email}');
        }
        state = state.copyWith(user: user, isLoading: false);
      } else {
        if (kDebugMode) {
          print('User not authenticated');
        }
        state = state.copyWith(isLoading: false);
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Auth initialization error: $e');
      }
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Login user
  Future<void> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.login(email, password, rememberMe: rememberMe);
      final user = _authService.getStoredUser();
      state = state.copyWith(user: user, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      final user = _authService.getStoredUser();
      state = state.copyWith(user: user, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Forgot password
  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.forgotPassword(email);
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reset password
  Future<void> resetPassword(String token, String newPassword) async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.resetPassword(token, newPassword);
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

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
    state = state.copyWith(isLoading: true);

    try {
      final updatedUser = await _authService.updateProfile(
        displayName: displayName,
        phoneNumber: phoneNumber,
        avatarUrl: avatarUrl,
        bio: bio,
        location: location,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );
      state = state.copyWith(user: updatedUser, isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Logout user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.logout();
      state = AuthState();
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith();
  }

  /// Auto-login using saved credentials
  Future<bool> autoLogin() async {
    state = state.copyWith(isLoading: true);

    try {
      final success = await _authService.autoLogin();
      if (success) {
        final user = _authService.getStoredUser();
        state = state.copyWith(user: user, isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

/// Auth notifier provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// API service provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
