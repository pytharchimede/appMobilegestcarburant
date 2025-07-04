// Fichier principal Flutter : main.dart
import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'utils/theme.dart';

void main() {
  runApp(GestionCarburantApp());
}

class GestionCarburantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Carburant',
      theme: appThemeData,
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}
