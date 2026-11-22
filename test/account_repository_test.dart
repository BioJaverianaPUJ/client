import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:biojaveriana/services/account_repository.dart';
import 'package:biojaveriana/services/api_client.dart';
import 'package:biojaveriana/services/community_repository.dart';

http.Response json(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('RF-40: cambia la contraseña y traduce los errores del servidor', () async {
    final bodies = <Map<String, dynamic>>[];
    var wrong = true;
    final api = ApiClient(
      httpClient: MockClient((r) async {
        expect(r.method, 'PATCH');
        expect(r.url.path, '/api/v1/users/me/password');
        bodies.add(jsonDecode(r.body) as Map<String, dynamic>);
        return wrong
            ? json({'code': 'INVALID_CURRENT_PASSWORD'}, 400)
            : json({'id': 'u'});
      }),
    )..token = 't';
    final repo = ApiAccountRepository(api);
    await expectLater(
      repo.changePassword('mala', 'nueva-clave'),
      throwsA(
        isA<FeatureUnavailable>().having(
          (e) => e.message,
          'message',
          contains('actual no es correcta'),
        ),
      ),
    );
    wrong = false;
    await repo.changePassword('buena', 'nueva-clave');
    expect(bodies.last, {
      'currentPassword': 'buena',
      'newPassword': 'nueva-clave',
    });
    api.close();
  });

  test('RF-41: sin la contraseña correcta no elimina la cuenta', () async {
    final calls = <String>[];
    var valid = false;
    final api = ApiClient(
      httpClient: MockClient((r) async {
        calls.add('${r.method} ${r.url.path}');
        if (r.url.path.endsWith('/auth/login')) {
          return valid
              ? json({
                  'token': 'x',
                  'expiresIn': '2030-01-01T00:00:00Z',
                })
              : json({'code': 'INVALID_CREDENTIALS'}, 401);
        }
        return http.Response('', 204);
      }),
    )..token = 't';
    final repo = ApiAccountRepository(api);
    await expectLater(
      repo.deleteAccount(email: 'a@b.co', password: 'mala'),
      throwsA(isA<FeatureUnavailable>()),
    );
    expect(calls, ['POST /api/v1/auth/login']);
    valid = true;
    await repo.deleteAccount(email: 'a@b.co', password: 'buena');
    expect(calls.last, 'DELETE /api/v1/users/me');
    api.close();
  });
}
