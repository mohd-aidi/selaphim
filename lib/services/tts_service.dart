import 'package:flutter_tts/flutter_tts.dart';

/// Wraps flutter_tts for text-to-speech output.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;

  Future<void> init({
    double speed = 1.0,
    double pitch = 1.0,
    String language = 'en-US',
    String? voice,
  }) async {
    if (!_initialized) {
      await _tts.awaitSpeakCompletion(true);
      _initialized = true;
    }
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(speed);
    await _tts.setPitch(pitch);
    if (voice != null) {
      await _tts.setVoice({'name': voice, 'locale': language});
    }
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<List<dynamic>> getVoices() async {
    return _tts.getVoices;
  }

  Future<List<dynamic>> getLanguages() async {
    return _tts.getLanguages;
  }

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  void setHandlers({
    void Function()? onStart,
    void Function()? onComplete,
    void Function(String)? onError,
  }) {
    if (onStart != null) {
      _tts.setStartHandler(() {
        _isSpeaking = true;
        onStart();
      });
    }
    if (onComplete != null) {
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        onComplete();
      });
    }
    if (onError != null) {
      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        onError(msg.toString());
      });
    }
  }
}
