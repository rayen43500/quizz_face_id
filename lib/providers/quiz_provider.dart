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
  
  QuizQuestion? get currentQuestion {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return null;
    }
    return _questions[_currentQuestionIndex];
  }
  
  bool _quizCompleted = false;
  bool get quizCompleted => _quizCompleted;
  
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
  
  Future<void> startQuiz() async {
    try {
      _isLoading = true;
      _error = '';
      _questions = [];
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _quizCompleted = false;
      notifyListeners();
      
      int? categoryId;
      if (_selectedCategory.isNotEmpty) {
        final category = _categories.firstWhere(
          (cat) => cat.name == _selectedCategory,
          orElse: () => QuizCategory(id: 0, name: ''),
        );
        if (category.id > 0) {
          categoryId = category.id;
        }
      }
      
      _questions = await _quizService.fetchQuizQuestions(
        amount: _selectedAmount,
        categoryId: categoryId,
        difficulty: _selectedDifficulty,
      );
      
      _isLoading = false;
      startTimer();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load questions: $e';
      _isLoading = false;
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
  
  void answerQuestion(String selectedAnswer) {
    if (currentQuestion == null) return;
    
    final isCorrect = selectedAnswer == currentQuestion!.correctAnswer;
    
    if (isCorrect) {
      _correctAnswers++;
      _audioService.playCorrectSound();
    } else {
      _audioService.playIncorrectSound();
    }
    
    // Delay to show feedback before moving to next question
    Future.delayed(const Duration(milliseconds: 1000), () {
      nextQuestion();
    });
  }
  
  void nextQuestion() {
    _timer?.cancel();
    
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
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
    _error = '';
    notifyListeners();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 