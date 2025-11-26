import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  // Cache keys
  static const String _latKey = 'cached_latitude';
  static const String _lonKey = 'cached_longitude';
  static const String _countryKey = 'cached_country';
  static const String _timestampKey = 'cached_location_timestamp';

  // Cache duration (24 hours)
  static const Duration _cacheDuration = Duration(hours: 24);

  // In-memory cache for faster access
  static Position? _cachedPosition;
  static String? _cachedCountry;

  /// Get cached position instantly (non-blocking)
  /// Returns null if no cache exists
  static Future<Position?> getCachedPosition() async {
    // Return in-memory cache if available
    if (_cachedPosition != null) {
      return _cachedPosition;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_latKey);
      final lon = prefs.getDouble(_lonKey);

      if (lat != null && lon != null) {
        _cachedPosition = Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        debugPrint('📍 Using cached position: $lat, $lon');
        return _cachedPosition;
      }
    } catch (e) {
      debugPrint('⚠️ Error reading cached position: $e');
    }
    return null;
  }

  /// Get cached country name instantly (non-blocking)
  static Future<String?> getCachedCountry() async {
    if (_cachedCountry != null) {
      return _cachedCountry;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedCountry = prefs.getString(_countryKey);
      return _cachedCountry;
    } catch (e) {
      debugPrint('⚠️ Error reading cached country: $e');
    }
    return null;
  }

  /// Save position to cache
  static Future<void> _cachePosition(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latKey, position.latitude);
      await prefs.setDouble(_lonKey, position.longitude);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      _cachedPosition = position;
      debugPrint('💾 Position cached: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('⚠️ Error caching position: $e');
    }
  }

  /// Save country to cache
  static Future<void> _cacheCountry(String country) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_countryKey, country);
      _cachedCountry = country;
      debugPrint('💾 Country cached: $country');
    } catch (e) {
      debugPrint('⚠️ Error caching country: $e');
    }
  }

  /// Check if cache is still valid
  static Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);
      if (timestamp == null) return false;

      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return DateTime.now().difference(cachedTime) < _cacheDuration;
    } catch (e) {
      return false;
    }
  }

  /// Get current position with caching
  /// Returns cached position immediately, then updates in background
  static Future<Position?> getCurrentPosition({
    bool forceRefresh = false,
  }) async {
    // If not forcing refresh and cache is valid, return cached
    if (!forceRefresh && await _isCacheValid()) {
      final cached = await getCachedPosition();
      if (cached != null) {
        // Still refresh in background for next time
        _refreshPositionInBackground();
        return cached;
      }
    }

    // Get fresh position
    return await _fetchFreshPosition();
  }

  /// Fetch fresh position from GPS
  static Future<Position?> _fetchFreshPosition() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permissions denied');
          return await getCachedPosition(); // Fallback to cache
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions permanently denied');
        return await getCachedPosition(); // Fallback to cache
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Faster than high
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () async {
          debugPrint('⚠️ Location timeout, trying last known');
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            return lastKnown;
          }
          throw Exception('Location timeout');
        },
      );

      debugPrint('✅ Fresh position: ${position.latitude}, ${position.longitude}');

      // Cache the new position
      await _cachePosition(position);

      return position;
    } catch (e) {
      debugPrint('❌ Error getting position: $e');
      return await getCachedPosition(); // Fallback to cache
    }
  }

  /// Refresh position in background (fire and forget)
  static void _refreshPositionInBackground() {
    Future(() async {
      await _fetchFreshPosition();
    });
  }

  /// Get country from position (with caching)
  static Future<String?> getCountryFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final country = placemarks.first.country;
        if (country != null) {
          await _cacheCountry(country);
          debugPrint('✅ Country: $country');
          return country;
        }
      }
      return await getCachedCountry();
    } catch (e) {
      debugPrint('❌ Error getting country: $e');
      return await getCachedCountry(); // Fallback to cache
    }
  }

  /// Calculate distance between two points (in km)
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
        1000;
  }

  /// Check if place is within radius
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

  /// Initialize location service (call on app start)
  /// Preloads cache and starts background refresh
  static Future<void> initialize() async {
    debugPrint('🚀 Initializing LocationService...');

    // Load cache into memory
    await getCachedPosition();
    await getCachedCountry();

    // Start background refresh if cache exists
    if (_cachedPosition != null) {
      _refreshPositionInBackground();
    }
  }
}
