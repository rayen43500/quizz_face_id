import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../services/audio_service.dart';
import 'home_screen.dart';
import 'quiz_setup_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key}) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final AudioService _audioService = AudioService();
  bool _soundPlayed = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        final totalQuestions = quizProvider.questions.length;
        final correctAnswers = quizProvider.correctAnswers;
        final scorePercentage = (correctAnswers / totalQuestions) * 100;
        
        // Play sound based on score if not already played
        if (!_soundPlayed) {
          _playResultSound(scorePercentage);
          _soundPlayed = true;
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Quiz Results'),
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildResultHeader(scorePercentage),
                  const SizedBox(height: 30),
                  
                  // Score display
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _getScoreColor(scorePercentage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _getScoreColor(scorePercentage),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$correctAnswers / $totalQuestions',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(scorePercentage),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${scorePercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(scorePercentage),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Score message
                  Text(
                    _getScoreMessage(scorePercentage),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  
                  // Quiz details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Category',
                            quizProvider.selectedCategory.isEmpty
                                ? 'Any Category'
                                : quizProvider.selectedCategory,
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Difficulty',
                            quizProvider.selectedDifficulty.isEmpty
                                ? 'Any Difficulty'
                                : quizProvider.selectedDifficulty[0].toUpperCase() +
                                    quizProvider.selectedDifficulty.substring(1),
                          ),
                          const Divider(),
                          _buildDetailRow(
                            'Questions',
                            totalQuestions.toString(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.replay),
                          label: const Text('Play Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            quizProvider.resetQuiz();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuizSetupScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.home),
                          label: const Text('Home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            quizProvider.resetQuiz();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultHeader(double scorePercentage) {
    if (scorePercentage >= 75) {
      return Column(
        children: [
          const Icon(
            Icons.emoji_events,
            size: 100,
            color: Colors.amber,
          ),
          const SizedBox(height: 20),
          const Text(
            'Excellent!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      );
    } else if (scorePercentage >= 50) {
      return Column(
        children: [
          const Icon(
            Icons.thumb_up,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          const Text(
            'Good Job!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          const Icon(
            Icons.sentiment_dissatisfied,
            size: 100,
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          const Text(
            'Try Again!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double scorePercentage) {
    if (scorePercentage >= 75) {
      return Colors.green;
    } else if (scorePercentage >= 50) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  String _getScoreMessage(double scorePercentage) {
    if (scorePercentage >= 75) {
      return 'Congratulations! You did great!';
    } else if (scorePercentage >= 50) {
      return 'Good effort! Keep practicing!';
    } else {
      return 'Don\'t worry, try again to improve!';
    }
  }

  void _playResultSound(double scorePercentage) {
    if (scorePercentage >= 75) {
      _audioService.playSuccessSound();
    } else if (scorePercentage >= 50) {
      _audioService.playCorrectSound();
    } else {
      _audioService.playFailureSound();
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
} 