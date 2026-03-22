import 'dart:async';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../config/constants.dart';

class LlmService {
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _isInitialized = false;
  bool _isModelInstalled = false;

  bool get isInitialized => _isInitialized;
  bool get isModelInstalled => _isModelInstalled;

  /// Initialize FlutterGemma (call once at app startup).
  Future<void> initialize() async {
    await FlutterGemma.initialize();
    _isModelInstalled = FlutterGemma.hasActiveModel();
    _isInitialized = true;
  }

  /// Install the Gemma model from a URL. Returns a stream of download progress (0-100).
  Stream<double> installModel(String modelUrl, {String? huggingFaceToken}) {
    final controller = StreamController<double>();

    FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.task,
    )
        .fromNetwork(modelUrl, token: huggingFaceToken)
        .withProgress((progress) {
          controller.add(progress.toDouble());
        })
        .install()
        .then((_) {
      _isModelInstalled = true;
      controller.close();
    }).catchError((e) {
      controller.addError(e);
      controller.close();
    });

    return controller.stream;
  }

  /// Load the model into memory and prepare for inference.
  Future<void> loadModel() async {
    _model = await FlutterGemma.getActiveModel(
      maxTokens: 1024,
      preferredBackend: PreferredBackend.gpu,
    );
  }

  /// Start a new chat session with optional category context.
  Future<void> startChat(String? categoryId) async {
    if (_model == null) {
      await loadModel();
    }

    _chat = await _model!.createChat(
      temperature: 0.7,
      topK: 40,
    );

    // Add the system prompt as context
    final systemPrompt = AppConstants.getSystemPrompt(categoryId);
    await _chat!.addQueryChunk(
      Message.text(text: systemPrompt, isUser: true),
    );

    // Let the model acknowledge the system prompt silently
    await _chat!.generateChatResponse();
  }

  /// Send a user message and get a streaming response.
  Stream<String> sendMessage(String text) async* {
    if (_chat == null) {
      throw StateError('Chat not started. Call startChat() first.');
    }

    await _chat!.addQuery(Message.text(text: text, isUser: true));

    final stream = _chat!.generateChatResponseAsync();
    await for (final response in stream) {
      if (response is TextResponse) {
        yield response.token;
      }
    }
  }

  /// Send a message and wait for the complete response.
  Future<String> sendMessageSync(String text) async {
    if (_chat == null) {
      throw StateError('Chat not started. Call startChat() first.');
    }

    await _chat!.addQuery(Message.text(text: text, isUser: true));
    final response = await _chat!.generateChatResponse();
    if (response is TextResponse) {
      return response.token;
    }
    return '';
  }

  /// Stop the current generation.
  void stopGeneration() {
    _chat?.stopGeneration();
  }

  /// End the current chat session.
  Future<void> endChat() async {
    await _chat?.clearHistory();
    _chat = null;
  }

  /// Release all resources.
  Future<void> dispose() async {
    await endChat();
    _model?.close();
    _model = null;
  }
}
