import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../presentation/screens/ai_chat/models/chat_history.dart';
import '../../presentation/screens/ai_chat/models/chat_mode.dart';

/// Service for storing and retrieving chat history from Supabase.
///
/// SECURITY: This service implements defense-in-depth with:
/// 1. Client-side authentication checks
/// 2. Explicit user_id filtering in all queries
/// 3. Server-side RLS policies (required in Supabase)
/// 4. Input validation and sanitization
///
/// Required Supabase table schema:
/// ```sql
/// -- Create table
/// CREATE TABLE chat_history (
///   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
///   user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
///   title TEXT NOT NULL DEFAULT 'New Chat',
///   mode TEXT NOT NULL DEFAULT 'tripGeneration',
///   messages JSONB NOT NULL DEFAULT '[]'::jsonb,
///   created_at TIMESTAMPTZ DEFAULT NOW(),
///   updated_at TIMESTAMPTZ DEFAULT NOW()
/// );
///
/// -- Enable RLS (CRITICAL!)
/// ALTER TABLE chat_history ENABLE ROW LEVEL SECURITY;
///
/// -- Force RLS for table owner too (extra security)
/// ALTER TABLE chat_history FORCE ROW LEVEL SECURITY;
///
/// -- Separate policies for each operation (more secure than single policy)
/// CREATE POLICY "Users can view own chats"
///   ON chat_history FOR SELECT
///   USING (auth.uid() = user_id);
///
/// CREATE POLICY "Users can insert own chats"
///   ON chat_history FOR INSERT
///   WITH CHECK (auth.uid() = user_id);
///
/// CREATE POLICY "Users can update own chats"
///   ON chat_history FOR UPDATE
///   USING (auth.uid() = user_id)
///   WITH CHECK (auth.uid() = user_id);
///
/// CREATE POLICY "Users can delete own chats"
///   ON chat_history FOR DELETE
///   USING (auth.uid() = user_id);
///
/// -- Indexes for performance
/// CREATE INDEX idx_chat_history_user_id ON chat_history(user_id);
/// CREATE INDEX idx_chat_history_updated_at ON chat_history(updated_at DESC);
/// CREATE INDEX idx_chat_history_user_updated ON chat_history(user_id, updated_at DESC);
/// ```
class ChatHistoryStorageService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'chat_history';

  // Validation constants
  static const int _maxTitleLength = 100;
  static const int _maxMessageLength = 10000;
  static const int _maxMessagesPerChat = 500;

  /// Get current authenticated user or throw
  static User _requireAuth() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user;
  }

  /// Sanitize text input to prevent injection
  static String _sanitizeText(String text, int maxLength) {
    if (text.isEmpty) return text;

    // Trim and limit length
    String sanitized = text.trim();
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    // Remove null bytes and control characters (except newlines and tabs)
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    return sanitized;
  }

  /// Validate chat mode
  static bool _isValidMode(String mode) {
    return ChatMode.values.any((m) => m.name == mode);
  }

  /// Create a new chat session
  static Future<ChatHistory> createChat(ChatMode mode) async {
    final user = _requireAuth();

    final now = DateTime.now();
    final welcomeMessage = {
      'text': _sanitizeText(mode.welcomeMessage, _maxMessageLength),
      'is_user': false,
      'timestamp': now.toIso8601String(),
      'trip_data': null,
    };

    try {
      final response = await _supabase
          .from(_tableName)
          .insert({
            'user_id': user.id,
            'title': 'New Chat',
            'mode': mode.name,
            'messages': [welcomeMessage],
          })
          .select()
          .single();

      return ChatHistory.fromJson(response);
    } catch (e) {
      debugPrint('Failed to create chat: $e');
      throw Exception('Failed to create chat');
    }
  }

  /// Get all chat sessions for current user
  static Future<List<ChatHistory>> getAllChats() async {
    final user = _requireAuth();

    try {
      // SECURITY: Explicit user_id filter as defense-in-depth
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', user.id)  // Defense-in-depth
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => ChatHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading chats: $e');
      return [];
    }
  }

  /// Get chats filtered by mode
  static Future<List<ChatHistory>> getChatsByMode(ChatMode mode) async {
    final user = _requireAuth();

    try {
      // SECURITY: Explicit user_id filter
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', user.id)  // Defense-in-depth
          .eq('mode', mode.name)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => ChatHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading chats by mode: $e');
      return [];
    }
  }

  /// Get a single chat by ID
  static Future<ChatHistory?> getChatById(String chatId) async {
    final user = _requireAuth();

    // SECURITY: Validate UUID format
    if (!_isValidUuid(chatId)) {
      debugPrint('Invalid chat ID format');
      return null;
    }

    try {
      // SECURITY: Filter by BOTH id AND user_id
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', chatId)
          .eq('user_id', user.id)  // Defense-in-depth - prevents accessing other users' chats
          .maybeSingle();

      if (response == null) return null;
      return ChatHistory.fromJson(response);
    } catch (e) {
      debugPrint('Error loading chat: $e');
      return null;
    }
  }

  /// Update chat messages and title
  static Future<ChatHistory> updateChat(ChatHistory chat) async {
    final user = _requireAuth();

    // SECURITY: Validate UUID format
    if (!_isValidUuid(chat.id)) {
      throw Exception('Invalid chat ID');
    }

    // SECURITY: Validate and limit messages
    if (chat.messages.length > _maxMessagesPerChat) {
      throw Exception('Too many messages');
    }

    // Generate and sanitize title
    String title = _sanitizeText(chat.title, _maxTitleLength);
    if (title == 'New Chat') {
      final userMessages = chat.messages.where((m) => m.isUser).toList();
      if (userMessages.isNotEmpty) {
        title = _generateTitle(userMessages.first.text);
      }
    }

    // Sanitize messages
    final sanitizedMessages = chat.messages.map((m) {
      final json = m.toJson();
      json['text'] = _sanitizeText(json['text'] as String? ?? '', _maxMessageLength);
      return json;
    }).toList();

    try {
      // SECURITY: Filter by BOTH id AND user_id
      final response = await _supabase
          .from(_tableName)
          .update({
            'title': title,
            'messages': sanitizedMessages,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', chat.id)
          .eq('user_id', user.id)  // Defense-in-depth - prevents updating other users' chats
          .select()
          .single();

      return ChatHistory.fromJson(response);
    } catch (e) {
      debugPrint('Failed to update chat: $e');
      throw Exception('Failed to update chat');
    }
  }

  /// Delete a chat session
  static Future<void> deleteChat(String chatId) async {
    final user = _requireAuth();

    // SECURITY: Validate UUID format
    if (!_isValidUuid(chatId)) {
      throw Exception('Invalid chat ID');
    }

    try {
      // SECURITY: Filter by BOTH id AND user_id
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', chatId)
          .eq('user_id', user.id);  // Defense-in-depth - prevents deleting other users' chats
    } catch (e) {
      debugPrint('Failed to delete chat: $e');
      throw Exception('Failed to delete chat');
    }
  }

  /// Delete all chats for current user
  static Future<void> deleteAllChats() async {
    final user = _requireAuth();

    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('Failed to delete all chats: $e');
      throw Exception('Failed to delete all chats');
    }
  }

  /// Validate UUID format
  static bool _isValidUuid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(uuid);
  }

  /// Generate a title from the user's first message
  static String _generateTitle(String message) {
    String title = _sanitizeText(message, _maxTitleLength);

    // Remove line breaks and extra spaces
    title = title.replaceAll(RegExp(r'\s+'), ' ');

    // Limit to 50 characters for display
    if (title.length > 50) {
      title = '${title.substring(0, 47)}...';
    }

    return title.isEmpty ? 'New Chat' : title;
  }

  /// Subscribe to real-time changes
  static RealtimeChannel subscribeToChats(
    void Function(List<ChatHistory>) onData,
  ) {
    final user = _requireAuth();

    final channel = _supabase
        .channel('chat_history_${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _tableName,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) async {
            final chats = await getAllChats();
            onData(chats);
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from real-time changes
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
