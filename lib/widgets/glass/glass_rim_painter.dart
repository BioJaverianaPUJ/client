import 'dart:math' as math;

import 'package:flutter/rendering.dart';

class GlassRimPainter extends CustomPainter {
  const GlassRimPainter({
    required this.radius,
    required this.borderWidth,
    required this.borderLight,
    required this.borderDark,
    required this.rimLight,
    required this.rimDark,
  });

  final double radius;
  final double borderWidth;
  final Color borderLight;
  final Color borderDark;
  final Color rimLight;
  final Color rimDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final outer = RRect.fromRectAndRadius(
      rect.deflate(borderWidth / 2),
      Radius.circular(math.max(radius - borderWidth / 2, 0)),
    );

    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          borderLight,
          borderLight.withValues(alpha: borderLight.a * 0.5),
          borderDark,
        ],
        stops: const [0, 0.45, 1],
      ).createShader(rect);

    canvas.drawRRect(outer, outerPaint);

    final inset = borderWidth + 0.5;

    final inner = RRect.fromRectAndRadius(
      rect.deflate(inset),
      Radius.circular(math.max(radius - inset, 0)),
    );

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          rimLight,
          rimLight.withValues(alpha: 0),
          rimDark,
        ],
        stops: const [0, 0.5, 1],
      ).createShader(rect);

    canvas.drawRRect(inner, rimPaint);
  }

  @override
  bool shouldRepaint(GlassRimPainter oldDelegate) =>
      radius != oldDelegate.radius ||
      borderWidth != oldDelegate.borderWidth ||
      borderLight != oldDelegate.borderLight ||
      borderDark != oldDelegate.borderDark ||
      rimLight != oldDelegate.rimLight ||
      rimDark != oldDelegate.rimDark;
}
