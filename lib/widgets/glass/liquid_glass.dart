import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/glass_tokens.dart';
import 'glass_depth.dart';
import 'glass_rim_painter.dart';

class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.material = GlassMaterial.clear,
    this.borderRadius = 32,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.minHeight,
    this.blur = true,
    this.shadow = true,
  });

  final Widget child;
  final GlassMaterial material;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final double? minHeight;
  final bool blur;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final depth = GlassDepth.of(context);
    final nested = depth > 0;
    final tokens = GlassTokens.of(material);
    final radius = BorderRadius.circular(borderRadius);
    final edgeInset = math.max(borderRadius * 0.6, 10.0);

    Widget surface = ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (blur)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: tokens.blurSigma,
                  sigmaY: tokens.blurSigma,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: tokens.fill),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: nested ? GlassNestedTokens.lift : tokens.veil,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: const Alignment(-0.3, 1),
                    colors: tokens.sheen,
                    stops: const [0, 0.34, 0.68, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: edgeInset,
            right: 0,
            height: 1,
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.42,
                  heightFactor: 1,
                  child: SizedBox.expand(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            tokens.highlight.withValues(alpha: 0),
                            tokens.highlight,
                            tokens.highlight.withValues(alpha: 0),
                          ],
                          stops: const [0, 0.4, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: GlassRimPainter(
                  radius: borderRadius,
                  borderWidth: tokens.borderWidth,
                  borderLight:
                      nested ? GlassNestedTokens.borderLight : tokens.borderLight,
                  borderDark:
                      nested ? GlassNestedTokens.borderDark : tokens.borderDark,
                  rimLight: nested ? GlassNestedTokens.rimLight : tokens.rimLight,
                  rimDark: tokens.rimDark,
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: GlassDepth(
              depth: depth + 1,
              child: child,
            ),
          ),
        ],
      ),
    );

    if (shadow) {
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: nested ? GlassNestedTokens.shadows : tokens.shadows,
        ),
        child: surface,
      );
    }

    if (width != null || height != null) {
      surface = SizedBox(width: width, height: height, child: surface);
    }

    if (minHeight != null) {
      surface = ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight!),
        child: surface,
      );
    }

    return surface;
  }
}
