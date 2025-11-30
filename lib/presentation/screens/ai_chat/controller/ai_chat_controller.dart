import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/trip_generation_api.dart';
import '../../../../core/services/ai_trips_storage_service.dart';
import '../../../../core/services/ai_places_storage_service.dart';
import '../../../../core/services/streaming_trip_service.dart';
import '../models/chat_message.dart';
import '../models/chat_history.dart';
import '../models/chat_mode.dart';

/// Controller for managing AI chat state and business logic.
class AiChatController extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final List<ChatHistory> _chatHistory = [];

  bool _isTyping = false;
  bool _showSuggestions = true;
  bool _isHistoryOpen = false;
  double _generationProgress = 0.0;
  ChatMode _currentMode = ChatMode.tripGeneration;

  // Streaming support
  bool _useStreaming = true; // Enable streaming by default
  StreamingTripService? _streamingService;
  StreamingTripState? _currentStreamingState;
  StreamSubscription? _streamSubscription;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatHistory> get chatHistory => List.unmodifiable(_chatHistory);
  bool get isTyping => _isTyping;
  bool get showSuggestions => _showSuggestions;
  bool get isHistoryOpen => _isHistoryOpen;
  double get generationProgress => _generationProgress;
  ChatMode get currentMode => _currentMode;
  bool get hasMessages => _messages.isNotEmpty;

  // Streaming getters
  bool get useStreaming => _useStreaming;
  StreamingTripState? get currentStreamingState => _currentStreamingState;
  bool get isStreaming => _streamingService != null && _currentStreamingState != null;

  /// Initialize with welcome message.
  void initialize() {
    _messages.add(ChatMessage(
      text:
          "What would you like me to generate for you today? Just describe your dream trip and I'll create a personalized itinerary!",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Set the current chat mode.
  void setMode(ChatMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  /// Toggle history panel.
  void toggleHistory() {
    _isHistoryOpen = !_isHistoryOpen;
    notifyListeners();
  }

  /// Set history open state directly.
  void setHistoryOpen(bool open) {
    if (_isHistoryOpen != open) {
      _isHistoryOpen = open;
      notifyListeners();
    }
  }

  /// Update suggestions visibility.
  void setSuggestionsVisible(bool visible) {
    if (_showSuggestions != visible) {
      _showSuggestions = visible;
      notifyListeners();
    }
  }

  /// Toggle streaming mode
  void setUseStreaming(bool value) {
    _useStreaming = value;
    notifyListeners();
  }

  /// Cancel current streaming
  void cancelStreaming() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamingService?.cancel();
    _streamingService = null;
    _currentStreamingState = null;
    _isTyping = false;
    _generationProgress = 0.0;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    cancelStreaming();
    super.dispose();
  }

  /// Add a user message and generate trip.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final messageText = text.trim();

    _showSuggestions = false;
    _messages.add(ChatMessage(
      text: messageText,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isTyping = true;
    _generationProgress = 0.0;
    notifyListeners();

    // Use streaming for trip generation (not single places for now)
    if (_useStreaming) {
      await _generateTripWithStreaming(messageText);
    } else {
      await _generateTripFromMessage(messageText);
    }
  }

  /// Build conversation context from previous messages for AI.
  /// Creates a full memory of the conversation including all user preferences,
  /// requirements, and generated results.
  List<Map<String, dynamic>> _buildConversationContext() {
    final context = <Map<String, dynamic>>[];

    for (final message in _messages) {
      if (message.isUser) {
        // User message - full text for context understanding
        context.add({
          'role': 'user',
          'content': message.text,
        });
      } else if (message.tripData != null) {
        // AI generated trip or place - include ALL relevant data
        final data = message.tripData!;
        final type = data['type'] as String? ?? 'trip';

        if (type == 'single_place') {
          // Extract FULL place info for context
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
                'address': place['address'],
                'rating': place['rating'],
                'review_count': place['review_count'],
                'price_level': place['price_level'],
                'price_range': place['price_range'],
                'estimated_price': place['estimated_price'],
                'cuisine_types': place['cuisine_types'],
                'features': place['features'],
                'opening_hours': place['opening_hours'],
                'is_open_now': place['is_open_now'],
              },
            ];

            // Add alternatives with full info
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
                    'price_level': alt['price_level'],
                  });
                }
              }
            }

            context.add({
              'role': 'assistant',
              'type': 'places',
              'places': places,
              // Store the primary city/country for easy access
              'city': place['city'],
              'country': place['country'],
            });
          }
        } else {
          // Extract FULL trip info for context
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
                        'category': place['category'],
                        'rating': place['rating'],
                        'estimated_price': place['estimated_price'],
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
            'duration_days': data['duration_days'],
            'places': places,
          });
        }
      }
    }

    return context;
  }

  /// Generate trip from message.
  Future<void> _generateTripFromMessage(String userMessage) async {
    try {
      _animateProgress();

      // Build context from previous messages
      final context = _buildConversationContext();

      // Debug: print context being sent
      debugPrint('📚 Building context from ${_messages.length} messages');
      debugPrint('📚 Context has ${context.length} entries');
      for (final entry in context) {
        if (entry['role'] == 'assistant' && entry['type'] == 'places') {
          final places = entry['places'] as List?;
          if (places != null && places.isNotEmpty) {
            debugPrint('📍 Context place: ${places[0]['name']} in ${places[0]['city']}');
          }
        }
      }

      final result = await TripGenerationApi.generateFlexibleTrip(
        query: userMessage,
        conversationContext: context.isNotEmpty ? context : null,
      );

      result['original_query'] = userMessage;

      // Check if it's a single place or a trip
      final isSinglePlace = result['type'] == 'single_place';
      debugPrint('🔍 Result type: ${result['type']}, isSinglePlace: $isSinglePlace');

      if (isSinglePlace) {
        // Save as place
        debugPrint('💾 Saving as place...');
        try {
          await AiPlacesStorageService.savePlace(result);
          debugPrint('✅ Place saved successfully');
        } catch (e) {
          debugPrint('❌ Error saving place: $e');
          rethrow;
        }
      } else {
        // Save as trip
        debugPrint('💾 Saving as trip...');
        await AiTripsStorageService.saveTrip(result);
      }

      HapticFeedback.heavyImpact();

      _generationProgress = 1.0;
      _isTyping = false;
      _messages.add(ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        tripData: result,
      ));
      notifyListeners();
    } catch (e) {
      _messages.add(ChatMessage(
        text: 'Sorry, I encountered an error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isTyping = false;
      _generationProgress = 0.0;
      notifyListeners();
    }
  }

  /// Generate trip with real-time streaming
  Future<void> _generateTripWithStreaming(String userMessage) async {
    try {
      // Build context from previous messages
      final context = _buildConversationContext();

      debugPrint('🌊 Starting streaming trip generation...');
      debugPrint('📚 Context has ${context.length} entries');

      // Initialize streaming service
      _streamingService = StreamingTripService();
      _currentStreamingState = null;

      // Create a completer to wait for stream completion
      final completer = Completer<void>();

      // Subscribe to the stream
      _streamSubscription = _streamingService!.generateTripStream(
        query: userMessage,
        conversationContext: context.isNotEmpty ? context : null,
        onStateUpdate: (state) {
          _currentStreamingState = state;
          _generationProgress = state.progress;
          notifyListeners();
        },
      ).listen(
        (event) {
          debugPrint('🌊 Received event: ${event.type.name}');

          switch (event.type) {
            case TripEventType.skeleton:
              // Provide haptic feedback when skeleton arrives
              HapticFeedback.lightImpact();
              break;

            case TripEventType.place:
              // Light feedback for each place
              HapticFeedback.selectionClick();
              break;

            case TripEventType.complete:
              // Heavy feedback on completion
              HapticFeedback.heavyImpact();

              // Convert streaming state to trip data
              if (_currentStreamingState != null) {
                final tripData = _currentStreamingState!.toTripData();
                tripData['original_query'] = userMessage;

                // Save the trip
                AiTripsStorageService.saveTrip(tripData);

                // Add as message
                _messages.add(ChatMessage(
                  text: '',
                  isUser: false,
                  timestamp: DateTime.now(),
                  tripData: tripData,
                ));
              }

              _isTyping = false;
              _generationProgress = 1.0;
              notifyListeners();

              // Clean up streaming state
              _streamingService = null;
              _currentStreamingState = null;

              if (!completer.isCompleted) {
                completer.complete();
              }
              break;

            case TripEventType.error:
              final errorMsg = event.data?['message'] as String? ?? 'Unknown error';
              debugPrint('🌊 Stream error: $errorMsg');

              // Fall back to non-streaming mode
              _streamingService?.cancel();
              _streamingService = null;
              _currentStreamingState = null;

              // Try regular generation as fallback
              if (!completer.isCompleted) {
                completer.complete();
              }

              // Use fallback
              _generateTripFromMessage(userMessage);
              break;

            default:
              break;
          }
        },
        onError: (error) {
          debugPrint('🌊 Stream error: $error');

          // Clean up and fall back
          _streamingService?.cancel();
          _streamingService = null;
          _currentStreamingState = null;

          if (!completer.isCompleted) {
            completer.complete();
          }

          // Use fallback
          _generateTripFromMessage(userMessage);
        },
        onDone: () {
          debugPrint('🌊 Stream done');
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        cancelOnError: false,
      );

      // Wait for stream to complete
      await completer.future;

    } catch (e) {
      debugPrint('🌊 Streaming error: $e');

      // Fall back to non-streaming
      _streamingService?.cancel();
      _streamingService = null;
      _currentStreamingState = null;

      await _generateTripFromMessage(userMessage);
    }
  }

  /// Regenerate a trip with the original query.
  Future<void> regenerateTrip(Map<String, dynamic> oldTrip) async {
    final originalQuery = oldTrip['original_query'] as String?;
    if (originalQuery == null || originalQuery.isEmpty) return;

    _messages.removeWhere((m) => m.tripData == oldTrip);
    _isTyping = true;
    _generationProgress = 0.0;
    notifyListeners();

    // Use streaming for regeneration too
    if (_useStreaming) {
      await _generateTripWithStreaming(originalQuery);
    } else {
      await _generateTripFromMessage(originalQuery);
    }
  }

  /// Animate progress during generation.
  void _animateProgress() {
    _generationProgress = 0.0;

    final progressSteps = [0.15, 0.35, 0.55, 0.75, 0.90];
    final delays = [500, 800, 1000, 1200, 800];

    for (int i = 0; i < progressSteps.length; i++) {
      Future.delayed(
        Duration(milliseconds: delays.take(i + 1).reduce((a, b) => a + b)),
        () {
          if (_isTyping) {
            _generationProgress = progressSteps[i];
            notifyListeners();
          }
        },
      );
    }
  }

  /// Format date for history display.
  String formatDate(DateTime date) {
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

}
