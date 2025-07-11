import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';

import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/quiz_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/quiz_setup_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'services/notification_service.dart';
import 'services/audio_service.dart';
import 'services/face_auth_service.dart';
import 'services/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/translation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final notificationService = NotificationService();
  await notificationService.initNotification();
  
  final audioService = AudioService();
  final faceAuthService = FaceAuthService();
  
  // Check if user is already authenticated
  final prefs = await SharedPreferences.getInstance();
  final isAuthenticated = prefs.getBool('is_authenticated') ?? false;
  
  // Initialiser le service de traduction et précharger les modèles
  final translationService = TranslationService();
  // Initialiser le service en arrière-plan
  translationService.initialize().then((initialized) {
    if (initialized && !kIsWeb) {
      // Précharger les modèles de traduction en arrière-plan (sauf sur le web)
      translationService.preloadTranslationModels();
    }
  });
  
  // Afficher un message si on est sur le web
  if (kIsWeb) {
    debugPrint('⚠️ Application exécutée sur le web: certaines fonctionnalités comme ML Kit ne sont pas disponibles');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MyApp(isAuthenticated: isAuthenticated),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;
  
  const MyApp({super.key, this.isAuthenticated = false});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return MaterialApp(
      title: 'Quiz App',
      theme: themeProvider.themeData,
      locale: languageProvider.locale,
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('fr', ''), // French
        Locale('ar', ''), // Arabic
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: isAuthenticated ? '/home' : '/auth',
      routes: {
        '/': (context) => isAuthenticated ? const HomeScreen() : const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/quiz_setup': (context) => const QuizSetupScreen(),
        '/quiz': (context) {
          // Use post-frame callback to show SnackBar after the build is complete
          if (kIsWeb) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sur le web, les traductions avancées avec ML Kit ne sont pas disponibles. Un dictionnaire de base sera utilisé à la place.'),
                  duration: Duration(seconds: 5),
                ),
              );
            });
          }
          return const QuizScreen();
        },
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/about': (context) => const AboutScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
