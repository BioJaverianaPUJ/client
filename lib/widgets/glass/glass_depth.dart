import 'package:flutter/widgets.dart';

class GlassDepth extends InheritedWidget {
  const GlassDepth({
    super.key,
    required this.depth,
    required super.child,
  });

  final int depth;

  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassDepth>()?.depth ?? 0;

  @override
  bool updateShouldNotify(GlassDepth oldWidget) => depth != oldWidget.depth;
}
