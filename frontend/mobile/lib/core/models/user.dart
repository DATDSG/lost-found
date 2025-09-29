class User {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool verified;
  final String? avatar;

  const User({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    required this.createdAt,
    required this.updatedAt,
    this.verified = false,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'] as String,
      phone: json['phone'] as String?,
      fullName: json['full_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      verified: json['verified'] as bool? ?? false,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'verified': verified,
      'avatar': avatar,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final User user;

  const AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}
