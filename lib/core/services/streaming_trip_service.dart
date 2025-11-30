import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Event types from the SSE stream
enum TripEventType {
  init,
  skeleton,
  day,
  place,
  image,
  prices,
  complete,
  error,
  connected,
}

/// Base event class for streaming trip generation
class TripStreamEvent {
  final TripEventType type;
  final String tripId;
  final int timestamp;
  final int sequence;
  final Map<String, dynamic>? data;

  TripStreamEvent({
    required this.type,
    required this.tripId,
    required this.timestamp,
    this.sequence = 0,
    this.data,
  });

  factory TripStreamEvent.fromJson(Map<String, dynamic> json) {
    return TripStreamEvent(
      type: _parseEventType(json['type'] as String? ?? 'init'),
      tripId: json['tripId'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      sequence: json['sequence'] as int? ?? 0,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  static TripEventType _parseEventType(String type) {
    switch (type) {
      case 'init':
        return TripEventType.init;
      case 'skeleton':
        return TripEventType.skeleton;
      case 'day':
        return TripEventType.day;
      case 'place':
        return TripEventType.place;
      case 'image':
        return TripEventType.image;
      case 'prices':
        return TripEventType.prices;
      case 'complete':
        return TripEventType.complete;
      case 'error':
        return TripEventType.error;
      case 'connected':
        return TripEventType.connected;
      default:
        return TripEventType.init;
    }
  }
}

/// Streaming trip state that gets progressively built
class StreamingTripState {
  String? tripId;

  // Skeleton data
  String? title;
  String? description;
  String? city;
  String? country;
  String? duration;
  int? durationDays;
  String? theme;
  List<String>? thematicKeywords;
  List<String>? vibe;
  Map<String, dynamic>? estimatedBudget;

  // Days and places
  final Map<int, Map<String, dynamic>> days = {};
  final Map<String, Map<String, dynamic>> places = {}; // key: "day-slot-index"

  // Images
  String? heroImageUrl;
  final Map<String, String> placeImages = {}; // placeId -> imageUrl

  // Prices
  Map<String, dynamic>? priceBreakdown;

  // Status
  double progress = 0.0;
  bool isComplete = false;
  String? error;

  /// Convert to trip format compatible with existing Flutter code
  Map<String, dynamic> toTripData() {
    final itinerary = <Map<String, dynamic>>[];

    // Build itinerary from days and places
    for (int dayNum = 1; dayNum <= (durationDays ?? 0); dayNum++) {
      final dayData = days[dayNum];
      if (dayData == null) continue;

      final dayPlaces = <Map<String, dynamic>>[];

      // Find places for this day
      for (final entry in places.entries) {
        final key = entry.key;
        final placeData = entry.value;

        if (key.startsWith('$dayNum-')) {
          final place = placeData['place'] as Map<String, dynamic>?;
          if (place != null) {
            // Add image if available
            final placeId = place['placeId'] as String?;
            if (placeId != null && placeImages.containsKey(placeId)) {
              place['image_url'] = placeImages[placeId];
            }
            dayPlaces.add(place);
          }
        }
      }

      itinerary.add({
        'day': dayNum,
        'title': dayData['title'] ?? 'Day $dayNum',
        'description': dayData['description'] ?? '',
        'places': dayPlaces,
        'images': [],
      });
    }

    return {
      'id': tripId,
      'type': 'trip',
      'title': title ?? 'Trip',
      'name': title ?? 'Trip',
      'description': description ?? '',
      'city': city ?? '',
      'country': country ?? '',
      'duration': duration ?? '$durationDays days',
      'duration_days': durationDays ?? 0,
      'price': estimatedBudget?['max']?.toString() ?? '0',
      'currency': estimatedBudget?['currency'] ?? 'EUR',
      'hero_image_url': heroImageUrl,
      'includes': [],
      'highlights': thematicKeywords ?? [],
      'itinerary': itinerary,
      'images': heroImageUrl != null ? [heroImageUrl] : [],
      'rating': 4.5,
      'reviews': 0,
      'estimated_cost_min': estimatedBudget?['min'] ?? 0,
      'estimated_cost_max': estimatedBudget?['max'] ?? 0,
      'activity_type': theme,
      'best_season': [],
    };
  }
}

/// Service for streaming trip generation via SSE
class StreamingTripService {
  // Configuration
  static const String _developmentIp = '192.168.0.7';
  static const String _productionUrl = 'https://stunning-light-production.up.railway.app';

  static String get baseUrl {
    // For local development, temporarily uncomment:
    // return 'http://$_developmentIp:3000';
    return _productionUrl;
  }

  HttpClient? _httpClient;
  StreamSubscription? _subscription;
  bool _isCancelled = false;

  /// Start streaming trip generation
  ///
  /// Returns a stream of [TripStreamEvent] that progressively builds the trip.
  /// Also provides [StreamingTripState] through the onStateUpdate callback.
  Stream<TripStreamEvent> generateTripStream({
    required String query,
    List<Map<String, dynamic>>? conversationContext,
    void Function(StreamingTripState state)? onStateUpdate,
  }) async* {
    _isCancelled = false;
    final state = StreamingTripState();

    try {
      // Step 1: Start generation and get tripId
      debugPrint('[SSE] Starting streaming trip generation...');
      debugPrint('[SSE] Query: $query');

      final startResponse = await http.post(
        Uri.parse('$baseUrl/api/trips/generate/stream'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          if (conversationContext != null && conversationContext.isNotEmpty)
            'conversationContext': conversationContext,
        }),
      );

      if (startResponse.statusCode != 200) {
        throw Exception('Failed to start generation: ${startResponse.body}');
      }

      final startData = jsonDecode(startResponse.body);
      if (startData['success'] != true || startData['data'] == null) {
        throw Exception('Invalid start response');
      }

      final tripId = startData['data']['tripId'] as String;
      final streamUrl = startData['data']['streamUrl'] as String;
      state.tripId = tripId;

      debugPrint('[SSE] Got tripId: $tripId');
      debugPrint('[SSE] Connecting to: $baseUrl$streamUrl');

      // Step 2: Connect to SSE stream
      yield* _connectToSSEStream(tripId, state, onStateUpdate);

    } catch (e) {
      debugPrint('[SSE] Error: $e');
      state.error = e.toString();
      state.isComplete = true;
      onStateUpdate?.call(state);

      yield TripStreamEvent(
        type: TripEventType.error,
        tripId: state.tripId ?? '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        data: {'code': 'STREAM_ERROR', 'message': e.toString()},
      );
    }
  }

  Stream<TripStreamEvent> _connectToSSEStream(
    String tripId,
    StreamingTripState state,
    void Function(StreamingTripState state)? onStateUpdate,
  ) async* {
    final controller = StreamController<TripStreamEvent>();

    try {
      _httpClient = HttpClient();
      final request = await _httpClient!.getUrl(
        Uri.parse('$baseUrl/api/trips/stream/$tripId'),
      );
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('SSE connection failed: ${response.statusCode}');
      }

      debugPrint('[SSE] Connected to stream');

      String buffer = '';

      response.transform(utf8.decoder).listen(
        (chunk) {
          if (_isCancelled) return;

          buffer += chunk;

          // Process complete messages (end with \n\n)
          while (buffer.contains('\n\n')) {
            final messageEnd = buffer.indexOf('\n\n');
            final message = buffer.substring(0, messageEnd);
            buffer = buffer.substring(messageEnd + 2);

            final event = _parseSSEMessage(message);
            if (event != null) {
              _updateState(state, event);
              onStateUpdate?.call(state);
              controller.add(event);

              if (event.type == TripEventType.complete ||
                  event.type == TripEventType.error) {
                state.isComplete = true;
                controller.close();
              }
            }
          }
        },
        onError: (error) {
          debugPrint('[SSE] Stream error: $error');
          state.error = error.toString();
          state.isComplete = true;
          controller.addError(error);
          controller.close();
        },
        onDone: () {
          debugPrint('[SSE] Stream done');
          state.isComplete = true;
          onStateUpdate?.call(state);
          controller.close();
        },
        cancelOnError: false,
      );

      yield* controller.stream;

    } catch (e) {
      debugPrint('[SSE] Connection error: $e');
      state.error = e.toString();
      state.isComplete = true;
      controller.addError(e);
      controller.close();
      yield* controller.stream;
    } finally {
      _httpClient?.close();
      _httpClient = null;
    }
  }

  TripStreamEvent? _parseSSEMessage(String message) {
    String? eventType;
    String? data;

    for (final line in message.split('\n')) {
      if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        data = line.substring(5).trim();
      } else if (line.startsWith(':')) {
        // Comment/heartbeat, ignore
        return null;
      }
    }

    if (data == null || data.isEmpty) return null;

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;

      // Handle connected event specially
      if (eventType == 'connected') {
        return TripStreamEvent(
          type: TripEventType.connected,
          tripId: json['tripId'] as String? ?? '',
          timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        );
      }

      return TripStreamEvent.fromJson(json);
    } catch (e) {
      debugPrint('[SSE] Failed to parse message: $e');
      return null;
    }
  }

  void _updateState(StreamingTripState state, TripStreamEvent event) {
    switch (event.type) {
      case TripEventType.init:
        state.progress = 0.05;
        break;

      case TripEventType.skeleton:
        final data = event.data;
        if (data != null) {
          state.title = data['title'] as String?;
          state.description = data['description'] as String?;
          state.city = data['city'] as String?;
          state.country = data['country'] as String?;
          state.duration = data['duration'] as String?;
          state.durationDays = data['durationDays'] as int?;
          state.theme = data['theme'] as String?;
          state.thematicKeywords = (data['thematicKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList();
          state.vibe = (data['vibe'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList();
          state.estimatedBudget = data['estimatedBudget'] as Map<String, dynamic>?;
        }
        state.progress = 0.15;
        break;

      case TripEventType.day:
        final data = event.data;
        if (data != null) {
          final dayNum = data['day'] as int?;
          if (dayNum != null) {
            state.days[dayNum] = data;
          }
        }
        state.progress = 0.25 + (state.days.length * 0.05);
        break;

      case TripEventType.place:
        final data = event.data;
        if (data != null) {
          final dayNum = data['day'] as int?;
          final slot = data['slot'] as String?;
          final index = data['index'] as int?;
          if (dayNum != null && slot != null && index != null) {
            final key = '$dayNum-$slot-$index';
            state.places[key] = data;
          }
        }
        state.progress = 0.50 + (state.places.length * 0.02);
        break;

      case TripEventType.image:
        final data = event.data;
        if (data != null) {
          final imageType = data['imageType'] as String?;
          final url = data['url'] as String?;

          if (imageType == 'hero' && url != null) {
            state.heroImageUrl = url;
          } else if (imageType == 'place') {
            final placeId = data['placeId'] as String?;
            if (placeId != null && url != null) {
              state.placeImages[placeId] = url;
            }
          }
        }
        state.progress = 0.80;
        break;

      case TripEventType.prices:
        state.priceBreakdown = event.data;
        state.progress = 0.95;
        break;

      case TripEventType.complete:
        state.progress = 1.0;
        state.isComplete = true;
        break;

      case TripEventType.error:
        state.error = event.data?['message'] as String? ?? 'Unknown error';
        state.isComplete = true;
        break;

      case TripEventType.connected:
        debugPrint('[SSE] Connected event received');
        break;
    }
  }

  /// Cancel the current stream
  void cancel() {
    _isCancelled = true;
    _httpClient?.close(force: true);
    _httpClient = null;
    _subscription?.cancel();
    _subscription = null;
  }

  /// Dispose resources
  void dispose() {
    cancel();
  }
}
