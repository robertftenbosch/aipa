import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'services/llm_service.dart';
import 'services/search_service.dart';
import 'services/tts_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AipaApp());
}

class AipaApp extends StatelessWidget {
  const AipaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LlmService>(
          create: (_) => LlmService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<TtsService>(
          create: (_) {
            final tts = TtsService();
            tts.initialize();
            return tts;
          },
          dispose: (_, service) => service.dispose(),
        ),
        Provider<SearchService>(
          create: (_) => SearchService(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AipaTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const _AppStartup(),
      ),
    );
  }
}

/// Handles LLM initialization and model setup before showing the main app.
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  bool _isInitializing = true;
  bool _needsModelDownload = false;
  double _downloadProgress = 0;
  bool _isDownloading = false;
  String? _error;
  int _selectedModelIndex = 0;
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final llm = context.read<LlmService>();
      await llm.initialize();

      if (!llm.isModelInstalled) {
        setState(() {
          _isInitializing = false;
          _needsModelDownload = true;
        });
      } else {
        await llm.loadModel();
        if (mounted) {
          setState(() => _isInitializing = false);
          _navigateToHome();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = 'Er ging iets mis bij het opstarten: $e';
        });
      }
    }
  }

  Future<void> _downloadModel() async {
    final selectedModel = AppConstants.availableModels[_selectedModelIndex];
    final token = _tokenController.text.trim();

    if (selectedModel.requiresToken && token.isEmpty) {
      setState(() {
        _error = 'Dit model vereist een HuggingFace token. Maak een gratis account aan op huggingface.co en vul uw token in.';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _error = null;
    });

    try {
      final llm = context.read<LlmService>();

      await for (final progress in llm.installModel(
        selectedModel.url,
        modelType: selectedModel.modelType,
        huggingFaceToken: token.isNotEmpty ? token : null,
      )) {
        if (mounted) {
          setState(() => _downloadProgress = progress);
        }
      }

      await llm.loadModel(supportImage: selectedModel.supportsVision);
      if (mounted) {
        setState(() => _isDownloading = false);
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error =
              'Download mislukt. Controleer uw internetverbinding en probeer het opnieuw.';
        });
      }
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitializing) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assistant, size: 80, color: Color(0xFF1565C0)),
          SizedBox(height: 24),
          Text(
            AppConstants.appName,
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            AppConstants.appSubtitle,
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          SizedBox(height: 32),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Even geduld...',
            style: TextStyle(fontSize: 18),
          ),
        ],
      );
    }

    if (_needsModelDownload) {
      final selectedModel = AppConstants.availableModels[_selectedModelIndex];
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download, size: 80, color: Color(0xFF1565C0)),
            const SizedBox(height: 24),
            const Text(
              'AI-model downloaden',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Kies een AI-model. Dit wordt eenmalig gedownload.',
              style: TextStyle(fontSize: 20, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Model selection
            ...List.generate(AppConstants.availableModels.length, (index) {
              final model = AppConstants.availableModels[index];
              final isSelected = index == _selectedModelIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected
                      ? const Color(0xFF1565C0).withAlpha(25)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _isDownloading
                        ? null
                        : () => setState(() => _selectedModelIndex = index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1565C0)
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                model.name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                model.size,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            model.description,
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                          if (model.requiresToken)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Vereist HuggingFace token',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[700],
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            // HuggingFace token input
            if (selectedModel.requiresToken) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'HuggingFace Token',
                  hintText: 'hf_...',
                  helperText: 'Maak gratis aan op huggingface.co/settings/tokens',
                  helperStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _downloadProgress / 100,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 12),
              Text(
                '${_downloadProgress.toStringAsFixed(0)}% gedownload',
                style: const TextStyle(fontSize: 20),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _downloadModel,
                  icon: const Icon(Icons.download, size: 28),
                  label: const Text('Download starten'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 24),
              Text(
                _error!,
                style: const TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _downloadModel,
                child: const Text('Opnieuw proberen'),
              ),
            ],
          ],
        ),
      );
    }

    // Error state
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 80, color: Colors.red),
        const SizedBox(height: 24),
        Text(
          _error ?? 'Er ging iets mis.',
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isInitializing = true;
              _error = null;
            });
            _initialize();
          },
          child: const Text('Opnieuw proberen'),
        ),
      ],
    );
  }
}
