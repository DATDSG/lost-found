import 'dart:io';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'messaging_provider.dart';
import '../core/error/api_error_handler.dart';

/// Authentication Provider
class AuthProvider with ChangeNotifier {
  // For testing only: set user directly
  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      final token = await _storageService.getToken();
      final user = await _storageService.getUser();

      if (token != null && user != null) {
        _apiService.setTokens(token.accessToken, token.refreshToken);
        _user = user;
        notifyListeners();

        // Verify token is still valid
        try {
          final currentUser = await _apiService.getCurrentUser();
          _user = currentUser;
          await _storageService.saveUser(currentUser);
          notifyListeners();
        } catch (e) {
          // Token expired, try to refresh
          await _refreshToken();
        }
      }
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _apiService.register(
        email: email,
        password: password,
        displayName: displayName ?? '',
      );
      await _storageService.saveToken(token);

      final user = await _apiService.getCurrentUser();
      _user = user;
      await _storageService.saveUser(user);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiErrorHandler.handleApiError(e, context: 'User Registration');
      _isLoading = false;
      notifyListeners();

      ApiErrorHandler.logError(e, context: 'User Registration');
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _apiService.login(email: email, password: password);
      await _storageService.saveToken(token);

      final user = await _apiService.getCurrentUser();
      _user = user;
      await _storageService.saveUser(user);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiErrorHandler.handleApiError(e, context: 'User Login');
      _isLoading = false;
      notifyListeners();

      ApiErrorHandler.logError(e, context: 'User Login');
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    // Disconnect WebSocket
    try {
      final messagingProvider = Provider.of<MessagingProvider>(
        context,
        listen: false,
      );
      await messagingProvider.disconnect();
    } catch (_) {}

    // Call API logout to invalidate tokens on server
    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('API logout failed: $e');
    }

    // Clear local storage and state
    await _storageService.clearAll();
    _user = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String displayName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _apiService.updateProfile({
        'display_name': displayName,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      });

      _user = updatedUser;
      await _storageService.saveUser(updatedUser);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadAvatar(File avatarFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final avatarUrl = await _apiService.uploadAvatar(avatarFile.path);

      // Update user with new avatar URL
      final updatedUser = await _apiService.updateProfile({
        'avatar_url': avatarUrl,
      });
      _user = updatedUser;
      await _storageService.saveUser(updatedUser);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      _user = user;
      await _storageService.saveUser(user);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  String? get accessToken {
    return _apiService.accessToken;
  }

  Future<void> _refreshToken() async {
    try {
      final token = await _apiService.refreshToken();
      await _storageService.saveToken(token);

      final user = await _apiService.getCurrentUser();
      _user = user;
      await _storageService.saveUser(user);
      notifyListeners();
    } catch (e) {
      // Fallback logout if context is not available
      _apiService.clearTokens();
      await _storageService.clearAll();
      _user = null;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Change user password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify if current token is valid
  Future<bool> verifyToken() async {
    try {
      return await _apiService.verifyToken();
    } catch (e) {
      debugPrint('Token verification failed: $e');
      return false;
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.requestPasswordReset(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset password with token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.resetPassword(token: token, newPassword: newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if user is authenticated and token is valid
  Future<bool> checkAuthStatus() async {
    if (!isAuthenticated) {
      return false;
    }

    try {
      final isValid = await verifyToken();
      if (!isValid) {
        // Token is invalid, try to refresh
        await _refreshToken();
        return isAuthenticated;
      }
      return true;
    } catch (e) {
      debugPrint('Auth status check failed: $e');
      return false;
    }
  }

  /// Get authentication status summary
  Map<String, dynamic> getAuthStatus() {
    return {
      'isAuthenticated': isAuthenticated,
      'hasUser': _user != null,
      'hasAccessToken': _apiService.accessToken != null,
      'isLoading': _isLoading,
      'hasError': _error != null,
      'userId': _user?.id,
      'userEmail': _user?.email,
      'userRole': _user?.role,
    };
  }
}
