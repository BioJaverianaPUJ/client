import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:biojaveriana/services/api_client.dart';
import 'package:biojaveriana/services/social_repository.dart';
import 'package:biojaveriana/services/community_repository.dart';

http.Response json(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('XP history reads Spring pagination and server ledger values', () async {
    final api = ApiClient(
      httpClient: MockClient((r) async {
        expect(r.url.path, '/api/v1/gamification/me/xp-history');
        expect(r.url.queryParameters, {'page': '1', 'size': '20'});
        return json({
          'content': [
            {
              'id': 'entry',
              'amount': 25,
              'reason': 'Logro conseguido',
              'totalAfter': 350,
              'levelAfter': 7,
              'createdAt': '2026-11-22T12:00:00Z',
            },
          ],
          'totalPages': 2,
          'number': 1,
        });
      }),
    );
    final history = await SocialRepository(api).xpHistory(page: 1);
    expect(history.hasMore, false);
    expect(history.items.single.amount, 25);
    expect(history.items.single.totalAfter, 350);
    expect(history.items.single.levelAfter, 7);
    expect(history.items.single.date.isUtc, true);
  });
  test(
    'uses server levels, thresholds and completion when target is absent',
    () async {
      final paths = <String>[];
      final api = ApiClient(
        httpClient: MockClient((r) async {
          paths.add(r.url.path);
          if (r.url.path.endsWith('/gamification/me')) {
            return json({
              'totalXp': 350,
              'level': 7,
              'xpForCurrentLevel': 300,
              'xpForNextLevel': 500,
            });
          }
          return json([
            {
              'id': 'a',
              'name': 'Explorador',
              'xpReward': 20,
              'progress': 0,
              'target': null,
              'completed': true,
            },
            {
              'id': 'b',
              'name': 'Fotógrafo',
              'xpReward': 30,
              'progress': 0,
              'target': null,
              'completed': false,
            },
          ]);
        }),
      );
      final result = await SocialRepository(api).progress();
      expect(paths, ['/api/v1/gamification/me', '/api/v1/achievements/me']);
      expect(result.level, 7);
      expect(result.xp, 350);
      expect(result.nextLevelXp, 500);
      expect(result.levelProgress, .25);
      expect(result.achievements.first.completed, true);
      expect(result.achievements.last.completed, false);
      expect(result.missionsAvailable, false);
    },
  );
  test('undeployed endpoint does not invent zero experience', () async {
    final api = ApiClient(httpClient: MockClient((_) async => json({}, 404)));
    await expectLater(
      SocialRepository(api).progress(),
      throwsA(isA<FeatureUnavailable>()),
    );
  });
  test('another profile never displays current user experience', () async {
    final paths = <String>[];
    final api = ApiClient(
      httpClient: MockClient((r) async {
        paths.add(r.url.path);
        return json({'id': 'me'});
      }),
    );
    await expectLater(
      SocialRepository(api).progress(userId: 'other'),
      throwsA(isA<FeatureUnavailable>()),
    );
    expect(paths, ['/api/v1/users/me']);
  });
}
