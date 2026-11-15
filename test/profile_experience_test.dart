import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biojaveriana/models/community.dart';
import 'package:biojaveriana/services/community_repository.dart';
import 'package:biojaveriana/services/api_client.dart';
import 'package:biojaveriana/state/session_controller.dart';
import 'package:biojaveriana/state/app_scope.dart';
import 'package:biojaveriana/screens/profile_screen.dart';
import 'package:biojaveriana/theme/bio_theme.dart';
import 'support/fakes.dart';

class ProgressOnly extends CommunityRepository {
  @override
  Future<ProgressSummary> progress({String? userId}) async =>
      const ProgressSummary(xp: 25, level: 4);
}

void main() {
  testWidgets('profile experience survives unavailable publications', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..on('GET', '/users/me', (_) => json(profileJson()));
    final session = SessionController(
      api: ApiClient(
        httpClient: backend.client,
        baseUrl: 'https://api.test/api/v1',
      ),
      storage: MemorySessionStorage(),
      community: ProgressOnly(),
      autoRefresh: false,
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(
      AppScope(
        session: session,
        child: MaterialApp(theme: BioTheme.dark, home: const ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('TU EXPERIENCIA'), 300);
    await tester.pumpAndSettle();
    expect(find.text('Nivel 4 · 25 XP'), findsOneWidget);
    expect(find.text('9 XP para el siguiente nivel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
