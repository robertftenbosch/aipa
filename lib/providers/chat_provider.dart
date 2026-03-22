import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/task_category.dart';
import '../services/llm_service.dart';
import '../services/search_service.dart';
import '../services/tts_service.dart';
import '../services/weather_service.dart';

enum _QueryType { weather, news, general }

class ChatProvider extends ChangeNotifier {
  final LlmService _llm;
  final TtsService _tts;
  final SearchService _search;
  final WeatherService _weather;
  final TaskCategory? category;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isSearching = false;
  bool _isSpeaking = false;
  bool _autoSpeak = false;
  String? _error;
  String _currentResponse = '';
  VoidCallback? _onSpeakingDone;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isSearching => _isSearching;
  bool get isSpeaking => _isSpeaking;
  bool get autoSpeak => _autoSpeak;
  bool get visionEnabled => _llm.visionEnabled;
  String? get error => _error;

  /// Set callback for when TTS finishes speaking (used for auto-listen).
  set onSpeakingDone(VoidCallback? callback) => _onSpeakingDone = callback;

  /// Toggle auto-speak mode.
  void toggleAutoSpeak() {
    _autoSpeak = !_autoSpeak;
    notifyListeners();
  }

  ChatProvider({
    required LlmService llm,
    required TtsService tts,
    required SearchService search,
    required WeatherService weather,
    this.category,
  })  : _llm = llm,
        _tts = tts,
        _search = search,
        _weather = weather;

  /// Detect what type of query this is.
  static _QueryType _detectQueryType(String text) {
    final lower = text.toLowerCase();
    const weatherWords = [
      'weer', 'temperatuur', 'graden', 'regen', 'zon', 'sneeuw',
      'wind', 'bewolkt', 'warm', 'koud', 'buien', 'onweer',
      'weather', 'forecast',
    ];
    const newsWords = [
      'nieuws', 'headlines', 'actualiteit', 'vandaag gebeurd',
      'wat is er gaande', 'krant', 'news',
    ];

    for (final w in weatherWords) {
      if (lower.contains(w)) return _QueryType.weather;
    }
    for (final w in newsWords) {
      if (lower.contains(w)) return _QueryType.news;
    }
    return _QueryType.general;
  }

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

    // Skip external lookups for casual chat
    if (category?.id == 'kletsen') {
      await _generateResponse(_llm.sendMessage(userText));
      return;
    }

    // Detect query type and fetch relevant context
    final queryType = _detectQueryType(userText);
    String? externalContext;

    try {
      _isSearching = true;
      notifyListeners();

      switch (queryType) {
        case _QueryType.weather:
          externalContext = await _weather.getCurrentWeather();
          break;
        case _QueryType.news:
          final results = await _search.searchNews(userText);
          if (results.isNotEmpty) {
            externalContext =
                _search.formatResults(results, label: 'Laatste nieuws');
          }
          break;
        case _QueryType.general:
          final results = await _search.search(userText);
          if (results.isNotEmpty) {
            externalContext = _search.formatResults(results);
          }
          break;
      }
    } catch (_) {
      // External lookup failed — continue without it
    } finally {
      _isSearching = false;
      notifyListeners();
    }

    // Build prompt with external context
    String prompt = userText;
    if (externalContext != null) {
      prompt = 'Vraag: $userText\n\n'
          '$externalContext\n\n'
          'Gebruik deze informatie om een duidelijk antwoord te geven in eenvoudig Nederlands.';
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

    // Auto-speak the response
    if (_autoSpeak && _currentResponse.isNotEmpty) {
      await speakMessage(_currentResponse);
    }
  }

  /// Stop the current generation.
  void stopGeneration() {
    _llm.stopGeneration();
    _isGenerating = false;
    notifyListeners();
  }

  /// Speak a message aloud using TTS.
  Future<void> speakMessage(String text) async {
    _isSpeaking = true;
    notifyListeners();
    await _tts.speak(text);
    _isSpeaking = false;
    notifyListeners();
    _onSpeakingDone?.call();
  }

  /// Stop speaking.
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _llm.endChat();
    _tts.stop();
    super.dispose();
  }
}
