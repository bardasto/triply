import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CacheManager {
  // ══════════════════════════════════════════════════════════════════════════
  // ✅ BOX NAMES
  // ══════════════════════════════════════════════════════════════════════════
  static const String _tripsBox = 'trips_cache';
  static const String _countriesBox = 'countries_cache';
  static const String _locationBox = 'location_cache';
  static const String _userBox = 'user_cache';
  static const String _settingsBox = 'settings_cache';

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ TTL (Time To Live)
  // ══════════════════════════════════════════════════════════════════════════
  static const Duration tripsTTL = Duration(hours: 24);
  static const Duration countriesTTL = Duration(days: 7);
  static const Duration locationTTL = Duration(hours: 1);
  static const Duration userTTL = Duration(days: 30);

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ INITIALIZATION
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> init() async {
    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox(_tripsBox),
      Hive.openBox(_countriesBox),
      Hive.openBox(_locationBox),
      Hive.openBox(_userBox),
      Hive.openBox(_settingsBox),
    ]);

    if (kDebugMode) {
      debugPrint('✅ [CACHE] All boxes initialized');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ TRIPS CACHE
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> cacheTrips({
    required String key,
    required List<Map<String, dynamic>> trips,
  }) async {
    final box = Hive.box(_tripsBox);
    await box.put(key, {
      'data': trips,
      'cached_at': DateTime.now().toIso8601String(),
    });
    if (kDebugMode) {
      debugPrint('💾 [CACHE] Cached ${trips.length} trips with key: $key');
    }
  }

  static List<Map<String, dynamic>>? getCachedTrips(String key) {
    final box = Hive.box(_tripsBox);
    final cached = box.get(key);

    if (cached == null) {
      if (kDebugMode) {
        debugPrint('❌ [CACHE] No cached trips for key: $key');
      }
      return null;
    }

    final cachedAt = DateTime.parse(cached['cached_at'] as String);
    final age = DateTime.now().difference(cachedAt);

    if (age > tripsTTL) {
      if (kDebugMode) {
        debugPrint('⏰ [CACHE] Trips cache expired for key: $key');
      }
      box.delete(key);
      return null;
    }

    final data = (cached['data'] as List).cast<Map<String, dynamic>>();
    if (kDebugMode) {
      debugPrint(
          '✅ [CACHE] Retrieved ${data.length} trips from cache (age: ${age.inHours}h)');
    }
    return data;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ COUNTRIES CACHE
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> cacheCountries(
      List<Map<String, dynamic>> countries) async {
    final box = Hive.box(_countriesBox);
    await box.put('all_countries', {
      'data': countries,
      'cached_at': DateTime.now().toIso8601String(),
    });
    if (kDebugMode) {
      debugPrint('💾 [CACHE] Cached ${countries.length} countries');
    }
  }

  static List<Map<String, dynamic>>? getCachedCountries() {
    final box = Hive.box(_countriesBox);
    final cached = box.get('all_countries');

    if (cached == null) {
      if (kDebugMode) {
        debugPrint('❌ [CACHE] No cached countries');
      }
      return null;
    }

    final cachedAt = DateTime.parse(cached['cached_at'] as String);
    final age = DateTime.now().difference(cachedAt);

    if (age > countriesTTL) {
      if (kDebugMode) {
        debugPrint('⏰ [CACHE] Countries cache expired');
      }
      box.delete('all_countries');
      return null;
    }

    final data = (cached['data'] as List).cast<Map<String, dynamic>>();
    if (kDebugMode) {
      debugPrint(
          '✅ [CACHE] Retrieved ${data.length} countries (age: ${age.inDays}d)');
    }
    return data;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ LOCATION CACHE
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> cacheLocation({
    required double latitude,
    required double longitude,
    String? country,
  }) async {
    final box = Hive.box(_locationBox);
    await box.put('current_location', {
      'latitude': latitude,
      'longitude': longitude,
      'country': country,
      'cached_at': DateTime.now().toIso8601String(),
    });
    if (kDebugMode) {
      debugPrint(
          '💾 [CACHE] Cached location: $latitude, $longitude ($country)');
    }
  }

  static Map<String, dynamic>? getCachedLocation() {
    final box = Hive.box(_locationBox);
    final cached = box.get('current_location');

    if (cached == null) {
      if (kDebugMode) {
        debugPrint('❌ [CACHE] No cached location');
      }
      return null;
    }

    final cachedAt = DateTime.parse(cached['cached_at'] as String);
    final age = DateTime.now().difference(cachedAt);

    if (age > locationTTL) {
      if (kDebugMode) {
        debugPrint('⏰ [CACHE] Location cache expired');
      }
      box.delete('current_location');
      return null;
    }

    if (kDebugMode) {
      debugPrint('✅ [CACHE] Retrieved location (age: ${age.inMinutes}m)');
    }
    return {
      'latitude': cached['latitude'] as double,
      'longitude': cached['longitude'] as double,
      'country': cached['country'] as String?,
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ USER PREFERENCES
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> cacheUserPreferences(
      Map<String, dynamic> preferences) async {
    final box = Hive.box(_userBox);
    await box.put('preferences', preferences);
    if (kDebugMode) {
      debugPrint('💾 [CACHE] Cached user preferences');
    }
  }

  static Map<String, dynamic>? getCachedUserPreferences() {
    final box = Hive.box(_userBox);
    return box.get('preferences') as Map<String, dynamic>?;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ APP SETTINGS
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> cacheSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  static T? getCachedSetting<T>(String key) {
    final box = Hive.box(_settingsBox);
    return box.get(key) as T?;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ CLEAR CACHE
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> clearTripsCache() async {
    final box = Hive.box(_tripsBox);
    await box.clear();
    if (kDebugMode) {
      debugPrint('🗑️ [CACHE] Trips cache cleared');
    }
  }

  static Future<void> clearCountriesCache() async {
    final box = Hive.box(_countriesBox);
    await box.clear();
    if (kDebugMode) {
      debugPrint('🗑️ [CACHE] Countries cache cleared');
    }
  }

  static Future<void> clearLocationCache() async {
    final box = Hive.box(_locationBox);
    await box.clear();
    if (kDebugMode) {
      debugPrint('🗑️ [CACHE] Location cache cleared');
    }
  }

  static Future<void> clearAllCache() async {
    await Future.wait([
      Hive.box(_tripsBox).clear(),
      Hive.box(_countriesBox).clear(),
      Hive.box(_locationBox).clear(),
    ]);
    if (kDebugMode) {
      debugPrint('🗑️ [CACHE] All cache cleared');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ CACHE STATS
  // ══════════════════════════════════════════════════════════════════════════
  static Map<String, int> getCacheStats() {
    return {
      'trips': Hive.box(_tripsBox).length,
      'countries': Hive.box(_countriesBox).length,
      'location': Hive.box(_locationBox).length,
      'user': Hive.box(_userBox).length,
      'settings': Hive.box(_settingsBox).length,
    };
  }
}
