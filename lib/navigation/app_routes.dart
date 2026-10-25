import 'package:flutter/material.dart';

import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/home_screen.dart';
import '../screens/identify_screen.dart';
import '../screens/map_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/records_screen.dart';
import '../state/app_scope.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const explore = '/explore';
  static const map = '/map';
  static const identify = '/identify';
  static const records = '/records';
  static const profile = '/profile';

  static const _mainRoutes = {home, explore, map, identify, records, profile};

  static Widget _screenFor(String? name) => switch (name) {
        signUp => const SignUpScreen(),
        forgotPassword => const ForgotPasswordScreen(),
        home => const HomeScreen(),
        explore => const ExploreScreen(),
        map => const MapScreen(),
        identify => const IdentifyScreen(),
        records => const RecordsScreen(),
        profile => const ProfileScreen(),
        _ => const LoginScreen(),
      };

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final screen = _screenFor(settings.name);

    if (_mainRoutes.contains(settings.name)) {
      return PageRouteBuilder<void>(
        settings: settings,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => screen,
      );
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => screen,
    );
  }

  static void goTo(BuildContext context, String route) {
    if (ModalRoute.of(context)?.settings.name == route) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  static void enterApp(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(home, (_) => false);
  }

  static Future<void> logout(BuildContext context) =>
      AppScope.read(context).logout();
}
