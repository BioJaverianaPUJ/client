import 'package:flutter/foundation.dart';

@immutable
class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.userId,
    required this.email,
    required this.role,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final expiresAt = DateTime.tryParse('${json['expiresIn']}');

    if (token is! String || token.isEmpty || expiresAt == null) {
      throw const FormatException('Respuesta de sesión inválida');
    }

    return AuthSession(
      token: token,
      expiresAt: expiresAt.toUtc(),
      userId: '${json['userId']}',
      email: '${json['email']}',
      role: '${json['role']}',
    );
  }

  final String token;
  final DateTime expiresAt;
  final String userId;
  final String email;
  final String role;

  bool get isAdmin => role == 'ADMIN';

  bool isExpired({Duration margin = Duration.zero}) =>
      !DateTime.now().toUtc().add(margin).isBefore(expiresAt);

  Map<String, dynamic> toJson() => {
        'token': token,
        'expiresIn': expiresAt.toIso8601String(),
        'userId': userId,
        'email': email,
        'role': role,
      };
}
