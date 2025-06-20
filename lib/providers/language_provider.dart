import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguageFromPrefs();
  }

  Future<void> _loadLanguageFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;
    
    _currentLanguage = languageCode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    
    notifyListeners();
  }

  // Version simplifiée qui retourne le texte original
  // Dans une vraie application, vous utiliseriez une API de traduction
  Future<String> translateText(String text, String sourceLanguage) async {
    // Pour l'instant, nous retournons simplement le texte original
    return text;
  }

  Locale get locale {
    switch (_currentLanguage) {
      case 'fr':
        return const Locale('fr', '');
      case 'ar':
        return const Locale('ar', '');
      case 'en':
      default:
        return const Locale('en', '');
    }
  }
} 