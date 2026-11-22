import 'package:latlong2/latlong.dart';
import '../models/community.dart';
import 'community_repository.dart';
import 'observation_repository.dart';
import 'api_exception.dart';

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

  @override
  Future<ProgressSummary> progress({String? userId}) async {
    try {
      if (userId != null) {
        final me = await api.get('/users/me');
        if (me['id'] != userId) {
          throw const FeatureUnavailable(
            'El servidor solo permite consultar tu propia experiencia.',
          );
        }
      }
      final status = await api.get('/gamification/me');
      final achievements = await api.get('/achievements/me');
      final xp = (status['totalXp'] as num).toInt();
      final lower = (status['xpForCurrentLevel'] as num).toInt();
      final upper = (status['xpForNextLevel'] as num).toInt();
      return ProgressSummary(
        xp: xp,
        level: (status['level'] as num).toInt(),
        nextLevelXp: upper,
        levelProgress: upper > lower
            ? ((xp - lower) / (upper - lower)).clamp(0.0, 1.0)
            : 1,
        missionsAvailable: false,
        achievements: (achievements['content'] as List).map((raw) {
          final a = raw as Map<String, dynamic>;
          return Mission(
            id: a['id'] as String,
            title: a['name'] as String,
            description: a['description'] as String? ?? '',
            period: 'Logros',
            progress: (a['progress'] as num?)?.toInt() ?? 0,
            target: (a['target'] as num?)?.toInt() ?? 0,
            xp: (a['xpReward'] as num).toInt(),
            completedByServer: a['completed'] == true,
          );
        }).toList(),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 501) {
        throw const FeatureUnavailable(
          'La experiencia y los logros todavía no están habilitados en este servidor.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<XpHistoryPage> xpHistory({int page = 0}) async {
    if (page < 0) throw ArgumentError.value(page, 'page');
    final result = await api.get(
      '/gamification/me/xp-history?page=$page&size=20',
    );
    return XpHistoryPage(
      (result['content'] as List).map((raw) {
        final row = raw as Map<String, dynamic>;
        return XpHistoryEntry(
          id: row['id'] as String,
          amount: (row['amount'] as num).toInt(),
          reason: row['reason'] as String? ?? 'Experiencia registrada',
          totalAfter: (row['totalAfter'] as num).toInt(),
          levelAfter: (row['levelAfter'] as num).toInt(),
          date: DateTime.parse(row['createdAt'] as String),
        );
      }).toList(),
      hasMore: page + 1 < (result['totalPages'] as num),
    );
  }

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

  static DateTime _date(Object? value) =>
      (value is String ? DateTime.tryParse(value) : null) ?? DateTime.now();

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
      // Al crear, el backend responde antes de guardar y envía createdAt nulo.
      date: _date(row['createdAt']),
      images: row['images'] is List
          ? (row['images'] as List)
                .map((e) => e['url'] as String?)
                .whereType<String>()
                .toList()
          : [
              if (row['firstImageUrl'] is String)
                row['firstImageUrl'] as String,
            ],
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
    // La publicación y su número de comentarios se piden a la vez.
    final results = await Future.wait([
      api.get('/posts/${_id(id)}'),
      api
          .get('/comments/${_id(id)}/count')
          .catchError((Object _) => <String, dynamic>{}),
    ]);
    final row = results[0];
    final count = results[1];
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
          rows.skip(i).take(3).map((summary) async {
            try {
              return await _detail(summary['id'] as String);
            } catch (_) {
              // Una publicación con error no debe tumbar todo el inicio.
              return decodePost(summary);
            }
          }),
        ),
      );
    }
    return FeedPage(
      posts,
      nextCursor: page + 1 < ((r['pagination'] as Map)['totalPages'] as num)
          ? '${page + 1}'
          : null,
      total: ((r['pagination'] as Map)['totalElements'] as num?)?.toInt(),
    );
  }

  @override
  Future<CommunityPost> savePost(PostDraft draft, {String? id}) async {
    final validation = draft.validate();
    if (validation != null) throw FeatureUnavailable(validation);
    if (draft.text.trim().isEmpty) {
      // PostCreateRequest exige una descripción no vacía (@NotBlank).
      throw const FeatureUnavailable(
        'Agrega una descripción: el servidor no acepta publicaciones sin ella.',
      );
    }
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
      final uploadUrl = signed['url'];
      final uploadKey = signed['key'];
      if (uploadUrl is! String ||
          uploadUrl.trim().isEmpty ||
          uploadKey is! String ||
          uploadKey.trim().isEmpty) {
        throw const FeatureUnavailable(
          'No se pudo preparar la carga de la foto. Tu publicación no se ha enviado; conserva el texto e inténtalo más tarde.',
        );
      }
      await api.uploadSignedPhoto(photo, signed);
      keys.add(uploadKey);
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
    final row = type == null
        ? await api.delete('/posts/${_id(id)}/vote')
        : await api.post('/posts/${_id(id)}/vote', body: {'voteType': type});
    if (row['id'] is! String) return _detail(id);
    // El servidor devuelve los totales correctos, pero el tipo de voto
    // anterior; el estado propio se toma de la acción solicitada.
    return decodePost(row).copyWith(
      liked: type == 'LIKE',
      disliked: type == 'DISLIKE',
    );
  }

  static PostComment decodeComment(Map<String, dynamic> r) {
    final author = r['author'] as Map<String, dynamic>;
    final summary = <CommentReactionCount>[];
    for (final raw in (r['reactions'] as List? ?? const [])) {
      final reaction = raw as Map<String, dynamic>;
      final users = (reaction['users'] as List? ?? const [])
          .map((u) => (u as Map<String, dynamic>)['id'])
          .whereType<String>()
          .toList();
      summary.add(
        CommentReactionCount(
          reaction['emoji'] as String,
          (reaction['count'] as num?)?.toInt() ?? users.length,
          users,
        ),
      );
    }
    return PostComment(
      id: r['id'] as String,
      authorId: author['id'] as String,
      authorName: author['username'] as String? ?? 'Usuario',
      avatar: author['profilePictureUrl'] as String?,
      text: r['content'] as String,
      date: _date(r['createdAt']),
      parentId: r['parentId'] as String?,
      reactions: (r['totalReactions'] as num?)?.toInt() ?? 0,
      reactionSummary: summary,
    );
  }

  /// Ejecuta [task] sobre [items] con un máximo de [limit] peticiones a la vez.
  Future<List<R>> _bounded<T, R>(
    List<T> items,
    Future<R> Function(T) task, {
    int limit = 4,
  }) async {
    final out = <R>[];
    for (var i = 0; i < items.length; i += limit) {
      out.addAll(await Future.wait(items.skip(i).take(limit).map(task)));
    }
    return out;
  }
  @override
  Future<List<PostComment>> comments(String postId) async {
    final roots = await _all('/comments?postId=${_id(postId)}');
    roots.sort(
      (a, b) => (a['createdAt'] as String).compareTo(b['createdAt'] as String),
    );
    final replies = await _bounded(
      roots,
      (root) => _all('/comments/${_id(root['id'] as String)}/replies'),
    );
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < roots.length; i++) {
      rows.add(roots[i]);
      rows.addAll(
        replies[i]..sort(
          (a, b) =>
              (a['createdAt'] as String).compareTo(b['createdAt'] as String),
        ),
      );
    }
    // El listado solo trae el total de reacciones; el detalle trae cada emoji
    // y quién reaccionó, necesario para mostrar la reacción propia.
    return _bounded(rows, (row) async {
      try {
        return decodeComment(
          await api.get('/comments/${_id(row['id'] as String)}'),
        );
      } catch (_) {
        return decodeComment(row);
      }
    });
  }

  @override
  Future<PostComment> comment(String id) async =>
      decodeComment(await api.get('/comments/${_id(id)}'));

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
      // RF-22: el backend distingue zonas verdes y zonas de interés.
      interest: row['type'] != 'GREEN_ZONE',
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
