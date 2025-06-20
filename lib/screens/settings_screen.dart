import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import '../services/translation_service.dart';
import '../services/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/quiz_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final AudioService _audioService = AudioService();
  final TranslationService _translationService = TranslationService();
  
  bool _soundEnabled = true;
  bool _notificationsEnabled = true;
  bool _mlKitEnabled = true;
  bool _isLoadingModels = false;
  
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
      _mlKitEnabled = settings['ml_kit_enabled'] ?? true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('appearance'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(context.tr('dark_mode')),
                    subtitle: Text(context.tr('enable_dark_theme')),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(context.tr('language')),
                    subtitle: Text(_getLanguageName(languageProvider.currentLanguage)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showLanguageDialog(context, languageProvider);
                    },
                  ),
                ],
              ),
            ),
            
            // ML Kit Translation Section
            const SizedBox(height: 30),
            Text(
              context.tr('translation'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(context.tr('ml_kit_translation')),
                    subtitle: Text(context.tr('use_ml_kit')),
                    value: _mlKitEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _mlKitEnabled = value;
                      });
                      await _storageService.saveSetting('ml_kit_enabled', value);
                      
                      if (value) {
                        _initializeModels();
                      }
                    },
                  ),
                  if (_isLoadingModels)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(context.tr('downloading_model')),
                          ],
                        ),
                      ),
                    ),
                  ListTile(
                    title: Text(context.tr('download_models')),
                    subtitle: Text(context.tr('manage_models')),
                    trailing: const Icon(Icons.download),
                    enabled: _mlKitEnabled,
                    onTap: _mlKitEnabled ? () {
                      _showModelManagementDialog(context);
                    } : null,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            Text(
              context.tr('sound_notifications'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(context.tr('sound_effects')),
                    subtitle: Text(context.tr('enable_sound')),
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
                    title: Text(context.tr('notifications')),
                    subtitle: Text(context.tr('receive_reminders')),
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
            Text(
              context.tr('data'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text(context.tr('clear_history')),
                    subtitle: Text(context.tr('delete_results')),
                    trailing: Icon(Icons.delete, color: Colors.red),
                    onTap: () {
                      _showClearDataDialog(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(context.tr('sign_out')),
                    subtitle: Text(context.tr('logout_message')),
                    trailing: Icon(Icons.logout, color: Colors.red),
                    onTap: () {
                      _showSignOutDialog(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Center(
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

  Future<void> _initializeModels() async {
    setState(() {
      _isLoadingModels = true;
    });
    
    try {
      await _translationService.initialize();
    } catch (e) {
      print('Error initializing translation models: $e');
    } finally {
      setState(() {
        _isLoadingModels = false;
      });
    }
  }

  Future<void> _showModelManagementDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.tr('download_models')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModelOption(context, 'en', 'English'),
                _buildModelOption(context, 'fr', 'Français'),
                _buildModelOption(context, 'ar', 'العربية'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(context.tr('close')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelOption(BuildContext context, String code, String name) {
    return ListTile(
      title: Text(name),
      trailing: ElevatedButton(
        child: Text(context.tr('download')),
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${context.tr('downloading_model')} $name'),
              duration: const Duration(seconds: 2),
            ),
          );
          
          try {
            await _translationService.downloadModelIfNeeded('en', code);
            await _translationService.downloadModelIfNeeded(code, 'en');
            
            if (!context.mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name ${context.tr('model_downloaded')}'),
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${context.tr('error_downloading')}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
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
          title: Text(context.tr('language')),
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
              child: Text(context.tr('cancel')),
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
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    
    return ListTile(
      title: Text(name),
      leading: Radio<String>(
        value: code,
        groupValue: languageProvider.currentLanguage,
        onChanged: (String? value) {
          if (value != null) {
            languageProvider.setLanguage(value);
            quizProvider.checkLanguageChange(value);
            Navigator.of(context).pop();
          }
        },
      ),
      onTap: () {
        languageProvider.setLanguage(code);
        quizProvider.checkLanguageChange(code);
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _showClearDataDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.tr('clear_history')),
          content: Text(context.tr('clear_confirmation')),
          actions: <Widget>[
            TextButton(
              child: Text(context.tr('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(context.tr('clear')),
              onPressed: () async {
                await _storageService.clearQuizResults();
                if (!mounted) return;
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('clear_history')),
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
          title: Text(context.tr('sign_out')),
          content: Text(context.tr('sign_out_confirmation')),
          actions: <Widget>[
            TextButton(
              child: Text(context.tr('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(context.tr('sign_out')),
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