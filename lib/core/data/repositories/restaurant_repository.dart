import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/restaurant_model.dart';

class RestaurantRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all restaurants for a specific city
  Future<List<Restaurant>> getRestaurantsByCity(String city) async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select('*')  // ✅ Photos already included in view
          .eq('is_active', true)
          .ilike('address', '%$city%')
          .order('rating', ascending: false);

      final restaurants = (response as List)
          .map((json) => Restaurant.fromJson(json))
          .toList();

      return restaurants;
    } catch (e) {
      debugPrint('❌ Error fetching restaurants for $city: $e');
      return [];
    }
  }

  /// Get all active restaurants
  Future<List<Restaurant>> getAllRestaurants() async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select('*')  // ✅ Photos already included in view
          .eq('is_active', true)
          .order('rating', ascending: false);

      final restaurants = (response as List)
          .map((json) => Restaurant.fromJson(json))
          .toList();

      return restaurants;
    } catch (e) {
      debugPrint('❌ Error fetching all restaurants: $e');
      return [];
    }
  }

  /// Get restaurant by ID with full details (photos and reviews)
  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select('*')  // ✅ Photos and reviews already included in view
          .eq('id', id)
          .single();

      return Restaurant.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching restaurant $id: $e');
      return null;
    }
  }

  /// Search restaurants by name or cuisine type
  Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select('*')  // ✅ Photos already included in view
          .eq('is_active', true)
          .or('name.ilike.%$query%,cuisine_types.cs.{$query}')
          .order('rating', ascending: false);

      final restaurants = (response as List)
          .map((json) => Restaurant.fromJson(json))
          .toList();

      return restaurants;
    } catch (e) {
      debugPrint('❌ Error searching restaurants: $e');
      return [];
    }
  }

  /// Get restaurants by cuisine type
  Future<List<Restaurant>> getRestaurantsByCuisine(String cuisine) async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select('*')  // ✅ Photos already included in view
          .eq('is_active', true)
          .contains('cuisine_types', [cuisine])
          .order('rating', ascending: false);

      final restaurants = (response as List)
          .map((json) => Restaurant.fromJson(json))
          .toList();

      return restaurants;
    } catch (e) {
      debugPrint('❌ Error fetching restaurants by cuisine: $e');
      return [];
    }
  }

  /// Get top rated restaurants
  Future<List<Restaurant>> getTopRatedRestaurants({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select('*')  // ✅ Photos already included in view
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(limit);

      final restaurants = (response as List)
          .map((json) => Restaurant.fromJson(json))
          .toList();

      return restaurants;
    } catch (e) {
      debugPrint('❌ Error fetching top restaurants: $e');
      return [];
    }
  }

  /// Convert restaurants to place maps for compatibility with existing UI
  Future<List<Map<String, dynamic>>> getRestaurantsAsPlaceMaps(String city) async {
    final restaurants = await getRestaurantsByCity(city);
    return restaurants.map((r) => r.toPlaceMap()).toList();
  }
}
