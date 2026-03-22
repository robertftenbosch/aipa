import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    return _isAvailable;
  }

  void listen({
    required void Function(String text, bool isFinal) onResult,
    void Function()? onDone,
  }) {
    if (!_isAvailable) return;

    _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: 'nl_NL',
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }
}
