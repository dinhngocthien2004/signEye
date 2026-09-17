import 'package:flutter_tts/flutter_tts.dart';

/// Wraps flutter_tts to replicate the "🔊 read aloud" button from the
/// original web app, which used the browser's SpeechSynthesis API with a
/// Vietnamese voice.
class TtsService {
  TtsService._() {
    _tts.setLanguage('vi-VN');
    _tts.setSpeechRate(0.48);
    _tts.setPitch(1.0);
  }

  static final TtsService instance = TtsService._();
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
