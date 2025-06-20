import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:html_unescape/html_unescape.dart';
import '../providers/quiz_provider.dart';
import '../providers/language_provider.dart';
import '../services/app_localizations.dart';
import '../models/quiz_model.dart';
import 'result_screen.dart';
import 'dart:math' as math;
import 'dart:collection';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  final HtmlUnescape _htmlUnescape = HtmlUnescape();
  String? _selectedAnswer;
  bool _isAnswered = false;
  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorAnimation;
  
  // Pour stocker les traductions avec un cache plus efficace
  final HashMap<String, String> _translatedTexts = HashMap<String, String>();
  bool _isTranslating = false;
  
  @override
  void initState() {
    super.initState();
    _colorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.purple,
    ).animate(_colorAnimationController);
    
    _colorAnimationController.addListener(() {
      setState(() {});
    });
  }
  
  @override
  void dispose() {
    _colorAnimationController.dispose();
    super.dispose();
  }

  // Méthode simplifiée pour décoder le texte HTML
  String _decodeHtml(String text) {
    return _htmlUnescape.convert(text);
  }
  
  // Méthode améliorée pour traduire un texte
  String _translateText(String text, LanguageProvider languageProvider) {
    if (text.isEmpty) {
      return text;
    }
    
    // Vérifier si le texte est déjà traduit dans notre cache
    if (_translatedTexts.containsKey(text)) {
      return _translatedTexts[text]!;
    }
    
    // Essayer de traduire avec le système de localisation
    String translated = context.tr(text);
    
    // Si pas de traduction dans le système de localisation, utiliser le LanguageProvider
    if (translated == text) {
      translated = languageProvider.translateText(text, 'en');
    }
    
    // Mettre en cache la traduction
    _translatedTexts[text] = translated;
    
    return translated;
  }
  
  // Méthode pour nettoyer et préparer le texte avant traduction
  String _prepareForTranslation(String text) {
    // Enlever les caractères spéciaux HTML qui pourraient rester
    String cleaned = text.replaceAll('&amp;', '&')
                          .replaceAll('&lt;', '<')
                          .replaceAll('&gt;', '>')
                          .replaceAll('&quot;', '"')
                          .replaceAll('&#039;', "'");
    
    return cleaned.trim();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<QuizProvider, LanguageProvider>(
      builder: (context, quizProvider, languageProvider, child) {
        if (quizProvider.quizCompleted) {
          // Navigate to results screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ResultScreen()),
            );
          });
          return const SizedBox();
        }

        final currentQuestion = quizProvider.currentQuestion;
        
        if (currentQuestion == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Décoder la question immédiatement
        final decodedQuestion = _decodeHtml(currentQuestion.question);
        final cleanedQuestion = _prepareForTranslation(decodedQuestion);
        final bool questionIsEmpty = cleanedQuestion.trim().isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text('${context.tr('question')} ${quizProvider.currentQuestionIndex + 1}/${quizProvider.questions.length}'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _showQuitDialog(context, quizProvider);
              },
            ),
            actions: [
              // Bouton pour recharger la question si elle n'est pas visible
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: context.tr('reload'),
                onPressed: () {
                  // Vider le cache de traduction lors du rechargement
                  _translatedTexts.clear();
                  
                  if (quizProvider.currentQuestionIndex > 0) {
                    quizProvider.goToPreviousQuestion();
                    Future.delayed(const Duration(milliseconds: 100), () {
                      quizProvider.goToNextQuestion();
                    });
                  } else {
                    // Si c'est la première question, redémarrer le quiz
                    quizProvider.resetAndStartQuiz();
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timer indicator
                LinearProgressIndicator(
                  value: quizProvider.timeLeft / 15, // 15 seconds total
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    quizProvider.timeLeft > 5 ? Colors.blue : Colors.red,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${context.tr('time_left')}: ${quizProvider.timeLeft} ${context.tr('seconds')}',
                  style: TextStyle(
                    color: quizProvider.timeLeft > 5 ? Colors.blue : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Category and difficulty
                Row(
                  children: [
                    Chip(
                      label: Text(_translateText(currentQuestion.category, languageProvider)),
                      backgroundColor: Colors.blue.shade100,
                    ),
                    const SizedBox(width: 10),
                    Chip(
                      label: Text(_translateText(currentQuestion.difficulty, languageProvider)),
                      backgroundColor: _getDifficultyColor(currentQuestion.difficulty),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Question with animated color
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _colorAnimation.value ?? Colors.blue,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_colorAnimation.value ?? Colors.blue).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                    color: (_colorAnimation.value ?? Colors.blue).withOpacity(0.1),
                  ),
                  child: questionIsEmpty 
                      ? Center(
                          child: Column(
                            children: [
                              Text(
                                context.tr('problem_displaying_question'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  // Vider le cache de traduction lors du rechargement
                                  _translatedTexts.clear();
                                  quizProvider.resetAndStartQuiz();
                                },
                                child: Text(context.tr('reload')),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          _translateText(cleanedQuestion, languageProvider),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(height: 30),
                
                // Answer options
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.allAnswers.length,
                    itemBuilder: (context, index) {
                      final answer = currentQuestion.allAnswers[index];
                      final decodedAnswer = _decodeHtml(answer);
                      final cleanedAnswer = _prepareForTranslation(decodedAnswer);
                      final translatedAnswer = _translateText(cleanedAnswer, languageProvider);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildAnswerButton(
                          translatedAnswer,
                          quizProvider,
                          currentQuestion,
                          decodedAnswer,
                        ),
                      );
                    },
                  ),
                ),
                
                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: quizProvider.currentQuestionIndex > 0
                          ? () => quizProvider.goToPreviousQuestion()
                          : null,
                      child: Text(context.tr('back')),
                    ),
                    ElevatedButton(
                      onPressed: _isAnswered
                          ? () {
                              _selectedAnswer = null;
                              _isAnswered = false;
                              quizProvider.goToNextQuestion();
                            }
                          : null,
                      child: Text(context.tr('next')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerButton(
    String displayText,
    QuizProvider quizProvider,
    QuizQuestion question,
    String originalAnswer,
  ) {
    final bool isCorrect = originalAnswer == _decodeHtml(question.correctAnswer);
    final bool isSelected = originalAnswer == _selectedAnswer;
    
    // Déterminer la couleur du bouton
    Color buttonColor = Colors.white;
    Color textColor = Colors.black;
    
    if (_isAnswered) {
      if (isSelected) {
        buttonColor = isCorrect ? Colors.green : Colors.red;
        textColor = Colors.white;
      } else if (isCorrect) {
        buttonColor = Colors.green.withOpacity(0.3);
      }
    } else if (isSelected) {
      buttonColor = Colors.blue.shade100;
    }
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
        ),
      ),
      onPressed: _isAnswered
          ? null
          : () {
              setState(() {
                _selectedAnswer = originalAnswer;
                _isAnswered = true;
              });
              
              quizProvider.answerQuestion(isCorrect);
            },
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isCorrect && _isAnswered ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'hard':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Future<void> _showQuitDialog(BuildContext context, QuizProvider quizProvider) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.tr('quit_quiz')),
          content: Text(context.tr('quit_confirmation')),
          actions: <Widget>[
            TextButton(
              child: Text(context.tr('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(context.tr('quit')),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
} 