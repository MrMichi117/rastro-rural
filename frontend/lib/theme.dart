import 'package:flutter/material.dart';

const green = Color(0xFF007A33);
const red = Color(0xFFE20613);
const blue = Color(0xFF0085CA);
const ink = Color(0xFF212529);
const background = Color(0xFFF8F9FA);

ThemeData rastroTheme() {
  final base = ThemeData(useMaterial3: true, fontFamily: 'Roboto');
  return base.copyWith(
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: green,
      secondary: blue,
      error: red,
      surface: Colors.white,
      onSurface: ink,
    ),
    textTheme: base.textTheme.copyWith(
      headlineMedium: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        height: 1.6,
        color: ink,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        height: 1.5,
        color: ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 60),
        backgroundColor: green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 60),
        foregroundColor: green,
        side: const BorderSide(color: green),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: blue,
        minimumSize: const Size(0, 60),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
