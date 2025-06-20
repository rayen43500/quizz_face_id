import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../services/app_localizations.dart';
import 'quiz_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({Key? key}) : super(key: key);

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  String _selectedCategory = '';
  String _selectedDifficulty = '';
  int _selectedAmount = 10;

  final List<int> _questionAmounts = [5, 10, 15, 20];
  final List<String> _difficulties = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    // Load categories when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('quiz_setup')),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (quizProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${context.tr('error')}: ${quizProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      quizProvider.loadCategories();
                    },
                    child: Text(context.tr('retry')),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('quiz_setup'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Category selection
                Text(
                  '${context.tr('select_category')}:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCategory.isEmpty ? null : _selectedCategory,
                      hint: Text('  ${context.tr('select_category')}'),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(context.tr('any_category')),
                        ),
                        ...quizProvider.categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.name,
                            child: Text(context.tr(category.name)),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedCategory = value ?? '';
                        });
                        quizProvider.setCategory(_selectedCategory);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Difficulty selection
                Text(
                  '${context.tr('select_difficulty')}:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedDifficulty.isEmpty ? null : _selectedDifficulty,
                      hint: Text('  ${context.tr('select_difficulty')}'),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(context.tr('any_difficulty')),
                        ),
                        ..._difficulties.map((difficulty) {
                          return DropdownMenuItem<String>(
                            value: difficulty,
                            child: Text(
                              context.tr(difficulty),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedDifficulty = value ?? '';
                        });
                        quizProvider.setDifficulty(_selectedDifficulty);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Number of questions selection
                Text(
                  '${context.tr('number_of_questions')}:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedAmount,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      items: _questionAmounts.map((amount) {
                        return DropdownMenuItem<int>(
                          value: amount,
                          child: Text('$amount ${context.tr('question')}'),
                        );
                      }).toList(),
                      onChanged: (int? value) {
                        setState(() {
                          _selectedAmount = value ?? 10;
                        });
                        quizProvider.setAmount(_selectedAmount);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Start quiz button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await quizProvider.startQuiz();
                      
                      if (!mounted) return;
                      
                      if (quizProvider.error.isEmpty) {
                        Navigator.pushNamed(context, '/quiz');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(quizProvider.error),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(
                      context.tr('start_quiz'),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 