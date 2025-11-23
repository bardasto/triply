import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for storing and retrieving AI-generated trips from Supabase
class AiTripsStorageService {
  static final _supabase = Supabase.instance.client;
  static const String _tableName = 'ai_generated_trips';

  /// Save a new AI-generated trip to Supabase
  static Future<Map<String, dynamic>> saveTrip(Map<String, dynamic> trip) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare trip data for database
      final tripData = {
        'user_id': user.id,
        'title': trip['title'] ?? trip['name'] ?? 'Untitled Trip',
        'city': trip['city'] ?? '',
        'country': trip['country'] ?? '',
        'description': trip['description'],
        'duration_days': trip['duration_days'] ?? 3,
        'price': trip['price'],
        'currency': trip['currency'] ?? 'EUR',
        'hero_image_url': trip['hero_image_url'],
        'images': trip['images'] ?? [],
        'includes': trip['includes'] ?? [],
        'highlights': trip['highlights'] ?? [],
        'itinerary': trip['itinerary'] ?? [],
        'rating': trip['rating'] ?? 4.5,
        'reviews': trip['reviews'] ?? 0,
        'estimated_cost_min': trip['estimated_cost_min'],
        'estimated_cost_max': trip['estimated_cost_max'],
        'activity_type': trip['activity_type'],
        'best_season': trip['best_season'] ?? [],
        'is_favorite': false,
        'original_query': trip['original_query'],
      };

      // Insert into Supabase
      final response = await _supabase
          .from(_tableName)
          .insert(tripData)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to save trip: $e');
    }
  }

  /// Get all AI-generated trips for current user
  static Future<List<Map<String, dynamic>>> getAllTrips() async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Query trips from Supabase (RLS automatically filters by user_id)
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading trips: $e');
      return [];
    }
  }

  /// Get favorite trips only
  static Future<List<Map<String, dynamic>>> getFavoriteTrips() async {
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
      print('Error loading favorite trips: $e');
      return [];
    }
  }

  /// Delete a trip by ID
  static Future<void> deleteTrip(String tripId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', tripId);
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  /// Toggle favorite status
  static Future<void> toggleFavorite(String tripId, bool isFavorite) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from(_tableName)
          .update({'is_favorite': isFavorite})
          .eq('id', tripId);
    } catch (e) {
      throw Exception('Failed to update favorite status: $e');
    }
  }

  /// Get trip by ID
  static Future<Map<String, dynamic>?> getTripById(String tripId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', tripId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting trip by ID: $e');
      return null;
    }
  }

  /// Get trips by city
  static Future<List<Map<String, dynamic>>> getTripsByCity(String city) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from(_tableName)
          .select()
          .ilike('city', '%$city%')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting trips by city: $e');
      return [];
    }
  }

  /// Get user's trip statistics
  static Future<Map<String, dynamic>> getTripStatistics() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final trips = await getAllTrips();

      final totalTrips = trips.length;
      final favoriteTrips = trips.where((trip) => trip['is_favorite'] == true).length;
      final uniqueCities = trips.map((trip) => trip['city']).toSet().length;

      final totalDuration = trips.fold<int>(
        0,
        (sum, trip) => sum + (trip['duration_days'] as int? ?? 0),
      );
      final avgDuration = totalTrips > 0 ? totalDuration / totalTrips : 0;

      return {
        'total_trips': totalTrips,
        'favorite_trips': favoriteTrips,
        'unique_cities': uniqueCities,
        'avg_duration': avgDuration,
      };
    } catch (e) {
      print('Error getting trip statistics: $e');
      return {
        'total_trips': 0,
        'favorite_trips': 0,
        'unique_cities': 0,
        'avg_duration': 0,
      };
    }
  }

  /// Clear all trips (for testing/debugging only)
  static Future<void> clearAllTrips() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from(_tableName)
          .delete()
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to clear trips: $e');
    }
  }

  /// Subscribe to real-time changes for user's trips
  static RealtimeChannel subscribeToTrips(Function(List<Map<String, dynamic>>) onData) {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final channel = _supabase
        .channel('ai_trips_${user.id}')
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
            // Reload all trips when any change occurs
            final trips = await getAllTrips();
            onData(trips);
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from real-time changes
  static Future<void> unsubscribeFromTrips(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
