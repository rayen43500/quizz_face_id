import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final AudioService _audioService = AudioService();
  
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final settings = await _storageService.getSettings();
    setState(() {
      _soundEnabled = settings['sound'] ?? true;
      _notificationsEnabled = settings['notifications'] ?? true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark theme'),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Language'),
                    subtitle: Text(_getLanguageName(languageProvider.currentLanguage)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showLanguageDialog(context, languageProvider);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Sound & Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Sound Effects'),
                    subtitle: const Text('Enable sound effects during quiz'),
                    value: _soundEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _soundEnabled = value;
                      });
                      _audioService.setSoundEnabled(value);
                      await _storageService.saveSetting('sound', value);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Notifications'),
                    subtitle: const Text('Receive quiz reminders'),
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      
                      if (value) {
                        await _notificationService.initNotification();
                        _notificationService.showNotification(
                          id: 1,
                          title: 'Notifications Enabled',
                          body: 'You will now receive quiz reminders',
                        );
                      } else {
                        await _notificationService.cancelAllNotifications();
                      }
                      
                      await _storageService.saveSetting('notifications', value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Clear Quiz History'),
                    subtitle: const Text('Delete all saved quiz results'),
                    trailing: const Icon(Icons.delete, color: Colors.red),
                    onTap: () {
                      _showClearDataDialog(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Sign Out'),
                    subtitle: const Text('Log out from the application'),
                    trailing: const Icon(Icons.logout, color: Colors.red),
                    onTap: () {
                      _showSignOutDialog(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'Quiz App v1.0.0',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      case 'en':
      default:
        return 'English';
    }
  }

  Future<void> _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption(context, languageProvider, 'en', 'English'),
                _buildLanguageOption(context, languageProvider, 'fr', 'Français'),
                _buildLanguageOption(context, languageProvider, 'ar', 'العربية'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    LanguageProvider languageProvider,
    String code,
    String name,
  ) {
    return ListTile(
      title: Text(name),
      leading: Radio<String>(
        value: code,
        groupValue: languageProvider.currentLanguage,
        onChanged: (String? value) {
          if (value != null) {
            languageProvider.setLanguage(value);
            Navigator.of(context).pop();
          }
        },
      ),
      onTap: () {
        languageProvider.setLanguage(code);
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _showClearDataDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Quiz History'),
          content: const Text(
            'Are you sure you want to delete all saved quiz results? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
              onPressed: () async {
                await _storageService.clearQuizResults();
                if (!mounted) return;
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quiz history cleared'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to sign out? You will need to authenticate again to use the app.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sign Out'),
              onPressed: () async {
                // Clear authentication state
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_authenticated', false);
                
                if (!context.mounted) return;
                
                // Navigate back to auth screen
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
} 