import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/task_category.dart';
import '../services/llm_service.dart';
import '../services/search_service.dart';
import '../services/tts_service.dart';

class ChatProvider extends ChangeNotifier {
  final LlmService _llm;
  final TtsService _tts;
  final SearchService _search;
  final TaskCategory? category;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isSearching = false;
  String? _error;
  String _currentResponse = '';

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isSearching => _isSearching;
  bool get visionEnabled => _llm.visionEnabled;
  String? get error => _error;

  ChatProvider({
    required LlmService llm,
    required TtsService tts,
    required SearchService search,
    this.category,
  })  : _llm = llm,
        _tts = tts,
        _search = search;

  /// Initialize the chat session and send a greeting.
  Future<void> initChat() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _llm.startChat(category?.id);

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

  /// Send a user message. Automatically searches the web first for context,
  /// then sends the question + search results to the AI.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isGenerating) return;

    _error = null;
    final userText = text.trim();

    _messages.add(ChatMessage(
      role: MessageRole.user,
      text: userText,
    ));
    notifyListeners();

    // Auto-search the web for context (skip for casual chat)
    final skipSearch = category?.id == 'kletsen';
    String? searchContext;
    if (!skipSearch) {
      try {
        _isSearching = true;
        notifyListeners();

        final results = await _search.search(userText);
        if (results.isNotEmpty) {
          searchContext = _search.formatResults(results);
        }
      } catch (_) {
        // Search failed — continue without it
      } finally {
        _isSearching = false;
        notifyListeners();
      }
    }

    // Build prompt with optional search context
    String prompt = userText;
    if (searchContext != null) {
      prompt = 'Vraag: $userText\n\n'
          'Hier is informatie van het internet die kan helpen:\n'
          '$searchContext\n\n'
          'Gebruik deze informatie om een duidelijk antwoord te geven.';
    }

    await _generateResponse(_llm.sendMessage(prompt));
  }

  /// Send an image with optional description.
  Future<void> sendImage(Uint8List imageBytes, {String? text}) async {
    if (_isGenerating) return;
    if (!_llm.visionEnabled) {
      _error = 'Dit model ondersteunt geen foto-analyse. Kies het Gemma 3n E4B model.';
      notifyListeners();
      return;
    }

    _error = null;

    _messages.add(ChatMessage(
      role: MessageRole.user,
      text: text ?? 'Wat zie je op deze foto?',
    ));
    notifyListeners();

    await _generateResponse(_llm.sendImage(imageBytes, text: text));
  }

  /// Search the web and inject results into the chat.
  Future<void> searchAndAsk(String query) async {
    if (_isGenerating || _isSearching) return;

    _error = null;
    _isSearching = true;

    _messages.add(ChatMessage(
      role: MessageRole.user,
      text: 'Zoek op internet: $query',
    ));
    notifyListeners();

    try {
      final results = await _search.search(query);
      final formattedResults = _search.formatResults(results);

      _isSearching = false;
      notifyListeners();

      // Send the search results to the LLM for a helpful answer
      final prompt =
          'De gebruiker zocht op internet naar: "$query"\n\n'
          '$formattedResults\n\n'
          'Geef een duidelijk en eenvoudig antwoord op basis van deze resultaten.';

      await _generateResponse(_llm.sendMessage(prompt));
    } catch (e) {
      _isSearching = false;
      _error = 'Zoeken mislukt. Controleer de internetverbinding.';
      notifyListeners();
    }
  }

  /// Shared method to stream a response from the LLM.
  Future<void> _generateResponse(Stream<String> responseStream) async {
    _isGenerating = true;
    _currentResponse = '';

    final assistantMessage = ChatMessage(
      role: MessageRole.assistant,
      text: '',
    );
    _messages.add(assistantMessage);
    notifyListeners();

    try {
      await for (final token in responseStream) {
        _currentResponse += token;
        _messages[_messages.length - 1] = ChatMessage(
          id: assistantMessage.id,
          role: MessageRole.assistant,
          text: _currentResponse,
        );
        notifyListeners();
      }
    } catch (e) {
      if (_currentResponse.isEmpty) {
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
