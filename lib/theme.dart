import 'package:flutter/material.dart';

/// Color palette lifted from the original `public/styles.css` `:root`
/// variables so the Flutter app keeps the same light, teal look.
class AppColors {
  static const bg = Color(0xFFF7F8F7);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F3F2);
  static const surface3 = Color(0xFFE5EEEB);
  static const text = Color(0xFF1F2926);
  static const text2 = Color(0xFF5D6B67);
  static const muted = Color(0xFF8B9692);
  static const line = Color(0xFFDFE6E3);
  static const primary = Color(0xFF006A63);
  static const primary2 = Color(0xFF00877D);
  static const primarySoft = Color(0xFFD7F1ED);
  static const primaryPale = Color(0xFFEEFAF8);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFEE4E2);
  static const warning = Color(0xFFB54708);
  static const warningSoft = Color(0xFFFFF2CC);
  static const success = Color(0xFF067647);
  static const blue = Color(0xFF2167D5);
  static const blueSoft = Color(0xFFE8F0FF);
}

/// Dark-theme palette lifted from `:root[data-theme="dark"]` in the
/// original `styles.css`.
class AppColorsDark {
  static const bg = Color(0xFF101614);
  static const surface = Color(0xFF18201E);
  static const surface2 = Color(0xFF222B28);
  static const text = Color(0xFFF2F6F4);
  static const text2 = Color(0xFFB8C4C0);
  static const muted = Color(0xFF85918D);
  static const line = Color(0xFF303B37);
  static const primary = Color(0xFF63D8CD);
}

ThemeData buildAppTheme({bool dark = false}) {
  if (dark) return _buildDarkTheme();
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.primary2,
      error: AppColors.danger,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
  );
}

ThemeData _buildDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColorsDark.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColorsDark.primary,
      secondary: AppColorsDark.primary,
      surface: AppColorsDark.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColorsDark.bg,
      foregroundColor: AppColorsDark.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColorsDark.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColorsDark.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColorsDark.line, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.primary,
        foregroundColor: const Color(0xFF10241F),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsDark.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsDark.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColorsDark.primary, width: 1.4),
      ),
    ),
    dividerTheme:
        const DividerThemeData(color: AppColorsDark.line, thickness: 1),
  );
}
