import 'package:flutter/material.dart';

import '../../theme/glass_tokens.dart';
import 'glass_depth.dart';
import 'glass_rim_painter.dart';

class GlassIcon extends StatelessWidget {
  const GlassIcon({
    super.key,
    required this.icon,
    this.size = 42,
    this.iconSize = 19,
    this.iconColor,
    this.strong = false,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final nested = GlassDepth.of(context) > 0;
    final radiusValue = (size * AccentTokens.radiusRatio).roundToDouble();
    final radius = BorderRadius.circular(radiusValue);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow:
              nested ? AccentTokens.nestedShadows : AccentTokens.shadows,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: strong ? AccentTokens.baseStrong : AccentTokens.base,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.4, -1),
                    end: Alignment(0.4, 1),
                    colors: AccentTokens.volume,
                    stops: [0, 0.42, 0.78, 1],
                  ),
                ),
              ),
              CustomPaint(
                painter: GlassRimPainter(
                  radius: radiusValue,
                  borderWidth: AccentTokens.borderWidth,
                  borderLight: AccentTokens.borderLight,
                  borderDark: AccentTokens.borderDark,
                  rimLight: AccentTokens.rimLight,
                  rimDark: AccentTokens.rimDark,
                ),
              ),
              Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor ?? AccentTokens.iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
