import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Authentication service
class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  /// Login with email and password
  Future<User> login(String email, String password) async {
    try {
      final response = await _api.post(
        ApiConfig.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      // Save token
      final token = response.data['token'];
      await _storage.saveToken(token);

      // Parse and return user
      final user = User.fromJson(response.data['user']);
      await _storage.saveUserId(user.id);

      return user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Register new user
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      final response = await _api.post(
        ApiConfig.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );

      // Save token
      final token = response.data['token'];
      await _storage.saveToken(token);

      // Parse and return user
      final user = User.fromJson(response.data['user']);
      await _storage.saveUserId(user.id);

      return user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _api.post(ApiConfig.logout);
    } catch (e) {
      // Continue even if API call fails
    } finally {
      // Always clear local storage
      await _storage.clearAll();
    }
  }

  /// Get user profile
  Future<User> getProfile() async {
    try {
      final response = await _api.get(ApiConfig.profile);
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }
}
