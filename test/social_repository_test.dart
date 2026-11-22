import 'dart:convert';

import 'package:latlong2/latlong.dart';

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:biojaveriana/models/community.dart';
import 'package:biojaveriana/services/api_client.dart';
import 'package:biojaveriana/services/social_repository.dart';
import 'package:biojaveriana/services/observation_repository.dart';
import 'package:biojaveriana/services/user_service.dart';

Map<String, dynamic> post() => {
  'id': 'p',
  'author': {'id': 'u', 'username': 'explorador', 'firstName': 'Privado'},
  'title': 'Campus',
  'description': 'Una historia',
  'images': [],
  'totalLikes': 2,
  'totalDislikes': 1,
  'userVoteType': 'DISLIKE',
  'createdAt': '2026-11-15T12:00:00Z',
};
http.Response json(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);
void main() {
  test('post photos use the exact signed URL before publishing keys', () async {
    const signedUrl =
        'https://storage.example.test/bucket/posts/u/photo.jpg?X-Amz-Signature=abc123&X-Amz-Credential=user%2Fregion';
    final calls = <String>[];
    final api = ApiClient(
      httpClient: MockClient((request) async {
        calls.add(request.method);
        if (request.url.path.endsWith('/presign')) {
          expect(request.headers['Authorization'], 'Bearer session-token');
          return json({
            'url': signedUrl,
            'key': 'posts/u/photo.jpg',
            'method': 'PUT',
            'contentType': 'image/jpeg',
          });
        }
        if (request.method == 'PUT') {
          expect(request.url.toString(), signedUrl);
          expect(request.headers.containsKey('Authorization'), false);
          expect(request.headers['Content-Type'], 'image/jpeg');
          expect(request.bodyBytes, [1, 2, 3]);
          expect(request.followRedirects, false);
          return http.Response('', 200);
        }
        expect(request.url.path, '/api/v1/posts');
        expect(jsonDecode(request.body)['imageKeys'], ['posts/u/photo.jpg']);
        return json(post());
      }),
    )..token = 'session-token';
    await SocialRepository(api).savePost(
      PostDraft(
        title: 'Campus',
        text: 'Foto de prueba',
        photos: [
          LocalPhoto(Uint8List.fromList([1, 2, 3]), 'photo.jpg', 'image/jpeg'),
        ],
      ),
    );
    expect(calls, ['POST', 'PUT', 'POST']);
    api.close();
  });

  test(
    'post links its observation with observationId and reads it back',
    () async {
      Map<String, dynamic>? sent;
      final api = ApiClient(
        httpClient: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return json({
            ...post(),
            // PostResponse.observation es un ObservationSummaryResponse.
            'observation': {
              'id': 'obs-1',
              'imageUrl': 'https://img.test/obs.jpg',
              'speciesCommonName': 'Pino romerón',
              'observationType': 'PLANT',
              'checked': true,
              'similarityScore': 0.675,
              'certainty': 0.004,
              'createdAt': '2026-11-22T12:00:00Z',
            },
          });
        }),
      );
      final saved = await SocialRepository(api).savePost(
        const PostDraft(
          title: 'Campus',
          text: 'Con observación',
          observationId: 'obs-1',
        ),
      );
      expect(sent!['observationId'], 'obs-1');
      expect(sent!.containsKey('observation'), false);
      expect(saved.observationId, 'obs-1');
      expect(saved.sighting!.photo, 'https://img.test/obs.jpg');
      expect(saved.sighting!.species, 'Pino romerón');
      api.close();
    },
  );

  test('failed storage upload does not publish a post', () async {
    var published = false;
    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/presign')) {
          return json({
            'url': 'https://storage.example.test/photo.jpg',
            'key': 'posts/u/photo.jpg',
            'method': 'PUT',
            'contentType': 'image/jpeg',
          });
        }
        if (request.method == 'PUT') return http.Response('', 403);
        published = true;
        return json(post());
      }),
    );
    await expectLater(
      SocialRepository(api).savePost(
        PostDraft(
          title: 'Campus',
          photos: [
            LocalPhoto(Uint8List.fromList([1]), 'photo.jpg', 'image/jpeg'),
          ],
        ),
      ),
      throwsException,
    );
    expect(published, false);
    api.close();
  });

  test('invalid signed upload metadata never sends an HTTP request', () async {
    var calls = 0;
    final api = ApiClient(
      httpClient: MockClient((request) async {
        calls++;
        return http.Response('', 200);
      }),
    );
    final photo = LocalPhoto(
      Uint8List.fromList([1]),
      'photo.jpg',
      'image/jpeg',
    );
    for (final url in [
      null,
      42,
      '',
      'http://storage.example.test/a',
      'https:///a',
    ]) {
      await expectLater(
        api.uploadSignedPhoto(photo, {
          'url': url,
          'method': 'PUT',
          'contentType': 'image/jpeg',
        }),
        throwsException,
      );
    }
    expect(calls, 0);
    api.close();
  });

  test('telemetry sends precise coordinates once and accepts an empty deduplicated response', () async {
    var calls = 0;
    final api = ApiClient(
      httpClient: MockClient((request) async {
        calls++;
        expect(request.method, 'POST');
        expect(request.url.path.endsWith('/pois/telemetry'), true);
        expect(jsonDecode(request.body), {
          'latitude': 4.6286,
          'longitude': -74.0637,
        });
        return json([]);
      }),
    );
    final repo = SocialRepository(api);
    const point = LatLng(4.6286, -74.0637);
    for (final accuracy in [double.nan, double.infinity, -1.0, 30.1]) {
      await repo.visit(point, accuracy);
    }
    expect(calls, 0);
    await repo.visit(point, 25);
    expect(calls, 1);
    api.close();
  });

  test(
    'feed expands summaries, keeps pagination and both vote counts',
    () async {
      final api = ApiClient(
        httpClient: MockClient((r) async {
          if (r.url.path.endsWith('/count')) return json(3);
          if (r.url.path.endsWith('/posts/p')) return json(post());
          expect(r.url.queryParameters['page'], '1');
          return json({
            'content': [
              {'id': 'p'},
            ],
            'pagination': {'totalPages': 3},
          });
        }),
      );
      final page = await SocialRepository(api).feed(cursor: '1');
      expect(page.nextCursor, '2');
      expect(page.items.single.disliked, true);
      expect(page.items.single.comments, 3);
      expect(page.items.single.authorName, 'explorador');
      api.close();
    },
  );
  test(
    'missing post upload URL never publishes or sends a token to storage',
    () async {
      final paths = <String>[];
      final api = ApiClient(
        httpClient: MockClient((r) async {
          paths.add(r.url.path);
          return json({
            'url': '',
            'key': 'posts/u/1',
            'method': 'PUT',
            'contentType': 'image/jpeg',
          });
        }),
      );
      await expectLater(
        SocialRepository(api).savePost(
          PostDraft(
            title: 'Ave',
            text: 'En el campus',
            photos: [
              LocalPhoto(Uint8List.fromList([1]), 'a.jpg', 'image/jpeg'),
            ],
          ),
        ),
        throwsException,
      );
      expect(paths, ['/api/v1/posts/presign']);
      api.close();
    },
  );
  test(
    'comments load root pages and replies; reports include required post id',
    () async {
      final api = ApiClient(
        httpClient: MockClient((r) async {
          if (r.method == 'POST') {
            final b = jsonDecode(r.body);
            expect(b['reportedPostId'], 'p');
            expect(b['reportedCommentId'], 'c');
            return json({});
          }
          if (r.url.path.endsWith('/comments/c')) return json({'postId': 'p'});
          final reply = r.url.path.endsWith('/replies');
          return json({
            'content': [
              {
                'id': reply ? 'r' : 'c',
                'author': {'id': 'u', 'username': 'yo'},
                'content': 'Hola',
                'parentId': reply ? 'c' : null,
                'createdAt': '2026-11-15T12:00:00Z',
                'totalReactions': 2,
              },
            ],
            'pagination': {'totalPages': 1},
          });
        }),
      );
      final repo = SocialRepository(api);
      final comments = await repo.comments('p');
      expect(comments.length, 2);
      expect(comments.last.parentId, 'c');
      expect(comments.first.reactions, 2);
      await repo.report('c', comment: true, reason: 'Spam');
      api.close();
    },
  );
  test('POI coordinates respect WKT longitude first and point radius', () {
    final polygon = SocialRepository.decodeZone({
      'id': 'z',
      'name': 'Zona',
      'geometryType': 'POLYGON',
      'polygonCoordinatesWkt': 'POLYGON ((-74.064 4.628, -74.063 4.628, -74.063 4.629, -74.064 4.628))',
    });
    expect(polygon.points.first.latitude, 4.628);
    expect(polygon.points.first.longitude, -74.064);
    final circle = SocialRepository.decodeZone({
      'id': 'c',
      'name': 'Lugar',
      'geometryType': 'POINT',
      'centerLatitude': 4.628,
      'centerLongitude': -74.064,
      'radiusMeters': 20,
    });
    expect(circle.points.length, 36);
    // RF-22: el tipo del backend separa zonas verdes y de interés.
    expect(polygon.interest, true);
    final green = SocialRepository.decodeZone({
      'id': 'g',
      'name': 'Jardín',
      'type': 'GREEN_ZONE',
      'geometryType': 'POINT',
      'centerLatitude': 4.628,
      'centerLongitude': -74.064,
      'radiusMeters': 10,
    });
    expect(green.interest, false);
  });
  test('RF14 uses similarity and plant matching rather than confidence', () {
    final r = <String, dynamic>{
      'id': 'o',
      'latitude': 4.628,
      'longitude': -74.064,
      'createdAt': '2026-11-15T12:00:00Z',
      'checked': true,
      'certainty': .99,
      'observationType': 'ANIMAL',
      'similarityScore': .24,
    };
    expect(ObservationRepository.decode(r).status, Verification.unverified);
    expect(
      ObservationRepository.decode({...r, 'similarityScore': .25}).status,
      Verification.verified,
    );
    expect(
      ObservationRepository.decode({
        ...r,
        'observationType': 'PLANT',
        'similarityScore': .4,
      }).status,
      Verification.unverified,
    );
    expect(
      ObservationRepository.decode({
        ...r,
        'observationType': 'PLANT',
        'similarityScore': .4,
        'specimen': {'id': 's'},
      }).status,
      Verification.verified,
    );
    expect(
      ObservationRepository.decode(r, jobStatus: 'FAILED').status,
      Verification.failed,
    );
  });
  test(
    'public profiles discard private data even if the server exposes it',
    () async {
      final api = ApiClient(
        httpClient: MockClient(
          (r) async => json({
            'id': 'u',
            'username': 'visible',
            'firstName': 'Privado',
            'lastName': 'Privado',
            'email': 'private@example.test',
            'gender': 'MALE',
            'role': 'USER',
          }),
        ),
      );
      final u = await UserService(api).byId('u');
      expect(u.username, 'visible');
      expect(u.email, isEmpty);
      expect(u.firstName, isEmpty);
      expect(u.gender, isNull);
      api.close();
    },
  );
  test('publication limits follow the updated SRS', () {
    expect(PostDraft(title: 'a' * 201).validate(), isNotNull);
    expect(PostDraft(title: 'Válido', text: 'b' * 201).validate(), isNotNull);
    expect(const PostDraft(title: 'Válido').validate(), isNull);
  });

  test('only active missions with a zone reveal interest zones', () async {
    final api = ApiClient(
      httpClient: MockClient(
        (_) async => json({
          'daily': [
            {'id': 'm1', 'status': 'ACTIVE', 'poiId': 'zona-1'},
            {'id': 'm2', 'status': 'COMPLETED', 'poiId': 'zona-2'},
          ],
          'weekly': [
            {
              'id': 'm3',
              'status': 'ACTIVE',
              'poi': {'id': 'zona-3', 'name': 'Jardín'},
            },
          ],
          'event': [
            {'id': 'm4', 'status': 'ACTIVE'},
          ],
        }),
      ),
    );
    expect(await SocialRepository(api).missionZoneIds(), {'zona-1', 'zona-3'});
    api.close();
  });
}
