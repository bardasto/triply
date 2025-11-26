/// Model representing a chat message in the AI chat.
class ChatMessage {
  final String? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? tripData;
  final bool isNew;

  const ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.tripData,
    this.isNew = false,
  });

  bool get hasTrip => tripData != null;

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    Map<String, dynamic>? tripData,
    bool? isNew,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      tripData: tripData ?? this.tripData,
      isNew: isNew ?? this.isNew,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'trip_data': tripData,
    };
  }

  /// Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      text: json['text'] as String? ?? '',
      isUser: json['is_user'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      tripData: json['trip_data'] as Map<String, dynamic>?,
      isNew: false,
    );
  }
}
