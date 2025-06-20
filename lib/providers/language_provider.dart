import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  // Dictionnaire de traductions simples
  final Map<String, Map<String, String>> _translations = {
    'fr': {
      // Questions générales
      'What is the capital of': 'Quelle est la capitale de',
      'Who painted the': 'Qui a peint',
      'Which planet is': 'Quelle planète est',
      'What is the largest': 'Quel est le plus grand',
      'Who wrote': 'Qui a écrit',
      'When did': 'Quand est-ce que',
      'What year': 'En quelle année',
      'Which element': 'Quel élément',
      'How many': 'Combien de',
      'What is the chemical formula for': 'Quelle est la formule chimique de',
      
      // Catégories
      'Geography': 'Géographie',
      'History': 'Histoire',
      'Science': 'Science',
      'Art': 'Art',
      'Literature': 'Littérature',
      'Sports': 'Sports',
      'Movies': 'Cinéma',
      'Music': 'Musique',
      'Technology': 'Technologie',
      'Economics': 'Économie',
      
      // Difficultés
      'easy': 'facile',
      'medium': 'moyen',
      'hard': 'difficile',
      
      // Interface
      'Time left': 'Temps restant',
      'seconds': 'secondes',
      'Question': 'Question',
      'Translating question...': 'Traduction en cours...',
      'Any Category': 'Toute Catégorie',
      'Any Difficulty': 'Toute Difficulté',
    },
    'ar': {
      // Questions générales (version simplifiée)
      'What is the capital of': 'ما هي عاصمة',
      'Who painted the': 'من رسم',
      'Which planet is': 'أي كوكب هو',
      'What is the largest': 'ما هو أكبر',
      'Who wrote': 'من كتب',
      
      // Catégories
      'Geography': 'الجغرافيا',
      'History': 'التاريخ',
      'Science': 'العلوم',
      'Art': 'الفن',
      'Literature': 'الأدب',
      
      // Difficultés
      'easy': 'سهل',
      'medium': 'متوسط',
      'hard': 'صعب',
      
      // Interface
      'Time left': 'الوقت المتبقي',
      'seconds': 'ثوان',
      'Question': 'سؤال',
      'Translating question...': 'جاري الترجمة...',
    }
  };

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

  // Méthode améliorée pour traduire du texte
  Future<String> translateText(String text, String sourceLanguage) async {
    // Si la langue actuelle est l'anglais ou la même que la source, retourner le texte original
    if (_currentLanguage == 'en' || _currentLanguage == sourceLanguage) {
      return text;
    }
    
    // Vérifier si nous avons des traductions pour cette langue
    final languageTranslations = _translations[_currentLanguage];
    if (languageTranslations == null) {
      return text; // Retourner le texte original si pas de traductions disponibles
    }
    
    // Chercher des correspondances exactes
    if (languageTranslations.containsKey(text)) {
      return languageTranslations[text]!;
    }
    
    // Chercher des correspondances partielles
    String translatedText = text;
    languageTranslations.forEach((key, value) {
      if (text.contains(key)) {
        translatedText = translatedText.replaceAll(key, value);
      }
    });
    
    return translatedText;
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