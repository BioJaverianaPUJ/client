import 'package:latlong2/latlong.dart';
import '../models/community.dart';
import 'community_repository.dart';
import 'observation_repository.dart';

/// Adapts the deployed social API without granting experience locally.
class SocialRepository extends ObservationRepository {
  SocialRepository(super.api);
  @override
  bool get available => true;
  @override
  bool get observationDeletionAvailable => false;
  @override
  bool get observationRetryAvailable => false;
  String _id(String id) => Uri.encodeComponent(id);

  Future<List<Map<String, dynamic>>> _all(String path) async {
    final rows = <Map<String, dynamic>>[];
    var page = 0;
    while (true) {
      final r = await api.get(
        '$path${path.contains('?') ? '&' : '?'}page=$page&size=100',
      );
      rows.addAll((r['content'] as List).cast<Map<String, dynamic>>());
      if (++page >= ((r['pagination'] as Map)['totalPages'] as num)) break;
    }
    return rows;
  }

  static CommunityPost decodePost(
    Map<String, dynamic> row, {
    Sighting? sighting,
    int count = 0,
  }) {
    final author = row['author'] as Map<String, dynamic>;
    return CommunityPost(
      id: row['id'] as String,
      authorId: author['id'] as String,
      authorName: author['username'] as String? ?? 'Usuario',
      avatar: author['profilePictureUrl'] as String?,
      title: row['title'] as String? ?? '',
      text: row['description'] as String? ?? '',
      date: DateTime.parse(row['createdAt'] as String),
      images: (row['images'] as List? ?? [])
          .map((e) => e['url'] as String)
          .toList(),
      likes: (row['totalLikes'] as num?)?.toInt() ?? 0,
      dislikes: (row['totalDislikes'] as num?)?.toInt() ?? 0,
      liked: row['userVoteType'] == 'LIKE',
      disliked: row['userVoteType'] == 'DISLIKE',
      observationId: row['observation'] as String?,
      comments: count,
      sighting: sighting,
    );
  }

  Future<CommunityPost> _detail(String id) async {
    final row = await api.get('/posts/${_id(id)}');
    final count = await api.get('/comments/${_id(id)}/count');
    Sighting? sighting;
    final observation = row['observation'];
    if (observation is String && observation.isNotEmpty) {
      try {
        sighting = ObservationRepository.decode(
          await api.get('/observations/${_id(observation)}'),
        );
      } catch (_) {
        /* Private or removed observations do not hide the public post. */
      }
    }
    return decodePost(
      row,
      sighting: sighting,
      count: (count['value'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<FeedPage> feed({String? cursor, String? authorId}) async {
    final page = int.tryParse(cursor ?? '0') ?? 0;
    final route = authorId == null
        ? '/posts'
        : '/posts/authors/${_id(authorId)}';
    final r = await api.get('$route?page=$page&size=10');
    final posts = <CommunityPost>[];
    // Bound concurrency to avoid overwhelming the API with a full feed page.
    final rows = (r['content'] as List).cast<Map<String, dynamic>>();
    for (var i = 0; i < rows.length; i += 3) {
      posts.addAll(
        await Future.wait(
          rows.skip(i).take(3).map((r) => _detail(r['id'] as String)),
        ),
      );
    }
    return FeedPage(
      posts,
      nextCursor: page + 1 < ((r['pagination'] as Map)['totalPages'] as num)
          ? '${page + 1}'
          : null,
    );
  }

  @override
  Future<CommunityPost> savePost(PostDraft draft, {String? id}) async {
    final validation = draft.validate();
    if (validation != null) throw FeatureUnavailable(validation);
    final body = <String, dynamic>{
      'title': draft.title.trim(),
      'description': draft.text.trim(),
      'observation': draft.sighting?.id ?? draft.observationId ?? '',
    };
    if (id != null) {
      if (draft.photos.isNotEmpty) {
        throw const FeatureUnavailable(
          'El servidor aún no permite modificar las imágenes de una publicación.',
        );
      }
      return decodePost(
        await api.put('/posts/${_id(id)}', body: body),
        sighting: draft.sighting,
      );
    }
    final keys = <String>[];
    for (final photo in draft.photos) {
      final signed = await api.post(
        '/posts/presign',
        body: {'contentType': photo.mimeType},
      );
      if ((signed['url'] as String? ?? '').isEmpty) {
        throw const FeatureUnavailable(
          'El servidor todavía no entrega una dirección para subir fotos de publicaciones. Tu publicación no se ha enviado; conserva el texto e inténtalo más tarde.',
        );
      }
      await api.uploadSignedPhoto(photo, signed);
      keys.add(signed['key'] as String);
    }
    body['imageKeys'] = keys;
    return decodePost(
      await api.post('/posts', body: body),
      sighting: draft.sighting,
    );
  }

  @override
  Future<void> deletePost(String id) async {
    await api.delete('/posts/${_id(id)}');
  }

  @override
  Future<CommunityPost> like(String id, bool liked) =>
      vote(id, liked ? 'LIKE' : null);
  @override
  Future<CommunityPost> vote(String id, String? type) async {
    if (type != null && !['LIKE', 'DISLIKE'].contains(type)) {
      throw ArgumentError.value(type);
    }
    if (type == null) {
      await api.delete('/posts/${_id(id)}/vote');
    } else {
      await api.post('/posts/${_id(id)}/vote', body: {'voteType': type});
    }
    return _detail(id);
  }

  PostComment _comment(Map<String, dynamic> r) => PostComment(
    id: r['id'] as String,
    authorId: r['author']['id'] as String,
    authorName: r['author']['username'] as String? ?? 'Usuario',
    text: r['content'] as String,
    date: DateTime.parse(r['createdAt'] as String),
    parentId: r['parentId'] as String?,
    reactions: (r['totalReactions'] as num?)?.toInt() ?? 0,
  );
  @override
  Future<List<PostComment>> comments(String postId) async {
    final roots = await _all('/comments?postId=${_id(postId)}');
    final result = <PostComment>[];
    for (final root in roots) {
      result.add(_comment(root));
      result.addAll(
        (await _all(
          '/comments/${_id(root['id'] as String)}/replies',
        )).map(_comment),
      );
    }
    return result;
  }

  @override
  Future<void> saveComment(
    String postId,
    String text, {
    String? id,
    String? parentId,
  }) async {
    if (text.trim().isEmpty || text.length > 5000) {
      throw const FeatureUnavailable(
        'El comentario debe tener entre 1 y 5000 caracteres.',
      );
    }
    if (id == null) {
      await api.post(
        '/comments?postId=${_id(postId)}',
        body: {'content': text.trim(), 'parentId': ?parentId},
      );
    } else {
      await api.put('/comments/${_id(id)}', body: {'content': text.trim()});
    }
  }

  @override
  Future<void> deleteComment(String postId, String id) async {
    await api.delete('/comments/${_id(id)}');
  }

  @override
  Future<void> react(String id, String? emoji) async {
    if (emoji == null) {
      await api.delete('/comments/${_id(id)}/react');
    } else {
      await api.post('/comments/${_id(id)}/react', body: {'emoji': emoji});
    }
  }

  @override
  Future<List<String>> reportReasons() async => const [
    'Acoso',
    'Discriminación',
    'Contenido violento',
    'Contenido sexual',
    'Spam',
    'Información falsa',
  ];
  @override
  Future<void> report(
    String id, {
    required bool comment,
    required String reason,
    String? text,
  }) async {
    final postId = comment
        ? (await api.get('/comments/${_id(id)}'))['postId']
        : id;
    await api.post(
      '/reports',
      body: {
        'reportType': comment ? 'COMMENT' : 'POST',
        'reportedPostId': postId,
        if (comment) 'reportedCommentId': id,
        'reason': [
          reason,
          if (text != null && text.isNotEmpty) text,
        ].join(': '),
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> myReports() =>
      _all('/reports/by-reporter');

  static CampusZone decodeZone(Map<String, dynamic> row) {
    final points = <LatLng>[];
    if (row['geometryType'] == 'POINT') {
      final center = LatLng(
        (row['centerLatitude'] as num).toDouble(),
        (row['centerLongitude'] as num).toDouble(),
      );
      final radius = (row['radiusMeters'] as num).toDouble();
      for (var angle = 0; angle < 360; angle += 10) {
        points.add(const Distance().offset(center, radius, angle.toDouble()));
      }
    } else {
      final wkt = row['polygonCoordinatesWkt'] as String? ?? '';
      final ring = RegExp(r'\(\(([^()]+)\)\)').firstMatch(wkt);
      if (ring == null) throw const FormatException('Polígono inválido');
      for (final pair in ring.group(1)!.split(',')) {
        final xy = pair.trim().split(RegExp(r'\s+')).map(double.parse).toList();
        points.add(LatLng(xy[1], xy[0]));
      }
    }
    return CampusZone(
      row['id'] as String,
      row['name'] as String,
      points,
      interest: true,
    );
  }

  @override
  Future<List<CampusZone>> zones() async => (await _all('/pois'))
      .where((r) => r['active'] != false && r['visibility'] == 'PUBLIC')
      .map(decodeZone)
      .toList();
  @override
  Future<void> visit(LatLng point, double accuracy) async {
    if (!accuracy.isFinite || accuracy > 5 || accuracy < 0) return;
    await api.post(
      '/pois/telemetry',
      body: {'latitude': point.latitude, 'longitude': point.longitude},
    );
  }
}
