import 'package:flutter/material.dart';

import 'bio_theme.dart';

abstract final class BioTextStyles {
  static const eyebrow = TextStyle(
    color: BioTheme.limeSoft,
    fontSize: 8.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 2.15,
  );

  static const screenTitle = TextStyle(
    color: BioTheme.textPrimary,
    fontSize: 38,
    height: 41 / 38,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.55,
  );

  static const screenDescription = TextStyle(
    color: BioTheme.textSecondary,
    fontSize: 13.5,
    height: 20 / 13.5,
  );

  static const sectionEyebrow = TextStyle(
    color: BioTheme.textMuted,
    fontSize: 8,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.8,
  );

  static const cardEyebrow = TextStyle(
    color: BioTheme.limeSoft,
    fontSize: 7,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );

  static const cardTitle = TextStyle(
    color: BioTheme.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const cardDescription = TextStyle(
    color: BioTheme.textMuted,
    fontSize: 10,
  );

  static const statValue = TextStyle(
    color: BioTheme.textPrimary,
    fontSize: 25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
  );

  static const statLabel = TextStyle(
    color: BioTheme.textMuted,
    fontSize: 9.5,
    fontWeight: FontWeight.w600,
  );
}
