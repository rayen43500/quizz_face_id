import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Service de traduction utilisant Google ML Kit pour la traduction hors ligne
class TranslationService {
  // Modèles de traduction
  final Map<String, OnDeviceTranslator> _translators = {};
  final Map<String, bool> _downloadedModels = {
    'en_fr': false,
    'en_ar': false,
    'fr_en': false,
    'ar_en': false,
  };
  
  // Files d'attente pour les téléchargements de modèles
  final Map<String, Completer<bool>> _downloadCompleters = {};

  // Langues supportées par le service
  final List<String> _supportedLanguages = ['en', 'fr', 'ar'];
  bool _isInitialized = false;
  bool _isNativePluginAvailable = true;
  
  // Statistiques de performance
  int _totalTranslations = 0;
  int _cacheHits = 0;
  int _translationErrors = 0;
  
  // Cache LRU (Least Recently Used) pour les traductions
  final int _maxCacheSize = 1000;
  final LinkedHashMap<String, String> _translationCache = LinkedHashMap();
  
  // Singleton pattern
  static final TranslationService _instance = TranslationService._internal();
  
  factory TranslationService() {
    return _instance;
  }
  
  TranslationService._internal() {
    // Désactiver ML Kit sur le web car il n'est pas supporté
    if (kIsWeb) {
      debugPrint('⚠️ Exécution sur le web détectée, ML Kit sera désactivé');
      _isNativePluginAvailable = false;
    }
  }

  /// Initialiser le service de traduction
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Si on est sur le web, on utilise directement le mode fallback
    if (kIsWeb) {
      debugPrint('⚠️ ML Kit n\'est pas supporté sur le web, utilisation du mode fallback');
      _isNativePluginAvailable = false;
      _isInitialized = true;
      return true;
    }

    try {
      debugPrint('🌐 Initialisation du service de traduction ML Kit...');
      // Création des traducteurs pour chaque paire de langues
      await _createTranslators();
      _isInitialized = true;
      debugPrint('✅ Service de traduction ML Kit initialisé avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation du service de traduction: $e');
      
      // Si l'erreur est liée à l'absence du plugin natif, désactiver ML Kit
      if (e.toString().contains('MissingPluginException')) {
        debugPrint('⚠️ Plugin ML Kit non disponible sur cette plateforme, utilisation du mode fallback');
        _isNativePluginAvailable = false;
        _isInitialized = true; // On considère quand même le service comme initialisé
        return true;
      }
      
      // Réessayer l'initialisation après un délai
      await Future.delayed(const Duration(seconds: 2));
      return false;
    }
  }

  /// Créer les traducteurs pour toutes les paires de langues supportées
  Future<void> _createTranslators() async {
    if (!_isNativePluginAvailable) {
      debugPrint('⚠️ Plugin ML Kit non disponible, traducteurs non créés');
      return;
    }
    
    for (final sourceLanguage in _supportedLanguages) {
      for (final targetLanguage in _supportedLanguages) {
        if (sourceLanguage != targetLanguage) {
          final key = '${sourceLanguage}_$targetLanguage';
          
          try {
            final sourceLanguageCode = _getTranslateLanguage(sourceLanguage);
            final targetLanguageCode = _getTranslateLanguage(targetLanguage);

            final translator = OnDeviceTranslator(
              sourceLanguage: sourceLanguageCode,
              targetLanguage: targetLanguageCode,
            );

            _translators[key] = translator;
            debugPrint('📚 Traducteur créé: $sourceLanguage -> $targetLanguage');

            // Vérifier si le modèle est déjà téléchargé
            await _checkModelDownloadStatus(sourceLanguage, targetLanguage);
          } catch (e) {
            debugPrint('⚠️ Erreur lors de la création du traducteur $key: $e');
            
            if (e.toString().contains('MissingPluginException')) {
              _isNativePluginAvailable = false;
              debugPrint('⚠️ Plugin ML Kit non disponible, arrêt de la création des traducteurs');
              return;
            }
          }
        }
      }
    }
  }

  /// Vérifier si un modèle de langue est déjà téléchargé
  Future<bool> _checkModelDownloadStatus(String sourceLanguage, String targetLanguage) async {
    if (!_isNativePluginAvailable) return false;
    
    final key = '${sourceLanguage}_$targetLanguage';
    
    try {
      final targetLanguageCode = _getTranslateLanguage(targetLanguage);
      final modelManager = OnDeviceTranslatorModelManager();
      
      final isDownloaded = await modelManager.isModelDownloaded(
        targetLanguageCode.bcpCode,
      );
      
      _downloadedModels[key] = isDownloaded;
      
      if (isDownloaded) {
        debugPrint('📥 Modèle déjà téléchargé: $sourceLanguage -> $targetLanguage');
      } else {
        debugPrint('📤 Modèle non téléchargé: $sourceLanguage -> $targetLanguage');
      }
      
      return isDownloaded;
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la vérification du modèle $key: $e');
      
      if (e.toString().contains('MissingPluginException')) {
        _isNativePluginAvailable = false;
      }
      
      return false;
    }
  }

  /// Convertir le code de langue interne en TranslateLanguage compatible avec ML Kit
  TranslateLanguage _getTranslateLanguage(String language) {
    switch (language) {
      case 'en':
        return TranslateLanguage.english;
      case 'fr':
        return TranslateLanguage.french;
      case 'ar':
        return TranslateLanguage.arabic;
      default:
        debugPrint('⚠️ Langue non supportée: $language, utilisation de l\'anglais par défaut');
        return TranslateLanguage.english;
    }
  }

  /// Télécharger le modèle de traduction si nécessaire
  /// Retourne true si le modèle est disponible (déjà téléchargé ou téléchargement réussi)
  Future<bool> downloadModelIfNeeded(String sourceLanguage, String targetLanguage) async {
    // Si le plugin natif n'est pas disponible, on ne peut pas télécharger de modèles
    if (!_isNativePluginAvailable) return false;
    
    // Vérifier que les deux langues sont supportées
    if (!_supportedLanguages.contains(sourceLanguage) ||
        !_supportedLanguages.contains(targetLanguage)) {
      debugPrint('❌ Paire de langues non supportée: $sourceLanguage -> $targetLanguage');
      return false;
    }

    final key = '${sourceLanguage}_$targetLanguage';
    
    // Si le modèle est déjà téléchargé, retourner immédiatement
    if (_downloadedModels[key] == true) {
      return true;
    }
    
    // Si un téléchargement est déjà en cours pour ce modèle, attendre sa fin
    if (_downloadCompleters.containsKey(key)) {
      debugPrint('⏳ Téléchargement déjà en cours pour $key, attente...');
      return await _downloadCompleters[key]!.future;
    }
    
    // Créer un nouveau completer pour ce téléchargement
    _downloadCompleters[key] = Completer<bool>();
    
    try {
      debugPrint('📥 Téléchargement du modèle: $sourceLanguage -> $targetLanguage');

      final targetLanguageCode = _getTranslateLanguage(targetLanguage);
      final modelManager = OnDeviceTranslatorModelManager();

      // Télécharger le modèle avec options avancées
      await modelManager.downloadModel(
        targetLanguageCode.bcpCode,
        isWifiRequired: false,  // Permettre le téléchargement sur données mobiles
      );

      _downloadedModels[key] = true;
      debugPrint('✅ Modèle téléchargé avec succès: $sourceLanguage -> $targetLanguage');
      
      // Compléter le future avec succès
      _downloadCompleters[key]!.complete(true);
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors du téléchargement du modèle $key: $e');
      
      if (e.toString().contains('MissingPluginException')) {
        _isNativePluginAvailable = false;
      }
      
      // Compléter le future avec échec
      _downloadCompleters[key]!.complete(false);
      return false;
    } finally {
      // Nettoyer le completer après utilisation
      _downloadCompleters.remove(key);
    }
  }

  /// Traduire du texte entre les langues supportées
  Future<String> translateText(String text, String sourceLanguage, String targetLanguage) async {
    _totalTranslations++;
    
    // Cas triviaux: texte vide ou même langue source/cible
    if (text.isEmpty) return text;
    if (sourceLanguage == targetLanguage) return text;

    // Vérifier que les deux langues sont supportées
    if (!_supportedLanguages.contains(sourceLanguage) ||
        !_supportedLanguages.contains(targetLanguage)) {
      debugPrint('❌ Paire de langues non supportée: $sourceLanguage -> $targetLanguage');
      return text;
    }

    // Clé de cache unique pour cette traduction
    final cacheKey = '$text|$sourceLanguage|$targetLanguage';

    // Vérifier si la traduction est déjà dans le cache
    if (_translationCache.containsKey(cacheKey)) {
      // Mettre à jour l'ordre LRU en supprimant et réinsérant la clé
      final cachedValue = _translationCache.remove(cacheKey)!;
      _translationCache[cacheKey] = cachedValue;
      
      _cacheHits++;
      return cachedValue;
    }
    
    // Si le plugin natif n'est pas disponible, utiliser une traduction de secours
    if (!_isNativePluginAvailable) {
      return _fallbackTranslation(text, sourceLanguage, targetLanguage);
    }

    try {
      // S'assurer que le service est initialisé
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          debugPrint('❌ Service de traduction non initialisé');
          return text;
        }
      }
      
      // S'assurer que le modèle est téléchargé
      final modelAvailable = await downloadModelIfNeeded(sourceLanguage, targetLanguage);
      if (!modelAvailable) {
        debugPrint('❌ Modèle de traduction non disponible: $sourceLanguage -> $targetLanguage');
        return _fallbackTranslation(text, sourceLanguage, targetLanguage);
      }

      final key = '${sourceLanguage}_$targetLanguage';
      final translator = _translators[key];

      if (translator == null) {
        debugPrint('❌ Traducteur non trouvé: $sourceLanguage -> $targetLanguage');
        return _fallbackTranslation(text, sourceLanguage, targetLanguage);
      }

      // Effectuer la traduction avec mesure du temps
      final stopwatch = Stopwatch()..start();
      final translatedText = await translator.translateText(text);
      stopwatch.stop();
      
      debugPrint('✅ Traduction effectuée en ${stopwatch.elapsedMilliseconds}ms: $sourceLanguage -> $targetLanguage');

      // Gérer le cache LRU: supprimer l'élément le plus ancien si le cache est plein
      if (_translationCache.length >= _maxCacheSize) {
        _translationCache.remove(_translationCache.keys.first);
      }
      
      // Mettre en cache la traduction
      _translationCache[cacheKey] = translatedText;

      return translatedText;
    } catch (e) {
      _translationErrors++;
      debugPrint('❌ Erreur de traduction: $e');
      
      // En cas d'erreur avec le plugin natif, désactiver ML Kit et utiliser la traduction de secours
      if (e.toString().contains('MissingPluginException')) {
        _isNativePluginAvailable = false;
      }
      
      return _fallbackTranslation(text, sourceLanguage, targetLanguage);
    }
  }
  
  /// Méthode de traduction de secours quand ML Kit n'est pas disponible
  String _fallbackTranslation(String text, String sourceLanguage, String targetLanguage) {
    debugPrint('⚠️ Utilisation de la traduction de secours pour: $sourceLanguage -> $targetLanguage');
    
    // Dictionnaire de traductions simples pour les cas courants
    final Map<String, Map<String, String>> basicTranslations = {
      'fr': {
        'Question': 'Question',
        'True': 'Vrai',
        'False': 'Faux',
        'Next': 'Suivant',
        'Back': 'Retour',
        'Time left': 'Temps restant',
        'seconds': 'secondes',
        'easy': 'facile',
        'medium': 'moyen',
        'hard': 'difficile',
        'Entertainment: Music': 'Divertissement: Musique',
        'Entertainment: Film': 'Divertissement: Cinéma',
        'Entertainment: Television': 'Divertissement: Télévision',
        'Entertainment: Video Games': 'Divertissement: Jeux Vidéo',
        'Science & Nature': 'Science & Nature',
        'Sports': 'Sports',
        'Geography': 'Géographie',
        'History': 'Histoire',
        'Politics': 'Politique',
        'Art': 'Art',
      },
      'ar': {
        'Question': 'سؤال',
        'True': 'صحيح',
        'False': 'خطأ',
        'Next': 'التالي',
        'Back': 'رجوع',
        'Time left': 'الوقت المتبقي',
        'seconds': 'ثوان',
        'easy': 'سهل',
        'medium': 'متوسط',
        'hard': 'صعب',
        'Entertainment: Music': 'الترفيه: الموسيقى',
        'Entertainment: Film': 'الترفيه: الأفلام',
        'Entertainment: Television': 'الترفيه: التلفزيون',
        'Entertainment: Video Games': 'الترفيه: ألعاب الفيديو',
        'Science & Nature': 'العلوم والطبيعة',
        'Sports': 'الرياضة',
        'Geography': 'الجغرافيا',
        'History': 'التاريخ',
        'Politics': 'السياسة',
        'Art': 'الفن',
      }
    };
    
    // Si la langue cible est supportée dans notre dictionnaire de secours
    if (basicTranslations.containsKey(targetLanguage)) {
      final translations = basicTranslations[targetLanguage]!;
      
      // Rechercher des correspondances exactes
      if (translations.containsKey(text)) {
        return translations[text]!;
      }
      
      // Rechercher des correspondances partielles
      for (final entry in translations.entries) {
        if (text.contains(entry.key)) {
          return text.replaceAll(entry.key, entry.value);
        }
      }
    }
    
    // Si aucune traduction n'est trouvée, retourner le texte original
    return text;
  }
  
  /// Précharger les modèles de traduction pour une utilisation future
  Future<void> preloadTranslationModels() async {
    if (!_isNativePluginAvailable) {
      debugPrint('⚠️ Plugin ML Kit non disponible, préchargement des modèles annulé');
      return;
    }
    
    if (!_isInitialized) {
      await initialize();
    }
    
    debugPrint('🔄 Préchargement des modèles de traduction...');
    
    // Télécharger tous les modèles en parallèle
    final futures = <Future<bool>>[];
    
    for (final sourceLanguage in _supportedLanguages) {
      for (final targetLanguage in _supportedLanguages) {
        if (sourceLanguage != targetLanguage) {
          futures.add(downloadModelIfNeeded(sourceLanguage, targetLanguage));
        }
      }
    }
    
    // Attendre que tous les téléchargements soient terminés
    final results = await Future.wait(futures);
    final successCount = results.where((result) => result).length;
    
    debugPrint('✅ Préchargement terminé: $successCount/${futures.length} modèles chargés');
  }
  
  /// Vider le cache de traduction
  void clearCache() {
    final cacheSize = _translationCache.length;
    _translationCache.clear();
    debugPrint('🧹 Cache de traduction vidé ($cacheSize entrées)');
  }
  
  /// Obtenir les statistiques de performance du service de traduction
  Map<String, dynamic> getStatistics() {
    final cacheHitRate = _totalTranslations > 0 
        ? (_cacheHits / _totalTranslations * 100).toStringAsFixed(1) 
        : '0';
        
    final errorRate = _totalTranslations > 0 
        ? (_translationErrors / _totalTranslations * 100).toStringAsFixed(1) 
        : '0';
        
    return {
      'totalTranslations': _totalTranslations,
      'cacheHits': _cacheHits,
      'cacheSize': _translationCache.length,
      'cacheHitRate': '$cacheHitRate%',
      'translationErrors': _translationErrors,
      'errorRate': '$errorRate%',
      'supportedLanguages': _supportedLanguages,
      'downloadedModels': Map.from(_downloadedModels),
      'isNativePluginAvailable': _isNativePluginAvailable,
    };
  }

  /// Nettoyer les ressources
  void dispose() {
    debugPrint('🧹 Nettoyage des ressources du service de traduction');
    
    if (_isNativePluginAvailable) {
      for (final translator in _translators.values) {
        translator.close();
      }
    }
    
    _translators.clear();
    _translationCache.clear();
    _downloadCompleters.clear();
    _isInitialized = false;
    
    debugPrint('✅ Service de traduction fermé');
  }
}
