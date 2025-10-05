import '../services/amadeus_service.dart';
import '../models/hotel_model.dart';

class HotelRepository {
  // ✅ Используем правильный метод getHotelsWithInfiniteScroll
  static Future<List<Hotel>> getPopularHotels() async {
    try {
      return await AmadeusService.getHotelsWithInfiniteScroll(
        page: 0,
        pageSize: 10,
        refresh: false,
      );
    } catch (e) {
      throw Exception('Failed to load popular hotels: $e');
    }
  }

  // ✅ Используем метод getHotelsByCity
  static Future<List<Hotel>> searchHotelsByCity(String cityCode) async {
    try {
      return await AmadeusService.getHotelsByCity(cityCode);
    } catch (e) {
      throw Exception('Failed to search hotels: $e');
    }
  }

  // ✅ Метод по координатам - используем getHotelsByCity как fallback
  static Future<List<Hotel>> searchHotelsByLocation({
    required double latitude,
    required double longitude,
    int radius = 5,
  }) async {
    try {
      print('🌍 Searching hotels near coordinates: $latitude, $longitude');

      // Fallback: используем популярные города
      const fallbackCities = ['PAR', 'LON', 'NYC', 'TYO'];
      final results = <Hotel>[];

      for (final cityCode in fallbackCities.take(2)) {
        try {
          final cityHotels = await AmadeusService.getHotelsByCity(cityCode);
          results.addAll(
              cityHotels.take(5)); // Берем по 5 отелей из каждого города
        } catch (e) {
          print('❌ Failed to load hotels from $cityCode: $e');
        }
      }

      return results.take(10).toList(); // Возвращаем первые 10
    } catch (e) {
      throw Exception('Failed to search hotels by location: $e');
    }
  }

  // ✅ Правильный метод для infinite scroll
  static Future<List<Hotel>> getHotelsPage({
    int page = 0,
    int pageSize = 20,
    bool refresh = false,
  }) async {
    try {
      return await AmadeusService.getHotelsWithInfiniteScroll(
        page: page,
        pageSize: pageSize,
        refresh: refresh,
      );
    } catch (e) {
      throw Exception('Failed to load hotels page: $e');
    }
  }

  // ✅ Тест соединения
  static Future<bool> testConnection() async {
    return await AmadeusService.testConnection();
  }

  // ✅ Очистка кеша
  static void clearCache() {
    AmadeusService.clearHotelsCache();
  }

  // ✅ Статистика для дебага
  static int get totalLoadedHotels => AmadeusService.totalLoadedHotels;
  static int get loadedCities => AmadeusService.loadedCities;
  static bool get hasMoreCities => AmadeusService.hasMoreCities;
}
