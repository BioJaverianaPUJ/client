import 'dart:convert';
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
      'polygonCoordinatesWkt':
          'POLYGON ((-74.064 4.628, -74.063 4.628, -74.063 4.629, -74.064 4.628))',
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
}
