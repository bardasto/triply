import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/services/trip_generation_api.dart';
import '../../../core/services/ai_trips_storage_service.dart';
import '../../../core/services/ai_places_storage_service.dart';
import '../../../core/services/chat_history_storage_service.dart';
import '../../../core/services/streaming_trip_service.dart';
import '../../../core/services/active_streaming_manager.dart';
import 'models/chat_message.dart';
import 'models/chat_history.dart';
import 'models/chat_mode.dart';
import 'theme/ai_chat_theme.dart';
import 'theme/ai_chat_prompts.dart';
import 'widgets/ai_generated_trip_view.dart';
import 'widgets/chat/chat_header.dart';
import 'widgets/chat/chat_input.dart';
import 'widgets/chat/message_bubble.dart';
import 'widgets/chat/suggestion_list.dart';
import 'widgets/chat/typing_indicator.dart';
import 'widgets/chat/trip_duration_selector.dart';
import 'widgets/sidebar/chat_sidebar.dart';
import 'widgets/trip_card/generated_trip_card.dart';
import 'widgets/place_card/generated_place_card.dart';
import 'widgets/streaming/streaming_trip_card.dart';
import '../home/widgets/trip_details/place_details_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Current chat state
  ChatHistory? _currentChat;
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showSuggestions = true;
  double _generationProgress = 0.0;
  bool _isHistoryOpen = false;
  bool _isLoading = true;
  bool _isSaving = false;

  // Trip creation from places state
  Map<String, dynamic>? _pendingTripPlaceData;

  // Streaming support - enabled for trip requests only
  StreamingTripState? _streamingState;
  bool _showStreamingSkeleton = false;
  bool _isTripGeneration = false; // True when generating a trip (hide typing indicator)

  // Global streaming manager for background streaming
  final _streamingManager = ActiveStreamingManager();

  ChatMode _currentMode = ChatMode.tripGeneration;
  List<ChatHistory> _chatHistory = [];

  late AnimationController _welcomeAnimationController;
  late Animation<double> _welcomeFadeAnimation;
  late Animation<Offset> _welcomeSlideAnimation;

  late AnimationController _historyAnimationController;
  late Animation<double> _historySlideAnimation;

  late List<String> _currentSuggestions;

  @override
  void initState() {
    super.initState();

    _currentSuggestions = AiChatPrompts.getRandomSuggestions(count: 3);

    _welcomeAnimationController = AnimationController(
      vsync: this,
      duration: AiChatTheme.welcomeAnimationDuration,
    );

    _welcomeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeAnimationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeOutQuart,
    ));

    _historyAnimationController = AnimationController(
      vsync: this,
      duration: AiChatTheme.sidebarAnimationDuration,
    );

    _historySlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _historyAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _messageController.addListener(_onMessageTextChanged);
    _focusNode.addListener(_onFocusChanged);

    // Initialize chat
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Load chat history
      await _loadChatHistory();

      // Check for recent chat session (within 30 minutes)
      final lastChatId = await ChatHistoryStorageService.getLastChatSession();

      if (lastChatId != null) {
        // Try to load the last chat
        final lastChat = await ChatHistoryStorageService.getChatById(lastChatId);

        if (lastChat != null) {
          // Restore the last chat session
          debugPrint('🔄 Restoring last chat session: ${lastChat.id}');
          if (mounted) {
            setState(() {
              _currentChat = lastChat;
              _messages = List.from(lastChat.messages);
              _currentMode = lastChat.mode;
              _showSuggestions = lastChat.isEmpty;
              _currentSuggestions = AiChatPrompts.getRandomSuggestions(count: 3);
              _isLoading = false;
            });

            // Check if there's active streaming for this chat
            _restoreStreamingIfNeeded(lastChat.id);

            Future.delayed(const Duration(milliseconds: 100), () {
              _welcomeAnimationController.forward();
            });
            _scrollToBottom(delay: 200);
          }
          return;
        }
      }

      // No recent session or chat not found - create a new chat
      await _createNewChat(animate: false);

      if (mounted) {
        setState(() => _isLoading = false);
        Future.delayed(const Duration(milliseconds: 100), () {
          _welcomeAnimationController.forward();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Fallback to local-only mode
        _messages = [
          ChatMessage(
            text: _currentMode.welcomeMessage,
            isUser: false,
            timestamp: DateTime.now(),
            isNew: true,
          ),
        ];
        Future.delayed(const Duration(milliseconds: 100), () {
          _welcomeAnimationController.forward();
        });
      }
    }
  }

  /// Restore streaming UI if there's active streaming for the current chat
  void _restoreStreamingIfNeeded(String chatId) {
    // Check for completed streaming first
    if (_streamingManager.hasCompletedStreaming(chatId)) {
      debugPrint('🌊 Found completed streaming for chat: $chatId');
      final tripData = _streamingManager.getCompletedTripData(chatId);
      final completionMessage = _streamingManager.getCompletionMessage(chatId);

      if (tripData != null) {
        // Add the trip messages to UI
        setState(() {
          _messages.add(ChatMessage(
            text: '',
            isUser: false,
            timestamp: DateTime.now(),
            tripData: tripData,
          ));
          if (completionMessage != null) {
            _messages.add(ChatMessage(
              text: completionMessage,
              isUser: false,
              timestamp: DateTime.now(),
              isNew: true,
            ));
          }
        });
        _saveCurrentChat();
        _streamingManager.clearCompletedData(chatId);
      }
      return;
    }

    // Check for active streaming
    if (_streamingManager.hasActiveStreaming(chatId)) {
      debugPrint('🌊 Restoring active streaming for chat: $chatId');

      // Get current state
      final state = _streamingManager.getStreamingState(chatId);

      setState(() {
        _streamingState = state;
        _showStreamingSkeleton = true;
        _isTyping = true;
        _isTripGeneration = true;
        _generationProgress = state?.progress ?? 0.0;
      });

      // Subscribe to state updates
      _streamingManager.addStateListener(_onStreamingStateUpdate);

      // Set completion callback
      _streamingManager.setOnComplete((tripData, message) {
        if (!mounted) return;
        _onStreamingComplete(tripData, message);
      });

      _streamingManager.setOnError((error) {
        if (!mounted) return;
        _onStreamingError(error);
      });
    }
  }

  void _onStreamingStateUpdate(StreamingTripState state) {
    if (!mounted) return;
    setState(() {
      _streamingState = state;
      _generationProgress = state.progress;
    });
  }

  void _onStreamingComplete(Map<String, dynamic> tripData, String message) {
    debugPrint('🌊 Streaming complete callback');

    // Save the trip to database
    AiTripsStorageService.saveTrip(tripData);

    // Check if we're still in the correct chat
    final activeChatId = _streamingManager.activeChatId;
    if (_currentChat?.id == activeChatId) {
      // Update UI directly
      setState(() {
        _isTyping = false;
        _isTripGeneration = false;
        _showStreamingSkeleton = false;
        _generationProgress = 1.0;
        _messages.add(ChatMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
          tripData: tripData,
        ));
        _messages.add(ChatMessage(
          text: message,
          isUser: false,
          timestamp: DateTime.now(),
          isNew: true,
        ));
      });
      _saveCurrentChat();
      _scrollToBottom();
      _streamingManager.clearCompletedData(activeChatId!);
    }

    // Cleanup listeners
    _streamingManager.removeStateListener(_onStreamingStateUpdate);
    HapticFeedback.heavyImpact();
  }

  void _onStreamingError(String error) {
    debugPrint('🌊 Streaming error callback: $error');

    if (_currentChat?.id == _streamingManager.activeChatId) {
      setState(() {
        _isTyping = false;
        _isTripGeneration = false;
        _showStreamingSkeleton = false;
        _generationProgress = 0.0;
        _messages.add(ChatMessage(
          text: _getFriendlyErrorMessage(error),
          isUser: false,
          timestamp: DateTime.now(),
          isNew: true,
        ));
      });
      _saveCurrentChat();
    }

    _streamingManager.removeStateListener(_onStreamingStateUpdate);
  }

  Future<void> _loadChatHistory() async {
    try {
      final history = await ChatHistoryStorageService.getAllChats();
      if (mounted) {
        setState(() => _chatHistory = history);
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  Future<void> _createNewChat({bool animate = true}) async {
    // Don't cancel streaming - let it complete in background and save to original chat
    final wasGenerating = _showStreamingSkeleton;
    if (wasGenerating) {
      debugPrint('🌊 Creating new chat while streaming - will save to original chat when complete');
    }

    try {
      final chat = await ChatHistoryStorageService.createChat(_currentMode);
      if (mounted) {
        // Mark first message as new for typewriter effect
        final messages = chat.messages.map((m) => m).toList();
        if (messages.isNotEmpty) {
          messages[0] = messages[0].copyWith(isNew: true);
        }

        setState(() {
          _currentChat = chat;
          _messages = messages;
          _showSuggestions = true;
          _currentSuggestions = AiChatPrompts.getRandomSuggestions(count: 3);
          _isTyping = false;
          _isTripGeneration = false;
          _generationProgress = 0.0;
          // Hide skeleton when switching, but streaming continues in background
          _showStreamingSkeleton = false;
        });

        // Reload history to include new chat
        await _loadChatHistory();

        if (animate) {
          _welcomeAnimationController.reset();
          _welcomeAnimationController.forward();
        }
      }
    } catch (e) {
      debugPrint('Error creating new chat: $e');
      // Fallback to local-only
      if (mounted) {
        setState(() {
          _currentChat = null;
          _messages = [
            ChatMessage(
              text: _currentMode.welcomeMessage,
              isUser: false,
              timestamp: DateTime.now(),
              isNew: true,
            ),
          ];
          _showSuggestions = true;
          _currentSuggestions = AiChatPrompts.getRandomSuggestions(count: 3);
        });
      }
    }
  }

  Future<void> _saveCurrentChat() async {
    if (_currentChat == null || _isSaving) return;

    _isSaving = true;
    try {
      final updatedChat = _currentChat!.copyWith(
        messages: _messages,
        updatedAt: DateTime.now(),
      );

      final savedChat = await ChatHistoryStorageService.updateChat(updatedChat);

      if (mounted) {
        setState(() {
          _currentChat = savedChat;
        });
        // Update history list
        await _loadChatHistory();
      }
    } catch (e) {
      debugPrint('Error saving chat: $e');
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _loadChat(ChatHistory history) async {
    HapticFeedback.selectionClick();

    // Remove listener from current streaming if any
    _streamingManager.removeStateListener(_onStreamingStateUpdate);

    // Don't cancel streaming - let it complete in background and save to original chat
    final wasGenerating = _showStreamingSkeleton;
    if (wasGenerating) {
      debugPrint('🌊 Switching chat while streaming - will save to original chat when complete');
    }

    setState(() {
      _currentChat = history;
      _messages = List.from(history.messages);
      _currentMode = history.mode;
      _showSuggestions = history.isEmpty;
      _currentSuggestions = AiChatPrompts.getRandomSuggestions(count: 3);
      _isTyping = false;
      _isTripGeneration = false;
      _generationProgress = 0.0;
      _showStreamingSkeleton = false;
      _streamingState = null;
    });

    // Check if this chat has active streaming and restore it
    _restoreStreamingIfNeeded(history.id);

    // Update last chat session to the newly selected chat
    ChatHistoryStorageService.saveLastChatSession(history.id);

    _toggleHistory();

    // Scroll to bottom after loading
    _scrollToBottom();
  }

  Future<void> _deleteChat(ChatHistory history) async {
    HapticFeedback.mediumImpact();

    try {
      await ChatHistoryStorageService.deleteChat(history.id);

      if (mounted) {
        // If deleting current chat, create a new one
        if (_currentChat?.id == history.id) {
          await _createNewChat(animate: false);
        }

        await _loadChatHistory();
      }
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }

  @override
  void dispose() {
    // Save current chat session for later restoration (within 30 min)
    if (_currentChat != null) {
      ChatHistoryStorageService.saveLastChatSession(_currentChat!.id);
    }

    _messageController.removeListener(_onMessageTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _welcomeAnimationController.dispose();
    _historyAnimationController.dispose();
    // Remove streaming listener but don't cancel - let it complete in background
    _streamingManager.removeStateListener(_onStreamingStateUpdate);
    super.dispose();
  }

  void _onMessageTextChanged() {
    // Text change listener kept for potential future use
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_showSuggestions) {
        setState(() => _showSuggestions = false);
      }
    }
  }

  void _toggleHistory() {
    setState(() => _isHistoryOpen = !_isHistoryOpen);
    if (_isHistoryOpen) {
      _historyAnimationController.forward();
    } else {
      _historyAnimationController.reverse();
    }
  }

  void _onHistoryDragUpdate(DragUpdateDetails details, double panelWidth) {
    final delta = -details.delta.dx / panelWidth;
    final newValue =
        (_historyAnimationController.value + delta).clamp(0.0, 1.0);
    _historyAnimationController.value = newValue;
  }

  void _onHistoryDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;

    if (velocity.abs() > 500) {
      if (velocity > 0) {
        _historyAnimationController.reverse();
        setState(() => _isHistoryOpen = false);
      } else {
        _historyAnimationController.forward();
        setState(() => _isHistoryOpen = true);
      }
      return;
    }

    if (_historyAnimationController.value < 0.05) {
      _historyAnimationController.forward();
      setState(() => _isHistoryOpen = true);
    } else if (_historyAnimationController.value > 0.95) {
      _historyAnimationController.reverse();
      setState(() => _isHistoryOpen = false);
    } else if (_historyAnimationController.value < 0.5) {
      _historyAnimationController.animateTo(0.0);
      setState(() => _isHistoryOpen = true);
    } else {
      _historyAnimationController.animateTo(1.0);
      setState(() => _isHistoryOpen = false);
    }
  }

  void _onModeSelected(ChatMode mode) async {
    if (_currentMode != mode) {
      setState(() {
        _currentMode = mode;
      });
      await _createNewChat();
    }
    _toggleHistory();
  }

  void _startNewChat() async {
    HapticFeedback.mediumImpact();
    // Clear last session since user explicitly wants a new chat
    await ChatHistoryStorageService.clearLastChatSession();
    await _createNewChat();
    _toggleHistory();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    _focusNode.unfocus();

    setState(() {
      _showSuggestions = false;
      _markAllMessagesAsOld();
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _generationProgress = 0.0;
    });

    // Save chat with user message
    _saveCurrentChat();

    _scrollToBottom();
    _generateTripFromMessage(messageText);
  }

  void _handleSuggestionTap(String suggestion) {
    setState(() => _showSuggestions = false);

    Future.delayed(const Duration(milliseconds: 150), () {
      _messageController.text = suggestion;
      _sendMessage();
    });
  }

  void _markAllMessagesAsOld() {
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].isNew) {
        _messages[i] = _messages[i].copyWith(isNew: false);
      }
    }
  }

  void _onTypewriterComplete(int messageIndex) {
    if (messageIndex < _messages.length) {
      setState(() {
        _messages[messageIndex] =
            _messages[messageIndex].copyWith(isNew: false);
      });
    }
  }

  /// Find the last generated trip in the chat messages
  Map<String, dynamic>? _findLastTripInChat() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].hasTrip) {
        return _messages[i].tripData;
      }
    }
    return null;
  }

  /// Build conversation context from previous messages for AI memory
  List<Map<String, dynamic>> _buildConversationContext() {
    final context = <Map<String, dynamic>>[];

    for (final message in _messages) {
      if (message.isUser && message.text.isNotEmpty) {
        // User message
        context.add({
          'role': 'user',
          'content': message.text,
        });
      } else if (message.hasSinglePlace && message.placeData != null) {
        // AI generated single place
        final data = message.placeData!;
        final place = data['place'] as Map<String, dynamic>?;
        final alternatives = data['alternatives'] as List<dynamic>?;

        if (place != null) {
          final places = <Map<String, dynamic>>[
            {
              'name': place['name'],
              'type': place['place_type'] ?? place['placeType'],
              'category': place['category'],
              'city': place['city'],
              'country': place['country'],
              'rating': place['rating'],
              'estimated_price': place['estimated_price'],
              'price_level': place['price_level'],
              'cuisine_types': place['cuisine_types'],
            },
          ];

          // Add alternatives
          if (alternatives != null) {
            for (final alt in alternatives) {
              if (alt is Map<String, dynamic>) {
                places.add({
                  'name': alt['name'],
                  'type': alt['place_type'] ?? alt['placeType'],
                  'city': alt['city'] ?? place['city'],
                  'country': alt['country'] ?? place['country'],
                  'rating': alt['rating'],
                  'estimated_price': alt['estimated_price'],
                });
              }
            }
          }

          context.add({
            'role': 'assistant',
            'type': 'places',
            'places': places,
            'city': place['city'],
            'country': place['country'],
          });
        }
      } else if (message.hasTrip && message.tripData != null) {
        // AI generated trip
        final data = message.tripData!;
        final itinerary = data['itinerary'] as List<dynamic>?;
        final places = <Map<String, dynamic>>[];

        if (itinerary != null) {
          for (final day in itinerary) {
            if (day is Map<String, dynamic>) {
              final dayPlaces = day['places'] as List<dynamic>?;
              if (dayPlaces != null) {
                for (final place in dayPlaces) {
                  if (place is Map<String, dynamic>) {
                    places.add({
                      'name': place['name'],
                      'type': place['type'] ?? place['category'],
                      'rating': place['rating'],
                      'day': day['day'],
                    });
                  }
                }
              }
            }
          }
        }

        context.add({
          'role': 'assistant',
          'type': 'trip',
          'city': data['city'],
          'country': data['country'],
          'duration_days': data['duration_days'],
          'places': places,
        });
      }
    }

    return context;
  }

  /// Pre-classify query to determine if it's likely a trip or single place request
  /// This allows us to use streaming for trips (which benefits from progressive UI)
  /// and regular API for single places (which streaming doesn't support well)
  bool _isLikelyTripRequest(String query) {
    final lowerQuery = query.toLowerCase();

    // Keywords that indicate a TRIP request (multi-day itinerary)
    final tripKeywords = [
      'trip', 'itinerary', 'travel', 'vacation', 'holiday',
      'day trip', 'days', 'week', 'weekend',
      'plan', 'schedule', 'route',
      'visit multiple', 'tour',
      // Patterns like "3 days", "5-day", etc.
    ];

    // Keywords that indicate a SINGLE PLACE request
    final placeKeywords = [
      'restaurant', 'cafe', 'coffee', 'bar', 'pub', 'club',
      'hotel', 'hostel', 'accommodation', 'stay',
      'museum', 'gallery', 'park', 'beach', 'attraction',
      'shop', 'store', 'mall', 'market',
      'spa', 'gym', 'cinema', 'theater', 'theatre',
      'best', 'recommend', 'find', 'where can i',
      'good place', 'nice place', 'cool place',
      // Food-related
      'sushi', 'ramen', 'pizza', 'burger', 'steak', 'seafood',
      'breakfast', 'lunch', 'dinner', 'brunch',
      'vegan', 'vegetarian', 'halal', 'kosher',
    ];

    // Check for day patterns like "3 days", "5-day", "a week"
    final dayPattern = RegExp(r'\d+[\s-]*(day|days|night|nights|week|weeks)', caseSensitive: false);
    if (dayPattern.hasMatch(lowerQuery)) {
      return true;
    }

    // Count matches for each category
    int tripScore = 0;
    int placeScore = 0;

    for (final keyword in tripKeywords) {
      if (lowerQuery.contains(keyword)) tripScore++;
    }

    for (final keyword in placeKeywords) {
      if (lowerQuery.contains(keyword)) placeScore++;
    }

    debugPrint('🔍 Query classification: tripScore=$tripScore, placeScore=$placeScore');

    // If trip keywords dominate or are present with no place keywords, it's a trip
    // If place keywords dominate, it's a single place
    // Default to single place for ambiguous queries (more common use case)
    return tripScore > placeScore && tripScore > 0;
  }

  Future<void> _generateTripFromMessage(String userMessage) async {
    // Build conversation context for AI memory
    final conversationContext = _buildConversationContext();
    debugPrint('📚 Building context: ${conversationContext.length} entries from ${_messages.length} messages');

    // Pre-classify the query
    final isTrip = _isLikelyTripRequest(userMessage);
    debugPrint('🔍 Query type: ${isTrip ? "TRIP" : "SINGLE PLACE"}');

    // Use streaming only for trip requests
    if (isTrip) {
      // Mark as trip generation to hide TypingIndicator completely
      _isTripGeneration = true;
      _streamingState = StreamingTripState();
      _showStreamingSkeleton = false;

      final streamingSuccess = await _generateTripWithStreaming(userMessage, conversationContext);
      if (streamingSuccess) return;
      // If streaming failed, fall through to regular generation
      debugPrint('🌊 Streaming failed, falling back to regular API');
      _cleanupStreaming();
      // Keep _isTripGeneration = true so TypingIndicator stays hidden during fallback
    }

    // Regular (non-streaming) generation for single places or as fallback
    await _generateTripRegular(userMessage, conversationContext);
  }

  /// Generate trip using SSE streaming for real-time updates
  /// Now uses global ActiveStreamingManager for background streaming
  Future<bool> _generateTripWithStreaming(
    String userMessage,
    List<Map<String, dynamic>> conversationContext,
  ) async {
    final completer = Completer<bool>();
    final chatId = _currentChat?.id;

    if (chatId == null) {
      debugPrint('🌊 No current chat ID, cannot start streaming');
      return false;
    }

    try {
      debugPrint('🌊 Starting streaming trip generation for chat: $chatId');

      // Add AI acknowledgment message before skeleton
      const acknowledgmentText = "Let me create the perfect trip for you...";
      if (mounted) {
        setState(() {
          // Temporarily hide typing indicator while showing acknowledgment
          _isTyping = false;
          _messages.add(ChatMessage(
            text: acknowledgmentText,
            isUser: false,
            timestamp: DateTime.now(),
            isNew: true,
          ));
        });
        _scrollToBottom();
        // Save chat with acknowledgment
        _saveCurrentChat();
      }

      // Wait for typewriter animation to complete before showing skeleton
      // TypewriterText uses 10ms per character
      const animationDuration = acknowledgmentText.length * 10 + 200; // +200ms buffer
      await Future.delayed(const Duration(milliseconds: animationDuration));

      if (!mounted) return false;

      // NOW show the streaming skeleton card
      if (mounted) {
        setState(() {
          _isTyping = true;
          _showStreamingSkeleton = true;
        });
      }

      // Subscribe to state updates from manager
      _streamingManager.addStateListener(_onStreamingStateUpdate);

      // Capture original chat and messages for saving when complete
      final originalChat = _currentChat;
      final originalMessages = List<ChatMessage>.from(_messages);

      // Start streaming via global manager
      await _streamingManager.startStreaming(
        chatId: chatId,
        query: userMessage,
        conversationContext: conversationContext.isNotEmpty ? conversationContext : null,
        onComplete: (tripData, message) async {
          HapticFeedback.heavyImpact();
          tripData['original_query'] = userMessage;

          // Save trip to Supabase (ai_generated_trips table)
          try {
            debugPrint('💾 Saving streaming trip to Supabase...');
            final savedTrip = await AiTripsStorageService.saveTrip(tripData);
            debugPrint('✅ Trip saved successfully with id: ${savedTrip['id']}');
          } catch (e) {
            debugPrint('❌ Error saving trip to Supabase: $e');
            // Continue anyway - trip is still shown in chat
          }

          // Check if we're still in the same chat
          final isCorrectChat = _currentChat?.id == chatId;

          if (isCorrectChat && mounted) {
            // Still in the same chat - update UI directly
            setState(() {
              _isTyping = false;
              _isTripGeneration = false;
              _showStreamingSkeleton = false;
              _generationProgress = 1.0;
              _messages.add(ChatMessage(
                text: '',
                isUser: false,
                timestamp: DateTime.now(),
                tripData: tripData,
              ));
              _messages.add(ChatMessage(
                text: message,
                isUser: false,
                timestamp: DateTime.now(),
                isNew: true,
              ));
            });
            _saveCurrentChat();
            _scrollToBottom();
            _streamingManager.clearCompletedData(chatId);
          } else {
            // User switched - save to original chat
            debugPrint('🌊 Trip completed but user switched chat');
            originalMessages.add(ChatMessage(
              text: '',
              isUser: false,
              timestamp: DateTime.now(),
              tripData: tripData,
            ));
            originalMessages.add(ChatMessage(
              text: message,
              isUser: false,
              timestamp: DateTime.now(),
            ));

            if (originalChat != null) {
              final updatedChat = originalChat.copyWith(
                messages: originalMessages,
                updatedAt: DateTime.now(),
              );
              ChatHistoryStorageService.updateChat(updatedChat);
              _loadChatHistory();
            }
          }

          _streamingManager.removeStateListener(_onStreamingStateUpdate);
          if (!completer.isCompleted) completer.complete(true);
        },
        onError: (error) {
          debugPrint('🌊 Streaming error: $error');
          _streamingManager.removeStateListener(_onStreamingStateUpdate);

          if (_currentChat?.id == chatId && mounted) {
            setState(() {
              _isTyping = false;
              _isTripGeneration = false;
              _showStreamingSkeleton = false;
              _generationProgress = 0.0;
            });
          }

          if (!completer.isCompleted) completer.complete(false);
        },
      );

      return await completer.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          debugPrint('🌊 Streaming timeout');
          _streamingManager.cancelStreaming();
          return false;
        },
      );
    } catch (e) {
      debugPrint('🌊 Streaming exception: $e');
      _cleanupStreaming();
      return false;
    }
  }

  void _cleanupStreaming() {
    _streamingManager.removeStateListener(_onStreamingStateUpdate);
    _streamingState = null;
    _showStreamingSkeleton = false;
  }

  /// Cancel current streaming generation
  void _cancelStreaming() {
    HapticFeedback.mediumImpact();
    _streamingManager.cancelStreaming();
    _cleanupStreaming();
    setState(() {
      _isTyping = false;
      _isTripGeneration = false;
      _generationProgress = 0.0;
      _messages.add(ChatMessage(
        text: 'Generation cancelled.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  /// Regular (non-streaming) trip generation
  Future<void> _generateTripRegular(
    String userMessage,
    List<Map<String, dynamic>> conversationContext,
  ) async {
    try {
      _animateProgress();

      Map<String, dynamic> result;

      // Always use flexible generation with context
      result = await TripGenerationApi.generateFlexibleTrip(
        query: userMessage,
        conversationContext: conversationContext.isNotEmpty ? conversationContext : null,
      );
      result['original_query'] = userMessage;

      // Check if this is a single place or trip
      final isSinglePlace = result['type'] == 'single_place';

      if (isSinglePlace) {
        // Save as place to the places table
        await AiPlacesStorageService.savePlace(result);
      } else {
        // Save as trip to the trips table
        await AiTripsStorageService.saveTrip(result);
      }

      if (mounted) {
        HapticFeedback.heavyImpact();

        String completionMessage;

        if (isSinglePlace) {
          final place = result['place'] as Map<String, dynamic>? ?? {};
          final placeName = place['name'] as String? ?? 'the place';
          completionMessage = _getPlaceCompletionMessage(placeName);
        } else {
          final location = result['location'] as String? ??
              result['city'] as String? ??
              result['destination'] as String? ??
              'your destination';
          completionMessage = AiChatPrompts.getRandomCompletionMessage(location);
        }

        setState(() {
          _generationProgress = 1.0;
          _isTyping = false;
          _isTripGeneration = false;

          if (isSinglePlace) {
            _messages.add(ChatMessage(
              text: '',
              isUser: false,
              timestamp: DateTime.now(),
              placeData: result,
            ));
            // Completion message with Create Trip button
            _messages.add(ChatMessage(
              text: completionMessage,
              isUser: false,
              timestamp: DateTime.now(),
              isNew: true,
              canCreateTrip: true,
              placeData: result, // Store place data for trip creation
            ));
          } else {
            _messages.add(ChatMessage(
              text: '',
              isUser: false,
              timestamp: DateTime.now(),
              tripData: result,
            ));
            _messages.add(ChatMessage(
              text: completionMessage,
              isUser: false,
              timestamp: DateTime.now(),
              isNew: true,
            ));
          }
        });

        // Save chat with AI response
        _saveCurrentChat();

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: _getFriendlyErrorMessage(e.toString()),
            isUser: false,
            timestamp: DateTime.now(),
            isNew: true,
          ));
          _isTyping = false;
          _isTripGeneration = false;
          _generationProgress = 0.0;
        });

        // Save chat with error message
        _saveCurrentChat();
      }
    }
  }

  String _getFriendlyErrorMessage(String error) {
    // Network/connection errors
    if (error.contains('SocketException') ||
        error.contains('Connection') ||
        error.contains('network')) {
      return "I'm having trouble connecting right now. Please check your internet connection and try again.";
    }

    // Timeout errors
    if (error.contains('timeout') || error.contains('Timeout')) {
      return "That took longer than expected. Please try again with a simpler request.";
    }

    // API/parsing errors
    if (error.contains('type') && error.contains('subtype')) {
      return "I had trouble understanding that request. Could you try rephrasing it? For example: 'Plan a 3-day trip to Paris' or 'Find a cozy cafe in Rome'.";
    }

    // Generic friendly messages
    final friendlyMessages = [
      "I couldn't quite process that. Could you try asking in a different way?",
      "Something went wrong on my end. Try asking again or rephrase your request.",
      "I'm having a bit of trouble with that. Could you try a simpler request like '3 days in Tokyo' or 'Best restaurants in Barcelona'?",
      "Hmm, I couldn't handle that request. Try being more specific about your destination or what you're looking for.",
    ];

    return friendlyMessages[DateTime.now().millisecond % friendlyMessages.length];
  }

  String _getPlaceCompletionMessage(String placeName) {
    final messages = [
      "I found $placeName for you! It looks like a great choice.\n\nWould you like me to create a full trip itinerary including this place?",
      "Here's $placeName - I think you'll love it!\n\nWant me to generate a complete trip with this spot?",
      "I've found the perfect spot: $placeName. Take a look!\n\nShall I create a full trip plan around this place?",
      "Check out $placeName - it matches what you're looking for!\n\nWould you like a complete trip itinerary with this destination?",
      "Based on your request, I recommend $placeName!\n\nWant me to build a full trip including this place?",
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  void _animateProgress() {
    _generationProgress = 0.0;

    final progressSteps = [0.15, 0.35, 0.55, 0.75, 0.90];
    final delays = [500, 800, 1000, 1200, 800];

    for (int i = 0; i < progressSteps.length; i++) {
      Future.delayed(
        Duration(milliseconds: delays.take(i + 1).reduce((a, b) => a + b)),
        () {
          if (mounted && _isTyping) {
            setState(() => _generationProgress = progressSteps[i]);
          }
        },
      );
    }
  }

  void _scrollToBottom({int delay = 100}) {
    Future.delayed(Duration(milliseconds: delay), () {
      if (_scrollController.hasClients) {
        // With reverse: true, "bottom" is at position 0
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openTripView(Map<String, dynamic> trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiGeneratedTripView(
          trip: trip,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _regenerateTrip(Map<String, dynamic> oldTrip) {
    final originalQuery = oldTrip['original_query'] as String?;
    if (originalQuery == null || originalQuery.isEmpty) return;

    setState(() {
      _messages.removeWhere((m) => m.tripData == oldTrip);
      _isTyping = true;
      _generationProgress = 0.0;
    });

    _scrollToBottom();
    _generateTripFromMessage(originalQuery);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          backgroundColor: AppColors.darkBackground,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              _buildMainContent(),
              ChatSidebar(
                slideAnimation: _historySlideAnimation,
                currentMode: _currentMode,
                chatHistory: _chatHistory,
                currentChatId: _currentChat?.id,
                onClose: _toggleHistory,
                onNewChat: _startNewChat,
                onModeSelected: _onModeSelected,
                onHistorySelected: _loadChat,
                onHistoryDeleted: _deleteChat,
                onDragUpdate: _onHistoryDragUpdate,
                onDragEnd: _onHistoryDragEnd,
                formatDate: _formatDate,
              ),
              _buildSwipeZone(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _historySlideAnimation,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final panelWidth = screenWidth * AiChatTheme.sidebarWidthFactor;

        return GestureDetector(
          onHorizontalDragUpdate: (details) =>
              _onHistoryDragUpdate(details, panelWidth),
          onHorizontalDragEnd: _onHistoryDragEnd,
          child: child,
        );
      },
      child: AnimatedBuilder(
        animation: _historySlideAnimation,
        builder: (context, child) {
          final screenWidth = MediaQuery.of(context).size.width;
          final panelWidth = screenWidth * AiChatTheme.sidebarWidthFactor;
          final offset = -panelWidth * (1 - _historySlideAnimation.value);
          final progress = 1 - _historySlideAnimation.value;

          final bgColor = Color.lerp(
            AppColors.darkBackground,
            AiChatTheme.lightBackground,
            progress,
          )!;

          return Transform.translate(
            offset: Offset(offset, 0),
            child: Container(
              color: bgColor,
              child: child,
            ),
          );
        },
        child: Builder(
          builder: (context) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final extraPadding = keyboardHeight > 0 ? 10.0 : 0.0;
            final bottomOffset = keyboardHeight + extraPadding;
            // Input height (~68) + safe area bottom when no keyboard
            final safeAreaBottom = MediaQuery.of(context).padding.bottom;
            final inputAreaHeight = 68.0 + (keyboardHeight > 0 ? 0 : safeAreaBottom);

            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: inputAreaHeight + bottomOffset),
                  child: _messages.length <= 1
                      ? _buildWelcomeScreen(0)
                      : SafeArea(
                          bottom: false,
                          child: _buildMessagesList(0),
                        ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _historySlideAnimation,
                    builder: (context, _) {
                      final progress = 1 - _historySlideAnimation.value;
                      final bgColor = Color.lerp(
                        AppColors.darkBackground,
                        AiChatTheme.lightBackground,
                        progress,
                      )!;
                      return ChatHeader(
                        showWelcome: _messages.length <= 1,
                        currentMode: _currentMode,
                        welcomeAnimation: _welcomeFadeAnimation,
                        onClose: () => Navigator.pop(context),
                        onMenuTap: _toggleHistory,
                        backgroundColor: bgColor,
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: bottomOffset,
                  child: SafeArea(
                    top: false,
                    maintainBottomViewPadding: true,
                    child: AnimatedBuilder(
                      animation: _historySlideAnimation,
                      builder: (context, _) {
                        final progress = 1 - _historySlideAnimation.value;
                        final bgColor = Color.lerp(
                          AppColors.darkBackground,
                          AiChatTheme.lightBackground,
                          progress,
                        )!;
                        return ChatInput(
                          controller: _messageController,
                          focusNode: _focusNode,
                          backgroundColor: bgColor,
                          onSend: _sendMessage,
                          onVoiceInput: () {
                            HapticFeedback.lightImpact();
                            // TODO: Voice input
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSwipeZone() {
    return AnimatedBuilder(
      animation: _historySlideAnimation,
      builder: (context, _) {
        if (_historySlideAnimation.value >= 1.0) {
          return const SizedBox.shrink();
        }
        final screenWidth = MediaQuery.of(context).size.width;
        final panelWidth = screenWidth * AiChatTheme.sidebarWidthFactor;
        final mainContentOffset =
            -panelWidth * (1 - _historySlideAnimation.value);

        return Positioned(
          top: 0,
          bottom: 0,
          left: mainContentOffset,
          width: screenWidth * 0.15,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) =>
                _onHistoryDragUpdate(details, panelWidth),
            onHorizontalDragEnd: _onHistoryDragEnd,
          ),
        );
      },
    );
  }

  Widget _buildWelcomeScreen(double bottomPadding) {
    return FadeTransition(
      opacity: _welcomeFadeAnimation,
      child: SlideTransition(
        position: _welcomeSlideAnimation,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: AiChatTheme.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: AiChatTheme.headerHeight + 16),
                if (_messages.isNotEmpty)
                  MessageBubble(
                    message: _messages.first,
                    useTypewriter: _messages.first.isNew,
                    onTypewriterComplete: () => _onTypewriterComplete(0),
                  ),
                const Spacer(),
                if (_showSuggestions)
                  SuggestionList(
                    suggestions: _currentSuggestions,
                    onSuggestionTap: _handleSuggestionTap,
                  ),
                SizedBox(height: bottomPadding + 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList(double bottomPadding) {
    // Total items: messages + typing indicator (if typing)
    final itemCount = _messages.length + (_isTyping ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Start from bottom - content lifts with keyboard automatically
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: AiChatTheme.headerHeight + 16,
        bottom: 16,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Reverse index: 0 = last item, itemCount-1 = first item
        final reversedIndex = itemCount - 1 - index;

        // Typing indicator or streaming card is the last item (reversedIndex == itemCount - 1 when _isTyping)
        if (_isTyping && reversedIndex == _messages.length) {
          // Show streaming card if we're in streaming mode AND skeleton should be visible
          // _showStreamingSkeleton is false during typewriter animation
          final hasActiveStreaming = _currentChat != null &&
              (_streamingManager.hasActiveStreaming(_currentChat!.id) || _showStreamingSkeleton);
          debugPrint('📺 UI Check: hasActiveStreaming=$hasActiveStreaming, _streamingState=${_streamingState != null}, _showStreamingSkeleton=$_showStreamingSkeleton, _isTripGeneration=$_isTripGeneration, progress=$_generationProgress');

          if (hasActiveStreaming && _streamingState != null) {
            // Streaming mode - show skeleton only when ready
            if (_showStreamingSkeleton) {
              return StreamingTripCard(
                state: _streamingState!,
                onCancel: _cancelStreaming,
              );
            }
            // During typewriter animation, show nothing (message is animating above)
            return const SizedBox.shrink();
          }

          // For trip generation (including fallback), hide the typing indicator completely
          if (_isTripGeneration) {
            return const SizedBox.shrink();
          }

          // Non-streaming mode (single places) - show regular typing indicator
          return TypingIndicator(progress: _generationProgress);
        }

        final message = _messages[reversedIndex];

        // Show trip duration selector for trip creation
        if (message.isTripCreationPrompt && message.placeData != null) {
          final place = message.placeData!['place'] as Map<String, dynamic>? ?? {};
          final city = place['city'] as String? ?? 'this destination';
          return TripDurationSelector(
            cityName: city,
            onDurationSelected: (days, {travelers, startDate}) => _onDurationSelected(
              days,
              travelers: travelers,
              startDate: startDate,
            ),
          );
        }

        // Show trip card (only if no text - pure card message)
        if (message.hasTrip && message.text.isEmpty) {
          return GeneratedTripCard(
            trip: message.tripData!,
            onTap: () => _openTripView(message.tripData!),
            onRegenerate: () => _regenerateTrip(message.tripData!),
          );
        }

        // Show single place card (only if no text - pure card message, not completion message)
        if (message.hasSinglePlace && message.text.isEmpty && !message.isTripCreationPrompt) {
          return GeneratedPlaceCard(
            placeData: message.placeData!,
            onTap: () => _openPlaceView(message.placeData!),
            onRegenerate: () => _regeneratePlace(message.placeData!),
            onAlternativeTap: (alt) => _openAlternativePlace(alt),
          );
        }

        // Check if this is a completion message after a place card (has text + canCreateTrip)
        // Only show Create Trip button after typewriter animation completes (!message.isNew)
        final showCreateTrip = message.canCreateTrip && !message.isUser && message.text.isNotEmpty && !message.isNew;

        return MessageBubble(
          message: message,
          useTypewriter: message.isNew && !message.isUser,
          onTypewriterComplete: () => _onTypewriterComplete(reversedIndex),
          onCreateTrip: showCreateTrip ? () => _onCreateTripFromMessage(reversedIndex) : null,
        );
      },
    );
  }

  void _openPlaceView(Map<String, dynamic> placeData) {
    final place = placeData['place'] as Map<String, dynamic>? ?? {};

    // Convert place data to format expected by PlaceDetailsScreen
    final placeForDetails = {
      'name': place['name'],
      'description': place['description'],
      'category': place['place_type'] ?? place['category'],
      'address': place['address'],
      'latitude': place['latitude'],
      'longitude': place['longitude'],
      'rating': place['rating'],
      'review_count': place['review_count'],
      'price_level': place['price_level'],
      'opening_hours': place['opening_hours'],
      'website': place['website'],
      'phone': place['phone'],
      'image_url': place['image_url'],
      'images': place['images'],
      'cuisine_types': place['cuisine_types'],
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaceDetailsScreen(
          place: placeForDetails,
          isDark: true,
        ),
      ),
    );
  }

  void _openAlternativePlace(Map<String, dynamic> alt) {
    // Convert alternative data to format expected by PlaceDetailsScreen
    // Include all available fields from alternative
    final placeForDetails = {
      'name': alt['name'],
      'description': alt['description'] ?? alt['why_alternative'] ?? '',
      'category': alt['place_type'] ?? 'place',
      'address': alt['address'],
      'city': alt['city'],
      'country': alt['country'],
      'rating': alt['rating'],
      'review_count': alt['review_count'],
      'price_level': alt['price_level'],
      'opening_hours': alt['opening_hours'],
      'is_open_now': alt['is_open_now'],
      'website': alt['website'],
      'phone': alt['phone'],
      'image_url': alt['image_url'],
      'images': alt['images'],
      'google_place_id': alt['google_place_id'],
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaceDetailsScreen(
          place: placeForDetails,
          isDark: true,
        ),
      ),
    );
  }

  void _regeneratePlace(Map<String, dynamic> oldPlace) {
    final originalQuery = oldPlace['original_query'] as String?;
    if (originalQuery == null || originalQuery.isEmpty) return;

    setState(() {
      _messages.removeWhere((m) => m.placeData == oldPlace);
      _isTyping = true;
      _generationProgress = 0.0;
    });

    _scrollToBottom();
    _generateTripFromMessage(originalQuery);
  }

  /// Handle "Create Trip" button press from message bubble
  void _onCreateTripFromMessage(int messageIndex) {
    final message = _messages[messageIndex];
    final placeData = message.placeData;

    if (placeData == null) return;

    HapticFeedback.mediumImpact();

    // Hide the Create Trip button by updating the message
    setState(() {
      _messages[messageIndex] = message.copyWith(canCreateTrip: false);
    });

    final place = placeData['place'] as Map<String, dynamic>? ?? {};
    final city = place['city'] as String? ?? '';

    if (city.isEmpty) {
      // Show error if city is missing
      setState(() {
        _messages.add(ChatMessage(
          text: "I couldn't determine the city from this place. Please try a different request.",
          isUser: false,
          timestamp: DateTime.now(),
          isNew: true,
        ));
      });
      _scrollToBottom();
      return;
    }

    // Store the place data for trip creation
    _pendingTripPlaceData = placeData;

    // Add message asking for duration
    setState(() {
      _markAllMessagesAsOld();
      _messages.add(ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        isTripCreationPrompt: true,
        placeData: placeData, // Pass place data for context
      ));
    });

    _saveCurrentChat();
    _scrollToBottom();
  }

  /// Handle duration selection for trip creation
  void _onDurationSelected(int days, {int? travelers, DateTime? startDate}) {
    HapticFeedback.mediumImpact();

    if (_pendingTripPlaceData == null) return;

    final placeData = _pendingTripPlaceData!;
    final place = placeData['place'] as Map<String, dynamic>? ?? {};
    final city = place['city'] as String? ?? '';
    final country = place['country'] as String? ?? '';
    final travelersCount = travelers ?? 2;

    // Clear pending state
    _pendingTripPlaceData = null;

    // Format date info if provided
    String dateInfo = '';
    if (startDate != null) {
      final endDate = startDate.add(Duration(days: days - 1));
      dateInfo = ' (${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month})';
    }

    // Add user message showing selection and AI response
    setState(() {
      _markAllMessagesAsOld();
      // Remove the duration selector message
      _messages.removeWhere((m) => m.isTripCreationPrompt);

      _messages.add(ChatMessage(
        text: 'Create a $days-day trip to $city$dateInfo for $travelersCount ${travelersCount == 1 ? 'person' : 'people'}',
        isUser: true,
        timestamp: DateTime.now(),
      ));

      // Mark as trip generation to hide TypingIndicator
      _isTripGeneration = true;
      _generationProgress = 0.0;

      // Initialize streaming state to prevent TypingIndicator from showing
      _streamingState = StreamingTripState();
      _showStreamingSkeleton = false;
    });

    _saveCurrentChat();
    _scrollToBottom();

    // Generate trip with context (streaming will add acknowledgment message)
    _generateTripFromContext(
      city: city,
      country: country,
      days: days,
      placeData: placeData,
      travelers: travelersCount,
    );
  }

  /// Generate a trip using conversation context and place data
  /// Now uses streaming for real-time skeleton display!
  Future<void> _generateTripFromContext({
    required String city,
    required String country,
    required int days,
    required Map<String, dynamic> placeData,
    int travelers = 2,
  }) async {
    final place = placeData['place'] as Map<String, dynamic>? ?? {};
    final placeName = place['name'] as String? ?? '';
    final placeType = place['place_type'] as String? ?? 'place';

    // Build query that includes the context
    final query = 'Create a $days-day trip to $city, $country for $travelers ${travelers == 1 ? 'person' : 'people'}. '
        'Make sure to include $placeName ($placeType) that I liked.';

    // Build conversation context
    final conversationContext = _buildConversationContext();

    debugPrint('📚 Creating trip from context: $city, $days days');
    debugPrint('📍 Must include: $placeName');

    // Use streaming for real-time updates (same as regular trip generation)
    final streamingSuccess = await _generateTripWithStreaming(query, conversationContext);

    if (!streamingSuccess) {
      // Fallback to regular API if streaming fails
      debugPrint('🌊 Streaming failed for context trip, falling back to regular API');
      await _generateTripFromContextFallback(
        city: city,
        country: country,
        days: days,
        placeData: placeData,
        travelers: travelers,
        query: query,
        conversationContext: conversationContext,
      );
    }
  }

  /// Fallback method if streaming fails for context-based trip generation
  Future<void> _generateTripFromContextFallback({
    required String city,
    required String country,
    required int days,
    required Map<String, dynamic> placeData,
    required int travelers,
    required String query,
    required List<Map<String, dynamic>> conversationContext,
  }) async {
    try {
      _animateProgress();

      final result = await TripGenerationApi.generateFlexibleTrip(
        query: query,
        conversationContext: conversationContext.isNotEmpty ? conversationContext : null,
      );
      result['original_query'] = query;

      // This should be a trip, not a single place
      final isSinglePlace = result['type'] == 'single_place';

      if (!isSinglePlace) {
        // Save as trip to the trips table
        await AiTripsStorageService.saveTrip(result);
      }

      if (mounted) {
        HapticFeedback.heavyImpact();

        final location = result['city'] as String? ?? city;
        final completionMessage = AiChatPrompts.getRandomCompletionMessage(location);

        setState(() {
          _generationProgress = 1.0;
          _isTyping = false;
          _isTripGeneration = false;

          if (isSinglePlace) {
            // Fallback if AI returned single place instead of trip
            _messages.add(ChatMessage(
              text: '',
              isUser: false,
              timestamp: DateTime.now(),
              placeData: result,
            ));
          } else {
            _messages.add(ChatMessage(
              text: '',
              isUser: false,
              timestamp: DateTime.now(),
              tripData: result,
            ));
          }

          _messages.add(ChatMessage(
            text: completionMessage,
            isUser: false,
            timestamp: DateTime.now(),
            isNew: true,
          ));
        });

        _saveCurrentChat();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: _getFriendlyErrorMessage(e.toString()),
            isUser: false,
            timestamp: DateTime.now(),
            isNew: true,
          ));
          _isTyping = false;
          _isTripGeneration = false;
          _generationProgress = 0.0;
        });

        _saveCurrentChat();
      }
    }
  }
}
