/// Model representing a chat message in the AI chat.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? tripData;
  final bool isNew;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.tripData,
    this.isNew = false,
  });

  bool get hasTrip => tripData != null;

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    Map<String, dynamic>? tripData,
    bool? isNew,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      tripData: tripData ?? this.tripData,
      isNew: isNew ?? this.isNew,
    );
  }
}
