import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:html_unescape/html_unescape.dart';
import '../providers/quiz_provider.dart';
import '../providers/language_provider.dart';
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

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Question ${quizProvider.currentQuestionIndex + 1}/${quizProvider.questions.length}',
            ),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _showQuitDialog(context, quizProvider);
              },
            ),
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
                  'Time left: ${quizProvider.timeLeft} seconds',
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
                      label: Text(currentQuestion.category),
                      backgroundColor: Colors.blue.shade100,
                    ),
                    const SizedBox(width: 10),
                    Chip(
                      label: Text(
                        currentQuestion.difficulty[0].toUpperCase() +
                        currentQuestion.difficulty.substring(1),
                      ),
                      backgroundColor: _getDifficultyColor(currentQuestion.difficulty),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Question with animated color
                Container(
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
                  child: FutureBuilder<String>(
                    future: languageProvider.translateText(
                      _htmlUnescape.convert(currentQuestion.question),
                      'en', // Assuming questions are in English
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Translating question...');
                      }
                      
                      return Text(
                        snapshot.data ?? _htmlUnescape.convert(currentQuestion.question),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _colorAnimation.value,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                
                // Answers
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.allAnswers.length,
                    itemBuilder: (context, index) {
                      final answer = currentQuestion.allAnswers[index];
                      final isCorrect = answer == currentQuestion.correctAnswer;
                      final isSelected = answer == _selectedAnswer;
                      
                      return FutureBuilder<String>(
                        future: languageProvider.translateText(
                          _htmlUnescape.convert(answer),
                          'en', // Assuming answers are in English
                        ),
                        builder: (context, snapshot) {
                          final translatedAnswer = snapshot.data ?? _htmlUnescape.convert(answer);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: isSelected ? 4 : 2,
                            color: _getAnswerColor(isSelected, isCorrect),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                translatedAnswer,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: isSelected ? FontWeight.bold : null,
                                ),
                              ),
                              onTap: _isAnswered
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedAnswer = answer;
                                        _isAnswered = true;
                                      });
                                      quizProvider.answerQuestion(answer);
                                      
                                      // Reset for next question
                                      Future.delayed(const Duration(milliseconds: 1000), () {
                                        if (mounted) {
                                          setState(() {
                                            _selectedAnswer = null;
                                            _isAnswered = false;
                                          });
                                        }
                                      });
                                    },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getAnswerColor(bool isSelected, bool isCorrect) {
    if (!_isAnswered || !isSelected) {
      return Colors.white;
    }
    
    return isCorrect ? Colors.green : Colors.red;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
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
          title: const Text('Quit Quiz?'),
          content: const Text('Are you sure you want to quit? Your progress will be lost.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Quit'),
              onPressed: () {
                quizProvider.resetQuiz();
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