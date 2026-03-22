import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../models/task_category.dart';
import '../providers/chat_provider.dart';
import '../services/llm_service.dart';
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
                MessageInput(
                  textController: _textController,
                  onSend: (text) => provider.sendMessage(text),
                  isGenerating: provider.isGenerating,
                  isListening: _isListening,
                  speechAvailable: _speechAvailable,
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
