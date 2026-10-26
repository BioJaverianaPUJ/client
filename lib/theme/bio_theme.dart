import 'package:flutter/material.dart';

/// Shared visual tokens ported from the existing BioJaveriana frontend.
abstract final class BioTheme {
  static const background = Color(0xFF00362F);
  static const backgroundDeep = Color(0xFF002E29);
  static const textPrimary = Color(0xFFF5F7F4);
  static const textSecondary = Color(0xFFC4CEC9);
  static const textMuted = Color(0xFFA9B8B1);
  static const lime = Color(0xFFD4E27E);
  static const limeSoft = Color(0xFFC4D474);
  static const iconDark = Color(0xFF17463D);
  static const iconLight = Color(0xFFCFDAD5);
  static const botanical = Color(0xFF8FAE78);
  static const forest = Color(0xFF789B70);
  static const danger = Color(0xFFF0A58F);

  static const heroRadius = 40.0;
  static const cardRadius = 32.0;
  static const inputRadius = 25.0;
  static const buttonRadius = 26.0;

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: lime,
      onPrimary: iconDark,
      secondary: limeSoft,
      onSecondary: iconDark,
      surface: backgroundDeep,
      onSurface: textPrimary,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 39,
        height: 43 / 39,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.55,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 36 / 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        height: 22 / 18,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(fontSize: 13.5, height: 19 / 13.5),
      labelMedium: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: textMuted),
      filled: true,
      fillColor: backgroundDeep,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: lime,
        foregroundColor: iconDark,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
    ),
  );
}
