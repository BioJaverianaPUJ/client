import 'package:flutter/widgets.dart';

import 'session_controller.dart';

class AppScope extends InheritedNotifier<SessionController> {
  const AppScope({
    super.key,
    required SessionController session,
    required super.child,
  }) : super(notifier: session);

  static SessionController watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static SessionController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
