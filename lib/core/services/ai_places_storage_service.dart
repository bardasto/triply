import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for storing and retrieving AI-generated places from Supabase
class AiPlacesStorageService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'ai_generated_places';

  /// Save a new AI-generated place to Supabase
  static Future<Map<String, dynamic>> savePlace(Map<String, dynamic> placeData) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final place = placeData['place'] as Map<String, dynamic>? ?? placeData;
      final alternatives = placeData['alternatives'] as List<dynamic>? ?? [];

      final data = {
        'user_id': user.id,
        'name': place['name'] ?? 'Unknown Place',
        'description': place['description'] ?? '',
        'place_type': place['place_type'] ?? place['placeType'] ?? 'other',
        'category': place['category'] ?? place['place_type'] ?? 'other',
        'address': place['address'] ?? '',
        'city': place['city'] ?? '',
        'country': place['country'] ?? '',
        'latitude': place['latitude'] ?? 0.0,
        'longitude': place['longitude'] ?? 0.0,
        'rating': place['rating'] ?? 0.0,
        'review_count': place['review_count'] ?? place['reviewCount'] ?? 0,
        'price_level': place['price_level'] ?? place['priceLevel'] ?? '€€',
        'price_range': place['price_range'] ?? place['priceRange'] ?? 'Moderate',
        'estimated_price': place['estimated_price'] ?? place['estimatedPrice'] ?? '',
        'phone': place['phone'],
        'website': place['website'],
        'opening_hours': place['opening_hours'] ?? place['openingHours'],
        'is_open_now': place['is_open_now'] ?? place['isOpenNow'],
        'cuisine_types': place['cuisine_types'] ?? place['cuisineTypes'] ?? [],
        'features': place['features'] ?? [],
        'why_recommended': place['why_recommended'] ?? place['whyRecommended'] ?? '',
        'image_url': place['image_url'] ?? place['imageUrl'],
        'images': place['images'] ?? [],
        'google_place_id': place['google_place_id'] ?? place['googlePlaceId'],
        'alternatives': alternatives,
        'is_favorite': false,
        'original_query': placeData['original_query'] ?? placeData['_meta']?['originalQuery'],
      };

      final response = await _supabase
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to save place: $e');
    }
  }

  /// Get all AI-generated places for current user
  static Future<List<Map<String, dynamic>>> getAllPlaces() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading places: $e');
      return [];
    }
  }

  /// Get favorite places only
  static Future<List<Map<String, dynamic>>> getFavoritePlaces() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('is_favorite', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading favorite places: $e');
      return [];
    }
  }

  /// Delete a place by ID
  static Future<void> deletePlace(String placeId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', placeId);
    } catch (e) {
      throw Exception('Failed to delete place: $e');
    }
  }

  /// Toggle favorite status
  static Future<void> toggleFavorite(String placeId, bool isFavorite) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from(_tableName)
          .update({'is_favorite': isFavorite})
          .eq('id', placeId);
    } catch (e) {
      throw Exception('Failed to update favorite status: $e');
    }
  }

  /// Get place by ID
  static Future<Map<String, dynamic>?> getPlaceById(String placeId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', placeId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting place by ID: $e');
      return null;
    }
  }

  /// Subscribe to real-time changes for user's places
  static RealtimeChannel subscribeToPlaces(Function(List<Map<String, dynamic>>) onData) {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final channel = _supabase
        .channel('ai_places_${user.id}')
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
            final places = await getAllPlaces();
            onData(places);
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from real-time changes
  static Future<void> unsubscribeFromPlaces(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
