import 'package:flutter/material.dart';
import 'voice_button.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController textController;
  final void Function(String text) onSend;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onSearchPressed;
  final bool isGenerating;
  final bool isListening;
  final bool speechAvailable;
  final bool visionAvailable;
  final VoidCallback? onVoicePressed;
  final VoidCallback? onStopGeneration;

  const MessageInput({
    super.key,
    required this.textController,
    required this.onSend,
    this.onCameraPressed,
    this.onSearchPressed,
    required this.isGenerating,
    required this.isListening,
    required this.speechAvailable,
    this.visionAvailable = false,
    this.onVoicePressed,
    this.onStopGeneration,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _focusNode = FocusNode();

  void _handleSend() {
    final text = widget.textController.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    widget.textController.clear();
    _focusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Action buttons row (camera, search)
            Row(
              children: [
                if (widget.visionAvailable)
                  _ActionChip(
                    icon: Icons.camera_alt,
                    label: 'Foto',
                    onPressed: widget.onCameraPressed,
                  ),
                if (widget.visionAvailable) const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.search,
                  label: 'Zoeken',
                  onPressed: widget.onSearchPressed,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Input row
            Row(
              children: [
                VoiceButton(
                  isListening: widget.isListening,
                  isAvailable: widget.speechAvailable,
                  onPressed: widget.onVoicePressed,
                ),
                if (widget.speechAvailable) const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: widget.textController,
                    focusNode: _focusNode,
                    style: const TextStyle(fontSize: 18),
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Typ uw vraag...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.isGenerating)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: IconButton(
                      onPressed: widget.onStopGeneration,
                      icon: const Icon(Icons.stop_circle, size: 32),
                      color: Colors.red,
                      tooltip: 'Stop',
                    ),
                  )
                else
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: IconButton.filled(
                      onPressed: widget.textController.text.trim().isEmpty
                          ? null
                          : _handleSend,
                      icon: const Icon(Icons.send, size: 28),
                      tooltip: 'Verstuur',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
