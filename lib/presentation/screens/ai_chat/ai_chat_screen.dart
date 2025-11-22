import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/services/trip_generation_api.dart';
import 'widgets/ai_generated_trip_view.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showSuggestions = true;
  Map<String, dynamic>? _generatedTrip;

  late AnimationController _welcomeAnimationController;
  late Animation<double> _welcomeFadeAnimation;
  late Animation<Offset> _welcomeSlideAnimation;

  @override
  void initState() {
    super.initState();

    _welcomeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _welcomeFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(const Duration(milliseconds: 200), () {
      _welcomeAnimationController.forward();
    });

    // Listen to text field changes
    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty && _showSuggestions) {
        setState(() => _showSuggestions = false);
      } else if (_messageController.text.isEmpty && !_showSuggestions) {
        setState(() => _showSuggestions = true);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _welcomeAnimationController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // Check if message is ready for trip generation
    if (_shouldGenerateTrip(messageText)) {
      // Generate trip using API
      _generateTripFromMessage(messageText);
    } else {
      // Not enough information - ask for city and activity
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _messages.add(ChatMessage(
              text: 'To help you plan the perfect trip, I need to know:\n\n'
                   '• Which city would you like to visit?\n'
                   '• What type of activities interest you? (e.g., sightseeing, food, culture, beach, etc.)',
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isTyping = false;
          });
          _scrollToBottom();
        }
      });
    }
  }

  bool _shouldGenerateTrip(String message) {
    final lowercaseMessage = message.toLowerCase();

    // Extended list of cities
    final cities = [
      'paris', 'london', 'tokyo', 'new york', 'rome', 'barcelona',
      'vienna', 'prague', 'amsterdam', 'berlin', 'istanbul', 'dubai',
      'bali', 'bangkok', 'singapore', 'sydney', 'toronto', 'madrid',
      'lisbon', 'budapest', 'athens', 'dublin', 'brussels', 'copenhagen',
      'stockholm', 'oslo', 'helsinki', 'warsaw', 'krakow', 'moscow',
      'edinburgh', 'venice', 'florence', 'milan', 'munich', 'hamburg',
    ];

    // Extended list of activity keywords and trip indicators
    final activities = [
      // Activities
      'walk', 'explore', 'visit', 'see', 'tour', 'museum', 'park',
      'beach', 'mountain', 'hiking', 'adventure', 'food', 'restaurant',
      'culture', 'history', 'shopping', 'nightlife', 'relax', 'romantic',
      'cycling', 'sailing', 'skiing', 'wellness', 'spa', 'wine', 'art',

      // Trip types
      'trip', 'vacation', 'holiday', 'weekend', 'getaway', 'travel',
      'honeymoon', 'anniversary',

      // Duration indicators
      'day', 'days', 'week', 'weeks', 'month',

      // General travel intent
      'go to', 'going to', 'want to', 'plan', 'planning',
    ];

    // Check if message contains at least one city
    final hasCity = cities.any((city) => lowercaseMessage.contains(city));

    // Check if message contains at least one activity OR trip indicator
    final hasActivity = activities.any((activity) => lowercaseMessage.contains(activity));

    // Also check for patterns like "to [city]" or "in [city]"
    final hasPreposition = lowercaseMessage.contains(' to ') ||
                          lowercaseMessage.contains(' in ') ||
                          lowercaseMessage.contains(' for ');

    return hasCity && (hasActivity || hasPreposition);
  }

  Future<void> _generateTripFromMessage(String userMessage) async {
    // Extract city from message
    final city = _extractCityFromMessage(userMessage);

    if (city == null) {
      // Fallback: ask for clarification
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'I couldn\'t identify the city. Could you please specify which city you\'d like to visit?',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
      }
      return;
    }

    try {
      // Call the real API
      final trip = await TripGenerationApi.generateTrip(
        city: city,
        activity: userMessage,
        durationDays: 3,
      );

      if (mounted) {
        setState(() {
          _generatedTrip = trip;
          _isTyping = false;
        });
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Sorry, I encountered an error while generating your trip. Please make sure the backend server is running and try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
      }

      // Log error for debugging
      print('Trip generation error: $e');
    }
  }

  String? _extractCityFromMessage(String message) {
    final lowercaseMessage = message.toLowerCase();

    // List of supported cities (must match backend cities)
    final cityMap = {
      'paris': 'Paris',
      'london': 'London',
      'barcelona': 'Barcelona',
      'vienna': 'Vienna',
      'prague': 'Prague',
      'amsterdam': 'Amsterdam',
      'berlin': 'Berlin',
      'rome': 'Rome',
      'madrid': 'Madrid',
      'lisbon': 'Lisbon',
      'budapest': 'Budapest',
      'athens': 'Athens',
      'dublin': 'Dublin',
      'brussels': 'Brussels',
      'copenhagen': 'Copenhagen',
      'stockholm': 'Stockholm',
      'oslo': 'Oslo',
      'helsinki': 'Helsinki',
      'warsaw': 'Warsaw',
      'krakow': 'Krakow',
      'edinburgh': 'Edinburgh',
      'venice': 'Venice',
      'florence': 'Florence',
      'milan': 'Milan',
      'munich': 'Munich',
      'hamburg': 'Hamburg',
      'nice': 'Nice',
      'lyon': 'Lyon',
      'marseille': 'Marseille',
      'bordeaux': 'Bordeaux',
      'porto': 'Porto',
      'seville': 'Seville',
      'valencia': 'Valencia',
    };

    // Find the first city mentioned in the message
    for (final entry in cityMap.entries) {
      if (lowercaseMessage.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
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

  @override
  Widget build(BuildContext context) {
    // If trip is generated, show trip view
    if (_generatedTrip != null) {
      return AiGeneratedTripView(
        trip: _generatedTrip!,
        onBack: () {
          setState(() {
            _generatedTrip = null;
            _messages.clear();
          });
        },
      );
    }

    // Otherwise show chat
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Messages or welcome area
                Expanded(
                  child: _messages.isEmpty
                      ? _buildWelcomeScreen()
                      : SafeArea(
                          bottom: false,
                          child: _buildMessagesList(),
                        ),
                ),
              ],
            ),

            // Floating input area at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Suggestions above input (only when no messages)
                  if (_messages.isEmpty && _showSuggestions)
                    _buildSuggestionChips(),

                  // Input area
                  SafeArea(
                    top: false,
                    child: _buildInputArea(),
                  ),
                ],
              ),
            ),

            // Close button (top left)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return FadeTransition(
      opacity: _welcomeFadeAnimation,
      child: SlideTransition(
        position: _welcomeSlideAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Where would you like to travel?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Tell me your dream destination and I\'ll help you plan the perfect trip',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'Beach vacation',
      'Mountain adventure',
      'City exploration',
      'Romantic getaway',
    ];

    return AnimatedOpacity(
      opacity: _showSuggestions ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 12),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                _messageController.text = suggestions[index];
                _focusNode.requestFocus();
              },
              child: Container(
                margin: EdgeInsets.only(right: index < suggestions.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    suggestions[index],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const _TypingAnimation(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 44,
                maxHeight: 120,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Ask anything',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),

                  // Microphone button
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Add voice input
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic_none,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// MESSAGE MODEL
// ══════════════════════════════════════════════════════════════════════════

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// TYPING ANIMATION
// ══════════════════════════════════════════════════════════════════════════

class _TypingAnimation extends StatefulWidget {
  const _TypingAnimation();

  @override
  State<_TypingAnimation> createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<_TypingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final progress = (_controller.value - delay) % 1.0;
            final opacity = progress < 0.5
                ? progress * 2
                : 2 - (progress * 2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

