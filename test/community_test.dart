import 'dart:convert';
import 'dart:typed_data';
import 'package:biojaveriana/main.dart';
import 'package:biojaveriana/models/auth_session.dart';
import 'package:biojaveriana/models/community.dart';
import 'package:biojaveriana/screens/gamification_screen.dart';
import 'package:biojaveriana/screens/home_screen.dart';
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
    await tester.scrollUntilVisible(
      find.text('Publicar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();
    expect(repo.saves, 0);
    expect(find.text('Escribe un título para la publicación.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TextField).first,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField).first, 'Mi descubrimiento');
    await tester.scrollUntilVisible(
      find.text('Publicar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Publicar'));
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
