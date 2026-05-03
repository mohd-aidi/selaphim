import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wraps the speech_to_text plugin for easy use throughout the app.
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (error) {
        // Errors are surfaced through the onResult callback status field.
      },
    );
    return _initialized;
  }

  /// Start listening. Call [onResult] on every recognition update.
  /// Returns true if listening started.
  Future<bool> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_initialized) {
      final ok = await init();
      if (!ok) return false;
    }
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
    );
    return true;
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }

  Future<List<stt.LocaleName>> getLocales() async {
    if (!_initialized) await init();
    return _speech.locales();
  }
}
