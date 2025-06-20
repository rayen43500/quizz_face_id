import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isSoundEnabled = true;
  bool get isSoundEnabled => _isSoundEnabled;

  AudioService() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }

  Future<void> playCorrectSound() async {
    if (_isSoundEnabled) {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    }
  }

  Future<void> playIncorrectSound() async {
    if (_isSoundEnabled) {
      await _audioPlayer.play(AssetSource('sounds/incorrect.mp3'));
    }
  }

  Future<void> playSuccessSound() async {
    if (_isSoundEnabled) {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    }
  }

  Future<void> playFailureSound() async {
    if (_isSoundEnabled) {
      await _audioPlayer.play(AssetSource('sounds/incorrect.mp3'));
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
} 