import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/country_model.dart';
import '../../models/trip.dart'; // New Trip (для public_trips)
import '../../models/trip_model.dart'; // Legacy TripModel

// ═══════════════════════════════════════════════════════════════════════════
// TRIP REPOSITORY - Production Ready
// Работа с Countries, Public Trips и Legacy Trips
// ═══════════════════════════════════════════════════════════════════════════

class TripRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════════════
  // СТРАНЫ (Countries)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Получить страны по континенту
  Future<List<CountryModel>> getCountriesByContinent(String continent) async {
    try {
      print('🔄 [REPO] Loading countries for continent: $continent');

      final response = await _supabase
          .from('countries')
          .select()
          .eq('continent', continent)
          .order('rating', ascending: false);

      print('📦 [REPO] Countries response: ${(response as List).length}');

      final countries = (response as List)
          .map((json) => CountryModel.fromJson(json))
          .toList();

      print('✅ [REPO] Loaded ${countries.length} countries');
      return countries;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching countries: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Получить все страны
  Future<List<CountryModel>> getAllCountries() async {
    try {
      print('🔄 [REPO] Loading all countries...');

      final response = await _supabase
          .from('countries')
          .select()
          .order('name', ascending: true);

      print('📦 [REPO] All countries response: ${(response as List).length}');

      final countries = (response as List)
          .map((json) => CountryModel.fromJson(json))
          .toList();

      print('✅ [REPO] Loaded ${countries.length} countries');
      return countries;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching all countries: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// 🔴 REALTIME: Подписка на изменения стран по континенту
  Stream<List<CountryModel>> watchCountriesByContinent(String continent) {
    print('🔴 [REALTIME] Subscribing to countries for continent: $continent');

    return _supabase
        .from('countries')
        .stream(primaryKey: ['id'])
        .eq('continent', continent)
        .order('rating', ascending: false)
        .map((data) {
          print(
              '🔴 [REALTIME] Countries updated for $continent! Count: ${data.length}');
          return data.map((json) => CountryModel.fromJson(json)).toList();
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC TRIPS (Публичные AI-generated трипы)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Получить публичные трипы (возвращает Trip, не TripModel!)
  Future<List<Trip>> getPublicTrips({
    int limit = 20,
    String? activityType,
    String? city,
    String? country,
    String? continent,
  }) async {
    try {
      print('🔄 [REPO] Loading public trips...');
      print('  🎯 Activity: $activityType');
      print('  🏙️  City: $city');
      print('  🌍 Country: $country');
      print('  🌎 Continent: $continent');

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

      print('📦 [REPO] Public trips response: ${response.length} items');

      // ✅ ИСПРАВЛЕНО: Используем Trip.fromPublicTrip (не TripModel!)
      final trips = response.map((json) => Trip.fromPublicTrip(json)).toList();

      print('✅ [REPO] Loaded ${trips.length} public trips');
      return trips;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching public trips: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Получить топ публичные трипы (featured)
  Future<List<Trip>> getFeaturedPublicTrips({int limit = 10}) async {
    try {
      print('🔄 [REPO] Loading featured public trips...');

      final response = await _supabase
          .from('public_trips')
          .select('*')
          .eq('status', 'active')
          .order('relevance_score', ascending: false)
          .order('view_count', ascending: false)
          .limit(limit);

      print('📦 [REPO] Featured public trips: ${response.length}');

      // ✅ ИСПРАВЛЕНО: Trip.fromPublicTrip
      final trips = response.map((json) => Trip.fromPublicTrip(json)).toList();

      print('✅ [REPO] Loaded ${trips.length} featured public trips');
      return trips;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching featured public trips: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Поиск публичных трипов
  Future<List<Trip>> searchPublicTrips(String query) async {
    try {
      print('🔍 [REPO] Searching public trips with query: "$query"');

      final response = await _supabase
          .from('public_trips')
          .select('*')
          .eq('status', 'active')
          .or('title.ilike.%$query%,city.ilike.%$query%,country.ilike.%$query%')
          .order('relevance_score', ascending: false)
          .limit(20);

      print('📦 [REPO] Search results: ${response.length}');

      // ✅ ИСПРАВЛЕНО: Trip.fromPublicTrip
      final trips = response.map((json) => Trip.fromPublicTrip(json)).toList();

      print('✅ [REPO] Found ${trips.length} public trips');
      return trips;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error searching public trips: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Получить детали публичного трипа
  Future<Trip?> getPublicTripDetails(String tripId) async {
    try {
      print('🔄 [REPO] Loading public trip details: $tripId');

      final response = await _supabase
          .from('public_trips')
          .select('*')
          .eq('id', tripId)
          .single();

      print('📦 [REPO] Public trip details loaded');

      // ✅ ИСПРАВЛЕНО: Trip.fromPublicTrip
      final trip = Trip.fromPublicTrip(response);

      // Увеличиваем счетчик просмотров
      await incrementPublicTripViewCount(tripId);

      print('✅ [REPO] Loaded public trip: ${trip.title}');
      return trip;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching public trip details: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Увеличить счетчик просмотров публичного трипа
  Future<void> incrementPublicTripViewCount(String tripId) async {
    try {
      // ✅ ИСПРАВЛЕНО: Используем правильный синтаксис для инкремента
      final currentTrip = await _supabase
          .from('public_trips')
          .select('view_count')
          .eq('id', tripId)
          .single();

      final currentCount = currentTrip['view_count'] as int? ?? 0;

      await _supabase
          .from('public_trips')
          .update({'view_count': currentCount + 1}).eq('id', tripId);

      print('✅ [REPO] Incremented view count for trip: $tripId');
    } catch (e) {
      print('⚠️ [REPO] Error incrementing view count: $e');
    }
  }

  /// 🔴 REALTIME: Подписка на публичные трипы
  Stream<List<Trip>> watchPublicTrips({
    String? activityType,
    String? continent,
    int limit = 20,
  }) {
    print('🔴 [REALTIME] Subscribing to public trips...');
    print('  🎯 Activity: $activityType');
    print('  🌍 Continent: $continent');

    return _supabase
        .from('public_trips')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .order('relevance_score', ascending: false)
        .limit(limit)
        .map((data) {
          print('🔴 [REALTIME] Public trips updated! Count: ${data.length}');

          var filteredData = data;

          if (activityType != null) {
            filteredData = filteredData
                .where((trip) => trip['activity_type'] == activityType)
                .toList();
            print('  🎯 After activity filter: ${filteredData.length}');
          }

          if (continent != null && continent != 'All') {
            filteredData = filteredData
                .where((trip) => trip['continent'] == continent)
                .toList();
            print('  🌍 After continent filter: ${filteredData.length}');
          }

          // ✅ ИСПРАВЛЕНО: Trip.fromPublicTrip
          return filteredData.map((json) => Trip.fromPublicTrip(json)).toList();
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY TRIPS (Старые трипы для обратной совместимости)
  // ═══════════════════════════════════════════════════════════════════════════

  /// ✅ ФИЛЬТРАЦИЯ ПО КОНТИНЕНТУ И АКТИВНОСТИ (LEGACY)
  Stream<List<TripModel>> watchFilteredTrips({
    String? continent,
    String? activityType,
  }) {
    print('🔴 [REALTIME] Subscribing to filtered legacy trips...');
    print('  🌍 Continent: $continent');
    print('  🎯 Activity: $activityType');

    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('is_featured', true)
        .order('rating', ascending: false)
        .map((data) {
          print('🔴 [REALTIME] Raw legacy trips count: ${data.length}');

          var filteredData = data;

          if (continent != null && continent != 'All') {
            filteredData = filteredData
                .where((trip) => trip['continent'] == continent)
                .toList();
            print('  🌍 After continent filter: ${filteredData.length}');
          }

          if (activityType != null) {
            filteredData = filteredData
                .where((trip) => trip['activity_type'] == activityType)
                .toList();
            print('  🎯 After activity filter: ${filteredData.length}');
          }

          print('✅ Final filtered count: ${filteredData.length}');

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
              print(
                  '⚠️ [REALTIME] Error loading images for trip ${trip.id}: $e');
              tripsWithImages.add(trip);
            }
          }

          return tripsWithImages;
        });
  }

  /// Получить все поездки (LEGACY)
  Future<List<TripModel>> getAllTrips() async {
    try {
      print('🔄 [REPO] Loading all legacy trips...');

      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .order('rating', ascending: false);

      print('📦 [REPO] All trips response: ${(response as List).length}');

      final trips = (response as List).map((json) {
        print('🔍 [REPO] Processing trip: ${json['title']}');

        final images = (json['trip_images'] as List?)
                ?.map((img) => img['image_url'] as String)
                .toList() ??
            [];

        json['images'] = images;
        print('  📸 [REPO] Images: ${images.length}');

        return TripModel.fromJson(json as Map<String, dynamic>);
      }).toList();

      print('✅ [REPO] Loaded ${trips.length} legacy trips');
      return trips;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching legacy trips: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Получить рекомендуемые поездки (LEGACY)
  Future<List<TripModel>> getFeaturedTrips() async {
    try {
      print('🔄 [REPO] Loading featured legacy trips...');

      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .eq('is_featured', true)
          .order('rating', ascending: false)
          .limit(10);

      print(
          '📦 [REPO] Featured trips response length: ${(response as List).length}');

      if (response.isEmpty) {
        print('⚠️ [REPO] No featured legacy trips found!');
        return [];
      }

      final trips = response.map((json) {
        print('🔍 [REPO] Processing trip: ${json['title']}');

        final images = (json['trip_images'] as List?)
                ?.map((img) => img['image_url'] as String)
                .toList() ??
            [];

        json['images'] = images;
        print('  📸 [REPO] Images count: ${images.length}');

        return TripModel.fromJson(json);
      }).toList();

      print(
          '✅ [REPO] Successfully loaded ${trips.length} featured legacy trips');
      return trips;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching featured legacy trips: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// 🔴 REALTIME: Подписка на рекомендуемые поездки (LEGACY)
  Stream<List<TripModel>> watchFeaturedTrips() {
    print('🔴 [REALTIME] Subscribing to featured legacy trips...');

    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('is_featured', true)
        .order('rating', ascending: false)
        .limit(10)
        .asyncMap((data) async {
          print(
              '🔴 [REALTIME] Featured legacy trips updated! Count: ${data.length}');

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
              print(
                  '⚠️ [REALTIME] Error loading images for trip ${json['id']}: $e');
              json['images'] = <String>[];
              trips.add(TripModel.fromJson(json));
            }
          }

          return trips;
        });
  }

  /// Получить поездки по стране (LEGACY)
  Future<List<TripModel>> getTripsByCountry(String countryId) async {
    try {
      print('🔄 [REPO] Loading trips for country: $countryId');

      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .eq('country_id', countryId)
          .order('rating', ascending: false);

      print(
          '📦 [REPO] Trips by country response: ${(response as List).length}');

      final trips = (response as List).map((json) {
        final images = (json['trip_images'] as List?)
                ?.map((img) => img['image_url'] as String)
                .toList() ??
            [];

        json['images'] = images;
        return TripModel.fromJson(json as Map<String, dynamic>);
      }).toList();

      print('✅ [REPO] Loaded ${trips.length} trips for country');
      return trips;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching trips by country: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Получить поездку по ID (LEGACY)
  Future<TripModel?> getTripById(String id) async {
    try {
      print('🔄 [REPO] Loading legacy trip with ID: $id');

      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .eq('id', id)
          .single();

      print('📦 [REPO] Trip by ID response loaded');

      final images = (response['trip_images'] as List?)
              ?.map((img) => img['image_url'] as String)
              .toList() ??
          [];

      response['images'] = images;

      final trip = TripModel.fromJson(response);
      print('✅ [REPO] Loaded legacy trip: ${trip.title}');
      return trip;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching legacy trip: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Поиск поездок по названию (LEGACY)
  Future<List<TripModel>> searchTrips(String query) async {
    try {
      print('🔍 [REPO] Searching legacy trips with query: "$query"');

      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .ilike('title', '%$query%')
          .order('rating', ascending: false);

      print('📦 [REPO] Search response: ${(response as List).length}');

      final trips = (response as List).map((json) {
        final images = (json['trip_images'] as List?)
                ?.map((img) => img['image_url'] as String)
                .toList() ??
            [];

        json['images'] = images;
        return TripModel.fromJson(json as Map<String, dynamic>);
      }).toList();

      print('✅ [REPO] Found ${trips.length} legacy trips');
      return trips;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error searching legacy trips: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// 🔴 REALTIME: Подписка на все поездки (LEGACY)
  Stream<List<TripModel>> watchAllTrips() {
    print('🔴 [REALTIME] Subscribing to all legacy trips...');

    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .order('rating', ascending: false)
        .asyncMap((data) async {
          print(
              '🔴 [REALTIME] All legacy trips updated! Count: ${data.length}');

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
