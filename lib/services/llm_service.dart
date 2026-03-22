import 'dart:async';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../config/constants.dart';

class LlmService {
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _isInitialized = false;
  bool _isModelInstalled = false;
  bool _isFirstMessage = true;
  String? _categoryId;

  bool get isInitialized => _isInitialized;
  bool get isModelInstalled => _isModelInstalled;

  /// Initialize FlutterGemma (call once at app startup).
  Future<void> initialize() async {
    await FlutterGemma.initialize();
    _isModelInstalled = FlutterGemma.hasActiveModel();
    _isInitialized = true;
  }

  /// Install a model from a URL. Returns a stream of download progress (0-100).
  Stream<double> installModel(
    String modelUrl, {
    ModelType modelType = ModelType.gemmaIt,
    String? huggingFaceToken,
  }) {
    final controller = StreamController<double>();

    var builder = FlutterGemma.installModel(
      modelType: modelType,
      fileType: ModelFileType.task,
    ).fromNetwork(modelUrl, token: huggingFaceToken);

    builder.withProgress((progress) {
      controller.add(progress.toDouble());
    }).install().then((_) {
      _isModelInstalled = true;
      controller.close();
    }).catchError((e) {
      controller.addError(e);
      controller.close();
    });

    return controller.stream;
  }

  /// Load the model into memory and prepare for inference.
  /// Uses CPU backend for maximum compatibility.
  Future<void> loadModel() async {
    _model = await FlutterGemma.getActiveModel(
      maxTokens: 512,
      preferredBackend: PreferredBackend.cpu,
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
    _isFirstMessage = true;
    _categoryId = categoryId;
  }

  /// Send a user message and get a streaming response.
  /// On the first message, prepends the system prompt for context.
  Stream<String> sendMessage(String text) async* {
    if (_chat == null) {
      throw StateError('Chat not started. Call startChat() first.');
    }

    String prompt = text;
    if (_isFirstMessage) {
      final systemPrompt = AppConstants.getSystemPrompt(_categoryId);
      prompt = '$systemPrompt\n\nGebruiker: $text';
      _isFirstMessage = false;
    }

    await _chat!.addQuery(Message.text(text: prompt, isUser: true));

    final stream = _chat!.generateChatResponseAsync();
    await for (final response in stream) {
      if (response is TextResponse) {
        yield response.token;
      }
    }
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
