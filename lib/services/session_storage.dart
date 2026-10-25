import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session.dart';

abstract interface class SessionStorage {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'biojaveriana.session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) {
        return null;
      }
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? AuthSession.fromJson(decoded)
          : null;
    } on Exception {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on Exception {
      return;
    }
  }
}
