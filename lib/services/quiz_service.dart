import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_model.dart';
import 'dart:async';
import 'package:html_unescape/html_unescape.dart';

class QuizService {
  static const String baseUrl = 'https://opentdb.com/api.php';
  static const String categoriesUrl = 'https://opentdb.com/api_category.php';
  final HtmlUnescape _htmlUnescape = HtmlUnescape();

  Future<List<QuizQuestion>> fetchQuizQuestions({
    required int amount,
    int? categoryId,
    String difficulty = '',
    String type = '',
  }) async {
    try {
      String url = '$baseUrl?amount=$amount&encode=base64';
      
      if (categoryId != null) {
        url += '&category=$categoryId';
      }
      
      if (difficulty.isNotEmpty) {
        url += '&difficulty=${difficulty.toLowerCase()}';
      }
      
      if (type.isNotEmpty) {
        url += '&type=$type';
      }
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['response_code'] == 0) {
          final List<dynamic> results = data['results'];
          
          return results.map((json) {
            Map<String, dynamic> decodedJson = {
              'question': _decodeBase64(json['question']),
              'correct_answer': _decodeBase64(json['correct_answer']),
              'category': _decodeBase64(json['category']),
              'difficulty': _decodeBase64(json['difficulty']),
              'type': _decodeBase64(json['type']),
              'incorrect_answers': (json['incorrect_answers'] as List)
                  .map((answer) => _decodeBase64(answer))
                  .toList(),
            };
            
            return QuizQuestion.fromJson(decodedJson);
          }).toList();
        } else {
          print('API error: ${_getErrorMessage(data['response_code'])}');
          return _getLocalQuestions(amount, difficulty);
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return _getLocalQuestions(amount, difficulty);
      }
    } catch (e) {
      print('Exception in fetchQuizQuestions: $e');
      return _getLocalQuestions(amount, difficulty);
    }
  }

  String _decodeBase64(String base64String) {
    try {
      final decoded = utf8.decode(base64Decode(base64String));
      return _htmlUnescape.convert(decoded);
    } catch (e) {
      print('Error decoding base64: $e');
      return base64String;
    }
  }

  List<QuizQuestion> _getLocalQuestions(int amount, String difficulty) {
    // Questions locales en cas d'échec de l'API
    final List<QuizQuestion> localQuestions = [
      QuizQuestion(
        question: "Quelle est la capitale de la France?",
        correctAnswer: "Paris",
        incorrectAnswers: ["Londres", "Berlin", "Madrid"],
        category: "Géographie",
        difficulty: difficulty.isEmpty ? "medium" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Qui a peint la Joconde?",
        correctAnswer: "Léonard de Vinci",
        incorrectAnswers: ["Pablo Picasso", "Vincent van Gogh", "Michel-Ange"],
        category: "Art",
        difficulty: difficulty.isEmpty ? "medium" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Quelle est la planète la plus proche du soleil?",
        correctAnswer: "Mercure",
        incorrectAnswers: ["Vénus", "Terre", "Mars"],
        category: "Science",
        difficulty: difficulty.isEmpty ? "easy" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Quel est le plus grand océan du monde?",
        correctAnswer: "Océan Pacifique",
        incorrectAnswers: ["Océan Atlantique", "Océan Indien", "Océan Arctique"],
        category: "Géographie",
        difficulty: difficulty.isEmpty ? "medium" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Qui a écrit 'Les Misérables'?",
        correctAnswer: "Victor Hugo",
        incorrectAnswers: ["Alexandre Dumas", "Émile Zola", "Gustave Flaubert"],
        category: "Littérature",
        difficulty: difficulty.isEmpty ? "medium" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "En quelle année a commencé la Première Guerre mondiale?",
        correctAnswer: "1914",
        incorrectAnswers: ["1918", "1939", "1945"],
        category: "Histoire",
        difficulty: difficulty.isEmpty ? "medium" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Quel est le plus grand pays du monde par superficie?",
        correctAnswer: "Russie",
        incorrectAnswers: ["Canada", "Chine", "États-Unis"],
        category: "Géographie",
        difficulty: difficulty.isEmpty ? "easy" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Quelle est la formule chimique de l'eau?",
        correctAnswer: "H2O",
        incorrectAnswers: ["CO2", "O2", "NaCl"],
        category: "Science",
        difficulty: difficulty.isEmpty ? "easy" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Qui a découvert la pénicilline?",
        correctAnswer: "Alexander Fleming",
        incorrectAnswers: ["Louis Pasteur", "Marie Curie", "Albert Einstein"],
        category: "Science",
        difficulty: difficulty.isEmpty ? "medium" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Quel est le plus long fleuve du monde?",
        correctAnswer: "Le Nil",
        incorrectAnswers: ["L'Amazone", "Le Mississippi", "Le Yangtsé"],
        category: "Géographie",
        difficulty: difficulty.isEmpty ? "medium" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Quelle est la monnaie du Japon?",
        correctAnswer: "Yen",
        incorrectAnswers: ["Won", "Yuan", "Dollar"],
        category: "Économie",
        difficulty: difficulty.isEmpty ? "easy" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Qui est l'auteur de 'Harry Potter'?",
        correctAnswer: "J.K. Rowling",
        incorrectAnswers: ["Stephen King", "George R.R. Martin", "Tolkien"],
        category: "Littérature",
        difficulty: difficulty.isEmpty ? "easy" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Quel est l'élément chimique le plus abondant dans l'univers?",
        correctAnswer: "Hydrogène",
        incorrectAnswers: ["Oxygène", "Carbone", "Fer"],
        category: "Science",
        difficulty: difficulty.isEmpty ? "medium" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Quelle est la plus haute montagne du monde?",
        correctAnswer: "Mont Everest",
        incorrectAnswers: ["K2", "Mont Blanc", "Kilimandjaro"],
        category: "Géographie",
        difficulty: difficulty.isEmpty ? "easy" : difficulty,
        type: "multiple",
      ),
      QuizQuestion(
        question: "Qui a peint 'La Nuit étoilée'?",
        correctAnswer: "Vincent van Gogh",
        incorrectAnswers: ["Pablo Picasso", "Claude Monet", "Salvador Dalí"],
        category: "Art",
        difficulty: difficulty.isEmpty ? "medium" : difficulty,
        type: "multiple",
      ),
    ];

    // Limiter au nombre demandé
    return localQuestions.take(amount).toList();
  }

  Future<List<QuizCategory>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(categoriesUrl)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> categories = data['trivia_categories'];
        return categories.map((json) => QuizCategory.fromJson(json)).toList();
      } else {
        print('HTTP error fetching categories: ${response.statusCode}');
        return _getLocalCategories();
      }
    } catch (e) {
      print('Exception in fetchCategories: $e');
      return _getLocalCategories();
    }
  }

  List<QuizCategory> _getLocalCategories() {
    // Catégories locales en cas d'échec de l'API
    return [
      QuizCategory(id: 1, name: "Géographie"),
      QuizCategory(id: 2, name: "Histoire"),
      QuizCategory(id: 3, name: "Science"),
      QuizCategory(id: 4, name: "Art"),
      QuizCategory(id: 5, name: "Littérature"),
      QuizCategory(id: 6, name: "Sport"),
      QuizCategory(id: 7, name: "Cinéma"),
      QuizCategory(id: 8, name: "Musique"),
      QuizCategory(id: 9, name: "Technologie"),
      QuizCategory(id: 10, name: "Économie"),
    ];
  }

  String _getErrorMessage(int responseCode) {
    switch (responseCode) {
      case 1:
        return 'No results found';
      case 2:
        return 'Invalid parameter';
      case 3:
        return 'Token not found';
      case 4:
        return 'Token empty';
      default:
        return 'Unknown error';
    }
  }
} 