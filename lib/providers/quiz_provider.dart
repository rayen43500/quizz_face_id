import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/quiz_service.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';

class QuizProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  final StorageService _storageService = StorageService();
  final AudioService _audioService = AudioService();
  
  List<QuizCategory> _categories = [];
  List<QuizCategory> get categories => _categories;
  
  List<QuizQuestion> _questions = [];
  List<QuizQuestion> get questions => _questions;
  
  int _currentQuestionIndex = 0;
  int get currentQuestionIndex => _currentQuestionIndex;
  
  int _correctAnswers = 0;
  int get correctAnswers => _correctAnswers;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _error = '';
  String get error => _error;
  
  Timer? _timer;
  int _timeLeft = 15; // Default time per question in seconds
  int get timeLeft => _timeLeft;
  
  String _selectedCategory = '';
  String get selectedCategory => _selectedCategory;
  
  String _selectedDifficulty = '';
  String get selectedDifficulty => _selectedDifficulty;
  
  int _selectedAmount = 10;
  int get selectedAmount => _selectedAmount;
  
  // Pour suivre si l'utilisateur a répondu à la question actuelle
  bool _hasAnswered = false;
  bool get hasAnswered => _hasAnswered;
  
  QuizQuestion? get currentQuestion {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return null;
    }
    return _questions[_currentQuestionIndex];
  }
  
  bool _quizCompleted = false;
  bool get quizCompleted => _quizCompleted;
  
  // Pour suivre la langue actuelle du quiz
  String _quizLanguage = 'en';
  
  QuizProvider() {
    loadCategories();
  }
  
  Future<void> loadCategories() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _categories = await _quizService.fetchCategories();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load categories: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
  
  void setDifficulty(String difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
  }
  
  void setAmount(int amount) {
    _selectedAmount = amount;
    notifyListeners();
  }
  
  // Méthode pour vérifier si la langue a changé et réinitialiser le quiz si nécessaire
  void checkLanguageChange(String currentLanguage) {
    if (_quizLanguage != currentLanguage && _questions.isNotEmpty) {
      // La langue a changé pendant un quiz en cours
      _quizLanguage = currentLanguage;
      // Réinitialiser la question actuelle pour forcer une nouvelle traduction
      if (_currentQuestionIndex > 0) {
        int savedIndex = _currentQuestionIndex;
        _currentQuestionIndex = 0;
        Future.delayed(const Duration(milliseconds: 100), () {
          _currentQuestionIndex = savedIndex;
          notifyListeners();
        });
      } else {
        notifyListeners();
      }
    } else {
      _quizLanguage = currentLanguage;
    }
  }
  
  Future<void> startQuiz() async {
    _isLoading = true;
    notifyListeners();

    try {
      final questions = await _quizService.fetchQuizQuestions(
        amount: _selectedAmount,
        categoryId: _selectedCategory.isEmpty ? null : _categories.firstWhere(
          (cat) => cat.name == _selectedCategory,
          orElse: () => QuizCategory(id: 0, name: ''),
        ).id,
        difficulty: _selectedDifficulty == 'Any Difficulty' ? '' : _selectedDifficulty.toLowerCase(),
      );
      
      // Prétraiter les questions pour faciliter la traduction
      _questions = _preprocessQuestions(questions);
      
      if (_questions.isNotEmpty) {
        _currentQuestionIndex = 0;
        _correctAnswers = 0;
        _quizCompleted = false;
        _hasAnswered = false;
        startTimer();
      }
    } catch (e) {
      print('Error starting quiz: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Prétraiter les questions pour faciliter la traduction
  List<QuizQuestion> _preprocessQuestions(List<QuizQuestion> questions) {
    return questions.map((question) {
      // Supprimer les caractères spéciaux HTML qui pourraient rester
      String cleanQuestion = _cleanHtmlText(question.question);
      String cleanCorrectAnswer = _cleanHtmlText(question.correctAnswer);
      List<String> cleanIncorrectAnswers = question.incorrectAnswers.map(_cleanHtmlText).toList();
      
      // Normaliser la catégorie et la difficulté pour la traduction
      String normalizedCategory = _normalizeText(question.category);
      String normalizedDifficulty = _normalizeText(question.difficulty);
      
      return QuizQuestion(
        question: cleanQuestion,
        correctAnswer: cleanCorrectAnswer,
        incorrectAnswers: cleanIncorrectAnswers,
        category: normalizedCategory,
        difficulty: normalizedDifficulty,
        type: question.type,
      );
    }).toList();
  }
  
  // Nettoyer le texte HTML pour la traduction
  String _cleanHtmlText(String text) {
    if (text.isEmpty) return text;
    
    // Remplacer les entités HTML courantes
    String cleaned = text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&eacute;', 'é')
      .replaceAll('&egrave;', 'è')
      .replaceAll('&agrave;', 'à')
      .replaceAll('&ccedil;', 'ç')
      .replaceAll('&ouml;', 'ö')
      .replaceAll('&uuml;', 'ü')
      .replaceAll('&auml;', 'ä')
      .replaceAll('&ntilde;', 'ñ')
      .replaceAll('&nbsp;', ' ');
    
    // Supprimer les balises HTML
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Normaliser les espaces multiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }
  
  // Normaliser le texte pour améliorer la traduction
  String _normalizeText(String text) {
    if (text.isEmpty) return text;
    
    // Convertir la première lettre en majuscule et le reste en minuscule
    String normalized = text.trim();
    if (normalized.isNotEmpty) {
      normalized = normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
    }
    
    return normalized;
  }
  
  // Réinitialiser et redémarrer le quiz
  Future<void> resetAndStartQuiz() async {
    _timer?.cancel();
    resetQuiz();
    await startQuiz();
  }
  
  // Aller à la question précédente
  void goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      _timer?.cancel();
      _currentQuestionIndex--;
      _hasAnswered = false;
      startTimer();
      notifyListeners();
    }
  }
  
  // Aller à la question suivante
  void goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _timer?.cancel();
      _currentQuestionIndex++;
      _hasAnswered = false;
      startTimer();
      notifyListeners();
    }
  }
  
  void startTimer() {
    _timeLeft = 15; // Reset timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        // Time's up, move to next question
        _audioService.playIncorrectSound();
        nextQuestion();
      }
    });
  }
  
  void answerQuestion(bool isCorrect) {
    if (currentQuestion == null) return;
    
    _hasAnswered = true;
    notifyListeners();
    
    if (isCorrect) {
      _correctAnswers++;
      _audioService.playCorrectSound();
    } else {
      _audioService.playIncorrectSound();
    }
    
    // Délai pour montrer le feedback puis passer à la question suivante
    Future.delayed(const Duration(milliseconds: 800), () {
      nextQuestion();
    });
  }
  
  void nextQuestion() {
    _timer?.cancel();
    
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      _hasAnswered = false;
      startTimer();
      notifyListeners();
    } else {
      completeQuiz();
    }
  }
  
  Future<void> completeQuiz() async {
    _timer?.cancel();
    _quizCompleted = true;
    
    // Play sound based on score
    final scorePercentage = (_correctAnswers / _questions.length) * 100;
    if (scorePercentage >= 75) {
      _audioService.playSuccessSound();
    } else {
      _audioService.playFailureSound();
    }
    
    // Save quiz result
    if (_questions.isNotEmpty) {
      final result = QuizResult(
        totalQuestions: _questions.length,
        correctAnswers: _correctAnswers,
        category: _selectedCategory.isEmpty ? 'Any Category' : _selectedCategory,
        difficulty: _selectedDifficulty.isEmpty ? 'Any Difficulty' : _selectedDifficulty,
        date: DateTime.now(),
      );
      
      await _storageService.saveQuizResult(result);
    }
    
    notifyListeners();
  }
  
  Future<List<QuizResult>> getQuizResults() async {
    return await _storageService.getQuizResults();
  }
  
  Future<void> clearQuizResults() async {
    await _storageService.clearQuizResults();
    notifyListeners();
  }
  
  void resetQuiz() {
    _timer?.cancel();
    _questions = [];
    _currentQuestionIndex = 0;
    _correctAnswers = 0;
    _quizCompleted = false;
    _hasAnswered = false;
    _error = '';
    notifyListeners();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 