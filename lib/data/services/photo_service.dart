import 'dart:convert';
import 'package:http/http.dart' as http;
import 'google_places_service.dart';

class PhotoService {
  // 🎯 ТОЛЬКО РЕАЛЬНЫЕ ФОТО - никаких константных fallback!

  // ✅ Получить РЕАЛЬНОЕ фото отеля через Google Places API
  static Future<String?> getRealHotelPhoto(
      String hotelName, String cityName, String hotelId) async {
    try {
      print('📸 Getting real photo for: $hotelName in $cityName');

      // Получаем реальные фото через Google Places
      final realPhotos = await GooglePlacesService.getHotelPhotosByName(
          hotelName, cityName,
          maxPhotos: 1);

      if (realPhotos.isNotEmpty) {
        final photoUrl = realPhotos.first;
        print('✅ Got real photo for $hotelName');
        return photoUrl;
      }

      print('❌ No real photo found for $hotelName');
      return null;
    } catch (e) {
      print('❌ Error getting real photo for $hotelName: $e');
      return null;
    }
  }

  // ✅ Получить несколько РЕАЛЬНЫХ фото отеля
  static Future<List<String>> getRealHotelPhotos(
      String hotelName, String cityName, String hotelId,
      {int count = 3}) async {
    try {
      print('📸 Getting $count real photos for: $hotelName in $cityName');

      // Получаем реальные фото через Google Places
      final realPhotos = await GooglePlacesService.getHotelPhotosByName(
          hotelName, cityName,
          maxPhotos: count);

      if (realPhotos.isNotEmpty) {
        print('✅ Got ${realPhotos.length} real photos for $hotelName');
        return realPhotos;
      }

      print('❌ No real photos found for $hotelName');
      return [];
    } catch (e) {
      print('❌ Error getting real photos for $hotelName: $e');
      return [];
    }
  }

  // ✅ Получить рейтинг отеля (детерминированный)
  static double getHotelRating(String hotelId) {
    final hash = hotelId.hashCode.abs();
    final rating = 3.5 + (hash % 16) / 10.0; // От 3.5 до 5.0
    return double.parse(rating.toStringAsFixed(1));
  }

  // ✅ Проверка статуса Google Places API
  static bool get isGooglePlacesConfigured {
    return GooglePlacesService.isConfigured;
  }
}
