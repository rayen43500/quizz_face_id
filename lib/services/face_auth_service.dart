import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';

// Service d'authentification faciale simplifié qui simule la détection faciale
// sans dépendre de Google ML Kit pour éviter les problèmes de compatibilité
class FaceAuthService {
  bool _isAuthSetup = false;
  bool get isAuthSetup => _isAuthSetup;

  // Stored auth data
  Map<String, dynamic>? _storedAuthData;

  FaceAuthService() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final authDataString = prefs.getString('face_auth_data');
    
    if (authDataString != null) {
      try {
        _storedAuthData = jsonDecode(authDataString);
        _isAuthSetup = true;
      } catch (e) {
        _isAuthSetup = false;
        _storedAuthData = null;
      }
    } else {
      _isAuthSetup = false;
      _storedAuthData = null;
    }
  }

  // Simule l'enregistrement du visage
  Future<bool> registerFace(dynamic inputImage) async {
    try {
      // Simuler un délai de traitement
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Créer des données d'authentification fictives
      final authData = {
        'userId': 'user_${math.Random().nextInt(10000)}',
        'registrationTime': DateTime.now().millisecondsSinceEpoch,
        'deviceInfo': 'Flutter Device',
      };
      
      // Enregistrer les données
      await _saveAuthData(authData);
      _isAuthSetup = true;
      
      return true;
    } catch (e) {
      print('Erreur d\'enregistrement: $e');
      return false;
    }
  }

  // Simule l'authentification par visage
  Future<bool> authenticateFace(dynamic inputImage) async {
    if (!_isAuthSetup || _storedAuthData == null) return false;
    
    try {
      // Simuler un délai de traitement
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Pour la démonstration, nous acceptons toujours l'authentification
      // Dans une application réelle, vous effectueriez une vérification biométrique
      return true;
    } catch (e) {
      print('Erreur d\'authentification: $e');
      return false;
    }
  }
  
  Future<void> _saveAuthData(Map<String, dynamic> authData) async {
    final prefs = await SharedPreferences.getInstance();
    final authDataString = jsonEncode(authData);
    await prefs.setString('face_auth_data', authDataString);
    _storedAuthData = authData;
  }

  Future<void> clearFaceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('face_auth_data');
    await prefs.remove('is_authenticated');
    _isAuthSetup = false;
    _storedAuthData = null;
  }

  void dispose() {
    // Rien à libérer dans cette implémentation simplifiée
  }
} 