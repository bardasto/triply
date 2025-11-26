import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/services/trip_generation_api.dart';
import '../../../core/services/ai_trips_storage_service.dart';
import '../../../core/services/chat_history_storage_service.dart';
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
import 'widgets/sidebar/chat_sidebar.dart';
import 'widgets/trip_card/generated_trip_card.dart';

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

    // Initialize chat
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Load chat history
      await _loadChatHistory();

      // Create a new chat session
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
          _generationProgress = 0.0;
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

    setState(() {
      _currentChat = history;
      _messages = List.from(history.messages);
      _currentMode = history.mode;
      _showSuggestions = history.isEmpty;
      _currentSuggestions = AiChatPrompts.getRandomSuggestions(count: 3);
      _isTyping = false;
      _generationProgress = 0.0;
    });

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
    _messageController.removeListener(_onMessageTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _welcomeAnimationController.dispose();
    _historyAnimationController.dispose();
    super.dispose();
  }

  void _onMessageTextChanged() {
    if (_messageController.text.isNotEmpty && _showSuggestions) {
      setState(() => _showSuggestions = false);
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

  Future<void> _generateTripFromMessage(String userMessage) async {
    try {
      _animateProgress();

      // Check if there's an existing trip to modify
      final existingTrip = _findLastTripInChat();

      Map<String, dynamic> trip;

      if (existingTrip != null) {
        // Modify existing trip instead of generating new one
        trip = await TripGenerationApi.modifyTrip(
          existingTrip: existingTrip,
          modificationRequest: userMessage,
        );
        // Keep original query for reference
        trip['original_query'] = existingTrip['original_query'] ?? userMessage;
        trip['modification_history'] = [
          ...(existingTrip['modification_history'] as List? ?? []),
          userMessage,
        ];
      } else {
        // Generate new trip
        trip = await TripGenerationApi.generateFlexibleTrip(
          query: userMessage,
        );
        trip['original_query'] = userMessage;
      }

      await AiTripsStorageService.saveTrip(trip);

      if (mounted) {
        HapticFeedback.heavyImpact();

        final location = trip['location'] as String? ??
            trip['city'] as String? ??
            trip['destination'] as String? ??
            'your destination';
        final completionMessage = existingTrip != null
            ? AiChatPrompts.getRandomModificationMessage(location)
            : AiChatPrompts.getRandomCompletionMessage(location);

        setState(() {
          _generationProgress = 1.0;
          _isTyping = false;
          _messages.add(ChatMessage(
            text: '',
            isUser: false,
            timestamp: DateTime.now(),
            tripData: trip,
          ));
          _messages.add(ChatMessage(
            text: completionMessage,
            isUser: false,
            timestamp: DateTime.now(),
            isNew: true,
          ));
        });

        // Save chat with AI response
        _saveCurrentChat();

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Sorry, I encountered an error: ${e.toString()}',
            isUser: false,
            timestamp: DateTime.now(),
            isNew: true,
          ));
          _isTyping = false;
          _generationProgress = 0.0;
        });

        // Save chat with error message
        _saveCurrentChat();
      }
    }
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
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
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: const Center(
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
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _messages.length <= 1
                      ? _buildWelcomeScreen()
                      : SafeArea(
                          bottom: false,
                          child: _buildMessagesList(),
                        ),
                ),
                if (_messages.length > 1) const SizedBox(height: 100),
              ],
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
              bottom: 0,
              child: SafeArea(
                top: false,
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

  Widget _buildWelcomeScreen() {
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
                const SizedBox(height: 140),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: AiChatTheme.headerHeight + 16,
        bottom: 16,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return TypingIndicator(progress: _generationProgress);
        }

        final message = _messages[index];
        if (message.hasTrip) {
          return GeneratedTripCard(
            trip: message.tripData!,
            onTap: () => _openTripView(message.tripData!),
            onRegenerate: () => _regenerateTrip(message.tripData!),
          );
        }

        return MessageBubble(
          message: message,
          useTypewriter: message.isNew && !message.isUser,
          onTypewriterComplete: () => _onTypewriterComplete(index),
        );
      },
    );
  }
}
