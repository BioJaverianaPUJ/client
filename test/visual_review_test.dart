import 'dart:io';
import 'dart:ui' as ui;
import 'package:biojaveriana/models/auth_session.dart';
import 'package:biojaveriana/screens/home_screen.dart';
import 'package:biojaveriana/screens/profile_screen.dart';
import 'package:biojaveriana/screens/explore_screen.dart';
import 'package:biojaveriana/screens/records_screen.dart';
import 'package:biojaveriana/screens/identify_screen.dart';
import 'package:biojaveriana/screens/auth/login_screen.dart';
import 'package:biojaveriana/screens/auth/sign_up_screen.dart';
import 'package:biojaveriana/screens/auth/forgot_password_screen.dart';
import 'package:biojaveriana/screens/post_editor_screen.dart';
import 'package:biojaveriana/screens/gamification_screen.dart';
import 'package:biojaveriana/services/api_client.dart';
import 'package:biojaveriana/state/app_scope.dart';
import 'package:biojaveriana/state/session_controller.dart';
import 'package:biojaveriana/theme/bio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'community_test.dart' show TestCommunity;
import 'support/fakes.dart';

void main() {
  testWidgets('Capturas de revisión con datos exclusivos de pruebas', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final fontFile = File('C:/Windows/Fonts/arial.ttf');
      if (await fontFile.exists()) {
        final loader = FontLoader('ReviewFont')
          ..addFont(
            fontFile.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
        await loader.load();
      }
    });
    await tester.runAsync(() async {
      final loader = FontLoader('MaterialIcons')
        ..addFont(
          File(
            'D:/dev/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    });
    tester.view.physicalSize = const Size(390, 844);
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
      community: TestCommunity(),
    );
    addTearDown(session.dispose);
    await session.restore();
    for (final entry in <String, Widget>{
      'inicio': const HomeScreen(),
      'publicacion': const PostEditorScreen(),
      'gamificacion': const GamificationScreen(),
      'perfil': const ProfileScreen(),
      'catalogo': const ExploreScreen(),
      'observaciones': const RecordsScreen(),
      'camara': const IdentifyScreen(),
      'login': const LoginScreen(),
      'registro': const SignUpScreen(),
      'recuperacion': const ForgotPasswordScreen(),
    }.entries) {
      await tester.pumpWidget(const SizedBox.shrink());
      final key = GlobalKey();
      await tester.pumpWidget(
        AppScope(
          session: session,
          child: MaterialApp(
            theme: BioTheme.dark.copyWith(
              textTheme: BioTheme.dark.textTheme.apply(
                fontFamily: 'ReviewFont',
              ),
            ),
            home: RepaintBoundary(key: key, child: entry.value),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = key.currentContext!;
        final images = tester
            .widgetList<Image>(find.byType(Image))
            .map((image) => image.image)
            .toList();
        for (final image in images) {
          await precacheImage(image, context);
        }
        final loader = FontLoader('MaterialDesignIcons')
          ..addFont(
            rootBundle.load('assets/fonts/materialdesignicons-webfont.ttf'),
          );
        await loader.load();
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('build/review');
        await directory.create(recursive: true);
        await File(
          '${directory.path}/${entry.key}.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
    }
  }, skip: !const bool.fromEnvironment('CAPTURE_REVIEW'));
}
