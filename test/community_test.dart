import 'dart:convert';
import 'dart:typed_data';
import 'package:biojaveriana/main.dart';
import 'package:biojaveriana/models/auth_session.dart';
import 'package:biojaveriana/models/community.dart';
import 'package:biojaveriana/screens/gamification_screen.dart';
import 'package:biojaveriana/screens/home_screen.dart';
import 'package:biojaveriana/screens/map_screen.dart';
import 'package:biojaveriana/screens/profile_screen.dart';
import 'package:biojaveriana/screens/xp_history_screen.dart';
import 'package:biojaveriana/widgets/post_comments.dart';
import 'package:biojaveriana/screens/post_editor_screen.dart';
import 'package:biojaveriana/services/api_client.dart';
import 'package:biojaveriana/services/catalog_service.dart';
import 'package:biojaveriana/services/community_repository.dart';
import 'package:biojaveriana/services/location_service.dart';
import 'package:biojaveriana/services/user_service.dart';
import 'package:biojaveriana/state/app_scope.dart';
import 'package:biojaveriana/state/session_controller.dart';
import 'package:biojaveriana/theme/bio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'support/fakes.dart';

class TestCommunity extends CommunityRepository {
  String? openedMention;
  @override
  Future<List<PostComment>> comments(String postId) async => [
    PostComment(
      id: 'c1',
      authorId: 'u-ana',
      authorName: 'ana_bio',
      text: 'Qué bonito, mira @camilo.',
      date: DateTime(2026, 11, 22),
    ),
  ];
  @override
  Future<List<MentionUser>> mentionCandidates() async => const [
    MentionUser(id: 'u-cam', username: 'camilo', name: 'Camilo Rojas'),
    MentionUser(id: 'u-lau', username: 'laura', name: 'Laura Gómez'),
  ];
  @override
  Future<String?> userIdByUsername(String username) async {
    openedMention = username;
    return username == 'camilo' ? 'u-cam' : null;
  }

  @override
  Future<XpHistoryPage> xpHistory({int page = 0}) async => XpHistoryPage([
    XpHistoryEntry(
      id: 'x2',
      amount: 15,
      reason: 'MISSION:semana-verde',
      totalAfter: 125,
      levelAfter: 3,
      date: DateTime.now(),
    ),
    XpHistoryEntry(
      id: 'x1',
      amount: 10,
      reason: 'ACHIEVEMENT:primera-planta',
      totalAfter: 110,
      levelAfter: 2,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ], hasMore: false);
  @override
  Future<Map<String, String>> rewardNames() async => const {
    'MISSION:semana-verde': 'Semana verde',
  };

  bool rejectSave = false;
  int saves = 0;
  PostDraft? draft;
  @override
  bool get available => true;
  final post = CommunityPost(
    id: 'p1',
    authorId: 'other',
    authorName: 'Comunidad de prueba',
    title: 'Un descubrimiento en el campus',
    text: 'Contenido exclusivo de pruebas.',
    date: DateTime(2026, 11, 3),
  );
  @override
  Future<FeedPage> feed({String? cursor, String? authorId}) async =>
      FeedPage([post]);
  @override
  Future<CommunityPost> savePost(PostDraft value, {String? id}) async {
    saves++;
    if (rejectSave) {
      throw const FeatureUnavailable('No se pudo publicar. Intenta de nuevo.');
    }
    draft = value;
    return post;
  }

  @override
  Future<ProgressSummary> progress({String? userId}) async => ProgressSummary(
    xp: 25,
    level: 4,
    missions: [
      Mission(
        id: 'm1',
        title: 'Recorre el campus',
        description: 'Visita dos zonas verdes.',
        period: 'Diarias',
        progress: 1,
        target: 2,
        xp: 10,
      ),
    ],
    curiosity: const Curiosity(
      'Biodiversidad cercana',
      'Contenido educativo de prueba.',
    ),
  );
}

void main() {
  test('Publicación valida título, máximo de fotos y observación fallida', () {
    final photo = LocalPhoto(Uint8List(1), 'a.jpg', 'image/jpeg');
    expect(const PostDraft(title: '  ').validate(), isNotNull);
    expect(
      PostDraft(title: 'Título', photos: List.filled(11, photo)).validate(),
      isNotNull,
    );
    expect(
      PostDraft(title: 'Título', photos: List.filled(10, photo)).validate(),
      isNull,
    );
    final failed = Sighting(
      id: 's1',
      species: '',
      photo: '',
      point: const LatLng(4, -74),
      date: DateTime.now(),
      status: Verification.failed,
    );
    expect(PostDraft(title: 'Título', sighting: failed).validate(), isNotNull);
    expect(failed.canRequestReview, isFalse);
  });

  test('El polígono admite borde e interior y rechaza exterior o ausencia', () {
    const polygon = [LatLng(0, 0), LatLng(0, 2), LatLng(2, 2), LatLng(2, 0)];
    expect(LocationService.inside(const LatLng(1, 1), polygon), isTrue);
    expect(LocationService.inside(const LatLng(0, 1), polygon), isTrue);
    expect(LocationService.inside(const LatLng(3, 1), polygon), isFalse);
    expect(LocationService.inside(const LatLng(1, 1), []), isFalse);
  });

  test(
    'Los servicios pendientes no inventan resultados ni publicaciones',
    () async {
      final repo = CommunityRepository();
      expect(repo.available, isFalse);
      await expectLater(repo.feed(), throwsA(isA<FeatureUnavailable>()));
      await expectLater(
        repo.savePost(const PostDraft(title: 'Título')),
        throwsA(isA<FeatureUnavailable>()),
      );
    },
  );

  test(
    'Catálogo respeta paginación y autorización del contrato real',
    () async {
      final backend = FakeBackend();
      backend.on('GET', '/species', (request) {
        expect(request.url.queryParameters, {'page': '1', 'size': '100'});
        expect(request.headers['Authorization'], 'Bearer token');
        return json({
          'content': [
            {'id': 's1', 'scientificName': 'Nombre'},
          ],
          'pagination': {'totalPages': 3},
        });
      });
      final api = ApiClient(
        httpClient: backend.client,
        baseUrl: 'https://api.test/api/v1',
      )..token = 'token';
      final page = await CatalogService(api).page('species', 1);
      expect(page.hasNext, isTrue);
      expect(page.items.single['id'], 's1');
      api.close();
    },
  );

  test(
    'Edición de perfil utiliza PATCH me sin enviar campos no admitidos',
    () async {
      final backend = FakeBackend();
      backend.on('PATCH', '/users/me', (request) {
        expect(jsonDecode(request.body), {
          'firstName': 'Brayan',
          'lastName': 'Fajardo',
          'username': 'brayanfajardo',
          'gender': 'MALE',
        });
        return json(profileJson());
      });
      final api = ApiClient(
        httpClient: backend.client,
        baseUrl: 'https://api.test/api/v1',
      );
      final user = await UserService(api).update({
        'firstName': 'Brayan',
        'lastName': 'Fajardo',
        'username': 'brayanfajardo',
        'gender': 'MALE',
      });
      expect(user.username, 'brayanfajardo');
      api.close();
    },
  );

  test(
    'Subida de perfil envía multipart con tipo y elimina usando DELETE',
    () async {
      final backend = FakeBackend();
      backend.on('PATCH', '/users/me/media', (request) {
        expect(request.url.queryParameters['type'], 'profile-picture');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data'),
        );
        expect(request.body, contains('name="file"'));
        expect(request.headers['Authorization'], 'Bearer token');
        return json({
          ...profileJson(),
          'profilePictureUrl': 'https://example.test/image.jpg',
        });
      });
      backend.on('DELETE', '/users/me/media', (request) {
        expect(request.url.queryParameters['type'], 'banner');
        return json(profileJson());
      });
      final api = ApiClient(
        httpClient: backend.client,
        baseUrl: 'https://api.test/api/v1',
      )..token = 'token';
      final service = UserService(api);
      final user = await service.upload(
        LocalPhoto(Uint8List.fromList([1, 2, 3]), 'photo.jpg', 'image/jpeg'),
        'profile-picture',
      );
      expect(user.profilePictureUrl, 'https://example.test/image.jpg');
      await service.removeMedia('banner');
      api.close();
    },
  );

  Future<SessionController> setup(
    WidgetTester tester,
    Widget screen, {
    TestCommunity? repo,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend()
      ..on('GET', '/users/me', (_) => json(profileJson()));
    final session = SessionController(
      api: ApiClient(
        httpClient: backend.client,
        baseUrl: 'https://api.test/api/v1',
      ),
      storage: MemorySessionStorage(AuthSession.fromJson(sessionJson())),
      autoRefresh: false,
      community: repo,
    );
    addTearDown(session.dispose);
    await session.restore();
    await tester.pumpWidget(
      AppScope(
        session: session,
        child: MaterialApp(
          theme: BioTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets(
    'Inicio muestra publicaciones y cinco secciones con texto al 200%',
    (tester) async {
      await setup(tester, const HomeScreen(), repo: TestCommunity(), scale: 2);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Mapa'), findsOneWidget);
      expect(find.text('Cámara'), findsOneWidget);
      expect(find.text('Gamificación'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Un descubrimiento en el campus'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Un descubrimiento en el campus'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Editor rechaza título vacío y conserva contenido ante error', (
    tester,
  ) async {
    final repo = TestCommunity()..rejectSave = true;
    await setup(tester, const PostEditorScreen(), repo: repo);
    // El botón inferior; el de la barra superior se habilita solo cuando
    // la publicación está completa.
    final publish = find.widgetWithText(FilledButton, 'Publicar');
    await tester.ensureVisible(publish);
    await tester.pumpAndSettle();
    await tester.tap(publish);
    await tester.pumpAndSettle();
    expect(repo.saves, 0);
    expect(find.text('Escribe un título para la publicación.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TextField).first,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField).first, 'Mi descubrimiento');
    await tester.tap(publish);
    await tester.pumpAndSettle();
    // El backend exige descripción: sin ella tampoco se envía.
    expect(repo.saves, 0);
    expect(
      find.text('Agrega una descripción a tu publicación.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).at(1), 'Un colibrí');
    await tester.ensureVisible(publish);
    await tester.pumpAndSettle();
    await tester.tap(publish);
    await tester.pumpAndSettle();
    expect(repo.saves, 1);
    expect(find.text('No se pudo publicar. Intenta de nuevo.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TextField).first,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mi descubrimiento'), findsOneWidget);
  });

  testWidgets(
    'Gamificación presenta curiosidad y progreso sin cálculos inventados',
    (tester) async {
      await setup(
        tester,
        const GamificationScreen(),
        repo: TestCommunity(),
        scale: 2,
      );
      await tester.scrollUntilVisible(
        find.text('Biodiversidad cercana'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Biodiversidad cercana'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Recorre el campus'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1/2 · 10 XP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Tocar una foto de la publicación la abre a pantalla completa', (
    tester,
  ) async {
    await setup(
      tester,
      Scaffold(
        body: ListView(
          children: [
            PostCard(
              post: CommunityPost(
                id: 'p1',
                authorId: 'u1',
                authorName: 'ana',
                title: 'Dos fotos',
                date: DateTime(2026, 11, 22),
                images: const [
                  'https://img.test/a.jpg',
                  'https://img.test/b.jpg',
                ],
              ),
              onChanged: () {},
            ),
          ],
        ),
      ),
      repo: TestCommunity(),
    );
    await tester.tap(find.byType(PageView).first);
    // Se espera el tiempo del doble toque (que es "me gusta").
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.byType(ImageViewer), findsOneWidget);
    expect(find.text('1/2'), findsWidgets);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(ImageViewer), findsNothing);
  });

  testWidgets('Al escribir @ se sugieren personas y la mención abre perfiles', (
    tester,
  ) async {
    final repo = TestCommunity();
    await setup(
      tester,
      Scaffold(
        body: ListView(
          children: [
            PostCommentsSection(post: repo.post, onCountChanged: (_) {}),
          ],
        ),
      ),
      repo: repo,
    );
    await tester.enterText(find.byType(TextField), 'Hola @la');
    await tester.pumpAndSettle();
    expect(find.text('laura'), findsOneWidget);
    expect(find.text('camilo'), findsNothing);
    await tester.tap(find.text('laura'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Hola @laura ');
    // Quien ya comentó aparece de primero al escribir solo "@".
    await tester.enterText(find.byType(TextField), '@');
    await tester.pumpAndSettle();
    expect(find.text('ana_bio'), findsWidgets);
    // Tocar la mención en un comentario abre el perfil de esa persona.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tapOnText(find.textRange.ofSubstring('@camilo'));
    await tester.pumpAndSettle();
    expect(repo.openedMention, 'camilo');
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('El historial de experiencia muestra nombres, días y niveles', (
    tester,
  ) async {
    await setup(tester, const XpHistoryScreen(), repo: TestCommunity());
    expect(find.text('Semana verde'), findsOneWidget);
    expect(find.text('Primera planta'), findsOneWidget);
    expect(find.text('HOY'), findsOneWidget);
    expect(find.text('AYER'), findsOneWidget);
    expect(find.textContaining('Subiste a nivel 3'), findsOneWidget);
    expect(find.text('+15 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('El espécimen de una planta verificada se marca en el mapa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Map<String, dynamic> page(List<Map<String, dynamic>> rows) => {
      'content': rows,
      'pagination': {'page': 0, 'size': 100, 'totalPages': 1},
    };
    const specimen = {
      'id': 's-verde',
      'speciesId': 'sp1',
      'latitude': 4.6286,
      'longitude': -74.0637,
    };
    final backend = FakeBackend()
      ..on('GET', '/users/me', (_) => json(profileJson()))
      ..on(
        'GET',
        '/specimens',
        (_) => json(
          page([
            specimen,
            {
              'id': 's-otro',
              'speciesId': 'sp1',
              'latitude': 4.6290,
              'longitude': -74.0640,
            },
          ]),
        ),
      )
      ..on(
        'GET',
        '/species',
        (_) => json(
          page([
            {
              'id': 'sp1',
              'scientificName': 'Quercus humboldtii',
              'commonName': 'Roble',
              'family': 'Fagaceae',
            },
          ]),
        ),
      );
    final session = SessionController(
      api: ApiClient(
        httpClient: backend.client,
        baseUrl: 'https://api.test/api/v1',
      ),
      storage: MemorySessionStorage(AuthSession.fromJson(sessionJson())),
      autoRefresh: false,
      community: _VerifiedCommunity(
        Sighting(
          id: 'o1',
          species: 'Roble',
          photo: '',
          point: const LatLng(4.6286, -74.0637),
          date: DateTime(2026, 11, 22),
          status: Verification.verified,
          similarity: 0.8,
          specimen: specimen,
        ),
      ),
    );
    addTearDown(session.dispose);
    await session.restore();
    await tester.pumpWidget(
      AppScope(
        session: session,
        child: MaterialApp(theme: BioTheme.dark, home: const MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp('Espécimen verificado por ti')),
      findsOneWidget,
    );
  });

  testWidgets(
    'Se puede mencionar con @ en el título y la descripción del post',
    (tester) async {
      final repo = TestCommunity();
      await setup(tester, const PostEditorScreen(), repo: repo);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Con @cam');
      await tester.pumpAndSettle();
      expect(find.text('camilo'), findsOneWidget);
      await tester.tap(find.text('camilo'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(fields.at(0)).controller!.text,
        'Con @camilo ',
      );
      await tester.enterText(fields.at(1), 'Gracias @lau');
      await tester.pumpAndSettle();
      await tester.tap(find.text('laura'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(fields.at(1)).controller!.text,
        'Gracias @laura ',
      );
    },
  );

  testWidgets('Una mención en la publicación abre el perfil', (tester) async {
    final repo = TestCommunity();
    await setup(
      tester,
      Scaffold(
        body: ListView(
          children: [
            PostCard(
              post: CommunityPost(
                id: 'p9',
                authorId: 'u1',
                authorName: 'ana',
                title: 'Paseo con @camilo',
                text: 'Lo vimos juntos.',
                date: DateTime(2026, 11, 22),
              ),
              onChanged: () {},
            ),
          ],
        ),
      ),
      repo: repo,
    );
    await tester.tapOnText(find.textRange.ofSubstring('@camilo'));
    await tester.pumpAndSettle();
    expect(repo.openedMention, 'camilo');
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('Suspensión invalida sesión y muestra aviso específico', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..on('GET', '/users/me', (_) => json({'code': 'USER_DEACTIVATED'}, 403));
    final storage = MemorySessionStorage(AuthSession.fromJson(sessionJson()));
    final session = backend.controller(storage);
    addTearDown(session.dispose);
    await session.restore();
    await tester.pumpWidget(BioJaverianaApp(session: session));
    await tester.pumpAndSettle();
    expect(session.isSignedIn, isFalse);
    expect(storage.session, isNull);
    expect(find.textContaining('Tu cuenta está suspendida'), findsOneWidget);
  });
}

class _VerifiedCommunity extends TestCommunity {
  _VerifiedCommunity(this.sighting);
  final Sighting sighting;
  @override
  Future<List<Sighting>> sightings() async => [sighting];
  @override
  Future<List<LatLng>> campusBoundary() async => const [];
  @override
  Future<List<CampusZone>> zones() async => const [];
}
