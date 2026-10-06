import 'package:flutter/material.dart';

/// Laptop Guardian global app theme.
/// Dark deep-navy palette with cyan accent and glassmorphism cards.
class AppTheme {
  static const _bgDark    = Color(0xFF0A0E1A);
  static const _bgCard    = Color(0xFF111827);
  static const _bgElevated= Color(0xFF1A2235);
  static const _accent    = Color(0xFF00C6FF);
  static const _accentAlt = Color(0xFF7B61FF);
  static const _online    = Color(0xFF22C55E);
  static const _offline   = Color(0xFFEF4444);
  static const _warning   = Color(0xFFF59E0B);
  static const _textPrimary   = Color(0xFFF1F5F9);
  static const _textSecondary = Color(0xFF94A3B8);
  static const _border    = Color(0xFF1E293B);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _bgDark,
    colorScheme: const ColorScheme.dark(
      primary:   _accent,
      secondary: _accentAlt,
      surface:   _bgCard,
      error:     _offline,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: _textPrimary,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: _textPrimary, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _textPrimary),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _textPrimary),
      bodyLarge: TextStyle(fontSize: 15, color: _textPrimary),
      bodyMedium: TextStyle(fontSize: 13, color: _textSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
      labelSmall: TextStyle(fontSize: 11, color: _textSecondary, letterSpacing: 0.5),
    ),
    cardTheme: CardThemeData(
      color: _bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _bgDark,
      foregroundColor: _textPrimary,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: _textPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 2),
      ),
      labelStyle: const TextStyle(color: _textSecondary),
      hintStyle: const TextStyle(color: _textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _accent,
        side: const BorderSide(color: _accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(color: _border, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _bgElevated,
      contentTextStyle: const TextStyle(color: _textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // Named colour accessors for use throughout the app
  static const Color online  = _online;
  static const Color offline = _offline;
  static const Color warning = _warning;
  static const Color accent    = _accent;
  static const Color accentAlt = _accentAlt;
  static const Color bgCard  = _bgCard;
  static const Color bgDark  = _bgDark;
  static const Color bgElevated = _bgElevated;
  static const Color border  = _border;
  static const Color textPrimary   = _textPrimary;
  static const Color textSecondary = _textSecondary;
}
