import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/country_model.dart';
import '../../models/trip.dart'; // Новый Trip (для public_trips)
import '../../models/trip_model.dart'; // Legacy TripModel

class TripRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ------ СТРАНЫ ------
  Future<List<CountryModel>> getCountriesByContinent(String continent) async {
    try {
      final response = await _supabase
          .from('countries')
          .select()
          .eq('continent', continent)
          .order('rating', ascending: false);

      final countries = (response as List)
          .map((json) => CountryModel.fromJson(json))
          .toList();
      return countries;
    } catch (e) {
      return [];
    }
  }

  Future<List<CountryModel>> getAllCountries() async {
    try {
      final response = await _supabase
          .from('countries')
          .select()
          .order('name', ascending: true);

      final countries = (response as List)
          .map((json) => CountryModel.fromJson(json))
          .toList();
      return countries;
    } catch (e) {
      return [];
    }
  }

  Stream<List<CountryModel>> watchCountriesByContinent(String continent) {
    return _supabase
        .from('countries')
        .stream(primaryKey: ['id'])
        .eq('continent', continent)
        .order('rating', ascending: false)
        .map(
            (data) => data.map((json) => CountryModel.fromJson(json)).toList());
  }

  // ------ PUBLIC TRIPS ------
  Future<List<Trip>> getPublicTrips({
    int limit = 20,
    String? activityType,
    String? city,
    String? country,
    String? continent,
  }) async {
    try {
      var query =
          _supabase.from('public_trips').select('*').eq('status', 'active');
      if (activityType != null) {
        query = query.eq('activity_type', activityType);
      }
      if (city != null) {
        query = query.eq('city', city);
      }
      if (country != null) {
        query = query.eq('country', country);
      }
      if (continent != null && continent != 'All') {
        query = query.eq('continent', continent);
      }

      final response = await query
          .order('relevance_score', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      final trips = response.map((json) => Trip.fromPublicTrip(json)).toList();
      return trips;
    } catch (e) {
      return [];
    }
  }

  Future<List<Trip>> getFeaturedPublicTrips({int limit = 10}) async {
    try {
      print('🔍 [REPOSITORY] Fetching featured public trips...');
      final response = await _supabase
          .from('public_trips')
          .select('*')
          .eq('status', 'active')
          .order('relevance_score', ascending: false)
          .order('view_count', ascending: false)
          .limit(limit);

      print('📦 [REPOSITORY] Raw response count: ${response.length}');
      if (response.isNotEmpty) {
        print('📋 [REPOSITORY] First trip: ${response[0]['title']}');
      }

      final trips = response.map((json) => Trip.fromPublicTrip(json)).toList();
      print('✅ [REPOSITORY] Converted to ${trips.length} Trip objects');
      return trips;
    } catch (e) {
      print('❌ [REPOSITORY] Error: $e');
      return [];
    }
  }

  Future<List<Trip>> searchPublicTrips(String query) async {
    try {
      final response = await _supabase
          .from('public_trips')
          .select('*')
          .eq('status', 'active')
          .or('title.ilike.%$query%,city.ilike.%$query%,country.ilike.%$query%')
          .order('relevance_score', ascending: false)
          .limit(20);

      final trips = response.map((json) => Trip.fromPublicTrip(json)).toList();
      return trips;
    } catch (e) {
      return [];
    }
  }

  Future<Trip?> getPublicTripDetails(String tripId) async {
    try {
      final response = await _supabase
          .from('public_trips')
          .select('*')
          .eq('id', tripId)
          .single();

      final trip = Trip.fromPublicTrip(response);
      await incrementPublicTripViewCount(tripId);
      return trip;
    } catch (e) {
      return null;
    }
  }

  Future<void> incrementPublicTripViewCount(String tripId) async {
    try {
      final currentTrip = await _supabase
          .from('public_trips')
          .select('view_count')
          .eq('id', tripId)
          .single();

      final currentCount = currentTrip['view_count'] as int? ?? 0;
      await _supabase
          .from('public_trips')
          .update({'view_count': currentCount + 1}).eq('id', tripId);
    } catch (e) {}
  }

  Stream<List<Trip>> watchPublicTrips({
    String? activityType,
    String? continent,
    int limit = 20,
  }) {
    return _supabase
        .from('public_trips')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .order('relevance_score', ascending: false)
        .limit(limit)
        .map((data) {
          var filteredData = data;
          if (activityType != null) {
            filteredData = filteredData
                .where((trip) => trip['activity_type'] == activityType)
                .toList();
          }
          if (continent != null && continent != 'All') {
            filteredData = filteredData
                .where((trip) => trip['continent'] == continent)
                .toList();
          }
          return filteredData.map((json) => Trip.fromPublicTrip(json)).toList();
        });
  }

  // ------ НОВОЕ: Получить рестораны по городу ------
  Future<List<Map<String, dynamic>>> getRestaurantsByCity(String city) async {
    try {
      final response = await _supabase
          .from('restaurants')
          .select(
              '*, restaurant_photos(photo_url,photo_type,display_order,is_primary)')
          .eq('is_active', true)
          .ilike('address', '%$city%')
          .order('rating', ascending: false);

      final List<Map<String, dynamic>> restaurants = [];
      for (final raw in response) {
        final restaurant = Map<String, dynamic>.from(raw);
        final photos = (restaurant['restaurant_photos'] as List?)
            ?.map((p) => p['photo_url'] as String)
            .toList();
        if (photos != null) {
          restaurant['images'] = photos;
          if (photos.isNotEmpty) {
            restaurant['image_url'] = photos.first;
          }
        }
        restaurant.remove('restaurant_photos');
        restaurant['type'] = 'restaurant';
        restaurant['cuisine'] =
            (restaurant['cuisine_types'] as List?)?.join(', ') ?? '';
        restaurant['price'] =
            _getPriceString(restaurant['price_level'] as int?);
        restaurants.add(restaurant);
      }
      return restaurants;
    } catch (e) {
      return [];
    }
  }

  // ------ НОВОЕ: Получить рестораны по POI ------
  Future<List<Map<String, dynamic>>> getRestaurantsByPoiIds(
      List<String> poiIds) async {
    try {
      if (poiIds.isEmpty) return [];

      final response = await _supabase
          .from('restaurants')
          .select(
              '*, restaurant_photos(photo_url,photo_type,display_order,is_primary)')
          .filter('poi_id', 'in', '(${poiIds.map((e) => '"$e"').join(',')})')
          .eq('is_active', true)
          .order('rating', ascending: false);

      final List<Map<String, dynamic>> restaurants = [];
      for (final raw in response) {
        final restaurant = Map<String, dynamic>.from(raw);
        final photos = (restaurant['restaurant_photos'] as List?)
            ?.map((p) => p['photo_url'] as String)
            .toList();
        if (photos != null) {
          restaurant['images'] = photos;
          if (photos.isNotEmpty) {
            restaurant['image_url'] = photos.first;
          }
        }
        restaurant.remove('restaurant_photos');
        restaurant['type'] = 'restaurant';
        restaurant['cuisine'] =
            (restaurant['cuisine_types'] as List?)?.join(', ') ?? '';
        restaurant['price'] =
            _getPriceString(restaurant['price_level'] as int?);
        restaurants.add(restaurant);
      }
      return restaurants;
    } catch (e) {
      return [];
    }
  }


  String _getPriceString(int? priceLevel) {
    if (priceLevel == null) return '€€';
    switch (priceLevel) {
      case 1:
        return '€';
      case 2:
        return '€€';
      case 3:
        return '€€€';
      case 4:
        return '€€€€';
      default:
        return '€€';
    }
  }

  // ------ LEGACY TRIPS ------
  Stream<List<TripModel>> watchFilteredTrips({
    String? continent,
    String? activityType,
  }) {
    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('is_featured', true)
        .order('rating', ascending: false)
        .map((data) {
          var filteredData = data;
          if (continent != null && continent != 'All') {
            filteredData = filteredData
                .where((trip) => trip['continent'] == continent)
                .toList();
          }
          if (activityType != null) {
            filteredData = filteredData
                .where((trip) => trip['activity_type'] == activityType)
                .toList();
          }
          return filteredData.map((json) => TripModel.fromJson(json)).toList();
        })
        .asyncMap((trips) async {
          final tripsWithImages = <TripModel>[];
          for (final trip in trips) {
            try {
              final imagesResponse = await _supabase
                  .from('trip_images')
                  .select('image_url')
                  .eq('trip_id', trip.id)
                  .order('order_index', ascending: true);

              final images = (imagesResponse as List)
                  .map((img) => img['image_url'] as String)
                  .toList();
              tripsWithImages.add(trip.copyWith(images: images));
            } catch (e) {
              tripsWithImages.add(trip);
            }
          }
          return tripsWithImages;
        });
  }

  Future<List<TripModel>> getAllTrips() async {
    try {
      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .order('rating', ascending: false);

      final trips = (response as List).map((json) {
        final images = (json['trip_images'] as List?)
                ?.map((img) => img['image_url'] as String)
                .toList() ??
            [];
        json['images'] = images;
        return TripModel.fromJson(json as Map<String, dynamic>);
      }).toList();
      return trips;
    } catch (e) {
      return [];
    }
  }

  Future<List<TripModel>> getFeaturedTrips() async {
    try {
      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .eq('is_featured', true)
          .order('rating', ascending: false)
          .limit(10);

      if (response.isEmpty) {
        return [];
      }
      final trips = response.map((json) {
        final images = (json['trip_images'] as List?)
                ?.map((img) => img['image_url'] as String)
                .toList() ??
            [];
        json['images'] = images;
        return TripModel.fromJson(json);
      }).toList();
      return trips;
    } catch (e) {
      return [];
    }
  }

  Stream<List<TripModel>> watchFeaturedTrips() {
    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('is_featured', true)
        .order('rating', ascending: false)
        .limit(10)
        .asyncMap((data) async {
          final trips = <TripModel>[];
          for (final json in data) {
            try {
              final imagesResponse = await _supabase
                  .from('trip_images')
                  .select('image_url')
                  .eq('trip_id', json['id'])
                  .order('order_index', ascending: true);
              final images = (imagesResponse as List)
                  .map((img) => img['image_url'] as String)
                  .toList();
              json['images'] = images;
              trips.add(TripModel.fromJson(json));
            } catch (e) {
              json['images'] = <String>[];
              trips.add(TripModel.fromJson(json));
            }
          }
          return trips;
        });
  }

  Future<List<TripModel>> getTripsByCountry(String countryId) async {
    try {
      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .eq('country_id', countryId)
          .order('rating', ascending: false);

      final trips = (response as List).map((json) {
        final images = (json['trip_images'] as List?)
                ?.map((img) => img['image_url'] as String)
                .toList() ??
            [];
        json['images'] = images;
        return TripModel.fromJson(json as Map<String, dynamic>);
      }).toList();
      return trips;
    } catch (e) {
      return [];
    }
  }

  Future<TripModel?> getTripById(String id) async {
    try {
      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .eq('id', id)
          .single();

      final images = (response['trip_images'] as List?)
              ?.map((img) => img['image_url'] as String)
              .toList() ??
          [];
      response['images'] = images;
      final trip = TripModel.fromJson(response);
      return trip;
    } catch (e) {
      return null;
    }
  }

  Future<List<TripModel>> searchTrips(String query) async {
    try {
      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .ilike('title', '%$query%')
          .order('rating', ascending: false);

      final trips = (response as List).map((json) {
        final images = (json['trip_images'] as List?)
                ?.map((img) => img['image_url'] as String)
                .toList() ??
            [];
        json['images'] = images;
        return TripModel.fromJson(json as Map<String, dynamic>);
      }).toList();
      return trips;
    } catch (e) {
      return [];
    }
  }

  Stream<List<TripModel>> watchAllTrips() {
    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .order('rating', ascending: false)
        .asyncMap((data) async {
          final trips = <TripModel>[];
          for (final json in data) {
            try {
              final imagesResponse = await _supabase
                  .from('trip_images')
                  .select('image_url')
                  .eq('trip_id', json['id'])
                  .order('order_index', ascending: true);
              final images = (imagesResponse as List)
                  .map((img) => img['image_url'] as String)
                  .toList();
              json['images'] = images;
              trips.add(TripModel.fromJson(json));
            } catch (e) {
              json['images'] = <String>[];
              trips.add(TripModel.fromJson(json));
            }
          }
          return trips;
        });
  }
}
