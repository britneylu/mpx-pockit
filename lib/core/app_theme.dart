import 'package:flutter/material.dart';

// share the green palette and rounded controls across screens
ThemeData get appTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF244C40),
    primary: const Color(0xFF244C40),
    surface: const Color(0xFFF8F7F3),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F7F3),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
);
