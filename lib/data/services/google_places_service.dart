import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GooglePlacesService {
  static String get _apiKey => dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  // 🚀 КЕШИРОВАНИЕ для ускорения
  static final Map<String, String> _placeIdCache = {};
  static final Map<String, List<String>> _photosCache = {};

  // ✅ Поиск отеля по названию и получение Place ID с кешем
  static Future<String?> findHotelPlaceId(
      String hotelName, String cityName) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
        print('⚠️ Google Places API key not configured');
        return null;
      }

      final cacheKey = '$hotelName|$cityName';

      // 🚀 Проверяем кеш
      if (_placeIdCache.containsKey(cacheKey)) {
        print('⚡ Using cached place_id for $hotelName');
        return _placeIdCache[cacheKey];
      }

      final query = '$hotelName hotel $cityName';
      final encodedQuery = Uri.encodeComponent(query);

      final url = '$_baseUrl/place/findplacefromtext/json'
          '?input=$encodedQuery'
          '&inputtype=textquery'
          '&fields=place_id,name,formatted_address'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10), // Таймаут для ускорения
        onTimeout: () {
          print('⏰ Timeout finding place_id for $hotelName');
          throw Exception('Timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['candidates'].isNotEmpty) {
          final placeId = data['candidates'][0]['place_id'];

          // 🚀 Сохраняем в кеш
          _placeIdCache[cacheKey] = placeId;
          print('✅ Found place_id for $hotelName: $placeId');
          return placeId;
        }
      }

      print('❌ No place_id found for $hotelName');
      return null;
    } catch (e) {
      print('❌ Error finding place_id for $hotelName: $e');
      return null;
    }
  }

  // ✅ Получение фото отеля по Place ID с кешем
  static Future<List<String>> getHotelPhotos(String placeId,
      {int maxPhotos = 3}) async {
    try {
      if (_apiKey.isEmpty || _apiKey == 'YOUR_GOOGLE_PLACES_API_KEY_HERE') {
        return [];
      }

      // 🚀 Проверяем кеш
      if (_photosCache.containsKey(placeId)) {
        print('⚡ Using cached photos for place_id: $placeId');
        return _photosCache[placeId]!;
      }

      final url = '$_baseUrl/place/details/json'
          '?place_id=$placeId'
          '&fields=photos'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10), // Таймаут для ускорения
        onTimeout: () {
          print('⏰ Timeout getting photos for place_id: $placeId');
          throw Exception('Timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['result']['photos'] != null) {
          final photos = data['result']['photos'] as List;
          final photoUrls = <String>[];

          for (int i = 0; i < photos.length && i < maxPhotos; i++) {
            final photoRef = photos[i]['photo_reference'];
            final photoUrl = getPhotoUrl(photoRef, maxWidth: 800);
            photoUrls.add(photoUrl);
          }

          // 🚀 Сохраняем в кеш
          _photosCache[placeId] = photoUrls;
          print('✅ Found ${photoUrls.length} photos for place_id: $placeId');
          return photoUrls;
        }
      }

      return [];
    } catch (e) {
      print('❌ Error getting photos for place_id $placeId: $e');
      return [];
    }
  }

  // ✅ Создание URL фото
  static String getPhotoUrl(String photoReference,
      {int maxWidth = 800, int maxHeight = 600}) {
    return '$_baseUrl/place/photo'
        '?maxwidth=$maxWidth'
        '&maxheight=$maxHeight'
        '&photoreference=$photoReference'
        '&key=$_apiKey';
  }

  // 🚀 БЫСТРЫЙ МЕТОД - получение фото отеля одним вызовом с кешем
  static Future<List<String>> getHotelPhotosByName(
      String hotelName, String cityName,
      {int maxPhotos = 3}) async {
    try {
      final cacheKey = '$hotelName|$cityName';

      // 🚀 Проверяем кеш фото
      if (_photosCache.containsKey(cacheKey)) {
        print('⚡ Using cached photos for $hotelName');
        return _photosCache[cacheKey]!;
      }

      // Находим Place ID (с кешем)
      final placeId = await findHotelPlaceId(hotelName, cityName);

      if (placeId != null) {
        // Получаем фото (с кешем)
        final photos = await getHotelPhotos(placeId, maxPhotos: maxPhotos);

        // 🚀 Дополнительное кеширование по имени отеля
        if (photos.isNotEmpty) {
          _photosCache[cacheKey] = photos;
        }

        return photos;
      }

      return [];
    } catch (e) {
      print('❌ Error getting photos for $hotelName in $cityName: $e');
      return [];
    }
  }

  // ✅ Проверка доступности API
  static bool get isConfigured {
    return _apiKey.isNotEmpty && _apiKey != 'YOUR_GOOGLE_PLACES_API_KEY_HERE';
  }

  // 🧹 Очистка кеша (для дебага)
  static void clearCache() {
    _placeIdCache.clear();
    _photosCache.clear();
    print('🧹 Google Places cache cleared');
  }

  // 📊 Статистика кеша
  static void printCacheStats() {
    print('📊 Google Places Cache Stats:');
    print('  Place IDs cached: ${_placeIdCache.length}');
    print('  Photos cached: ${_photosCache.length}');
  }
}
