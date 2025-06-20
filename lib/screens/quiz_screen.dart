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
  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorAnimation;
  
  // Pour stocker les traductions avec un cache plus efficace
  final HashMap<String, String> _translatedTexts = HashMap<String, String>();
  
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
  
  // Méthode améliorée pour traduire un texte avec ML Kit (asynchrone)
  Future<String> _translateTextAsync(String text, LanguageProvider languageProvider) async {
    if (text.isEmpty) {
      return text;
    }
    
    // Vérifier si le texte est déjà traduit dans notre cache
    if (_translatedTexts.containsKey(text)) {
      return _translatedTexts[text]!;
    }
    
    // Essayer de traduire avec le système de localisation
    String translated = context.tr(text);
    
    // Si pas de traduction dans le système de localisation, utiliser ML Kit via LanguageProvider
    if (translated == text) {
      try {
        // Afficher un indicateur de chargement pour les textes longs
        if (text.length > 50 && mounted) {
          setState(() {
            // Mise à jour de l'interface pour indiquer une traduction en cours
          });
        }
        
        translated = await languageProvider.translateTextAsync(text, 'en');
        
        // Si la traduction a échoué (retourne le texte original), essayer une approche alternative
        if (translated == text) {
          // Diviser le texte en phrases plus courtes pour une meilleure traduction
          final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
          if (sentences.length > 1) {
            final translatedSentences = <String>[];
            
            for (final sentence in sentences) {
              final translatedSentence = await languageProvider.translateTextAsync(sentence, 'en');
              translatedSentences.add(translatedSentence);
            }
            
            translated = translatedSentences.join(' ');
          }
        }
      } catch (e) {
        debugPrint('Erreur de traduction ML Kit: $e');
        // En cas d'erreur, utiliser la méthode synchrone comme fallback
        translated = languageProvider.translateText(text, 'en');
      }
    }
    
    // Mettre en cache la traduction
    if (translated != text) {
      _translatedTexts[text] = translated;
    }
    
    return translated;
  }
  
  // Méthode synchrone pour les cas où on ne peut pas attendre
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

        // Réinitialiser la sélection si on passe à une nouvelle question
        if (!quizProvider.hasAnswered && _selectedAnswer != null) {
          _selectedAnswer = null;
        }

        // Décoder la question immédiatement
        final decodedQuestion = _decodeHtml(currentQuestion.question);
        final cleanedQuestion = _prepareForTranslation(decodedQuestion);
        final bool questionIsEmpty = cleanedQuestion.trim().isEmpty;
        
        // Pré-traduire la question et les réponses avec ML Kit
        if (!_translatedTexts.containsKey(cleanedQuestion) && !questionIsEmpty) {
          // Lancer la traduction en arrière-plan
          _translateTextAsync(cleanedQuestion, languageProvider).then((_) {
            // Forcer une mise à jour de l'UI une fois la traduction terminée
            if (mounted) setState(() {});
          });
        }
        
        // Pré-traduire les réponses
        for (final answer in currentQuestion.allAnswers) {
          final decodedAnswer = _decodeHtml(answer);
          final cleanedAnswer = _prepareForTranslation(decodedAnswer);
          if (!_translatedTexts.containsKey(cleanedAnswer)) {
            // Lancer la traduction en arrière-plan
            _translateTextAsync(cleanedAnswer, languageProvider).then((_) {
              // Forcer une mise à jour de l'UI une fois la traduction terminée
              if (mounted) setState(() {});
            });
          }
        }

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
                      onPressed: quizProvider.hasAnswered
                          ? () {
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
    Color borderColor = isSelected ? Colors.blue : Colors.grey.shade300;
    double borderWidth = 2.0;
    
    if (quizProvider.hasAnswered) {
      if (isSelected) {
        buttonColor = isCorrect ? Colors.green.shade500 : Colors.red.shade500;
        textColor = Colors.white;
        borderColor = isCorrect ? Colors.green.shade700 : Colors.red.shade700;
        borderWidth = 3.0;
      } else if (isCorrect) {
        buttonColor = Colors.green.shade100;
        borderColor = Colors.green.shade500;
        borderWidth = 2.5;
      }
    } else if (isSelected) {
      buttonColor = Colors.blue.shade100;
      borderColor = Colors.blue.shade500;
    }
    
    // Icône à afficher pour indiquer si la réponse est correcte ou incorrecte
    Widget? leadingIcon;
    if (quizProvider.hasAnswered) {
      if (isSelected) {
        leadingIcon = Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
        );
      } else if (isCorrect) {
        leadingIcon = Icon(
          Icons.check_circle_outline,
          color: Colors.green.shade700,
        );
      }
    }
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        elevation: isSelected ? 4 : 2,
      ),
      onPressed: quizProvider.hasAnswered
          ? null
          : () {
              setState(() {
                _selectedAnswer = originalAnswer;
              });
              
              quizProvider.answerQuestion(isCorrect);
            },
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            leadingIcon,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: (isCorrect && quizProvider.hasAnswered) || isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
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