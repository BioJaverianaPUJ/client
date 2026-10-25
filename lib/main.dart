import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'navigation/app_routes.dart';
import 'state/app_scope.dart';
import 'state/session_controller.dart';
import 'theme/bio_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = SessionController.create();
  await session.restore();
  runApp(BioJaverianaApp(session: session));
}

class BioJaverianaApp extends StatefulWidget {
  const BioJaverianaApp({super.key, required this.session});

  final SessionController session;

  @override
  State<BioJaverianaApp> createState() => _BioJaverianaAppState();
}

class _BioJaverianaAppState extends State<BioJaverianaApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late bool _wasSignedIn = widget.session.isSignedIn;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_handleSessionChange);
  }

  @override
  void dispose() {
    widget.session.removeListener(_handleSessionChange);
    super.dispose();
  }

  void _handleSessionChange() {
    final signedIn = widget.session.isSignedIn;
    if (_wasSignedIn && !signedIn) {
      _navigator.currentState
          ?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
    _wasSignedIn = signedIn;
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: widget.session,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: BioTheme.backgroundDeep,
        ),
        child: MaterialApp(
          title: 'BioJaveriana',
          debugShowCheckedModeBanner: false,
          theme: BioTheme.dark,
          navigatorKey: _navigator,
          initialRoute:
              widget.session.isSignedIn ? AppRoutes.home : AppRoutes.login,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          onGenerateInitialRoutes: (name) => [
            AppRoutes.onGenerateRoute(RouteSettings(name: name)),
          ],
        ),
      ),
    );
  }
}
