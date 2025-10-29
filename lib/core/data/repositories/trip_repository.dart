import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/country_model.dart';
import '../../models/trip_model.dart';

class TripRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ========================================
  // СТРАНЫ (Countries)
  // ========================================

  /// Получить страны по континенту
  Future<List<CountryModel>> getCountriesByContinent(String continent) async {
    try {
      print('🔄 [REPO] Loading countries for continent: $continent');

      final response = await _supabase
          .from('countries')
          .select()
          .eq('continent', continent)
          .order('rating', ascending: false);

      print('📦 [REPO] Countries response: $response');
      print('📏 [REPO] Response length: ${(response as List).length}');

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

      print('📦 [REPO] All countries response: $response');
      print('📏 [REPO] Response length: ${(response as List).length}');

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

  // ========================================
  // ПОЕЗДКИ (Trips)
  // ========================================

  /// ✅ ФИЛЬТРАЦИЯ ПО КОНТИНЕНТУ И АКТИВНОСТИ (ИСПРАВЛЕННАЯ)
  Stream<List<TripModel>> watchFilteredTrips({
    String? continent,
    String? activityType,
  }) {
    print('🔴 [REALTIME] Subscribing to filtered trips...');
    print('  🌍 Continent: $continent');
    print('  🎯 Activity: $activityType');

    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('is_featured', true)
        .order('rating', ascending: false)
        .map((data) {
          print('🔴 [REALTIME] Raw trips count: ${data.length}');

          // ✅ ФИЛЬТРАЦИЯ В КОДЕ (после получения данных)
          var filteredData = data;

          // Фильтр по континенту
          if (continent != null && continent != 'All') {
            filteredData = filteredData
                .where((trip) => trip['continent'] == continent)
                .toList();
            print('  🌍 After continent filter: ${filteredData.length}');
          }

          // Фильтр по активности
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
          // Загружаем изображения для каждой поездки
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

              // Создаём новый TripModel с изображениями
              tripsWithImages.add(TripModel(
                id: trip.id,
                title: trip.title,
                description: trip.description,
                duration: trip.duration,
                price: trip.price,
                rating: trip.rating,
                reviews: trip.reviews,
                imageUrl: trip.imageUrl,
                countryId: trip.countryId,
                includes: trip.includes,
                images: images,
                category: trip.category,
                isFeatured: trip.isFeatured,
                city: trip.city,
                country: trip.country,
                latitude: trip.latitude,
                longitude: trip.longitude,
                activityType: trip.activityType,
                continent: trip.continent,
              ));
            } catch (e) {
              print(
                  '⚠️ [REALTIME] Error loading images for trip ${trip.id}: $e');
              tripsWithImages.add(trip);
            }
          }

          return tripsWithImages;
        });
  }

  /// Получить все поездки
  Future<List<TripModel>> getAllTrips() async {
    try {
      print('🔄 [REPO] Loading all trips...');

      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .order('rating', ascending: false);

      print('📦 [REPO] All trips response: $response');
      print('📏 [REPO] Response length: ${(response as List).length}');

      final trips = (response as List).map((json) {
        print('🔍 [REPO] Processing trip: ${json['title']}');

        final images = (json['trip_images'] as List?)
                ?.map((img) => img['image_url'] as String)
                .toList() ??
            [];

        json['images'] = images;
        print('  📸 [REPO] Images: ${images.length}');

        return TripModel.fromJson(json);
      }).toList();

      print('✅ [REPO] Loaded ${trips.length} trips');
      return trips;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching trips: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Получить рекомендуемые поездки (is_featured = true)
  Future<List<TripModel>> getFeaturedTrips() async {
    try {
      print('🔄 [REPO] Loading featured trips...');

      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .eq('is_featured', true)
          .order('rating', ascending: false)
          .limit(10);

      print('📦 [REPO] Featured trips response: $response');

      if (response == null || response is! List || response.isEmpty) {
        print('⚠️ [REPO] No featured trips found!');
        return [];
      }

      print('📏 [REPO] Response length: ${response.length}');

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

      print('✅ [REPO] Successfully loaded ${trips.length} featured trips');
      return trips;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching featured trips: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// 🔴 REALTIME: Подписка на рекомендуемые поездки
  Stream<List<TripModel>> watchFeaturedTrips() {
    print('🔴 [REALTIME] Subscribing to featured trips...');

    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('is_featured', true)
        .order('rating', ascending: false)
        .limit(10)
        .asyncMap((data) async {
          print('🔴 [REALTIME] Featured trips updated! Count: ${data.length}');

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

  /// Получить поездки по стране
  Future<List<TripModel>> getTripsByCountry(String countryId) async {
    try {
      print('🔄 [REPO] Loading trips for country: $countryId');

      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .eq('country_id', countryId)
          .order('rating', ascending: false);

      print('📦 [REPO] Trips by country response: $response');
      print('📏 [REPO] Response length: ${(response as List).length}');

      final trips = (response as List).map((json) {
        final images = (json['trip_images'] as List?)
                ?.map((img) => img['image_url'] as String)
                .toList() ??
            [];

        json['images'] = images;
        return TripModel.fromJson(json);
      }).toList();

      print('✅ [REPO] Loaded ${trips.length} trips for country');
      return trips;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching trips by country: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Получить поездку по ID
  Future<TripModel?> getTripById(String id) async {
    try {
      print('🔄 [REPO] Loading trip with ID: $id');

      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .eq('id', id)
          .single();

      print('📦 [REPO] Trip by ID response: $response');

      final images = (response['trip_images'] as List?)
              ?.map((img) => img['image_url'] as String)
              .toList() ??
          [];

      response['images'] = images;

      final trip = TripModel.fromJson(response);
      print('✅ [REPO] Loaded trip: ${trip.title}');
      return trip;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error fetching trip: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Поиск поездок по названию
  Future<List<TripModel>> searchTrips(String query) async {
    try {
      print('🔍 [REPO] Searching trips with query: "$query"');

      final response = await _supabase
          .from('trips')
          .select('*, trip_images(image_url, order_index, caption)')
          .ilike('title', '%$query%')
          .order('rating', ascending: false);

      print('📦 [REPO] Search response: $response');
      print('📏 [REPO] Response length: ${(response as List).length}');

      final trips = (response as List).map((json) {
        final images = (json['trip_images'] as List?)
                ?.map((img) => img['image_url'] as String)
                .toList() ??
            [];

        json['images'] = images;
        return TripModel.fromJson(json);
      }).toList();

      print('✅ [REPO] Found ${trips.length} trips');
      return trips;
    } catch (e, stackTrace) {
      print('❌ [REPO] Error searching trips: $e');
      print('📋 [REPO] Stack trace: $stackTrace');
      return [];
    }
  }

  /// 🔴 REALTIME: Подписка на все поездки
  Stream<List<TripModel>> watchAllTrips() {
    print('🔴 [REALTIME] Subscribing to all trips...');

    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .order('rating', ascending: false)
        .asyncMap((data) async {
          print('🔴 [REALTIME] All trips updated! Count: ${data.length}');

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
