import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../services/llm_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _tokenKey = 'hf_token';
  static const _storage = FlutterSecureStorage();
  static const _envToken = String.fromEnvironment('HF_TOKEN');

  final _tokenController = TextEditingController();
  int _selectedModelIndex = 0;
  double _downloadProgress = 0;
  bool _isDownloading = false;
  bool _tokenSaved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedToken();
  }

  Future<void> _loadSavedToken() async {
    if (_envToken.isNotEmpty) {
      _tokenController.text = _envToken;
      return;
    }
    final saved = await _storage.read(key: _tokenKey);
    if (saved != null && saved.isNotEmpty) {
      _tokenController.text = saved;
    }
  }

  Future<void> _saveToken() async {
    final token = _tokenController.text.trim();
    if (token.isNotEmpty) {
      await _storage.write(key: _tokenKey, value: token);
      setState(() => _tokenSaved = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _tokenSaved = false);
      });
    }
  }

  Future<void> _downloadModel() async {
    final selectedModel = AppConstants.availableModels[_selectedModelIndex];
    final token = _tokenController.text.trim();

    if (selectedModel.requiresToken && token.isEmpty) {
      setState(() {
        _error =
            'Dit model vereist een HuggingFace token. Vul uw token hierboven in.';
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

      if (token.isNotEmpty) {
        await _storage.write(key: _tokenKey, value: token);
      }

      await llm.loadModel(supportImage: selectedModel.supportsVision);

      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedModel.name} is geinstalleerd!',
              style: const TextStyle(fontSize: 18),
            ),
            backgroundColor: Colors.green,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final llm = context.read<LlmService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instellingen'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 28),
          tooltip: 'Terug',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: llm.isModelInstalled
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: llm.isModelInstalled
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    llm.isModelInstalled
                        ? Icons.check_circle
                        : Icons.warning,
                    color: llm.isModelInstalled
                        ? Colors.green
                        : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      llm.isModelInstalled
                          ? 'AI-model is geinstalleerd en klaar voor gebruik.'
                          : 'Nog geen AI-model geinstalleerd. Download hieronder een model.',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // HuggingFace token
            const Text(
              'HuggingFace Token',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nodig voor Gemma modellen. Maak gratis aan op huggingface.co',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tokenController,
                    style: const TextStyle(fontSize: 16),
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'hf_...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveToken,
                  child: Text(_tokenSaved ? 'Opgeslagen!' : 'Opslaan'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Model selection
            const Text(
              'AI-model',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kies en download een model. Dit vervangt het huidige model.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),

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
                              Expanded(
                                child: Text(
                                  model.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
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

            const SizedBox(height: 16),

            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _downloadProgress / 100,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '${_downloadProgress.toStringAsFixed(0)}% gedownload',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: _downloadModel,
                  icon: const Icon(Icons.download, size: 28),
                  label: Text(
                    llm.isModelInstalled
                        ? 'Ander model downloaden'
                        : 'Download starten',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            // App info
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'AIPA v1.0.0',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
