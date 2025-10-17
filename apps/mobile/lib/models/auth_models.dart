/// Enhanced Authentication Models for comprehensive auth management

import 'auth_token.dart';
import 'user.dart';

/// Authentication state enum
enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Authentication error types
enum AuthErrorType {
  networkError,
  invalidCredentials,
  emailAlreadyExists,
  weakPassword,
  tokenExpired,
  tokenInvalid,
  userNotFound,
  accountDisabled,
  serverError,
  unknown,
}

/// Authentication error model
class AuthError {
  final AuthErrorType type;
  final String message;
  final String? details;
  final int? statusCode;

  AuthError({
    required this.type,
    required this.message,
    this.details,
    this.statusCode,
  });

  factory AuthError.fromException(Exception e) {
    final message = e.toString().replaceAll('Exception: ', '');

    if (message.contains('401') || message.contains('Unauthorized')) {
      return AuthError(
        type: AuthErrorType.invalidCredentials,
        message: 'Invalid email or password',
        details: message,
      );
    } else if (message.contains('400') && message.contains('already')) {
      return AuthError(
        type: AuthErrorType.emailAlreadyExists,
        message: 'Email is already registered',
        details: message,
      );
    } else if (message.contains('expired') || message.contains('refresh')) {
      return AuthError(
        type: AuthErrorType.tokenExpired,
        message: 'Session expired. Please login again.',
        details: message,
      );
    } else if (message.contains('403') || message.contains('disabled')) {
      return AuthError(
        type: AuthErrorType.accountDisabled,
        message: 'Account is disabled',
        details: message,
      );
    } else if (message.contains('404') || message.contains('not found')) {
      return AuthError(
        type: AuthErrorType.userNotFound,
        message: 'User not found',
        details: message,
      );
    } else if (message.contains('network') || message.contains('connection')) {
      return AuthError(
        type: AuthErrorType.networkError,
        message: 'Network error. Please check your connection.',
        details: message,
      );
    } else {
      return AuthError(
        type: AuthErrorType.unknown,
        message: message,
        details: message,
      );
    }
  }

  bool get isNetworkError => type == AuthErrorType.networkError;
  bool get isAuthError => [
    AuthErrorType.invalidCredentials,
    AuthErrorType.tokenExpired,
    AuthErrorType.tokenInvalid,
  ].contains(type);
  bool get isUserError => [
    AuthErrorType.emailAlreadyExists,
    AuthErrorType.weakPassword,
    AuthErrorType.userNotFound,
    AuthErrorType.accountDisabled,
  ].contains(type);
}

/// Authentication session model
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String tokenType;

  AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.createdAt,
    this.tokenType = 'bearer',
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isExpiringSoon =>
      DateTime.now().add(const Duration(minutes: 5)).isAfter(expiresAt);

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
  Duration get timeUntilExpiringSoon =>
      expiresAt.subtract(const Duration(minutes: 5)).difference(DateTime.now());

  factory AuthSession.fromAuthToken(AuthToken token) {
    // JWT tokens typically expire in 15 minutes, but we'll use a default
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));
    return AuthSession(
      accessToken: token.accessToken,
      refreshToken: token.refreshToken,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
      tokenType: token.tokenType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'token_type': tokenType,
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
      tokenType: json['token_type'] ?? 'bearer',
    );
  }
}

/// Authentication result model
class AuthResult {
  final bool success;
  final AuthError? error;
  final User? user;
  final AuthSession? session;

  AuthResult({required this.success, this.error, this.user, this.session});

  factory AuthResult.success({
    required User user,
    required AuthSession session,
  }) {
    return AuthResult(success: true, user: user, session: session);
  }

  factory AuthResult.failure(AuthError error) {
    return AuthResult(success: false, error: error);
  }

  factory AuthResult.fromException(Exception e) {
    return AuthResult.failure(AuthError.fromException(e));
  }
}

/// Password strength validator
class PasswordValidator {
  static const int minLength = 8;
  static const int maxLength = 128;

  static PasswordStrength validate(String password) {
    if (password.isEmpty) {
      return PasswordStrength.empty;
    }

    if (password.length < minLength) {
      return PasswordStrength.weak;
    }

    int score = 0;

    // Length check
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;

    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) score += 1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 1;

    // Common patterns check (penalty)
    if (password.contains(RegExp(r'(.)\1{2,}'))) score -= 1; // Repeated chars
    if (password.contains(RegExp(r'(123|abc|qwe)')))
      score -= 1; // Common sequences

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  static String getStrengthMessage(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return 'Password is required';
      case PasswordStrength.weak:
        return 'Password is too weak. Use at least 8 characters with mixed case, numbers, and symbols.';
      case PasswordStrength.medium:
        return 'Password strength is medium. Consider adding more variety.';
      case PasswordStrength.strong:
        return 'Password strength is good.';
      case PasswordStrength.veryStrong:
        return 'Password strength is excellent.';
    }
  }

  static List<String> getStrengthSuggestions(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.empty:
        return ['Enter a password'];
      case PasswordStrength.weak:
        return [
          'Use at least 8 characters',
          'Include uppercase and lowercase letters',
          'Add numbers and special characters',
          'Avoid common words and patterns',
        ];
      case PasswordStrength.medium:
        return [
          'Use 12+ characters for better security',
          'Add more special characters',
          'Avoid repeated characters',
        ];
      case PasswordStrength.strong:
        return [
          'Consider using 16+ characters',
          'Add more variety in character types',
        ];
      case PasswordStrength.veryStrong:
        return ['Your password is very secure!'];
    }
  }
}

/// Password strength enum
enum PasswordStrength { empty, weak, medium, strong, veryStrong }

/// Email validator
class EmailValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static bool isValid(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  static String? validate(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }

    if (!isValid(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }
}

/// Authentication configuration
class AuthConfig {
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // Password requirements
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const bool requireSpecialChars = true;
  static const bool requireNumbers = true;
  static const bool requireMixedCase = true;

  // Security settings
  static const bool enableBiometricAuth = true;
  static const bool enableRememberMe = true;
  static const Duration rememberMeDuration = Duration(days: 30);
}
