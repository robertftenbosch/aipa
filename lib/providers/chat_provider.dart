import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/task_category.dart';
import '../services/llm_service.dart';
import '../services/tts_service.dart';

class ChatProvider extends ChangeNotifier {
  final LlmService _llm;
  final TtsService _tts;
  final TaskCategory? category;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;
  String _currentResponse = '';

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  ChatProvider({
    required LlmService llm,
    required TtsService tts,
    this.category,
  })  : _llm = llm,
        _tts = tts;

  /// Initialize the chat session and send a greeting.
  Future<void> initChat() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _llm.startChat(category?.id);

      // Add the greeting as an assistant message
      if (category != null) {
        _messages.add(ChatMessage(
          role: MessageRole.assistant,
          text: category!.greeting,
        ));
      } else {
        _messages.add(ChatMessage(
          role: MessageRole.assistant,
          text: 'Hallo! Waarmee kan ik u helpen?',
        ));
      }
    } catch (e) {
      _error = 'Er ging iets mis bij het starten. Probeer het opnieuw.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Send a user message and stream the AI response.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isGenerating) return;

    _error = null;

    // Add user message
    _messages.add(ChatMessage(
      role: MessageRole.user,
      text: text.trim(),
    ));
    notifyListeners();

    // Start generating response
    _isGenerating = true;
    _currentResponse = '';

    // Add a placeholder for the assistant response
    final assistantMessage = ChatMessage(
      role: MessageRole.assistant,
      text: '',
    );
    _messages.add(assistantMessage);
    notifyListeners();

    try {
      await for (final token in _llm.sendMessage(text.trim())) {
        _currentResponse += token;
        // Update the last message with accumulated text
        _messages[_messages.length - 1] = ChatMessage(
          id: assistantMessage.id,
          role: MessageRole.assistant,
          text: _currentResponse,
        );
        notifyListeners();
      }
    } catch (e) {
      if (_currentResponse.isEmpty) {
        // Remove the empty placeholder
        _messages.removeLast();
        _error = 'Er ging iets mis. Probeer het opnieuw.';
      }
    }

    _isGenerating = false;
    notifyListeners();
  }

  /// Stop the current generation.
  void stopGeneration() {
    _llm.stopGeneration();
    _isGenerating = false;
    notifyListeners();
  }

  /// Speak a message aloud using TTS.
  Future<void> speakMessage(String text) async {
    await _tts.speak(text);
  }

  /// Stop speaking.
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  @override
  void dispose() {
    _llm.endChat();
    _tts.stop();
    super.dispose();
  }
}
