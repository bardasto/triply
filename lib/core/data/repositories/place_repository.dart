import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaceRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all places from public trips for a specific city and category
  Future<List<Map<String, dynamic>>> getPlacesByCityAndCategory({
    required String city,
    required String category,
    bool strictCategoryMatch = false,
  }) async {
    try {
      // Fetch all active public trips for this exact city (case-insensitive)
      final response = await _supabase
          .from('public_trips')
          .select('itinerary, city')
          .eq('status', 'active')
          .ilike('city', city);

      final places = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      for (final tripData in response) {
        final itinerary = tripData['itinerary'] as List?;
        if (itinerary == null) continue;

        for (final day in itinerary) {
          final dayPlaces = day['places'] as List?;
          if (dayPlaces == null) continue;

          for (final place in dayPlaces) {
            final placeCategory = place['category'] as String? ?? 'attraction';

            // Skip restaurants - they have their own system
            if (placeCategory == 'restaurant' ||
                placeCategory == 'cafe' ||
                placeCategory == 'bar') {
              continue;
            }

            // Filter by category if specified
            if (category.isNotEmpty) {
              if (strictCategoryMatch) {
                // Exact category match
                if (placeCategory.toLowerCase() != category.toLowerCase()) {
                  continue;
                }
              } else {
                // Flexible category matching
                if (!_categoryMatches(placeCategory, category)) {
                  continue;
                }
              }
            }

            final placeId = place['poi_id']?.toString() ?? place['name'];

            // Avoid duplicates
            if (seenIds.contains(placeId)) continue;
            seenIds.add(placeId);

            places.add(Map<String, dynamic>.from(place));
          }
        }
      }

      // Sort by rating
      places.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0;
        return ratingB.compareTo(ratingA);
      });

      debugPrint('📍 Found ${places.length} places for "$city" with category "$category" (strict: $strictCategoryMatch)');
      return places;
    } catch (e) {
      debugPrint('❌ Error fetching places: $e');
      return [];
    }
  }

  /// Check if categories match (with some flexibility)
  bool _categoryMatches(String placeCategory, String targetCategory) {
    final normalizedPlace = placeCategory.toLowerCase();
    final normalizedTarget = targetCategory.toLowerCase();

    // Exact match
    if (normalizedPlace == normalizedTarget) return true;

    // Group similar categories
    final categoryGroups = {
      'attraction': ['attraction', 'landmark', 'monument', 'sight', 'viewpoint'],
      'museum': ['museum', 'gallery', 'exhibition'],
      'park': ['park', 'garden', 'nature', 'outdoor'],
      'shopping': ['shopping', 'market', 'mall', 'store'],
      'entertainment': ['entertainment', 'theater', 'cinema', 'nightlife'],
      'beach': ['beach', 'waterfront', 'coastal'],
      'historical': ['historical', 'historic', 'castle', 'palace', 'ruins'],
      'religious': ['religious', 'church', 'temple', 'mosque', 'cathedral'],
    };

    for (final group in categoryGroups.values) {
      if (group.contains(normalizedPlace) && group.contains(normalizedTarget)) {
        return true;
      }
    }

    return false;
  }

  /// Get all unique categories from places in a city
  Future<List<String>> getCategoriesForCity(String city) async {
    try {
      final response = await _supabase
          .from('public_trips')
          .select('itinerary')
          .eq('status', 'active')
          .ilike('city', '%$city%');

      final categories = <String>{};

      for (final tripData in response) {
        final itinerary = tripData['itinerary'] as List?;
        if (itinerary == null) continue;

        for (final day in itinerary) {
          final dayPlaces = day['places'] as List?;
          if (dayPlaces == null) continue;

          for (final place in dayPlaces) {
            final category = place['category'] as String?;
            if (category != null &&
                category != 'restaurant' &&
                category != 'cafe' &&
                category != 'bar') {
              categories.add(category);
            }
          }
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      debugPrint('❌ Error fetching categories: $e');
      return [];
    }
  }
}
