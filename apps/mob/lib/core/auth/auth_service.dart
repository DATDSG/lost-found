import 'package:shared_preferences/shared_preferences.dart';

/// Very lightweight local auth (demo-only).
class AuthService {
  AuthService._();
  static final AuthService I = AuthService._();

  static const _kLoggedIn = 'auth.logged_in';
  static const _kName = 'auth.name';

  bool _isLoggedIn = false;
  String? _name;

  bool get isLoggedIn => _isLoggedIn;
  String? get displayName => _name;

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    _isLoggedIn = sp.getBool(_kLoggedIn) ?? false;
    _name = sp.getString(_kName);
  }

  Future<bool> signInWithPassword(String user, String pass, {bool remember = true}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Accept anything with >= 6 chars as demo creds
    if (user.isNotEmpty && pass.length >= 6) {
      final sp = await SharedPreferences.getInstance();
      _isLoggedIn = true;
      _name = user;
      if (remember) {
        await sp.setBool(_kLoggedIn, true);
        await sp.setString(_kName, user);
      }
      return true;
    }
    return false;
  }

  Future<bool> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (password.length >= 8) {
      final sp = await SharedPreferences.getInstance();
      _isLoggedIn = true;
      _name = fullName;
      await sp.setBool(_kLoggedIn, true);
      await sp.setString(_kName, fullName);
      return true;
    }
    return false;
  }

  Future<bool> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 700));
    final sp = await SharedPreferences.getInstance();
    _isLoggedIn = true;
    _name = 'Google User';
    await sp.setBool(_kLoggedIn, true);
    await sp.setString(_kName, _name!);
    return true;
  }

  Future<void> signOut() async {
    final sp = await SharedPreferences.getInstance();
    _isLoggedIn = false;
    _name = null;
    await sp.remove(_kLoggedIn);
    await sp.remove(_kName);
  }
}
