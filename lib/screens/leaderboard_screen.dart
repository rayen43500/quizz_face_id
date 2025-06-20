import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedCategory = 'All Categories';
  String _selectedDifficulty = 'All Difficulties';
  
  final List<String> _difficulties = [
    'All Difficulties',
    'Easy',
    'Medium',
    'Hard',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        value: _selectedCategory,
                        items: _buildCategoryDropdownItems(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        value: _selectedDifficulty,
                        items: _difficulties.map((difficulty) {
                          return DropdownMenuItem<String>(
                            value: difficulty,
                            child: Text(difficulty),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDifficulty = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results list
          Expanded(
            child: Consumer<QuizProvider>(
              builder: (context, quizProvider, child) {
                return FutureBuilder<List<QuizResult>>(
                  future: quizProvider.getQuizResults(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading results: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    
                    final results = snapshot.data ?? [];
                    
                    if (results.isEmpty) {
                      return const Center(
                        child: Text(
                          'No quiz results yet.\nComplete a quiz to see your scores!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }
                    
                    // Filter results
                    final filteredResults = _filterResults(results);
                    
                    // Sort by score percentage (descending)
                    filteredResults.sort((a, b) => b.scorePercentage.compareTo(a.scorePercentage));
                    
                    if (filteredResults.isEmpty) {
                      return Center(
                        child: Text(
                          'No results for $_selectedCategory with $_selectedDifficulty difficulty.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredResults.length,
                      itemBuilder: (context, index) {
                        final result = filteredResults[index];
                        final rank = index + 1;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getRankColor(rank),
                              child: Text(
                                rank.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '${result.correctAnswers}/${result.totalQuestions} (${result.scorePercentage.toStringAsFixed(1)}%)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Category: ${result.category}'),
                                Text('Difficulty: ${result.difficulty}'),
                                Text('Date: ${DateFormat('MMM dd, yyyy - HH:mm').format(result.date)}'),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Icon(
                              _getScoreIcon(result.scorePercentage),
                              color: _getScoreColor(result.scorePercentage),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          return FloatingActionButton(
            onPressed: () async {
              final confirmed = await _showClearConfirmationDialog(context);
              if (confirmed == true) {
                await quizProvider.clearQuizResults();
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Leaderboard cleared')),
                );
              }
            },
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete),
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildCategoryDropdownItems() {
    return [
      const DropdownMenuItem<String>(
        value: 'All Categories',
        child: Text('All Categories'),
      ),
      ...Provider.of<QuizProvider>(context, listen: false)
          .categories
          .map((category) {
        return DropdownMenuItem<String>(
          value: category.name,
          child: Text(category.name),
        );
      }).toList(),
    ];
  }

  List<QuizResult> _filterResults(List<QuizResult> results) {
    return results.where((result) {
      // Filter by category
      final categoryMatch = _selectedCategory == 'All Categories' ||
          result.category == _selectedCategory;
      
      // Filter by difficulty
      final difficultyMatch = _selectedDifficulty == 'All Difficulties' ||
          result.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase();
      
      return categoryMatch && difficultyMatch;
    }).toList();
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.blueGrey.shade300; // Silver
      case 3:
        return Colors.brown.shade300; // Bronze
      default:
        return Colors.blue;
    }
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

  IconData _getScoreIcon(double scorePercentage) {
    if (scorePercentage >= 75) {
      return Icons.emoji_events;
    } else if (scorePercentage >= 50) {
      return Icons.thumb_up;
    } else {
      return Icons.thumb_down;
    }
  }

  Future<bool?> _showClearConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Leaderboard'),
          content: const Text(
            'Are you sure you want to clear all quiz results? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
} 