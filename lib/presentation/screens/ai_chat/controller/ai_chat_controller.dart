import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/trip_generation_api.dart';
import '../../../../core/services/ai_trips_storage_service.dart';
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

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatHistory> get chatHistory => List.unmodifiable(_chatHistory);
  bool get isTyping => _isTyping;
  bool get showSuggestions => _showSuggestions;
  bool get isHistoryOpen => _isHistoryOpen;
  double get generationProgress => _generationProgress;
  ChatMode get currentMode => _currentMode;
  bool get hasMessages => _messages.isNotEmpty;

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

    await _generateTripFromMessage(messageText);
  }

  /// Generate trip from message.
  Future<void> _generateTripFromMessage(String userMessage) async {
    try {
      _animateProgress();

      final trip = await TripGenerationApi.generateFlexibleTrip(
        query: userMessage,
      );

      trip['original_query'] = userMessage;
      await AiTripsStorageService.saveTrip(trip);

      HapticFeedback.heavyImpact();

      _generationProgress = 1.0;
      _isTyping = false;
      _messages.add(ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        tripData: trip,
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

  /// Regenerate a trip with the original query.
  Future<void> regenerateTrip(Map<String, dynamic> oldTrip) async {
    final originalQuery = oldTrip['original_query'] as String?;
    if (originalQuery == null || originalQuery.isEmpty) return;

    _messages.removeWhere((m) => m.tripData == oldTrip);
    _isTyping = true;
    _generationProgress = 0.0;
    notifyListeners();

    await _generateTripFromMessage(originalQuery);
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
