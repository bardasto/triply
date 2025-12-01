import 'dart:async';
import 'package:flutter/foundation.dart';

import 'streaming_trip_service.dart';

/// Manages active streaming sessions globally.
/// Allows streaming to continue in background when user leaves chat screen
/// and restore the skeleton UI when they return.
class ActiveStreamingManager {
  static final ActiveStreamingManager _instance = ActiveStreamingManager._internal();
  factory ActiveStreamingManager() => _instance;
  ActiveStreamingManager._internal();

  // Active streaming session data
  String? _activeChatId;
  StreamingTripService? _streamingService;
  StreamingTripState? _streamingState;
  StreamSubscription? _streamSubscription;
  bool _isComplete = false;
  Map<String, dynamic>? _completedTripData;
  String? _completionMessage;

  // Callbacks for UI updates
  final List<void Function(StreamingTripState)> _stateListeners = [];
  void Function(Map<String, dynamic> tripData, String message)? _onComplete;
  void Function(String error)? _onError;

  /// Check if there's an active streaming session for a chat
  bool hasActiveStreaming(String chatId) {
    return _activeChatId == chatId && _streamingService != null && !_isComplete;
  }

  /// Check if streaming just completed for a chat (to show the result)
  bool hasCompletedStreaming(String chatId) {
    return _activeChatId == chatId && _isComplete && _completedTripData != null;
  }

  /// Get the current streaming state
  StreamingTripState? getStreamingState(String chatId) {
    if (_activeChatId == chatId) {
      return _streamingState;
    }
    return null;
  }

  /// Get completed trip data
  Map<String, dynamic>? getCompletedTripData(String chatId) {
    if (_activeChatId == chatId && _isComplete) {
      return _completedTripData;
    }
    return null;
  }

  /// Get completion message
  String? getCompletionMessage(String chatId) {
    if (_activeChatId == chatId && _isComplete) {
      return _completionMessage;
    }
    return null;
  }

  /// Clear completed data after it's been consumed
  void clearCompletedData(String chatId) {
    if (_activeChatId == chatId) {
      _completedTripData = null;
      _completionMessage = null;
      _isComplete = false;
      _activeChatId = null;
    }
  }

  /// Register a listener for state updates
  void addStateListener(void Function(StreamingTripState) listener) {
    _stateListeners.add(listener);
    // Immediately notify with current state if available
    if (_streamingState != null) {
      listener(_streamingState!);
    }
  }

  /// Remove a state listener
  void removeStateListener(void Function(StreamingTripState) listener) {
    _stateListeners.remove(listener);
  }

  /// Set completion callback
  void setOnComplete(void Function(Map<String, dynamic> tripData, String message)? callback) {
    _onComplete = callback;
  }

  /// Set error callback
  void setOnError(void Function(String error)? callback) {
    _onError = callback;
  }

  void _notifyStateListeners(StreamingTripState state) {
    for (final listener in _stateListeners) {
      listener(state);
    }
  }

  /// Start a new streaming session
  Future<void> startStreaming({
    required String chatId,
    required String query,
    List<Map<String, dynamic>>? conversationContext,
    required void Function(Map<String, dynamic> tripData, String message) onComplete,
    required void Function(String error) onError,
  }) async {
    // Cancel any existing streaming
    await cancelStreaming();

    _activeChatId = chatId;
    _isComplete = false;
    _completedTripData = null;
    _completionMessage = null;
    _onComplete = onComplete;
    _onError = onError;

    _streamingService = StreamingTripService();
    _streamingState = StreamingTripState();

    debugPrint('🌊 [Manager] Starting streaming for chat: $chatId');

    _streamSubscription = _streamingService!.generateTripStream(
      query: query,
      conversationContext: conversationContext,
      onStateUpdate: (state) {
        _streamingState = state;
        _notifyStateListeners(state);
      },
    ).listen(
      (event) {
        debugPrint('🌊 [Manager] Event: ${event.type.name}');

        switch (event.type) {
          case TripEventType.complete:
            if (_streamingState != null) {
              final tripData = _streamingState!.toTripData();
              tripData['original_query'] = query;

              final location = tripData['city'] as String? ?? 'your destination';
              final message = _getCompletionMessage(location);

              _completedTripData = tripData;
              _completionMessage = message;
              _isComplete = true;

              debugPrint('🌊 [Manager] Streaming complete for chat: $_activeChatId');

              // Notify completion
              _onComplete?.call(tripData, message);
            }
            _cleanupService();
            break;

          case TripEventType.error:
            final errorMsg = event.data?['message'] as String? ?? 'Unknown error';
            debugPrint('🌊 [Manager] Streaming error: $errorMsg');
            _onError?.call(errorMsg);
            _cleanupService();
            _activeChatId = null;
            break;

          default:
            break;
        }
      },
      onError: (error) {
        debugPrint('🌊 [Manager] Stream error: $error');
        _onError?.call(error.toString());
        _cleanupService();
        _activeChatId = null;
      },
      cancelOnError: false,
    );
  }

  String _getCompletionMessage(String location) {
    final messages = [
      "Your trip to $location is ready! Tap to explore the full itinerary.",
      "Here's your personalized $location adventure! Take a look at what I've planned.",
      "I've crafted an amazing $location experience for you. Check it out!",
      "Your $location journey awaits! Here's what I've put together.",
      "All set! Your $location itinerary is ready to explore.",
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  void _cleanupService() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _streamingService?.dispose();
    _streamingService = null;
    // Keep _streamingState for UI to show final state
  }

  /// Cancel the current streaming session
  Future<void> cancelStreaming() async {
    if (_streamingService != null) {
      debugPrint('🌊 [Manager] Cancelling streaming for chat: $_activeChatId');
      _streamSubscription?.cancel();
      _streamSubscription = null;
      _streamingService?.dispose();
      _streamingService = null;
      _streamingState = null;
      _activeChatId = null;
      _isComplete = false;
      _completedTripData = null;
      _completionMessage = null;
      _stateListeners.clear();
      _onComplete = null;
      _onError = null;
    }
  }

  /// Get the chat ID that has active streaming
  String? get activeChatId => _activeChatId;

  /// Check if streaming is in progress (not complete)
  bool get isStreaming => _streamingService != null && !_isComplete;
}
