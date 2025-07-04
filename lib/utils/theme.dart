import 'package:flutter/material.dart';

final ThemeData appThemeData = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0E1E25),
  cardColor: const Color(0xFF17333F),
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF00A9A5),
    secondary: Color(0xFF00A9A5),
    background: Color(0xFF0E1E25),
    surface: Color(0xFF17333F),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white70),
  ),
);
