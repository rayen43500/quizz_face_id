import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_model.dart';
import 'dart:async';

class QuizService {
  static const String baseUrl = 'https://opentdb.com/api.php';
  static const String categoriesUrl = 'https://opentdb.com/api_category.php';

  Future<List<QuizQuestion>> fetchQuizQuestions({
    required int amount,
    int? categoryId,
    String difficulty = '',
    String type = '',
  }) async {
    String url = '$baseUrl?amount=$amount';
    
    if (categoryId != null) {
      url += '&category=$categoryId';
    }
    
    if (difficulty.isNotEmpty) {
      url += '&difficulty=${difficulty.toLowerCase()}';
    }
    
    if (type.isNotEmpty) {
      url += '&type=$type';
    }
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['response_code'] == 0) {
        final List<dynamic> results = data['results'];
        return results.map((json) => QuizQuestion.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load questions: ${_getErrorMessage(data['response_code'])}');
      }
    } else {
      throw Exception('Failed to load questions');
    }
  }

  Future<List<QuizCategory>> fetchCategories() async {
    final response = await http.get(Uri.parse(categoriesUrl));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> categories = data['trivia_categories'];
      return categories.map((json) => QuizCategory.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
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