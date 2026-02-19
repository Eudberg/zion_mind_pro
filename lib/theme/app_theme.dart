import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B1220);
  static const Color surface = Color(0xFF111827);
  static const Color surface2 = Color(0xFF1F2937);

  // ✅ Agora o destaque principal do app é emerald (Iterum)
  static const Color primary = Color(0xFF10B981); // emerald
  static const Color secondary = Color(0xFF2563EB); // blue (suporte)

  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Color textPrimary = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFF334155);

  static final ThemeData midnightBlueEmerald = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    dividerColor: divider,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
      onPrimary: Colors.white,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onError: textPrimary,
      outline: divider,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      iconTheme: IconThemeData(color: textPrimary),
      actionsIconTheme: IconThemeData(color: textPrimary),
      elevation: 0,
    ),

    cardTheme: const CardThemeData(
      color: surface,
      shadowColor: Color(0x33000000),
      elevation: 2,
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: surface,
      titleTextStyle: TextStyle(color: textPrimary, fontSize: 20),
      contentTextStyle: TextStyle(color: textPrimary),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: surface,
      contentTextStyle: TextStyle(color: textPrimary),
      actionTextColor: primary,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: const BorderSide(color: divider),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),

    // ✅ Se você ainda usar ToggleButtons em alguma tela, agora fica emerald
    toggleButtonsTheme: ToggleButtonsThemeData(
      color: textSecondary,
      selectedColor: Colors.white,
      fillColor: primary, // emerald
      borderColor: divider,
      selectedBorderColor: primary,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary, // emerald
      unselectedItemColor: textSecondary,
    ),
  );
}
