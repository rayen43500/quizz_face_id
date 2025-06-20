import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
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
        title: const Text('Quiz Setup'),
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
                    'Error: ${quizProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      quizProvider.loadCategories();
                    },
                    child: const Text('Retry'),
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
                const Text(
                  'Select Quiz Options',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Category selection
                const Text(
                  'Category:',
                  style: TextStyle(
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
                      hint: const Text('  Select a category'),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Any Category'),
                        ),
                        ...quizProvider.categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.name,
                            child: Text(category.name),
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
                const Text(
                  'Difficulty:',
                  style: TextStyle(
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
                      hint: const Text('  Select difficulty'),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Any Difficulty'),
                        ),
                        ..._difficulties.map((difficulty) {
                          return DropdownMenuItem<String>(
                            value: difficulty,
                            child: Text(
                              difficulty[0].toUpperCase() + difficulty.substring(1),
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
                const Text(
                  'Number of Questions:',
                  style: TextStyle(
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
                          child: Text('$amount Questions'),
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
                    child: const Text(
                      'Start Quiz',
                      style: TextStyle(fontSize: 18),
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