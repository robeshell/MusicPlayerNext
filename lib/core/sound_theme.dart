import 'package:flutter/material.dart';

abstract final class SoundColors {
  static const accent = Color(0xFFFA243C);
  static const darkCanvas = Color(0xFF0D0D0F);
  static const darkSurface = Color(0xFF17171A);
  static const darkElevated = Color(0xFF202024);
  static const lightCanvas = Color(0xFFF5F3F0);
  static const lightSurface = Color(0xFFFCFBF9);
  static const webDav = Color(0xFF5E8BFF);
  static const local = Color(0xFF55B889);
}

abstract final class SoundTheme {
  static final _focusSide = WidgetStateProperty.resolveWith<BorderSide?>(
    (states) => states.contains(WidgetState.focused)
        ? const BorderSide(color: SoundColors.accent, width: 2)
        : null,
  );

  static final _focusOverlay = WidgetStateProperty.resolveWith<Color?>(
    (states) => states.contains(WidgetState.focused)
        ? SoundColors.accent.withValues(alpha: 0.22)
        : null,
  );

  static ButtonStyle get _focusButtonStyle =>
      ButtonStyle(side: _focusSide, overlayColor: _focusOverlay);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: SoundColors.accent,
      brightness: Brightness.dark,
      surface: SoundColors.darkSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: SoundColors.accent,
        surface: SoundColors.darkSurface,
      ),
      scaffoldBackgroundColor: SoundColors.darkCanvas,
      fontFamily: '.SF Pro Text',
      focusColor: SoundColors.accent.withValues(alpha: 0.28),
      dividerColor: Colors.white.withValues(alpha: 0.08),
      splashFactory: InkSparkle.splashFactory,
      iconButtonTheme: IconButtonThemeData(style: _focusButtonStyle),
      filledButtonTheme: FilledButtonThemeData(style: _focusButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _focusButtonStyle),
      textButtonTheme: TextButtonThemeData(style: _focusButtonStyle),
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: SoundColors.accent, width: 2),
        ),
      ),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: SoundColors.accent,
      brightness: Brightness.light,
      surface: SoundColors.lightSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme.copyWith(primary: SoundColors.accent),
      scaffoldBackgroundColor: SoundColors.lightCanvas,
      fontFamily: '.SF Pro Text',
      focusColor: SoundColors.accent.withValues(alpha: 0.2),
      iconButtonTheme: IconButtonThemeData(style: _focusButtonStyle),
      filledButtonTheme: FilledButtonThemeData(style: _focusButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _focusButtonStyle),
      textButtonTheme: TextButtonThemeData(style: _focusButtonStyle),
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: SoundColors.accent, width: 2),
        ),
      ),
    );
  }
}
