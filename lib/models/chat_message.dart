import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.role,
    required this.text,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();
}
