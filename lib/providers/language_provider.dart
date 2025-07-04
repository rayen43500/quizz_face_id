import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';
import '../services/storage_service.dart';
import '../services/app_localizations.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;
  
  // ML Kit translation service
  final TranslationService _translationService = TranslationService();
  final StorageService _storageService = StorageService();
  bool _isInitialized = false;
  bool _mlKitEnabled = true;

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
      'Who discovered': 'Qui a découvert',
      'What is the longest': 'Quel est le plus long',
      'What is the currency of': 'Quelle est la monnaie de',
      'Who is the author of': 'Qui est l\'auteur de',
      'What is the most abundant': 'Quel est le plus abondant',
      'What is the highest': 'Quelle est la plus haute',
      'What is': 'Qu\'est-ce que',
      'Which of these': 'Laquelle de ces',
      'In which year': 'En quelle année',
      'Which country': 'Quel pays',
      'What was the': 'Quel était le',
      'What does': 'Que signifie',
      'Where is': 'Où se trouve',
      'Who was': 'Qui était',
      
      // Réponses communes
      'True': 'Vrai',
      'False': 'Faux',
      'Yes': 'Oui',
      'No': 'Non',
      'All of the above': 'Toutes les réponses ci-dessus',
      'None of the above': 'Aucune des réponses ci-dessus',
      'I don\'t know': 'Je ne sais pas',
      'Maybe': 'Peut-être',
      'Both A and B': 'À la fois A et B',
      'Neither A nor B': 'Ni A ni B',
      'A and C': 'A et C',
      'B and D': 'B et D',
      'All of these': 'Tous ces éléments',
      'None of these': 'Aucun de ces éléments',
      'Correct': 'Correct',
      'Incorrect': 'Incorrect',
      
      // Pays et lieux
      'France': 'France',
      'London': 'Londres',
      'Berlin': 'Berlin',
      'Madrid': 'Madrid',
      'Pacific Ocean': 'Océan Pacifique',
      'Atlantic Ocean': 'Océan Atlantique',
      'Indian Ocean': 'Océan Indien',
      'Arctic Ocean': 'Océan Arctique',
      'Russia': 'Russie',
      'Canada': 'Canada',
      'China': 'Chine',
      'United States': 'États-Unis',
      'Japan': 'Japon',
      'Mount Everest': 'Mont Everest',
      'K2': 'K2',
      'Mont Blanc': 'Mont Blanc',
      'Kilimanjaro': 'Kilimandjaro',
      'The Nile': 'Le Nil',
      'The Amazon': 'L\'Amazone',
      'The Mississippi': 'Le Mississippi',
      'The Yangtze': 'Le Yangtsé',
      'Paris': 'Paris',
      'Rome': 'Rome',
      'New York': 'New York',
      'Tokyo': 'Tokyo',
      'Cairo': 'Le Caire',
      'Sydney': 'Sydney',
      'Moscow': 'Moscou',
      'Brazil': 'Brésil',
      'Germany': 'Allemagne',
      'Italy': 'Italie',
      'Spain': 'Espagne',
      'United Kingdom': 'Royaume-Uni',
      'Australia': 'Australie',
      'India': 'Inde',
      'Mexico': 'Mexique',
      'Egypt': 'Égypte',
      'South Africa': 'Afrique du Sud',
      'Argentina': 'Argentine',
      
      // Personnes
      'Leonardo da Vinci': 'Léonard de Vinci',
      'Pablo Picasso': 'Pablo Picasso',
      'Vincent van Gogh': 'Vincent van Gogh',
      'Michelangelo': 'Michel-Ange',
      'Victor Hugo': 'Victor Hugo',
      'Alexandre Dumas': 'Alexandre Dumas',
      'Émile Zola': 'Émile Zola',
      'Gustave Flaubert': 'Gustave Flaubert',
      'Alexander Fleming': 'Alexander Fleming',
      'Louis Pasteur': 'Louis Pasteur',
      'Marie Curie': 'Marie Curie',
      'Albert Einstein': 'Albert Einstein',
      'J.K. Rowling': 'J.K. Rowling',
      'Stephen King': 'Stephen King',
      'George R.R. Martin': 'George R.R. Martin',
      'Tolkien': 'Tolkien',
      'Claude Monet': 'Claude Monet',
      'Salvador Dalí': 'Salvador Dalí',
      'William Shakespeare': 'William Shakespeare',
      'Isaac Newton': 'Isaac Newton',
      'Charles Darwin': 'Charles Darwin',
      'Galileo Galilei': 'Galilée',
      'Napoleon Bonaparte': 'Napoléon Bonaparte',
      'Julius Caesar': 'Jules César',
      'Alexander the Great': 'Alexandre le Grand',
      'Mozart': 'Mozart',
      'Beethoven': 'Beethoven',
      'Bach': 'Bach',
      
      // Éléments et sciences
      'Mercury': 'Mercure',
      'Venus': 'Vénus',
      'Earth': 'Terre',
      'Mars': 'Mars',
      'H2O': 'H2O',
      'CO2': 'CO2',
      'O2': 'O2',
      'NaCl': 'NaCl',
      'Hydrogen': 'Hydrogène',
      'Oxygen': 'Oxygène',
      'Carbon': 'Carbone',
      'Iron': 'Fer',
      'Gold': 'Or',
      'Silver': 'Argent',
      'Copper': 'Cuivre',
      'Helium': 'Hélium',
      'Nitrogen': 'Azote',
      'Calcium': 'Calcium',
      'Sodium': 'Sodium',
      'Potassium': 'Potassium',
      'Zinc': 'Zinc',
      'Magnesium': 'Magnésium',
      'Physics': 'Physique',
      'Chemistry': 'Chimie',
      'Biology': 'Biologie',
      'Astronomy': 'Astronomie',
      'Mathematics': 'Mathématiques',
      'Geology': 'Géologie',
      
      // Œuvres
      'Mona Lisa': 'La Joconde',
      'Les Misérables': 'Les Misérables',
      'Harry Potter': 'Harry Potter',
      'The Starry Night': 'La Nuit étoilée',
      'The Last Supper': 'La Cène',
      'War and Peace': 'Guerre et Paix',
      'The Great Gatsby': 'Gatsby le Magnifique',
      'Don Quixote': 'Don Quichotte',
      'The Bible': 'La Bible',
      'The Odyssey': 'L\'Odyssée',
      'Romeo and Juliet': 'Roméo et Juliette',
      'Hamlet': 'Hamlet',
      'Macbeth': 'Macbeth',
      
      // Monnaies et économie
      'Yen': 'Yen',
      'Won': 'Won',
      'Yuan': 'Yuan',
      'Dollar': 'Dollar',
      'Euro': 'Euro',
      'Pound': 'Livre',
      'Rupee': 'Roupie',
      'Peso': 'Peso',
      'Franc': 'Franc',
      'Ruble': 'Rouble',
      
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
      'Entertainment: Books': 'Divertissement: Livres',
      'Entertainment: Film': 'Divertissement: Films',
      'Entertainment: Music': 'Divertissement: Musique',
      'Entertainment: Television': 'Divertissement: Télévision',
      'Entertainment: Video Games': 'Divertissement: Jeux Vidéo',
      'Entertainment: Board Games': 'Divertissement: Jeux de Société',
      'Science & Nature': 'Science & Nature',
      'Science: Computers': 'Science: Informatique',
      'Science: Mathematics': 'Science: Mathématiques',
      'Mythology': 'Mythologie',
      'Sports': 'Sports',
      'General Knowledge': 'Culture Générale',
      'Vehicles': 'Véhicules',
      'Animals': 'Animaux',
      'Politics': 'Politique',
      'Celebrities': 'Célébrités',
      
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
      'Quit Quiz?': 'Quitter le Quiz?',
      'Are you sure you want to quit? Your progress will be lost.': 'Êtes-vous sûr de vouloir quitter? Votre progression sera perdue.',
      'Cancel': 'Annuler',
      'Quit': 'Quitter',
      'Reload': 'Recharger',
      'Problem displaying question': 'Problème d\'affichage de la question',
      'Recharger': 'Recharger',
      'back': 'Retour',
      'next': 'Suivant',
      'question': 'Question',
      'time_left': 'Temps restant',
      'seconds': 'secondes',
      'reload': 'Recharger',
      'problem_displaying_question': 'Problème d\'affichage de la question',
      'quit_quiz': 'Quitter le Quiz',
      'quit_confirmation': 'Êtes-vous sûr de vouloir quitter? Votre progression sera perdue.',
      'cancel': 'Annuler',
      'quit': 'Quitter',
    },
    'ar': {
      // Questions générales
      'What is the capital of': 'ما هي عاصمة',
      'Who painted the': 'من رسم',
      'Which planet is': 'أي كوكب هو',
      'What is the largest': 'ما هو أكبر',
      'Who wrote': 'من كتب',
      'When did': 'متى',
      'What year': 'في أي سنة',
      'Which element': 'أي عنصر',
      'How many': 'كم عدد',
      'What is the chemical formula for': 'ما هي الصيغة الكيميائية لـ',
      'Who discovered': 'من اكتشف',
      'What is the longest': 'ما هو أطول',
      'What is the currency of': 'ما هي عملة',
      'Who is the author of': 'من هو مؤلف',
      'What is the most abundant': 'ما هو الأكثر وفرة',
      'What is the highest': 'ما هو الأعلى',
      'What is': 'ما هو',
      'Which of these': 'أي من هذه',
      'In which year': 'في أي سنة',
      'Which country': 'أي بلد',
      'What was the': 'ما كان',
      'What does': 'ماذا يعني',
      'Where is': 'أين يقع',
      'Who was': 'من كان',
      
      // Réponses communes
      'True': 'صحيح',
      'False': 'خطأ',
      'Yes': 'نعم',
      'No': 'لا',
      'All of the above': 'كل ما سبق',
      'None of the above': 'لا شيء مما سبق',
      'I don\'t know': 'لا أعرف',
      'Maybe': 'ربما',
      'Both A and B': 'كل من أ و ب',
      'Neither A nor B': 'لا أ ولا ب',
      'A and C': 'أ و ج',
      'B and D': 'ب و د',
      'All of these': 'كل هذه',
      'None of these': 'لا شيء من هذه',
      'Correct': 'صحيح',
      'Incorrect': 'خطأ',
      
      // Pays et lieux
      'France': 'فرنسا',
      'London': 'لندن',
      'Berlin': 'برلين',
      'Madrid': 'مدريد',
      'Pacific Ocean': 'المحيط الهادئ',
      'Atlantic Ocean': 'المحيط الأطلسي',
      'Indian Ocean': 'المحيط الهندي',
      'Russia': 'روسيا',
      'Canada': 'كندا',
      'China': 'الصين',
      'United States': 'الولايات المتحدة',
      'Japan': 'اليابان',
      'Mount Everest': 'جبل إفرست',
      'K2': 'كي2',
      'Mont Blanc': 'مون بلان',
      'Kilimanjaro': 'كليمنجارو',
      'The Nile': 'النيل',
      'The Amazon': 'الأمازون',
      'The Mississippi': 'المسيسيبي',
      'The Yangtze': 'اليانغتسي',
      'Paris': 'باريس',
      'Rome': 'روما',
      'New York': 'نيويورك',
      'Tokyo': 'طوكيو',
      'Cairo': 'القاهرة',
      'Sydney': 'سيدني',
      'Moscow': 'موسكو',
      'Brazil': 'البرازيل',
      'Germany': 'ألمانيا',
      'Italy': 'إيطاليا',
      'Spain': 'إسبانيا',
      'United Kingdom': 'المملكة المتحدة',
      'Australia': 'أستراليا',
      'India': 'الهند',
      'Mexico': 'المكسيك',
      'Egypt': 'مصر',
      'South Africa': 'جنوب أفريقيا',
      'Argentina': 'الأرجنتين',
      
      // Personnes
      'Leonardo da Vinci': 'ليوناردو دا فينشي',
      'Pablo Picasso': 'بابلو بيكاسو',
      'Vincent van Gogh': 'فينسنت فان جوخ',
      'Michelangelo': 'مايكل أنجلو',
      'Victor Hugo': 'فيكتور هوجو',
      'Alexandre Dumas': 'ألكسندر دوما',
      'Marie Curie': 'ماري كوري',
      'Albert Einstein': 'ألبرت أينشتاين',
      'William Shakespeare': 'ويليام شكسبير',
      'Isaac Newton': 'إسحاق نيوتن',
      'Charles Darwin': 'تشارلز داروين',
      'Galileo Galilei': 'غاليليو غاليلي',
      'Napoleon Bonaparte': 'نابليون بونابرت',
      'Julius Caesar': 'يوليوس قيصر',
      'Alexander the Great': 'الإسكندر الأكبر',
      'Mozart': 'موتسارت',
      'Beethoven': 'بيتهوفن',
      'Bach': 'باخ',
      
      // Éléments et sciences
      'Mercury': 'عطارد',
      'Venus': 'الزهرة',
      'Earth': 'الأرض',
      'Mars': 'المريخ',
      'Jupiter': 'المشتري',
      'Saturn': 'زحل',
      'Uranus': 'أورانوس',
      'Neptune': 'نبتون',
      'Pluto': 'بلوتو',
      'H2O': 'H2O',
      'CO2': 'CO2',
      'O2': 'O2',
      'Hydrogen': 'هيدروجين',
      'Oxygen': 'أكسجين',
      'Carbon': 'كربون',
      'Iron': 'حديد',
      'Gold': 'ذهب',
      'Silver': 'فضة',
      'Copper': 'نحاس',
      'Helium': 'هيليوم',
      'Nitrogen': 'نيتروجين',
      'Calcium': 'كالسيوم',
      'Sodium': 'صوديوم',
      'Potassium': 'بوتاسيوم',
      'Zinc': 'زنك',
      'Magnesium': 'مغنيسيوم',
      'Physics': 'فيزياء',
      'Chemistry': 'كيمياء',
      'Biology': 'علم الأحياء',
      'Astronomy': 'علم الفلك',
      'Mathematics': 'رياضيات',
      'Geology': 'جيولوجيا',
      
      // Catégories
      'Geography': 'الجغرافيا',
      'History': 'التاريخ',
      'Science': 'العلوم',
      'Art': 'الفن',
      'Literature': 'الأدب',
      'Sports': 'الرياضة',
      'Movies': 'الأفلام',
      'Music': 'الموسيقى',
      'Technology': 'التكنولوجيا',
      'Economics': 'الاقتصاد',
      'Entertainment: Books': 'الترفيه: الكتب',
      'Entertainment: Film': 'الترفيه: الأفلام',
      'Entertainment: Music': 'الترفيه: الموسيقى',
      'Entertainment: Television': 'الترفيه: التلفزيون',
      'Entertainment: Video Games': 'الترفيه: ألعاب الفيديو',
      'Entertainment: Board Games': 'الترفيه: ألعاب اللوح',
      'Science & Nature': 'العلوم والطبيعة',
      'Science: Computers': 'العلوم: الكمبيوتر',
      'Science: Mathematics': 'العلوم: الرياضيات',
      'Mythology': 'الميثولوجيا',
      'Sports': 'الرياضة',
      'General Knowledge': 'المعرفة العامة',
      'Vehicles': 'المركبات',
      'Animals': 'الحيوانات',
      'Politics': 'السياسة',
      'Celebrities': 'المشاهير',
      
      // Difficultés
      'easy': 'سهل',
      'medium': 'متوسط',
      'hard': 'صعب',
      
      // Interface
      'Time left': 'الوقت المتبقي',
      'seconds': 'ثوان',
      'Question': 'سؤال',
      'Translating question...': 'جاري الترجمة...',
      'Any Category': 'أي فئة',
      'Any Difficulty': 'أي صعوبة',
      'Quit Quiz?': 'الخروج من الاختبار؟',
      'Are you sure you want to quit? Your progress will be lost.': 'هل أنت متأكد أنك تريد الخروج؟ سيتم فقدان تقدمك.',
      'Cancel': 'إلغاء',
      'Quit': 'خروج',
      'Reload': 'إعادة تحميل',
      'Problem displaying question': 'مشكلة في عرض السؤال',
      'Recharger': 'إعادة تحميل',
      'back': 'رجوع',
      'next': 'التالي',
      'question': 'سؤال',
      'time_left': 'الوقت المتبقي',
      'seconds': 'ثوان',
      'reload': 'إعادة تحميل',
      'problem_displaying_question': 'مشكلة في عرض السؤال',
      'quit_quiz': 'الخروج من الاختبار',
      'quit_confirmation': 'هل أنت متأكد أنك تريد الخروج؟ سيتم فقدان تقدمك.',
      'cancel': 'إلغاء',
      'quit': 'خروج',
    }
  };

  LanguageProvider() {
    _loadLanguageFromPrefs();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _storageService.getSettings();
    _mlKitEnabled = settings['ml_kit_enabled'] ?? true;
    
    if (_mlKitEnabled) {
      _initializeTranslationService();
    }
  }

  Future<void> _initializeTranslationService() async {
    try {
      await _translationService.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing translation service: $e');
    }
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

  // Méthode pour traduire du texte
  Future<String> translateTextAsync(String text, String sourceLanguage) async {
    // Si la langue actuelle est l'anglais ou la même que la source, retourner le texte original
    if (_currentLanguage == 'en' || _currentLanguage == sourceLanguage) {
      return text;
    }
    
    // Nettoyage du texte avant traduction
    String cleanedText = text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .trim();
    
    // Si ML Kit est activé et initialisé, essayer d'abord la traduction ML Kit
    if (_mlKitEnabled && _isInitialized) {
      try {
        final translatedText = await _translationService.translateText(
          cleanedText, 
          sourceLanguage, 
          _currentLanguage
        );
        
        if (translatedText != cleanedText) {
          return translatedText;
        }
      } catch (e) {
        print('ML Kit translation error: $e');
        // En cas d'erreur, continuer avec la traduction basée sur le dictionnaire
      }
    }
    
    // Traduction basée sur le dictionnaire comme fallback
    final languageTranslations = _translations[_currentLanguage];
    if (languageTranslations != null) {
      // Chercher des correspondances exactes
      if (languageTranslations.containsKey(cleanedText)) {
        return languageTranslations[cleanedText]!;
      }
      
      // Chercher des correspondances pour des phrases complètes
      String translatedText = cleanedText;
      
      // Trier les clés par longueur (des plus longues aux plus courtes) pour éviter les remplacements partiels
      final sortedKeys = languageTranslations.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      
      for (final key in sortedKeys) {
        if (cleanedText.contains(key)) {
          translatedText = translatedText.replaceAll(key, languageTranslations[key]!);
        }
      }
      
      if (translatedText != cleanedText) {
        return translatedText;
      }
    }
    
    // Si aucune traduction n'est trouvée, retourner le texte original
    return text;
  }
  
  // Méthode synchrone pour la compatibilité avec le code existant
  String translateText(String text, String sourceLanguage) {
    // Si la langue actuelle est l'anglais ou la même que la source, retourner le texte original
    if (_currentLanguage == 'en' || _currentLanguage == sourceLanguage) {
      return text;
    }
    
    // Nettoyage du texte avant traduction
    String cleanedText = text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .trim();
    
    // Pour la méthode synchrone, utiliser uniquement le dictionnaire
    final languageTranslations = _translations[_currentLanguage];
    if (languageTranslations != null) {
      // Chercher des correspondances exactes
      if (languageTranslations.containsKey(cleanedText)) {
        return languageTranslations[cleanedText]!;
      }
      
      // Chercher des correspondances pour des phrases complètes
      String translatedText = cleanedText;
      
      // Trier les clés par longueur (des plus longues aux plus courtes) pour éviter les remplacements partiels
      final sortedKeys = languageTranslations.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      
      for (final key in sortedKeys) {
        if (cleanedText.contains(key)) {
          translatedText = translatedText.replaceAll(key, languageTranslations[key]!);
        }
      }
      
      if (translatedText != cleanedText) {
        return translatedText;
      }
    }
    
    // Si aucune traduction n'est trouvée, retourner le texte original
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
  
  @override
  void dispose() {
    _translationService.dispose();
    super.dispose();
  }
} 