import 'package:flutter_tts/flutter_tts.dart';

/// Wraps flutter_tts to replicate the "🔊 read aloud" button from the
/// original web app, which used the browser's SpeechSynthesis API with a
/// Vietnamese voice.
class TtsService {
  TtsService._();

  static final TtsService instance = TtsService._();
  final FlutterTts _tts = FlutterTts();
  Future<void>? _setupFuture;

  Future<void> _setup() {
    return _setupFuture ??= _configureVietnameseVoice();
  }

  Future<void> _configureVietnameseVoice() async {
    await _tts.setLanguage('vi-VN');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);

    // Browser TTS can fall back to English unless a Vietnamese voice is
    // selected explicitly when voices are available.
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        for (final voice in voices) {
          if (voice is Map) {
            final locale = '${voice['locale'] ?? voice['lang'] ?? ''}'
                .toLowerCase()
                .replaceAll('_', '-');
            if (locale == 'vi-vn' || locale == 'vi') {
              await _tts.setVoice({
                'name': '${voice['name'] ?? ''}',
                'locale': voice['locale'] ?? voice['lang'] ?? 'vi-VN',
              });
              break;
            }
          }
        }
      }
    } catch (_) {
      // The language setting above remains the fallback on platforms that
      // do not expose their installed voice list.
    }
  }

  Future<void> speak(String text) async {
    await _setup();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
