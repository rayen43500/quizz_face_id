import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  double _volume = 1.0; // Volume maximum par défaut
  
  AudioService() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _volume = prefs.getDouble('sound_volume') ?? 1.0;
  }
  
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }
  
  Future<void> setVolume(double volume) async {
    _volume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sound_volume', volume);
  }
  
  Future<void> playCorrectSound() async {
    if (!_soundEnabled) return;
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      print('Error playing correct sound: $e');
    }
  }
  
  Future<void> playIncorrectSound() async {
    if (!_soundEnabled) return;
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.play(AssetSource('sounds/incorrect.mp3'));
    } catch (e) {
      print('Error playing incorrect sound: $e');
    }
  }
  
  Future<void> playSuccessSound() async {
    if (!_soundEnabled) return;
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      print('Error playing success sound: $e');
    }
  }
  
  Future<void> playFailureSound() async {
    if (!_soundEnabled) return;
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.play(AssetSource('sounds/incorrect.mp3'));
    } catch (e) {
      print('Error playing failure sound: $e');
    }
  }
  
  Future<void> playClickSound() async {
    if (!_soundEnabled) return;
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(_volume * 0.7); // Volume légèrement plus bas pour le clic
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      print('Error playing click sound: $e');
    }
  }
  
  void dispose() {
    _audioPlayer.dispose();
  }
} 