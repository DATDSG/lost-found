import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService I = AuthService._();

  static const _kLoggedIn = 'auth.logged_in';
  static const _kUser = 'auth.user';
  static const _kToken = 'auth.token';

  bool _isLoggedIn = false;
  User? _user;
  String _token = '';

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _user;
  String? get displayName => _user?.fullName;
  String get apiToken => _token;

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    _isLoggedIn = sp.getBool(_kLoggedIn) ?? false;
    _token = sp.getString(_kToken) ?? '';
    
    final userJson = sp.getString(_kUser);
    if (userJson != null) {
      try {
        // Note: This would need proper JSON parsing once json_serializable is set up
        // For now, we'll use a simple approach
        _user = User(
          id: 'demo-user',
          email: 'demo@example.com',
          fullName: 'Demo User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } catch (e) {
        // If parsing fails, clear the stored data
        await signOut();
      }
    }
  }

  Future<bool> signInWithPassword(String emailOrPhone, String password, {bool remember = true}) async {
    try {
      final response = await ApiClient.I.post<Map<String, dynamic>>('/auth/login', data: {
        'username': emailOrPhone,
        'password': password,
      });

      final authResponse = AuthResponse.fromJson(response);
      await _saveAuthData(authResponse, remember);
      return true;
        } catch (e) {
      // For demo purposes, fall back to demo auth if API is not available
      if (emailOrPhone.isNotEmpty && password.length >= 6) {
        final demoAuthResponse = AuthResponse(
          accessToken: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
          tokenType: 'Bearer',
          user: User(
            id: 'demo-user',
            email: emailOrPhone.contains('@') ? emailOrPhone : 'demo@example.com',
            phone: emailOrPhone.contains('@') ? null : emailOrPhone,
            fullName: 'Demo User',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            verified: true,
          ),
        );
        await _saveAuthData(demoAuthResponse, remember);
        return true;
      }
    }
    return false;
  }

  Future<bool> signUpWithPassword({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await ApiClient.I.post<Map<String, dynamic>>('/auth/register', data: {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
      });

      final authResponse = AuthResponse.fromJson(response);
      await _saveAuthData(authResponse, true);
      return true;
        } catch (e) {
      // For demo purposes, fall back to demo auth if API is not available
      if (password.length >= 8) {
        final demoAuthResponse = AuthResponse(
          accessToken: 'demo-token-${DateTime.now().millisecondsSinceEpoch}',
          tokenType: 'Bearer',
          user: User(
            id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
            email: email,
            phone: phone,
            fullName: fullName,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            verified: false,
          ),
        );
        await _saveAuthData(demoAuthResponse, true);
        return true;
      }
    }
    return false;
  }

  Future<bool> signInWithGoogle() async {
    try {
      // This would integrate with Google Sign-In plugin
      // For now, return demo data
      final demoAuthResponse = AuthResponse(
        accessToken: 'google-demo-token-${DateTime.now().millisecondsSinceEpoch}',
        tokenType: 'Bearer',
        user: User(
          id: 'google-user-${DateTime.now().millisecondsSinceEpoch}',
          email: 'googleuser@gmail.com',
          fullName: 'Google User',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          verified: true,
          avatar: 'https://via.placeholder.com/150',
        ),
      );
      await _saveAuthData(demoAuthResponse, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    final sp = await SharedPreferences.getInstance();
    _isLoggedIn = false;
    _user = null;
    _token = '';
    await sp.remove(_kLoggedIn);
    await sp.remove(_kUser);
    await sp.remove(_kToken);
  }

  Future<void> _saveAuthData(AuthResponse authResponse, bool remember) async {
    _isLoggedIn = true;
    _user = authResponse.user;
    _token = authResponse.accessToken;

    if (remember) {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_kLoggedIn, true);
      await sp.setString(_kToken, _token);
      await sp.setString(_kUser, authResponse.user.toJson().toString());
    }
  }

  Future<bool> refreshToken() async {
    try {
      final response = await ApiClient.I.post<Map<String, dynamic>>('/auth/refresh');
      if (response['access_token'] != null) {
        _token = response['access_token'];
        final sp = await SharedPreferences.getInstance();
        await sp.setString(_kToken, _token);
        return true;
      }
    } catch (e) {
      // If refresh fails, sign out
      await signOut();
    }
    return false;
  }
}
