import 'chat_message.dart';

/// Model representing a chat history entry.
class ChatHistory {
  final String id;
  final String title;
  final DateTime timestamp;
  final List<ChatMessage> messages;
  final Map<String, dynamic>? generatedTrip;

  const ChatHistory({
    required this.id,
    required this.title,
    required this.timestamp,
    required this.messages,
    this.generatedTrip,
  });

  ChatHistory copyWith({
    String? id,
    String? title,
    DateTime? timestamp,
    List<ChatMessage>? messages,
    Map<String, dynamic>? generatedTrip,
  }) {
    return ChatHistory(
      id: id ?? this.id,
      title: title ?? this.title,
      timestamp: timestamp ?? this.timestamp,
      messages: messages ?? this.messages,
      generatedTrip: generatedTrip ?? this.generatedTrip,
    );
  }
}
