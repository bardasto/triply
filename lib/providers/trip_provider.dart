import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/models/country_model.dart';
import '../core/models/trip_model.dart';
import '../core/data/repositories/trip_repository.dart';
import '../data/services/location_service.dart';

class TripProvider with ChangeNotifier {
  final TripRepository _repository = TripRepository();

  List<CountryModel> _countries = [];
  List<TripModel> _trips = [];
  List<TripModel> _featuredTrips = [];
  List<TripModel> _nearbyTrips = [];
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  String? _error;

  Position? _userPosition;
  String? _currentCountry;

  List<CountryModel> get countries => _countries;
  List<TripModel> get trips => _trips;
  List<TripModel> get featuredTrips => _featuredTrips;
  List<TripModel> get nearbyTrips => _nearbyTrips;
  bool get isLoading => _isLoading;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get error => _error;
  String? get currentCountry => _currentCountry;
  Position? get userPosition => _userPosition;

  // ✅ Загрузить ближайшие места на основе геолокации
  Future<void> loadNearbyTrips({double radiusKm = 3000}) async {
    _isLoadingLocation = true;
    _error = null;
    notifyListeners();

    try {
      // Получаем текущую позицию
      final position = await LocationService.getCurrentPosition();

      if (position == null) {
        print('⚠️ Could not get position, loading featured trips instead');
        await loadFeaturedTrips();
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      _userPosition = position;
      print('📍 User position: ${position.latitude}, ${position.longitude}');

      // Получаем название страны
      _currentCountry = await LocationService.getCountryFromPosition(position);
      print('🌍 Current country: $_currentCountry');

      // Загружаем все поездки
      final allTrips = await _repository.getFeaturedTrips();
      print('📦 Total trips loaded: ${allTrips.length}');

      // Фильтруем по радиусу и сортируем по расстоянию
      final tripsWithDistance = <Map<String, dynamic>>[];

      for (var trip in allTrips) {
        // Проверяем, есть ли координаты у поездки
        if (trip.latitude != null && trip.longitude != null) {
          final distance = LocationService.calculateDistance(
            position.latitude,
            position.longitude,
            trip.latitude!,
            trip.longitude!,
          );

          // Добавляем только если в радиусе
          if (distance <= radiusKm) {
            tripsWithDistance.add({
              'trip': trip,
              'distance': distance,
            });
          }
        }
      }

      print('🎯 Trips within ${radiusKm}km: ${tripsWithDistance.length}');

      // Сортируем по расстоянию (ближайшие первые)
      tripsWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      _nearbyTrips =
          tripsWithDistance.map((item) => item['trip'] as TripModel).toList();

      print('✅ Loaded ${_nearbyTrips.length} nearby trips');

      // Если не нашли ничего поблизости, загружаем featured trips
      if (_nearbyTrips.isEmpty) {
        print('⚠️ No nearby trips found, using featured trips');
        await loadFeaturedTrips();
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading nearby trips: $e');
      // Fallback на featured trips
      await loadFeaturedTrips();
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // ✅ Получить расстояние до поездки (для UI)
  double? getDistanceToTrip(TripModel trip) {
    if (_userPosition == null ||
        trip.latitude == null ||
        trip.longitude == null) {
      return null;
    }

    return LocationService.calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      trip.latitude!,
      trip.longitude!,
    );
  }

  // ✅ Загрузить страны по континенту
  Future<void> loadCountriesByContinent(String continent) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _countries = await _repository.getCountriesByContinent(continent);
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading countries: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ Загрузить все страны
  Future<void> loadAllCountries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _countries = await _repository.getAllCountries();
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading all countries: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ Загрузить все поездки
  Future<void> loadAllTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trips = await _repository.getAllTrips();
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading trips: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ Загрузить рекомендуемые поездки
  Future<void> loadFeaturedTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _featuredTrips = await _repository.getFeaturedTrips();
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading featured trips: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ Поиск поездок
  Future<List<TripModel>> searchTrips(String query) async {
    try {
      return await _repository.searchTrips(query);
    } catch (e) {
      print('❌ Error searching trips: $e');
      return [];
    }
  }

  // ✅ Получить поездки по стране
  Future<List<TripModel>> getTripsByCountry(String countryId) async {
    try {
      return await _repository.getTripsByCountry(countryId);
    } catch (e) {
      print('❌ Error getting trips by country: $e');
      return [];
    }
  }

  // ✅ Обновить локацию вручную
  Future<void> refreshLocation() async {
    await loadNearbyTrips();
  }
}
