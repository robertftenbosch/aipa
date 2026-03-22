import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/constants.dart';
import 'services/llm_service.dart';
import 'services/search_service.dart';
import 'services/tts_service.dart';
import 'services/weather_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

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
        Provider<WeatherService>(
          create: (_) => WeatherService(),
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

/// Quick splash that initializes LLM and routes to the right screen.
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
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
        // No model yet — go to settings to download one
        if (mounted) _navigateTo(const SettingsScreen(), replace: true);
      } else {
        try {
          await llm.loadModel();
          if (mounted) _navigateTo(const HomeScreen(), replace: true);
        } catch (_) {
          // Model load failed (corrupt cache, etc.) — go to settings
          if (mounted) _navigateTo(const SettingsScreen(), replace: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Er ging iets mis bij het opstarten: $e');
      }
    }
  }

  void _navigateTo(Widget screen, {bool replace = false}) {
    final route = MaterialPageRoute(builder: (_) => screen);
    if (replace) {
      Navigator.pushReplacement(context, route);
    } else {
      Navigator.push(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 80, color: Colors.red),
                      const SizedBox(height: 24),
                      Text(
                        _error!,
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _error = null);
                          _initialize();
                        },
                        child: const Text('Opnieuw proberen'),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assistant,
                          size: 80, color: Color(0xFF1565C0)),
                      SizedBox(height: 24),
                      Text(
                        AppConstants.appName,
                        style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold),
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
                  ),
          ),
        ),
      ),
    );
  }
}
