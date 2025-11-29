import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TripGenerationApi {
  // 🔧 КОНФИГУРАЦИЯ ДЛЯ РАЗРАБОТКИ
  // Установи свой IP адрес Mac (найди через: ifconfig | grep "inet " | grep -v 127.0.0.1)
  static const String _developmentIp = '192.168.0.7';

  // 🎯 Production URL
  static const String _productionUrl = 'https://stunning-light-production.up.railway.app';

  static String get baseUrl {
    // Для локальной разработки можно временно раскомментировать строку ниже:
    // return 'http://$_developmentIp:3000';

    return _productionUrl;
  }

  /// Generate a trip based on city and activity
  ///
  /// Parameters:
  ///   - city: City name (e.g., "Paris", "Barcelona")
  ///   - activity: Optional activity description (e.g., "romantic weekend", "food tour")
  ///   - durationDays: Optional trip duration in days (default: 3)
  static Future<Map<String, dynamic>> generateTrip({
    required String city,
    String? activity,
    int? durationDays,
  }) async {
    final url = Uri.parse('$baseUrl/api/trips/generate');

    // Debug: показываем какой URL используется
    print('🌐 Connecting to: $baseUrl');
    print('📍 Full URL: $url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'city': city,
          if (activity != null) 'activity': activity,
          if (durationDays != null) 'durationDays': durationDays,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return _convertTripFormat(data['data']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to generate trip');
      }
    } catch (e) {
      throw Exception('Trip generation failed: $e');
    }
  }

  /// Convert backend trip format to Flutter app format
  static Map<String, dynamic> _convertTripFormat(Map<String, dynamic> backendTrip) {
    return {
      'id': backendTrip['id'],
      'title': backendTrip['title'], // Keep original title
      'name': backendTrip['title'], // Also map to name for compatibility
      'city': backendTrip['city'],
      'country': backendTrip['country'],
      'duration_days': _parseDuration(backendTrip['duration']),
      'price': _parsePrice(backendTrip['price']),
      'currency': backendTrip['currency'] ?? 'EUR',
      'hero_image_url': backendTrip['hero_image_url'],
      'description': backendTrip['description'],
      'includes': backendTrip['includes'] ?? [],
      'highlights': backendTrip['highlights'] ?? [],
      'itinerary': backendTrip['itinerary']?.map((day) => {
        'day': day['day'],
        'title': day['title'],
        'description': day['description'],
        'places': day['places'] ?? [],
        'images': day['images'] ?? [],
      }).toList() ?? [],
      'images': backendTrip['images'] ?? [],
      'rating': backendTrip['rating'] ?? 4.5,
      'reviews': backendTrip['reviews'] ?? 0,
      'estimated_cost_min': backendTrip['estimated_cost_min'] ?? 150,
      'estimated_cost_max': backendTrip['estimated_cost_max'] ?? 450,
      'activity_type': backendTrip['activity_type'],
      'best_season': backendTrip['best_season'] ?? [],
    };
  }

  /// Parse duration string (e.g., "3 days") to integer
  static int _parseDuration(String? duration) {
    if (duration == null) return 3;

    final match = RegExp(r'(\d+)').firstMatch(duration);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 3;
    }

    return 3;
  }

  /// Parse price string (e.g., "€500") to double
  static double _parsePrice(String? price) {
    if (price == null) return 500.0;

    final numericString = price.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(numericString) ?? 500.0;
  }

  /// Generate trip or single place from free-form query (AI-powered)
  ///
  /// Parameters:
  ///   - query: Free-form text query (e.g., "romantic weekend in Paris", "I want a Michelin restaurant in Paris")
  ///
  /// Returns a map with 'type' field indicating 'trip' or 'single_place'
  static Future<Map<String, dynamic>> generateFlexibleTrip({
    required String query,
  }) async {
    final url = Uri.parse('$baseUrl/api/trips/generate');

    // Debug: показываем какой URL используется
    print('🌐 Connecting to: $baseUrl');
    print('📍 Full URL: $url');
    print('📝 Query: $query');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': query,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final responseType = data['type'] as String? ?? 'trip';

          if (responseType == 'single_place') {
            return _convertSinglePlaceFormat(data['data']);
          } else {
            return _convertTripFormat(data['data']);
          }
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to generate');
      }
    } catch (e) {
      throw Exception('Generation failed: $e');
    }
  }

  /// Convert backend single place format to Flutter app format
  static Map<String, dynamic> _convertSinglePlaceFormat(
      Map<String, dynamic> backendPlace) {
    final place = backendPlace['place'] as Map<String, dynamic>? ?? {};

    return {
      'type': 'single_place',
      'id': backendPlace['id'],
      'place': {
        'id': place['id'],
        'name': place['name'] ?? 'Unknown Place',
        'description': place['description'] ?? '',
        'place_type': place['placeType'] ?? place['place_type'] ?? 'other',
        'category': place['category'] ?? '',
        'address': place['address'] ?? '',
        'city': place['city'] ?? '',
        'country': place['country'] ?? '',
        'latitude': (place['latitude'] as num?)?.toDouble() ?? 0.0,
        'longitude': (place['longitude'] as num?)?.toDouble() ?? 0.0,
        'rating': (place['rating'] as num?)?.toDouble() ?? 0.0,
        'review_count': place['reviewCount'] ?? place['review_count'] ?? 0,
        'price_level': place['priceLevel'] ?? place['price_level'] ?? '€€',
        'price_range': place['priceRange'] ?? place['price_range'] ?? 'Moderate',
        'phone': place['phone'],
        'website': place['website'],
        'opening_hours': place['openingHours'] ?? place['opening_hours'],
        'is_open_now': place['isOpenNow'] ?? place['is_open_now'],
        'cuisine_types': place['cuisineTypes'] ?? place['cuisine_types'] ?? [],
        'features': place['features'] ?? [],
        'why_recommended':
            place['whyRecommended'] ?? place['why_recommended'] ?? '',
        'image_url': place['imageUrl'] ?? place['image_url'],
        'images': place['images'] ?? [],
        'google_place_id': place['googlePlaceId'] ?? place['google_place_id'],
      },
      'alternatives': (backendPlace['alternatives'] as List<dynamic>?)
              ?.map((alt) => {
                    'id': alt['id'],
                    'name': alt['name'] ?? '',
                    'rating': (alt['rating'] as num?)?.toDouble() ?? 0.0,
                    'price_level': alt['priceLevel'] ?? alt['price_level'] ?? '€€',
                    'why_alternative':
                        alt['whyAlternative'] ?? alt['why_alternative'] ?? '',
                    'google_place_id':
                        alt['googlePlaceId'] ?? alt['google_place_id'],
                    'image_url': alt['imageUrl'] ?? alt['image_url'],
                    'address': alt['address'] ?? '',
                  })
              .toList() ??
          [],
      '_meta': backendPlace['_meta'],
    };
  }

  /// Modify an existing trip based on user request
  ///
  /// Parameters:
  ///   - existingTrip: The current trip data to modify
  ///   - modificationRequest: What the user wants to change (e.g., "make it cheaper", "add more restaurants")
  static Future<Map<String, dynamic>> modifyTrip({
    required Map<String, dynamic> existingTrip,
    required String modificationRequest,
  }) async {
    final url = Uri.parse('$baseUrl/api/trips/modify');

    print('🌐 Connecting to: $baseUrl');
    print('📍 Full URL: $url');
    print('📝 Modification request: $modificationRequest');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'existingTrip': existingTrip,
          'modificationRequest': modificationRequest,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return _convertTripFormat(data['data']);
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'Failed to modify trip');
      }
    } catch (e) {
      throw Exception('Trip modification failed: $e');
    }
  }

  /// Check if the API server is healthy
  static Future<bool> healthCheck() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
