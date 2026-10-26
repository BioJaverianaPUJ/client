import 'package:flutter/material.dart';

enum GlassMaterial { clear, regular, frosted }

@immutable
class GlassTokens {
  const GlassTokens({
    required this.blurSigma,
    required this.fill,
    required this.veil,
    required this.sheen,
    required this.borderWidth,
    required this.borderLight,
    required this.borderDark,
    required this.highlight,
    required this.rimLight,
    required this.rimDark,
    required this.shadows,
  });

  final double blurSigma;
  final Color fill;
  final Color veil;
  final List<Color> sheen;
  final double borderWidth;
  final Color borderLight;
  final Color borderDark;
  final Color highlight;
  final Color rimLight;
  final Color rimDark;
  final List<BoxShadow> shadows;

  static GlassTokens of(GlassMaterial material) => switch (material) {
        GlassMaterial.clear => clear,
        GlassMaterial.regular => regular,
        GlassMaterial.frosted => frosted,
      };

  static const clear = GlassTokens(
    blurSigma: 5,
    fill: Color.fromRGBO(40, 98, 84, 0.10),
    veil: Color.fromRGBO(208, 234, 220, 0.05),
    sheen: [
      Color.fromRGBO(206, 234, 214, 0.07),
      Color.fromRGBO(206, 234, 214, 0.018),
      Color.fromRGBO(0, 26, 22, 0),
      Color.fromRGBO(0, 26, 22, 0.12),
    ],
    borderWidth: 0.75,
    borderLight: Color.fromRGBO(226, 246, 232, 0.26),
    borderDark: Color.fromRGBO(140, 186, 158, 0.05),
    highlight: Color.fromRGBO(232, 248, 236, 0.16),
    rimLight: Color.fromRGBO(236, 250, 240, 0.08),
    rimDark: Color.fromRGBO(0, 20, 17, 0.16),
    shadows: [
      BoxShadow(
        color: Color.fromRGBO(0, 16, 13, 0.18),
        offset: Offset(0, 3),
        blurRadius: 10,
      ),
    ],
  );

  static const regular = GlassTokens(
    blurSigma: 12,
    fill: Color.fromRGBO(30, 86, 74, 0.26),
    veil: Color.fromRGBO(208, 234, 220, 0.07),
    sheen: [
      Color.fromRGBO(206, 234, 214, 0.05),
      Color.fromRGBO(206, 234, 214, 0.012),
      Color.fromRGBO(0, 26, 22, 0),
      Color.fromRGBO(0, 22, 19, 0.20),
    ],
    borderWidth: 0.75,
    borderLight: Color.fromRGBO(222, 244, 230, 0.19),
    borderDark: Color.fromRGBO(130, 178, 150, 0.05),
    highlight: Color.fromRGBO(232, 248, 236, 0.13),
    rimLight: Color.fromRGBO(236, 250, 240, 0.07),
    rimDark: Color.fromRGBO(0, 18, 15, 0.20),
    shadows: [
      BoxShadow(
        color: Color.fromRGBO(0, 14, 12, 0.26),
        offset: Offset(0, 8),
        blurRadius: 20,
      ),
    ],
  );

  static const frosted = GlassTokens(
    blurSigma: 24,
    fill: Color.fromRGBO(34, 92, 80, 0.36),
    veil: Color.fromRGBO(214, 238, 226, 0.12),
    sheen: [
      Color.fromRGBO(206, 234, 214, 0.06),
      Color.fromRGBO(206, 234, 214, 0.025),
      Color.fromRGBO(0, 26, 22, 0.02),
      Color.fromRGBO(0, 22, 19, 0.16),
    ],
    borderWidth: 0.75,
    borderLight: Color.fromRGBO(222, 244, 230, 0.17),
    borderDark: Color.fromRGBO(130, 178, 150, 0.05),
    highlight: Color.fromRGBO(232, 248, 236, 0.10),
    rimLight: Color.fromRGBO(236, 250, 240, 0.065),
    rimDark: Color.fromRGBO(0, 18, 15, 0.18),
    shadows: [
      BoxShadow(
        color: Color.fromRGBO(0, 14, 12, 0.32),
        offset: Offset(0, 10),
        blurRadius: 26,
      ),
    ],
  );
}

abstract final class GlassNestedTokens {
  static const lift = Color.fromRGBO(214, 240, 224, 0.07);
  static const borderLight = Color.fromRGBO(234, 250, 240, 0.34);
  static const borderDark = Color.fromRGBO(0, 18, 15, 0.22);
  static const rimLight = Color.fromRGBO(240, 252, 244, 0.11);
  static const shadows = [
    BoxShadow(
      color: Color.fromRGBO(0, 16, 13, 0.32),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 16, 13, 0.20),
      offset: Offset(0, 4),
      blurRadius: 10,
    ),
  ];
}

abstract final class AccentTokens {
  static const radiusRatio = 0.41;
  static const base = Color.fromRGBO(206, 226, 120, 0.84);
  static const baseStrong = Color.fromRGBO(216, 234, 130, 0.90);
  static const volume = [
    Color.fromRGBO(246, 252, 212, 0.40),
    Color.fromRGBO(246, 252, 212, 0),
    Color.fromRGBO(84, 124, 46, 0.12),
    Color.fromRGBO(232, 246, 176, 0.24),
  ];
  static const borderWidth = 0.75;
  static const borderLight = Color.fromRGBO(250, 254, 226, 0.62);
  static const borderDark = Color.fromRGBO(70, 108, 40, 0.50);
  static const rimLight = Color.fromRGBO(252, 255, 236, 0.26);
  static const rimDark = Color.fromRGBO(78, 116, 42, 0.30);
  static const iconColor = Color(0xFF0B3B34);
  static const shadows = [
    BoxShadow(
      color: Color.fromRGBO(0, 20, 16, 0.30),
      offset: Offset(0, 3),
      blurRadius: 8,
    ),
    BoxShadow(
      color: Color.fromRGBO(212, 226, 126, 0.12),
      blurRadius: 10,
    ),
  ];
  static const nestedShadows = [
    BoxShadow(
      color: Color.fromRGBO(0, 18, 14, 0.38),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 18, 14, 0.24),
      offset: Offset(0, 4),
      blurRadius: 10,
    ),
    BoxShadow(
      color: Color.fromRGBO(212, 226, 126, 0.12),
      blurRadius: 10,
    ),
  ];
}
