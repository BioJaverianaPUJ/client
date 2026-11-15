import 'dart:convert';

import 'package:biojaveriana/models/auth_session.dart';
import 'package:biojaveriana/services/api_client.dart';
import 'package:biojaveriana/services/session_storage.dart';
import 'package:biojaveriana/state/session_controller.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemorySessionStorage implements SessionStorage {
  MemorySessionStorage([this.session]);

  AuthSession? session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession session) async => this.session = session;

  @override
  Future<void> clear() async => session = null;
}

class FakeBackend {
  final requests = <http.Request>[];
  final routes = <String, http.Response Function(http.Request)>{};

  void on(String method, String path, http.Response Function(http.Request) h) =>
      routes['$method $path'] = h;

  late final client = MockClient((request) async {
    requests.add(request);
    final key =
        '${request.method} ${request.url.path.replaceFirst('/api/v1', '')}';
    final handler = routes[key];
    if (handler == null) {
      return json({'status': 404, 'code': 'NOT_FOUND'}, 404);
    }
    return handler(request);
  });

  SessionController controller(SessionStorage storage) => SessionController(
    api: ApiClient(httpClient: client, baseUrl: 'https://api.test/api/v1'),
    storage: storage,
    autoRefresh: false,
  );
}

http.Response json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> sessionJson({
  Duration validFor = const Duration(hours: 1),
}) {
  final expires = DateTime.now().toUtc().add(validFor).toIso8601String();
  return {
    'userId': '943e5eda-be65-40bc-b896-a4daad3f3d85',
    'email': 'brayan@example.com',
    'role': 'USER',
    'token': 'token-de-prueba',
    'expiresIn': expires.replaceFirst('Z', '244Z'),
  };
}

Map<String, dynamic> profileJson() => {
  'id': '943e5eda-be65-40bc-b896-a4daad3f3d85',
  'firstName': 'Brayan',
  'lastName': 'Fajardo',
  'username': 'brayanfajardo',
  'email': 'brayan@example.com',
  'role': 'USER',
  'gender': 'MALE',
  'profilePictureUrl': null,
  'bannerUrl': null,
};
