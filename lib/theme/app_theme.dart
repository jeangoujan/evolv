import 'package:flutter/material.dart';

// === Evolv Brand Colors ===
const Color mintPrimary = Color(0xFF7BC8A4);
const Color mintSecondary = Color(0xFF4CAF93);
const Color lightBackground = Color(0xFFF8FAF8);
const Color cardBackground = Color(0xFFFFFFFF);
const Color darkBackground = Color(0xFF121412);
const Color textDark = Color(0xFF222222);
const Color textLight = Color(0xFFE6ECE6);

ThemeData evolvLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: mintPrimary,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: lightBackground,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w600, color: textDark),
      titleMedium: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w500, color: textDark),
      bodyMedium: TextStyle(fontFamily: 'Inter', color: textDark),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: mintPrimary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 6,
    ),
  );
}

ThemeData evolvDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: mintPrimary,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: darkBackground,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w600, color: textLight),
      titleMedium: TextStyle(
          fontFamily: 'Inter', fontWeight: FontWeight.w500, color: textLight),
      bodyMedium: TextStyle(fontFamily: 'Inter', color: textLight),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textLight,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: mintSecondary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 6,
    ),
  );
}