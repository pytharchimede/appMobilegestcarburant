// Fichier principal Flutter : main.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart'; // À créer pour le bouton Google
import 'utils/theme.dart';

final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // S'assure que Firebase est initialisé avec les bonnes options (web/mobile)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Gère la notification reçue en arrière-plan ici
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Important sur le Web: fournir les options de configuration
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialise les données locales Intl dynamiquement selon l'appareil
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final candidates = <String>{
    'fr',
    'fr_FR',
    deviceLocale.toString(),
    deviceLocale.languageCode,
  }.map((l) => Intl.canonicalizedLocale(l)).where((l) => l.isNotEmpty).toList();
  for (final loc in candidates) {
    try {
      await initializeDateFormatting(loc);
    } catch (_) {
      // Ignorer les locales non supportées par intl
    }
  }
  Intl.defaultLocale = Intl.canonicalizedLocale(deviceLocale.toString());
  // Ne pas enregistrer le background handler sur le Web (non supporté)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  runApp(GestionCarburantApp());
}

class GestionCarburantApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Carburant',
      theme: appThemeData,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localeResolutionCallback: (locale, supported) {
        // Détermine une locale supportée et synchronise Intl
        Locale resolved = supported.first;
        if (locale != null) {
          for (final s in supported) {
            if (s.languageCode == locale.languageCode) {
              resolved = s;
              break;
            }
          }
        }
        Intl.defaultLocale = Intl.canonicalizedLocale(resolved.toLanguageTag());
        return resolved;
      },
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
      home: AuthGate(),
    );
  }
}

// Widget qui gère la redirection automatique selon l'état de connexion
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return DashboardScreen();
        }
        return LoginScreen(); // Affiche l'écran de connexion Google
      },
    );
  }
}
