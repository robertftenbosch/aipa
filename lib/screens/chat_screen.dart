import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/task_category.dart';
import '../providers/chat_provider.dart';
import '../services/llm_service.dart';
import '../services/search_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';

class ChatScreen extends StatefulWidget {
  final TaskCategory? category;

  const ChatScreen({super.key, this.category});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final SpeechService _speech = SpeechService();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize();
    if (mounted) {
      setState(() => _speechAvailable = available);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleListening(ChatProvider provider) {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (text, isFinal) {
          _textController.text = text;
          if (isFinal) {
            setState(() => _isListening = false);
            if (text.trim().isNotEmpty) {
              provider.sendMessage(text.trim());
              _textController.clear();
            }
          }
        },
      );
    }
  }

  Future<void> _pickImage(ChatProvider provider) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Foto kiezen',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, size: 32),
                title: const Text('Maak een foto',
                    style: TextStyle(fontSize: 20)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, size: 32),
                title: const Text('Kies uit bibliotheek',
                    style: TextStyle(fontSize: 20)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 768,
      maxHeight: 768,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    final description = _textController.text.trim();
    _textController.clear();

    await provider.sendImage(
      bytes,
      text: description.isNotEmpty
          ? description
          : 'Wat zie je op deze foto? Help mij alstublieft.',
    );
  }

  void _showSearchDialog(ChatProvider provider) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Zoeken op internet',
          style: TextStyle(fontSize: 24),
        ),
        content: TextField(
          controller: searchController,
          style: const TextStyle(fontSize: 18),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Bijv. "hoe HDMI kabel aansluiten"',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              Navigator.pop(context);
              provider.searchAndAsk(query.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Annuleren', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final query = searchController.text.trim();
              if (query.isNotEmpty) {
                Navigator.pop(context);
                provider.searchAndAsk(query);
              }
            },
            icon: const Icon(Icons.search),
            label: const Text('Zoeken', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = ChatProvider(
          llm: context.read<LlmService>(),
          tts: context.read<TtsService>(),
          search: context.read<SearchService>(),
          category: widget.category,
        );
        provider.initChat();
        return provider;
      },
      child: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          _scrollToBottom();

          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.category?.label ?? 'AIPA Chat',
              ),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 28),
                tooltip: 'Terug',
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: _buildMessageList(provider),
                ),
                if (provider.isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Zoeken op internet...',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                MessageInput(
                  textController: _textController,
                  onSend: (text) => provider.sendMessage(text),
                  onCameraPressed: () => _pickImage(provider),
                  onSearchPressed: () => _showSearchDialog(provider),
                  isGenerating: provider.isGenerating,
                  isListening: _isListening,
                  speechAvailable: _speechAvailable,
                  visionAvailable: provider.visionEnabled,
                  onVoicePressed: () => _toggleListening(provider),
                  onStopGeneration: provider.stopGeneration,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageList(ChatProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Even geduld...',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      );
    }

    if (provider.error != null && provider.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => provider.initChat(),
                child: const Text('Opnieuw proberen'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        return ChatBubble(
          message: message,
          onSpeak: message.role == MessageRole.assistant
              ? () => provider.speakMessage(message.text)
              : null,
        );
      },
    );
  }
}
