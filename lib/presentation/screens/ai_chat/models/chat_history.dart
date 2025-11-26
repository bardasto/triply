import 'chat_message.dart';
import 'chat_mode.dart';

/// Model representing a chat session with history.
class ChatHistory {
  final String id;
  final String title;
  final ChatMode mode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  const ChatHistory({
    required this.id,
    required this.title,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  /// Get a preview of the last user message
  String get preview {
    final userMessages = messages.where((m) => m.isUser).toList();
    if (userMessages.isEmpty) return 'New conversation';
    return userMessages.last.text;
  }

  /// Check if this is an empty/new chat
  bool get isEmpty => messages.where((m) => m.isUser).isEmpty;

  ChatHistory copyWith({
    String? id,
    String? title,
    ChatMode? mode,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatHistory(
      id: id ?? this.id,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  /// Convert to JSON for Supabase storage
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'mode': mode.name,
      'messages': messages.map((m) => m.toJson()).toList(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from Supabase JSON response
  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];
    final modeStr = json['mode'] as String? ?? 'tripGeneration';

    return ChatHistory(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      mode: ChatMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => ChatMode.tripGeneration,
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      messages: messagesJson
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Create a new empty chat session
  factory ChatHistory.newChat({
    required String id,
    required ChatMode mode,
  }) {
    final now = DateTime.now();
    return ChatHistory(
      id: id,
      title: 'New Chat',
      mode: mode,
      createdAt: now,
      updatedAt: now,
      messages: [
        ChatMessage(
          text: mode.welcomeMessage,
          isUser: false,
          timestamp: now,
          isNew: true,
        ),
      ],
    );
  }
}
