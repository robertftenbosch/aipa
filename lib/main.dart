import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'services/llm_service.dart';
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
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _error = null;
    });

    try {
      final llm = context.read<LlmService>();

      // Gemma 3n E2B model URL from HuggingFace
      const modelUrl =
          'https://huggingface.co/aspect12/gemma-3n-E2B-it-mediapipe/resolve/main/gemma3n-E2B-it-gpu.task';

      await for (final progress in llm.installModel(modelUrl)) {
        if (mounted) {
          setState(() => _downloadProgress = progress);
        }
      }

      await llm.loadModel();
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
      return Column(
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
            'Om u te kunnen helpen moet de app eerst een AI-model downloaden. Dit is eenmalig en duurt een paar minuten.',
            style: TextStyle(fontSize: 20, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Grootte: ongeveer 1-2 GB',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 32),
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
