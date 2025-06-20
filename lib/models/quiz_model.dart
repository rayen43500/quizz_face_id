class QuizQuestion {
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;
  final String category;
  final String difficulty;
  final String type;
  final List<String> _allAnswers;

  QuizQuestion({
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
    required this.category,
    required this.difficulty,
    required this.type,
  }) : _allAnswers = _prepareAllAnswers(correctAnswer, incorrectAnswers);

  static List<String> _prepareAllAnswers(String correctAnswer, List<String> incorrectAnswers) {
    final allAnswers = List<String>.from(incorrectAnswers);
    allAnswers.add(correctAnswer);
    allAnswers.shuffle();
    return allAnswers;
  }

  List<String> get allAnswers => List<String>.from(_allAnswers);

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'],
      correctAnswer: json['correct_answer'],
      incorrectAnswers: List<String>.from(json['incorrect_answers']),
      category: json['category'],
      difficulty: json['difficulty'],
      type: json['type'],
    );
  }
}

class QuizCategory {
  final int id;
  final String name;

  QuizCategory({
    required this.id,
    required this.name,
  });

  factory QuizCategory.fromJson(Map<String, dynamic> json) {
    return QuizCategory(
      id: json['id'],
      name: json['name'],
    );
  }
}

class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final String category;
  final String difficulty;
  final DateTime date;

  QuizResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.category,
    required this.difficulty,
    required this.date,
  });

  double get scorePercentage => (correctAnswers / totalQuestions) * 100;

  Map<String, dynamic> toJson() {
    return {
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'category': category,
      'difficulty': difficulty,
      'date': date.toIso8601String(),
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      totalQuestions: json['totalQuestions'],
      correctAnswers: json['correctAnswers'],
      category: json['category'],
      difficulty: json['difficulty'],
      date: DateTime.parse(json['date']),
    );
  }
} 