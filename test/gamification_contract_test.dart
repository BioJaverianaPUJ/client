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
          'pagination': {'page': 1, 'size': 20, 'totalPages': 3},
        });
      }),
    );
    final history = await SocialRepository(api).xpHistory(page: 1);
    expect(history.hasMore, true);
    expect(history.items.single.amount, 25);
    expect(history.items.single.totalAfter, 350);
    expect(history.items.single.levelAfter, 7);
    expect(history.items.single.date.isUtc, true);
  });
  test(
    'reads PredicateProgress, mission board and the fun fact of the day',
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
          if (r.url.path.endsWith('/achievements/me')) {
            return json({
              'content': [
                {
                  'id': 'a',
                  'name': 'Explorador',
                  'xpReward': 20,
                  'completed': true,
                  'progress': {
                    'type': 'CONDITION',
                    'satisfied': true,
                    'metric': 'observations',
                    'current': 4,
                    'target': 3,
                  },
                },
                {
                  'id': 'b',
                  'name': 'Fotógrafo',
                  'xpReward': 15,
                  'completed': false,
                  'progress': {
                    'type': 'AND',
                    'satisfied': false,
                    'metChildren': 1,
                    'totalChildren': 2,
                  },
                },
              ],
              'pagination': {'totalPages': 1},
            });
          }
          if (r.url.path.endsWith('/missions/me')) {
            return json({
              'daily': [
                {
                  'id': 'm1',
                  'name': 'Observa 2 especies',
                  'xpReward': 10,
                  'type': 'DAILY',
                  'status': 'ACTIVE',
                  'periodEnd': '2026-11-23T05:00:00Z',
                  'progress': {
                    'type': 'CONDITION',
                    'satisfied': false,
                    'current': 1,
                    'target': 2,
                  },
                },
              ],
              'weekly': [
                {
                  'id': 'm2',
                  'name': 'Vencida',
                  'xpReward': 5,
                  'type': 'WEEKLY',
                  'status': 'EXPIRED',
                },
              ],
              'event': [],
            });
          }
          return json({
            'displayDate': '2026-11-22',
            'funFact': {
              'id': 'f',
              'title': 'El roble andino',
              'description': 'Puede vivir siglos.',
              'images': [
                {'url': 'https://img.test/2.jpg', 'orderIndex': 1},
                {'url': 'https://img.test/1.jpg', 'orderIndex': 0},
              ],
              'poi': {
                'id': 'z',
                'name': 'Jardín',
                'geometryType': 'POINT',
                'type': 'GREEN_ZONE',
                'centerLatitude': 4.6286,
                'centerLongitude': -74.0637,
                'radiusMeters': 20,
              },
            },
          });
        }),
      );
      final result = await SocialRepository(api).progress();
      expect(paths, [
        '/api/v1/gamification/me',
        '/api/v1/achievements/me',
        '/api/v1/missions/me',
        '/api/v1/motd/today',
      ]);
      expect(result.level, 7);
      expect(result.levelProgress, .25);
      expect(result.achievements.first.completed, true);
      expect(result.achievements.first.progress, 4);
      expect(result.achievements.last.progress, 1);
      expect(result.achievements.last.target, 2);
      expect(result.missionsAvailable, true);
      expect(result.missions.single.title, 'Observa 2 especies');
      expect(result.missions.single.period, 'Diarias');
      expect(result.missions.single.target, 2);
      expect(result.missions.single.endsAt, isNotNull);
      expect(result.curiosity!.title, 'El roble andino');
      expect(result.curiosity!.images.first, 'https://img.test/1.jpg');
      expect(result.curiosity!.zone!.interest, false);
    },
  );
  test('missing missions or fun fact do not hide the experience', () async {
    final api = ApiClient(
      httpClient: MockClient((r) async {
        if (r.url.path.endsWith('/gamification/me')) {
          return json({
            'totalXp': 0,
            'level': 1,
            'xpForCurrentLevel': 0,
            'xpForNextLevel': 100,
          });
        }
        if (r.url.path.endsWith('/achievements/me')) {
          return json({
            'content': [],
            'pagination': {'totalPages': 0},
          });
        }
        if (r.url.path.endsWith('/motd/today')) {
          return http.Response('null', 200);
        }
        return json({}, 404);
      }),
    );
    final result = await SocialRepository(api).progress();
    expect(result.missionsAvailable, false);
    expect(result.curiosity, isNull);
    expect(result.level, 1);
  });
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
