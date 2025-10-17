import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/auth_token.dart';
import '../models/auth_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Comprehensive Authentication Service
///
/// Handles all authentication operations including:
/// - User registration and login
/// - Token management and refresh
/// - Password management
/// - Session management
/// - Security features
class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Current session state
  AuthSession? _currentSession;
  User? _currentUser;
  AuthState _authState = AuthState.initial;
  AuthError? _lastError;

  // Getters
  AuthSession? get currentSession => _currentSession;
  User? get currentUser => _currentUser;
  AuthState get authState => _authState;
  AuthError? get lastError => _lastError;
  bool get isAuthenticated => _currentUser != null && _currentSession != null;
  bool get isSessionValid =>
      _currentSession != null && !_currentSession!.isExpired;

  /// Initialize authentication service
  Future<void> initialize() async {
    try {
      _authState = AuthState.loading;

      // Load stored session and user
      final storedSession = await _loadStoredSession();
      final storedUser = await _storageService.getUser();

      if (storedSession != null && storedUser != null) {
        _currentSession = storedSession;
        _currentUser = storedUser;

        // Set tokens in API service
        _apiService.setTokens(
          storedSession.accessToken,
          storedSession.refreshToken,
        );

        // Verify session is still valid
        if (await _verifySession()) {
          _authState = AuthState.authenticated;
        } else {
          await _clearSession();
          _authState = AuthState.unauthenticated;
        }
      } else {
        _authState = AuthState.unauthenticated;
      }
    } catch (e) {
      _lastError = AuthError.fromException(Exception(e.toString()));
      _authState = AuthState.error;
      await _clearSession();
    }
  }

  /// Register a new user
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    try {
      _authState = AuthState.loading;
      _lastError = null;

      // Validate inputs
      final emailError = EmailValidator.validate(email);
      if (emailError != null) {
        _lastError = AuthError(
          type: AuthErrorType.invalidCredentials,
          message: emailError,
        );
        _authState = AuthState.error;
        return AuthResult.failure(_lastError!);
      }

      final passwordStrength = PasswordValidator.validate(password);
      if (passwordStrength == PasswordStrength.weak) {
        _lastError = AuthError(
          type: AuthErrorType.weakPassword,
          message: PasswordValidator.getStrengthMessage(passwordStrength),
        );
        _authState = AuthState.error;
        return AuthResult.failure(_lastError!);
      }

      // Call API
      final token = await _apiService.register(
        email: email,
        password: password,
        displayName: displayName,
        phoneNumber: phoneNumber,
      );

      // Create session
      final session = AuthSession.fromAuthToken(token);
      final user = await _apiService.getCurrentUser();

      // Store session and user
      await _saveSession(session);
      await _storageService.saveUser(user);

      _currentSession = session;
      _currentUser = user;
      _authState = AuthState.authenticated;

      return AuthResult.success(user: user, session: session);
    } catch (e) {
      _lastError = AuthError.fromException(Exception(e.toString()));
      _authState = AuthState.error;
      return AuthResult.failure(_lastError!);
    }
  }

  /// Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      _authState = AuthState.loading;
      _lastError = null;

      // Validate inputs
      final emailError = EmailValidator.validate(email);
      if (emailError != null) {
        _lastError = AuthError(
          type: AuthErrorType.invalidCredentials,
          message: emailError,
        );
        _authState = AuthState.error;
        return AuthResult.failure(_lastError!);
      }

      if (password.isEmpty) {
        _lastError = AuthError(
          type: AuthErrorType.invalidCredentials,
          message: 'Password is required',
        );
        _authState = AuthState.error;
        return AuthResult.failure(_lastError!);
      }

      // Call API
      final token = await _apiService.login(email: email, password: password);

      // Create session
      final session = AuthSession.fromAuthToken(token);
      final user = await _apiService.getCurrentUser();

      // Store session and user
      await _saveSession(session);
      await _storageService.saveUser(user);

      _currentSession = session;
      _currentUser = user;
      _authState = AuthState.authenticated;

      return AuthResult.success(user: user, session: session);
    } catch (e) {
      _lastError = AuthError.fromException(Exception(e.toString()));
      _authState = AuthState.error;
      return AuthResult.failure(_lastError!);
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Call API logout to invalidate tokens on server
      await _apiService.logout();
    } catch (e) {
      debugPrint('API logout failed: $e');
    } finally {
      await _clearSession();
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    if (_currentSession == null) {
      return false;
    }

    try {
      final token = await _apiService.refreshToken();
      final newSession = AuthSession.fromAuthToken(token);

      await _saveSession(newSession);
      _currentSession = newSession;

      return true;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await _clearSession();
      return false;
    }
  }

  /// Change user password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Validate new password
      final passwordStrength = PasswordValidator.validate(newPassword);
      if (passwordStrength == PasswordStrength.weak) {
        _lastError = AuthError(
          type: AuthErrorType.weakPassword,
          message: PasswordValidator.getStrengthMessage(passwordStrength),
        );
        return false;
      }

      await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      return true;
    } catch (e) {
      _lastError = AuthError.fromException(Exception(e.toString()));
      return false;
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      final emailError = EmailValidator.validate(email);
      if (emailError != null) {
        _lastError = AuthError(
          type: AuthErrorType.invalidCredentials,
          message: emailError,
        );
        return false;
      }

      await _apiService.requestPasswordReset(email);
      return true;
    } catch (e) {
      _lastError = AuthError.fromException(Exception(e.toString()));
      return false;
    }
  }

  /// Reset password with token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final passwordStrength = PasswordValidator.validate(newPassword);
      if (passwordStrength == PasswordStrength.weak) {
        _lastError = AuthError(
          type: AuthErrorType.weakPassword,
          message: PasswordValidator.getStrengthMessage(passwordStrength),
        );
        return false;
      }

      await _apiService.resetPassword(token: token, newPassword: newPassword);

      return true;
    } catch (e) {
      _lastError = AuthError.fromException(Exception(e.toString()));
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String displayName,
    String? phoneNumber,
  }) async {
    try {
      final updatedUser = await _apiService.updateProfile({
        'display_name': displayName,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      });

      _currentUser = updatedUser;
      await _storageService.saveUser(updatedUser);
      return true;
    } catch (e) {
      _lastError = AuthError.fromException(Exception(e.toString()));
      return false;
    }
  }

  /// Upload user avatar
  Future<bool> uploadAvatar(File avatarFile) async {
    try {
      final avatarUrl = await _apiService.uploadAvatar(avatarFile.path);

      // Update user with new avatar URL
      final updatedUser = await _apiService.updateProfile({
        'avatar_url': avatarUrl,
      });

      _currentUser = updatedUser;
      await _storageService.saveUser(updatedUser);
      return true;
    } catch (e) {
      _lastError = AuthError.fromException(Exception(e.toString()));
      return false;
    }
  }

  /// Verify current session
  Future<bool> verifySession() async {
    if (_currentSession == null) {
      return false;
    }

    if (_currentSession!.isExpired) {
      return await refreshToken();
    }

    return await _verifySession();
  }

  /// Check if session needs refresh
  bool get needsTokenRefresh {
    return _currentSession?.isExpiringSoon ?? false;
  }

  /// Get authentication status
  Map<String, dynamic> getAuthStatus() {
    return {
      'isAuthenticated': isAuthenticated,
      'isSessionValid': isSessionValid,
      'needsTokenRefresh': needsTokenRefresh,
      'authState': _authState.name,
      'hasError': _lastError != null,
      'errorType': _lastError?.type.name,
      'errorMessage': _lastError?.message,
      'userId': _currentUser?.id,
      'userEmail': _currentUser?.email,
      'userRole': _currentUser?.role,
      'sessionExpiresAt': _currentSession?.expiresAt.toIso8601String(),
      'timeUntilExpiry': _currentSession?.timeUntilExpiry.inMinutes,
    };
  }

  /// Clear error
  void clearError() {
    _lastError = null;
  }

  // Private methods

  Future<AuthSession?> _loadStoredSession() async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        return AuthSession.fromAuthToken(token);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading stored session: $e');
      return null;
    }
  }

  Future<void> _saveSession(AuthSession session) async {
    try {
      final token = AuthToken(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        tokenType: session.tokenType,
      );
      await _storageService.saveToken(token);
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<void> _clearSession() async {
    _currentSession = null;
    _currentUser = null;
    _authState = AuthState.unauthenticated;
    _lastError = null;

    _apiService.clearTokens();
    await _storageService.clearAll();
  }

  Future<bool> _verifySession() async {
    try {
      await _apiService.getCurrentUser();
      return true;
    } catch (e) {
      return false;
    }
  }
}
