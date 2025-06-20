import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_model.dart';

class StorageService {
  static const String resultsKey = 'quiz_results';
  static const String settingsKey = 'quiz_settings';

  // Save quiz result
  Future<void> saveQuizResult(QuizResult result) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing results
    List<QuizResult> results = await getQuizResults();
    results.add(result);
    
    // Convert to JSON and save
    final jsonResults = results.map((result) => result.toJson()).toList();
    await prefs.setString(resultsKey, jsonEncode(jsonResults));
  }

  // Get all quiz results
  Future<List<QuizResult>> getQuizResults() async {
    final prefs = await SharedPreferences.getInstance();
    
    final jsonString = prefs.getString(resultsKey);
    if (jsonString == null) {
      return [];
    }
    
    final jsonResults = jsonDecode(jsonString) as List;
    return jsonResults.map((json) => QuizResult.fromJson(json)).toList();
  }

  // Clear all quiz results
  Future<void> clearQuizResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(resultsKey);
  }

  // Save app settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(settingsKey, jsonEncode(settings));
  }

  // Get app settings
  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final jsonString = prefs.getString(settingsKey);
    if (jsonString == null) {
      return {
        'sound': true,
        'notifications': true,
        'language': 'en',
        'darkMode': false,
      };
    }
    
    return jsonDecode(jsonString);
  }

  // Save specific setting
  Future<void> saveSetting(String key, dynamic value) async {
    final settings = await getSettings();
    settings[key] = value;
    await saveSettings(settings);
  }
} 