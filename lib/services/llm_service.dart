import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class LlmService {
  InferenceModel? _model;
  InferenceChat? _chat;
  bool _isInitialized = false;
  bool _isModelInstalled = false;
  bool _isFirstMessage = true;
  bool _visionEnabled = false;
  bool _useGpu = true;
  String? _categoryId;

  static const _gpuPrefKey = 'use_gpu';

  bool get isInitialized => _isInitialized;
  bool get isModelInstalled => _isModelInstalled;
  bool get visionEnabled => _visionEnabled;
  bool get useGpu => _useGpu;

  /// Initialize FlutterGemma (call once at app startup).
  Future<void> initialize() async {
    await FlutterGemma.initialize()
        .timeout(const Duration(seconds: 30));
    // Check memory first (fast, synchronous)
    _isModelInstalled = FlutterGemma.hasActiveModel();
    // If not in memory, check disk (async, can be slow)
    if (!_isModelInstalled) {
      try {
        final installed = await FlutterGemma.listInstalledModels()
            .timeout(const Duration(seconds: 10));
        _isModelInstalled = installed.isNotEmpty;
      } catch (_) {
        // Timeout or error — assume not installed
        _isModelInstalled = false;
      }
    }
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

  bool _modelLoaded = false;

  bool get isModelLoaded => _modelLoaded;

  /// Load GPU preference from storage.
  Future<void> _loadGpuPref() async {
    final prefs = await SharedPreferences.getInstance();
    _useGpu = prefs.getBool(_gpuPrefKey) ?? true;
  }

  /// Set GPU preference.
  Future<void> setUseGpu(bool value) async {
    _useGpu = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gpuPrefKey, value);
  }

  /// Load the model into memory and prepare for inference.
  /// Tries GPU first (fast), falls back to CPU (reliable).
  Future<void> loadModel({bool supportImage = false}) async {
    _visionEnabled = supportImage;
    _modelLoaded = false;
    await _loadGpuPref();

    final backend =
        _useGpu ? PreferredBackend.gpu : PreferredBackend.cpu;

    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 512,
        preferredBackend: backend,
        supportImage: supportImage,
      ).timeout(const Duration(seconds: 90));
      _modelLoaded = true;
    } catch (_) {
      // If GPU failed, try CPU as fallback
      if (_useGpu) {
        try {
          _model = await FlutterGemma.getActiveModel(
            maxTokens: 512,
            preferredBackend: PreferredBackend.cpu,
            supportImage: supportImage,
          ).timeout(const Duration(seconds: 90));
          _modelLoaded = true;
          // Remember that CPU worked (GPU had issues)
          await setUseGpu(false);
        } catch (_) {
          _model = null;
          _modelLoaded = false;
          rethrow;
        }
      } else {
        _model = null;
        _modelLoaded = false;
        rethrow;
      }
    }
  }

  /// Start a new chat session with optional category context.
  Future<void> startChat(String? categoryId) async {
    if (_model == null) {
      throw StateError(
          'Model niet geladen. Ga naar Instellingen om een model te downloaden.');
    }

    _chat = await _model!.createChat(
      temperature: 0.7,
      topK: 40,
      supportImage: _visionEnabled,
    );
    _isFirstMessage = true;
    _categoryId = categoryId;
  }

  /// Send a text message and get a streaming response.
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

  /// Send an image with optional text and get a streaming response.
  Stream<String> sendImage(Uint8List imageBytes, {String? text}) async* {
    if (_chat == null) {
      throw StateError('Chat not started. Call startChat() first.');
    }
    if (!_visionEnabled) {
      throw StateError('Vision is not enabled for this model.');
    }

    String prompt = text ?? 'Beschrijf wat je ziet op deze foto. Help de gebruiker.';
    if (_isFirstMessage) {
      final systemPrompt = AppConstants.getSystemPrompt(_categoryId);
      prompt = '$systemPrompt\n\n$prompt';
      _isFirstMessage = false;
    }

    await _chat!.addQuery(
      Message.withImage(text: prompt, imageBytes: imageBytes, isUser: true),
    );

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
