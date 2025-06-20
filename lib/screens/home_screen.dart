import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../services/app_localizations.dart';
import 'quiz_setup_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import 'leaderboard_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('app_title')),
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (String language) {
              languageProvider.setLanguage(language);
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'en',
                  child: Text('English'),
                ),
                const PopupMenuItem<String>(
                  value: 'fr',
                  child: Text('Français'),
                ),
                const PopupMenuItem<String>(
                  value: 'ar',
                  child: Text('العربية'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 70,
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.quiz,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                context.tr('welcome'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Test your knowledge with questions from various categories',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildMenuButton(
                context,
                context.tr('start_quiz'),
                Icons.play_arrow,
                Colors.green,
                () {
                  Navigator.pushNamed(context, '/quiz_setup');
                },
              ),
              const SizedBox(height: 15),
              _buildMenuButton(
                context,
                context.tr('leaderboard'),
                Icons.leaderboard,
                Colors.orange,
                () {
                  Navigator.pushNamed(context, '/leaderboard');
                },
              ),
              const SizedBox(height: 15),
              _buildMenuButton(
                context,
                context.tr('settings'),
                Icons.settings,
                Colors.purple,
                () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              const SizedBox(height: 15),
              _buildMenuButton(
                context,
                context.tr('about'),
                Icons.info,
                Colors.blue,
                () {
                  Navigator.pushNamed(context, '/about');
                },
              ),
              const SizedBox(height: 15),
              _buildMenuButton(
                context,
                'Face Authentication',
                Icons.face,
                Colors.red,
                () {
                  Navigator.pushNamed(context, '/auth');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
} 