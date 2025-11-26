import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/models/country_model.dart';
import '../core/models/trip_model.dart';
import '../core/models/trip.dart';
import '../core/data/repositories/trip_repository.dart';
import '../data/services/location_service.dart'; 

// ═══════════════════════════════════════════════════════════════════════════
// TRIP PROVIDER - Production Ready
// Управление состоянием трипов (public_trips + legacy trips)
// ═══════════════════════════════════════════════════════════════════════════

class TripProvider with ChangeNotifier {
  final TripRepository _repository = TripRepository();

  // ════════════════════════════════════════════════
  // State Variables
  // ════════════════════════════════════════════════

  // Countries
  List<CountryModel> _countries = [];

  // Public Trips (AI-generated)
  List<Trip> _publicTrips = [];
  List<Trip> _featuredPublicTrips = [];
  List<Trip> _nearbyPublicTrips = [];

  // Legacy Trips (for backward compatibility)
  List<TripModel> _legacyTrips = [];
  List<TripModel> _featuredLegacyTrips = [];
  List<TripModel> _nearbyLegacyTrips = [];

  // Loading states
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  String? _error;

  // Location
  Position? _userPosition;
  String? _currentCountry;

  // Filters
  String? _selectedActivity;
  String? _selectedContinent;

  // ════════════════════════════════════════════════
  // Getters
  // ════════════════════════════════════════════════

  List<CountryModel> get countries => _countries;

  // Public Trips
  List<Trip> get publicTrips => _publicTrips;
  List<Trip> get featuredPublicTrips => _featuredPublicTrips;
  List<Trip> get nearbyPublicTrips => _nearbyPublicTrips;

  // Legacy Trips
  List<TripModel> get legacyTrips => _legacyTrips;
  List<TripModel> get featuredLegacyTrips => _featuredLegacyTrips;
  List<TripModel> get nearbyLegacyTrips => _nearbyLegacyTrips;

  // Combined trips (public + legacy)
  List<dynamic> get allTrips => [..._publicTrips, ..._legacyTrips];
  List<dynamic> get featuredTrips =>
      [..._featuredPublicTrips, ..._featuredLegacyTrips];
  List<dynamic> get nearbyTrips =>
      [..._nearbyPublicTrips, ..._nearbyLegacyTrips];

  bool get isLoading => _isLoading;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get error => _error;
  String? get currentCountry => _currentCountry;
  Position? get userPosition => _userPosition;
  String? get selectedActivity => _selectedActivity;
  String? get selectedContinent => _selectedContinent;

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC TRIPS (AI-Generated)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Загрузить публичные трипы
  Future<void> loadPublicTrips({
    String? activityType,
    String? city,
    String? country,
    String? continent,
    int limit = 20,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _publicTrips = await _repository.getPublicTrips(
        activityType: activityType,
        city: city,
        country: country,
        continent: continent,
        limit: limit,
      );

      print('✅ [PROVIDER] Loaded ${_publicTrips.length} public trips');
    } catch (e) {
      _error = e.toString();
      print('❌ [PROVIDER] Error loading public trips: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Загрузить featured публичные трипы
  Future<void> loadFeaturedPublicTrips({int limit = 10}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _featuredPublicTrips =
          await _repository.getFeaturedPublicTrips(limit: limit);
      print(
          '✅ [PROVIDER] Loaded ${_featuredPublicTrips.length} featured public trips');
    } catch (e) {
      _error = e.toString();
      print('❌ [PROVIDER] Error loading featured public trips: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Поиск публичных трипов
  Future<List<Trip>> searchPublicTrips(String query) async {
    try {
      return await _repository.searchPublicTrips(query);
    } catch (e) {
      print('❌ [PROVIDER] Error searching public trips: $e');
      return [];
    }
  }

  /// Получить детали публичного трипа
  Future<Trip?> getPublicTripDetails(String tripId) async {
    try {
      return await _repository.getPublicTripDetails(tripId);
    } catch (e) {
      print('❌ [PROVIDER] Error getting public trip details: $e');
      return null;
    }
  }

  /// Фильтровать публичные трипы по активности
  Future<void> filterPublicTripsByActivity(String activityType) async {
    _selectedActivity = activityType;
    await loadPublicTrips(
      activityType: activityType,
      continent: _selectedContinent,
    );
  }

  /// Фильтровать публичные трипы по континенту
  Future<void> filterPublicTripsByContinent(String continent) async {
    _selectedContinent = continent;
    await loadPublicTrips(
      continent: continent,
      activityType: _selectedActivity,
    );
  }

  /// Сбросить фильтры
  Future<void> clearFilters() async {
    _selectedActivity = null;
    _selectedContinent = null;
    await loadPublicTrips();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEARBY TRIPS (Geolocation-based)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Загрузить ближайшие публичные трипы на основе геолокации
  Future<void> loadNearbyPublicTrips({double radiusKm = 3000}) async {
    _error = null;

    // Try to get cached position INSTANTLY (non-blocking)
    final cachedPosition = await LocationService.getCachedPosition();
    final cachedCountry = await LocationService.getCachedCountry();

    if (cachedPosition != null) {
      // We have cached location - use it immediately!
      _userPosition = cachedPosition;
      _currentCountry = cachedCountry;
      print('⚡ Using cached position: ${cachedPosition.latitude}, ${cachedPosition.longitude}');
      print('⚡ Using cached country: $cachedCountry');
      notifyListeners();

      // Load and sort trips using cached position (fast)
      await _loadTripsWithPosition(cachedPosition, radiusKm);

      // Then refresh location in background for next time
      _refreshLocationInBackground(radiusKm);
    } else {
      // No cache - load featured first, then get location
      print('📍 No cached position, loading featured trips first...');
      await loadFeaturedPublicTrips();
      _nearbyPublicTrips = List.from(_featuredPublicTrips);
      notifyListeners();

      // Then get location in background and update
      _loadLocationAndNearbyTrips(radiusKm);
    }
  }

  /// Load trips sorted by distance using given position
  Future<void> _loadTripsWithPosition(Position position, double radiusKm) async {
    try {
      // Загружаем все публичные трипы
      final allTrips = await _repository.getPublicTrips(limit: 100);
      print('📦 Total public trips loaded: ${allTrips.length}');

      // Фильтруем по радиусу и сортируем по расстоянию
      final tripsWithDistance = <Map<String, dynamic>>[];

      for (var trip in allTrips) {
        if (trip.latitude != null && trip.longitude != null) {
          final distance = LocationService.calculateDistance(
            position.latitude,
            position.longitude,
            trip.latitude!,
            trip.longitude!,
          );

          if (distance <= radiusKm) {
            tripsWithDistance.add({
              'trip': trip,
              'distance': distance,
            });
          }
        }
      }

      print('🎯 Trips within ${radiusKm}km: ${tripsWithDistance.length}');

      // Сортируем по расстоянию
      tripsWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      if (tripsWithDistance.isNotEmpty) {
        _nearbyPublicTrips =
            tripsWithDistance.map((item) => item['trip'] as Trip).toList();
        print('✅ Sorted ${_nearbyPublicTrips.length} nearby public trips by distance');
      } else {
        // Fallback to featured if no nearby trips
        await loadFeaturedPublicTrips();
        _nearbyPublicTrips = List.from(_featuredPublicTrips);
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error loading trips with position: $e');
      await loadFeaturedPublicTrips();
      _nearbyPublicTrips = List.from(_featuredPublicTrips);
      notifyListeners();
    }
  }

  /// Refresh location in background (fire and forget)
  void _refreshLocationInBackground(double radiusKm) {
    Future(() async {
      try {
        final freshPosition = await LocationService.getCurrentPosition(forceRefresh: true);
        if (freshPosition != null &&
            (freshPosition.latitude != _userPosition?.latitude ||
             freshPosition.longitude != _userPosition?.longitude)) {
          print('🔄 Location updated in background');
          _userPosition = freshPosition;

          // Update country in background
          _loadCountryName(freshPosition);

          // Re-sort trips with new position
          await _loadTripsWithPosition(freshPosition, radiusKm);
        }
      } catch (e) {
        print('⚠️ Background location refresh failed: $e');
      }
    });
  }

  Future<void> _loadLocationAndNearbyTrips(double radiusKm) async {
    _isLoadingLocation = true;
    notifyListeners();

    try {
      // Получаем текущую позицию
      final position = await LocationService.getCurrentPosition();

      if (position == null) {
        print('⚠️ Could not get position, using featured trips');
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      _userPosition = position;
      print('📍 User position: ${position.latitude}, ${position.longitude}');

      // Получаем название страны в фоне
      _loadCountryName(position);

      // Загружаем все публичные трипы
      final allTrips = await _repository.getPublicTrips(limit: 100);
      print('📦 Total public trips loaded: ${allTrips.length}');

      // Фильтруем по радиусу и сортируем по расстоянию
      final tripsWithDistance = <Map<String, dynamic>>[];

      for (var trip in allTrips) {
        if (trip.latitude != null && trip.longitude != null) {
          final distance = LocationService.calculateDistance(
            position.latitude,
            position.longitude,
            trip.latitude!,
            trip.longitude!,
          );

          if (distance <= radiusKm) {
            tripsWithDistance.add({
              'trip': trip,
              'distance': distance,
            });
          }
        }
      }

      print('🎯 Trips within ${radiusKm}km: ${tripsWithDistance.length}');

      // Сортируем по расстоянию
      tripsWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      if (tripsWithDistance.isNotEmpty) {
        _nearbyPublicTrips =
            tripsWithDistance.map((item) => item['trip'] as Trip).toList();
        print('✅ Updated to ${_nearbyPublicTrips.length} nearby public trips');
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading nearby public trips: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  Future<void> _loadCountryName(Position position) async {
    try {
      _currentCountry = await LocationService.getCountryFromPosition(position);
      print('🌍 Current country: $_currentCountry');
      notifyListeners();
    } catch (e) {
      print('⚠️ Could not get country name: $e');
    }
  }

  /// Получить расстояние до публичного трипа
  double? getDistanceToPublicTrip(Trip trip) {
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

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY TRIPS (Backward Compatibility)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Загрузить legacy featured trips
  Future<void> loadFeaturedLegacyTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _featuredLegacyTrips = await _repository.getFeaturedTrips();
      print(
          '✅ [PROVIDER] Loaded ${_featuredLegacyTrips.length} featured legacy trips');
    } catch (e) {
      _error = e.toString();
      print('❌ [PROVIDER] Error loading featured legacy trips: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Загрузить все legacy trips
  Future<void> loadAllLegacyTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _legacyTrips = await _repository.getAllTrips();
      print('✅ [PROVIDER] Loaded ${_legacyTrips.length} legacy trips');
    } catch (e) {
      _error = e.toString();
      print('❌ [PROVIDER] Error loading legacy trips: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Поиск legacy trips
  Future<List<TripModel>> searchLegacyTrips(String query) async {
    try {
      return await _repository.searchTrips(query);
    } catch (e) {
      print('❌ [PROVIDER] Error searching legacy trips: $e');
      return [];
    }
  }

  /// Получить legacy trips по стране
  Future<List<TripModel>> getLegacyTripsByCountry(String countryId) async {
    try {
      return await _repository.getTripsByCountry(countryId);
    } catch (e) {
      print('❌ [PROVIDER] Error getting legacy trips by country: $e');
      return [];
    }
  }

  /// Загрузить ближайшие legacy trips
  Future<void> loadNearbyLegacyTrips({double radiusKm = 3000}) async {
    _isLoadingLocation = true;
    _error = null;
    notifyListeners();

    try {
      final position = await LocationService.getCurrentPosition();

      if (position == null) {
        print('⚠️ Could not get position, loading featured legacy trips');
        await loadFeaturedLegacyTrips();
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      _userPosition = position;
      print('📍 User position: ${position.latitude}, ${position.longitude}');

      _currentCountry = await LocationService.getCountryFromPosition(position);
      print('🌍 Current country: $_currentCountry');

      final allTrips = await _repository.getFeaturedTrips();
      print('📦 Total legacy trips loaded: ${allTrips.length}');

      final tripsWithDistance = <Map<String, dynamic>>[];

      for (var trip in allTrips) {
        if (trip.latitude != null && trip.longitude != null) {
          final distance = LocationService.calculateDistance(
            position.latitude,
            position.longitude,
            trip.latitude!,
            trip.longitude!,
          );

          if (distance <= radiusKm) {
            tripsWithDistance.add({
              'trip': trip,
              'distance': distance,
            });
          }
        }
      }

      print(
          '🎯 Legacy trips within ${radiusKm}km: ${tripsWithDistance.length}');

      tripsWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      _nearbyLegacyTrips =
          tripsWithDistance.map((item) => item['trip'] as TripModel).toList();

      print('✅ Loaded ${_nearbyLegacyTrips.length} nearby legacy trips');

      if (_nearbyLegacyTrips.isEmpty) {
        print('⚠️ No nearby legacy trips found, using featured trips');
        await loadFeaturedLegacyTrips();
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error loading nearby legacy trips: $e');
      await loadFeaturedLegacyTrips();
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Получить расстояние до legacy trip
  double? getDistanceToLegacyTrip(TripModel trip) {
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

  // ═══════════════════════════════════════════════════════════════════════════
  // COUNTRIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Загрузить страны по континенту
  Future<void> loadCountriesByContinent(String continent) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _countries = await _repository.getCountriesByContinent(continent);
      print('✅ [PROVIDER] Loaded ${_countries.length} countries');
    } catch (e) {
      _error = e.toString();
      print('❌ [PROVIDER] Error loading countries: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Загрузить все страны
  Future<void> loadAllCountries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _countries = await _repository.getAllCountries();
      print('✅ [PROVIDER] Loaded ${_countries.length} countries');
    } catch (e) {
      _error = e.toString();
      print('❌ [PROVIDER] Error loading all countries: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Обновить локацию вручную
  Future<void> refreshLocation() async {
    await loadNearbyPublicTrips();
  }

  /// Загрузить все данные (initial load)
  Future<void> loadInitialData() async {
    await Future.wait([
      loadFeaturedPublicTrips(),
      loadFeaturedLegacyTrips(),
    ]);
  }

  /// Очистить все данные
  void clearAll() {
    _publicTrips = [];
    _featuredPublicTrips = [];
    _nearbyPublicTrips = [];
    _legacyTrips = [];
    _featuredLegacyTrips = [];
    _nearbyLegacyTrips = [];
    _countries = [];
    _userPosition = null;
    _currentCountry = null;
    _selectedActivity = null;
    _selectedContinent = null;
    _error = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isSearching = false;
  List<dynamic> _searchResults = [];

  bool get isSearching => _isSearching;
  List<dynamic> get searchResults => _searchResults;

  /// Поиск трипов по городу
  Future<void> searchTripsByCity(String cityQuery) async {
    if (cityQuery.trim().isEmpty) {
      clearSearch();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      // Поиск по public trips (searches by title, city, country)
      final publicResults = await _repository.searchPublicTrips(
        cityQuery.trim(),
      );

      // Поиск по legacy trips (searches by title only)
      final legacyResults = await _repository.searchTrips(
        cityQuery.trim(),
      );

      _searchResults = [...publicResults, ...legacyResults];
      print('🔍 Search results for "$cityQuery": ${_searchResults.length} trips');
    } catch (e) {
      _error = e.toString();
      print('❌ [PROVIDER] Search error: $e');
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  /// Очистить результаты поиска
  void clearSearch() {
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }
}
