import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSpeak;

  const ChatBubble({
    super.key,
    required this.message,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
        margin: EdgeInsets.only(
          left: isUser ? 40 : 8,
          right: isUser ? 8 : 40,
          top: 4,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.5,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (!isUser && message.text.isNotEmpty && onSpeak != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: IconButton(
                  onPressed: onSpeak,
                  icon: Icon(
                    Icons.volume_up,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Voorlezen',
                  iconSize: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
