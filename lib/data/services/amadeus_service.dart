import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/config/amadeus_config.dart';
import '../models/hotel_model.dart';
import 'photo_service.dart';

class AmadeusService {
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  // ✅ Расширенный список городов для бесконечного скролла
  static const List<Map<String, String>> _cities = [
    {'name': 'Paris', 'code': 'PAR', 'country': 'France'},
    {'name': 'London', 'code': 'LON', 'country': 'United Kingdom'},
    {'name': 'New York', 'code': 'NYC', 'country': 'United States'},
    {'name': 'Tokyo', 'code': 'TYO', 'country': 'Japan'},
    {'name': 'Barcelona', 'code': 'BCN', 'country': 'Spain'},
    {'name': 'Rome', 'code': 'ROM', 'country': 'Italy'},
    {'name': 'Amsterdam', 'code': 'AMS', 'country': 'Netherlands'},
    {'name': 'Dubai', 'code': 'DXB', 'country': 'UAE'},
    {'name': 'Singapore', 'code': 'SIN', 'country': 'Singapore'},
    {'name': 'Sydney', 'code': 'SYD', 'country': 'Australia'},
    {'name': 'Bangkok', 'code': 'BKK', 'country': 'Thailand'},
    {'name': 'Istanbul', 'code': 'IST', 'country': 'Turkey'},
    {'name': 'Los Angeles', 'code': 'LAX', 'country': 'United States'},
    {'name': 'Berlin', 'code': 'BER', 'country': 'Germany'},
    {'name': 'Madrid', 'code': 'MAD', 'country': 'Spain'},
  ];

  static int _currentCityBatch = 0;
  static List<Hotel> _allHotels = [];
  static bool _allCitiesLoaded = false;

  // 🔐 Получение access token
  static Future<String?> _getAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!
            .subtract(Duration(seconds: AmadeusConfig.tokenExpiryBuffer)))) {
      return _accessToken;
    }

    try {
      final response = await http.post(
        Uri.parse('${AmadeusConfig.baseUrl}${AmadeusConfig.tokenUrl}'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': AmadeusConfig.apiKey,
          'client_secret': AmadeusConfig.apiSecret,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];

        final expiresIn = data['expires_in'] ?? 1799;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

        return _accessToken;
      } else {
        print('❌ Token error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Token exception: $e');
      return null;
    }
  }

  // 🏨 СВЕРХБЫСТРОЕ получение отелей БЕЗ ожидания фото
  static Future<List<Hotel>> getHotelsByCity(String cityCode) async {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('Failed to get access token');
    }

    try {
      final uri =
          Uri.parse('${AmadeusConfig.baseUrl}${AmadeusConfig.hotelsByCity}')
              .replace(queryParameters: {'cityCode': cityCode});

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> hotelsData = data['data'] ?? [];

        // Находим название города по коду
        final cityInfo = _cities.firstWhere((city) => city['code'] == cityCode,
            orElse: () =>
                {'name': 'Unknown', 'code': cityCode, 'country': 'Unknown'});
        final cityName = cityInfo['name']!;

        print('✅ Found ${hotelsData.length} hotels in $cityName ($cityCode)');

        // 🚀 МАКСИМАЛЬНАЯ СКОРОСТЬ: создаем отели БЕЗ ожидания фото
        final hotels = <Hotel>[];
        for (int i = 0; i < hotelsData.length; i++) {
          final hotel = Hotel.fromJson(hotelsData[i]);

          // Создаем отель с placeholder'ом
          final hotelWithPlaceholder = hotel.copyWith(
            photos: [],
            mainPhoto: null,
            rating: PhotoService.getHotelRating(hotel.hotelId),
          );

          hotels.add(hotelWithPlaceholder);

          // 🚀 АСИНХРОННО загружаем фото В ФОНЕ (не блокируя UI)
          if (i < 100) {
            // Загружаем фото только для первых 100 отелей
            _loadPhotoInBackground(hotelWithPlaceholder, cityName, hotels, i);
          }
        }

        return hotels;
      } else {
        print('❌ Hotels error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch hotels: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Hotels exception: $e');
      throw Exception('Failed to fetch hotels: $e');
    }
  }

  // 🚀 Загрузка фото в фоне (асинхронно)
  static void _loadPhotoInBackground(
      Hotel hotel, String cityName, List<Hotel> hotelsList, int index) {
    PhotoService.getRealHotelPhoto(hotel.name, cityName, hotel.hotelId)
        .then((photoUrl) {
      if (photoUrl != null && index < hotelsList.length) {
        // Обновляем отель в списке с новым фото
        final updatedHotel = hotel.copyWith(
          mainPhoto: photoUrl,
          photos: [photoUrl],
        );

        // Заменяем отель в списке (если он еще там)
        if (index < hotelsList.length &&
            hotelsList[index].hotelId == hotel.hotelId) {
          hotelsList[index] = updatedHotel;
          print('✅ Updated photo for ${hotel.name}');
        }
      }
    }).catchError((error) {
      print('⚠️ Background photo loading failed for ${hotel.name}: $error');
    });
  }

  // ✅ БЕСКОНЕЧНЫЙ СКРОЛЛ - загрузка отелей порциями
  static Future<List<Hotel>> getHotelsWithInfiniteScroll({
    int page = 0,
    int pageSize = 20,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        print('🔄 Refreshing hotels - resetting cache...');
        _allHotels.clear();
        _currentCityBatch = 0;
        _allCitiesLoaded = false;
      }

      final startIndex = page * pageSize;
      final endIndex = startIndex + pageSize;

      // 🚀 ВАЖНО: Загружаем больше отелей ДО проверки кеша
      if (_allHotels.length < endIndex && !_allCitiesLoaded) {
        print('📈 Need more hotels: have ${_allHotels.length}, need $endIndex');
        await _loadMoreHotels();
      }

      // Если у нас достаточно отелей в кеше, возвращаем их
      if (_allHotels.length >= endIndex) {
        final result = _allHotels.sublist(startIndex, endIndex);
        print(
            '📄 Returning hotels $startIndex-$endIndex of ${_allHotels.length}');
        return result;
      }

      // Возвращаем что есть, если достигли конца
      if (_allHotels.length > startIndex) {
        final result = _allHotels.sublist(startIndex);
        print(
            '📄 Returning remaining hotels $startIndex-${_allHotels.length} (final batch)');
        return result;
      }

      // Если все города загружены и больше отелей нет
      if (_allCitiesLoaded) {
        print('🏁 All hotels loaded, no more data available');
        return [];
      }

      return [];
    } catch (e) {
      print('❌ Infinite scroll error: $e');
      return [];
    }
  }

  // ✅ Загрузка дополнительных отелей из новых городов
  static Future<void> _loadMoreHotels() async {
    const batchSize =
        3; // Увеличили до 3 городов для большего количества отелей
    final startCityIndex = _currentCityBatch * batchSize;
    final endCityIndex = (startCityIndex + batchSize).clamp(0, _cities.length);

    if (startCityIndex >= _cities.length) {
      _allCitiesLoaded = true;
      print('🏁 All cities processed');
      return;
    }

    print(
        '🌍 Loading hotels from cities ${startCityIndex + 1}-$endCityIndex of ${_cities.length}');

    for (int i = startCityIndex; i < endCityIndex; i++) {
      final city = _cities[i];
      final cityCode = city['code']!;
      final cityName = city['name']!;

      try {
        print('🌍 Loading hotels from $cityName ($cityCode)...');
        final cityHotels = await getHotelsByCity(cityCode);
        _allHotels.addAll(cityHotels);

        // Минимальная задержка между запросами
        if (i < endCityIndex - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        print('❌ Failed to load hotels from $cityName: $e');
      }
    }

    _currentCityBatch++;

    // Перемешиваем для разнообразия
    _allHotels.shuffle();

    // Проверяем, загружены ли все города
    if (endCityIndex >= _cities.length) {
      _allCitiesLoaded = true;
    }

    print('✅ Total hotels loaded: ${_allHotels.length}');
  }

  // 🧪 Тестовый метод для проверки подключения
  static Future<bool> testConnection() async {
    try {
      final token = await _getAccessToken();
      return token != null;
    } catch (e) {
      return false;
    }
  }

  // 🔄 Сброс кеша отелей
  static void clearHotelsCache() {
    _allHotels.clear();
    _currentCityBatch = 0;
    _allCitiesLoaded = false;
    print('🧹 Hotels cache cleared');
  }

  // 📊 Статистика загруженных отелей
  static int get totalLoadedHotels => _allHotels.length;
  static int get loadedCities => _currentCityBatch * 3;
  static bool get hasMoreCities => !_allCitiesLoaded;
}
