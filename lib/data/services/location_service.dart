import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Получить текущую позицию
  static Future<Position?> getCurrentPosition() async {
    try {
      // Проверяем разрешения
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions permanently denied');
        return null;
      }

      // Получаем текущую позицию
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('✅ Current position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting position: $e');
      return null;
    }
  }

  // Получить название страны по координатам
  static Future<String?> getCountryFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final country = placemarks.first.country;
        print('✅ Current country: $country');
        return country;
      }
      return null;
    } catch (e) {
      print('❌ Error getting country: $e');
      return null;
    }
  }

  // Вычислить расстояние между двумя точками (в км)
  static double calculateDistance(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) {
    return Geolocator.distanceBetween(
          startLat,
          startLon,
          endLat,
          endLon,
        ) /
        1000; // Конвертируем метры в километры
  }

  // Проверить, находится ли место в радиусе
  static bool isWithinRadius(
    Position userPosition,
    double placeLat,
    double placeLon,
    double radiusKm,
  ) {
    final distance = calculateDistance(
      userPosition.latitude,
      userPosition.longitude,
      placeLat,
      placeLon,
    );
    return distance <= radiusKm;
  }
}
