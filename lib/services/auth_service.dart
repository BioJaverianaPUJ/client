import '../models/auth_session.dart';
import '../models/registration_data.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AuthService {
  const AuthService(this._api);

  final ApiClient _api;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    return _parse(json);
  }

  Future<AuthSession> register(RegistrationData data) async {
    final json = await _api.post(
      '/auth/register',
      body: data.toJson(),
      authenticated: false,
    );
    return _parse(json);
  }

  Future<AuthSession> refresh() async {
    final json = await _api.post('/auth/refresh-token');
    return _parse(json);
  }

  AuthSession _parse(Map<String, dynamic> json) {
    try {
      return AuthSession.fromJson(json);
    } on FormatException {
      throw const ApiException(ApiErrorKind.server);
    }
  }
}
