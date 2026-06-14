import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _primary      = Color(0xFF1B5E20); // deep green (feed/agro)
  static const Color _primaryLight = Color(0xFF2E7D32);
  static const Color _accent       = Color(0xFFF57F17); // amber
  static const Color _error        = Color(0xFFC62828);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _accent,
      error: _error,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF1B5E20),
      selectedIconTheme: IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: Color(0xFFA5D6A7)),
      selectedLabelTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: TextStyle(color: Color(0xFFA5D6A7)),
      indicatorColor: Color(0xFF2E7D32),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
    ),
  );
}
