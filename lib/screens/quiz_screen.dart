import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:html_unescape/html_unescape.dart';
import '../providers/quiz_provider.dart';
import '../providers/language_provider.dart';
import '../services/app_localizations.dart';
import '../models/quiz_model.dart';
import 'result_screen.dart';
import 'dart:math' as math;

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
  
  // Pour stocker les traductions
  Map<String, String> _translatedTexts = {};
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
  
  // Méthode pour traduire un texte avec cache
  Future<String> _getTranslatedText(String text, LanguageProvider languageProvider) async {
    // Si déjà traduit, retourner depuis le cache
    if (_translatedTexts.containsKey(text)) {
      return _translatedTexts[text]!;
    }
    
    // Sinon, traduire et mettre en cache
    final translated = await languageProvider.translateText(text, 'en');
    _translatedTexts[text] = translated;
    return translated;
  }
  
  // Traduire tous les textes nécessaires pour la question actuelle
  Future<void> _translateCurrentQuestion(QuizQuestion question, LanguageProvider languageProvider) async {
    if (languageProvider.currentLanguage == 'en') return;
    
    setState(() {
      _isTranslating = true;
    });
    
    // Traduire la question, la catégorie et toutes les réponses
    await _getTranslatedText(question.question, languageProvider);
    await _getTranslatedText(question.category, languageProvider);
    await _getTranslatedText(question.difficulty, languageProvider);
    
    for (final answer in question.allAnswers) {
      await _getTranslatedText(answer, languageProvider);
    }
    
    setState(() {
      _isTranslating = false;
    });
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

        // Déclencher la traduction quand une nouvelle question est chargée
        if (languageProvider.currentLanguage != 'en' && !_isTranslating && _translatedTexts.isEmpty) {
          _translateCurrentQuestion(currentQuestion, languageProvider);
        }

        // Décoder la question immédiatement
        final decodedQuestion = _decodeHtml(currentQuestion.question);
        final bool questionIsEmpty = decodedQuestion.trim().isEmpty;

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
                    FutureBuilder<String>(
                      future: _getTranslatedText(currentQuestion.category, languageProvider),
                      builder: (context, snapshot) {
                        return Chip(
                          label: Text(snapshot.data ?? currentQuestion.category),
                          backgroundColor: Colors.blue.shade100,
                        );
                      }
                    ),
                    const SizedBox(width: 10),
                    FutureBuilder<String>(
                      future: _getTranslatedText(currentQuestion.difficulty, languageProvider),
                      builder: (context, snapshot) {
                        final difficulty = snapshot.data ?? currentQuestion.difficulty;
                        return Chip(
                          label: Text(context.tr(currentQuestion.difficulty)),
                          backgroundColor: _getDifficultyColor(currentQuestion.difficulty),
                        );
                      }
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
                      : _isTranslating
                          ? Center(
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 10),
                                  Text(context.tr('translating_question')),
                                ],
                              ),
                            )
                          : FutureBuilder<String>(
                              future: _getTranslatedText(decodedQuestion, languageProvider),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                return Text(
                                  snapshot.data ?? decodedQuestion,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
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
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FutureBuilder<String>(
                          future: _getTranslatedText(decodedAnswer, languageProvider),
                          builder: (context, snapshot) {
                            return _buildAnswerButton(
                              snapshot.data ?? decodedAnswer,
                              quizProvider,
                              currentQuestion,
                            );
                          },
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

  Widget _buildAnswerButton(String answer, QuizProvider quizProvider, QuizQuestion question) {
    final bool isCorrect = answer == _decodeHtml(question.correctAnswer);
    final bool isSelected = answer == _selectedAnswer;
    
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
                _selectedAnswer = answer;
                _isAnswered = true;
              });
              
              quizProvider.answerQuestion(answer == _decodeHtml(question.correctAnswer));
            },
      child: Text(
        answer,
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