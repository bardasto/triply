/// Helper functions for restaurant-related operations.
/// Extracted from main controller for better organization.
class RestaurantHelpers {
  RestaurantHelpers._();

  /// Categories that are considered restaurants
  static const restaurantCategories = ['breakfast', 'lunch', 'dinner'];

  /// Check if a category is a restaurant type
  static bool isRestaurantCategory(String? category) {
    return restaurantCategories.contains(category);
  }

  /// Get all restaurants from itinerary (both from restaurants[] and places[])
  static List<Map<String, dynamic>> getRestaurantsFromItinerary(
    Map<String, dynamic> trip,
  ) {
    final itinerary = trip['itinerary'] as List?;
    if (itinerary == null) return [];

    final allRestaurants = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var day in itinerary) {
      // From restaurants array
      final dayRestaurants = day['restaurants'] as List?;
      if (dayRestaurants != null) {
        for (var restaurant in dayRestaurants) {
          final id = restaurant['poi_id']?.toString() ?? restaurant['name'];
          if (!seenIds.contains(id)) {
            seenIds.add(id);
            allRestaurants.add(restaurant as Map<String, dynamic>);
          }
        }
      }

      // From places with restaurant categories
      final places = day['places'] as List?;
      if (places != null) {
        for (var place in places) {
          final category = place['category'] as String?;
          if (isRestaurantCategory(category)) {
            final id = place['poi_id']?.toString() ?? place['name'];
            if (!seenIds.contains(id)) {
              seenIds.add(id);
              allRestaurants.add(place as Map<String, dynamic>);
            }
          }
        }
      }
    }

    return allRestaurants;
  }

  /// Get restaurants currently in trip
  static List<Map<String, dynamic>> getRestaurantsInTrip(
    Map<String, dynamic> trip,
  ) {
    return getRestaurantsFromItinerary(trip);
  }

  /// Get set of identifiers for restaurants in trip
  static Set<String> getTripRestaurantIdentifiers(
    List<Map<String, dynamic>> restaurantsInTrip,
  ) {
    final identifiers = <String>{};

    for (var r in restaurantsInTrip) {
      if (r['poi_id'] != null) {
        identifiers.add(r['poi_id'].toString());
      }
      if (r['google_place_id'] != null) {
        identifiers.add(r['google_place_id'].toString());
      }
      if (r['name'] != null) {
        identifiers.add(r['name'].toString().toLowerCase());
      }
    }

    return identifiers;
  }

  /// Check if restaurant is in trip
  static bool isRestaurantInTrip(
    Map<String, dynamic> restaurant,
    Set<String> tripIdentifiers,
  ) {
    final poiId = restaurant['poi_id']?.toString();
    final googlePlaceId = restaurant['google_place_id']?.toString();
    final name = restaurant['name']?.toString().toLowerCase();

    return (poiId != null && tripIdentifiers.contains(poiId)) ||
        (googlePlaceId != null && tripIdentifiers.contains(googlePlaceId)) ||
        (name != null && tripIdentifiers.contains(name));
  }

  /// Get restaurants available but not in trip
  static List<Map<String, dynamic>> getAvailableRestaurantsNotInTrip({
    required List<Map<String, dynamic>> allAvailable,
    required List<Map<String, dynamic>> inTrip,
  }) {
    final tripIdentifiers = getTripRestaurantIdentifiers(inTrip);

    return allAvailable
        .where((r) => !isRestaurantInTrip(r, tripIdentifiers))
        .toList();
  }

  /// Get restaurants for replacement (excluding current one)
  static List<Map<String, dynamic>> getRestaurantsForReplacement({
    required List<Map<String, dynamic>> allAvailable,
    required List<Map<String, dynamic>> inTrip,
    required String currentRestaurantId,
  }) {
    final tripIdentifiers = getTripRestaurantIdentifiers(inTrip);

    return allAvailable.where((r) {
      final id = r['poi_id']?.toString() ?? r['name'];
      // Not the current one being replaced
      if (id == currentRestaurantId) return false;
      // Not already in trip (or is the current one)
      return !isRestaurantInTrip(r, tripIdentifiers);
    }).toList();
  }

  /// Replace restaurant in itinerary
  static void replaceRestaurant({
    required Map<String, dynamic> trip,
    required Map<String, dynamic> oldRestaurant,
    required Map<String, dynamic> newRestaurant,
  }) {
    final itinerary = trip['itinerary'] as List?;
    if (itinerary == null) return;

    final oldId = oldRestaurant['poi_id']?.toString() ?? oldRestaurant['name'];

    for (var day in itinerary) {
      // Check restaurants array
      final dayRestaurants = day['restaurants'] as List?;
      if (dayRestaurants != null) {
        final index = dayRestaurants.indexWhere(
            (r) => (r['poi_id']?.toString() ?? r['name']) == oldId);
        if (index != -1) {
          dayRestaurants[index] = newRestaurant;
          return;
        }
      }

      // Check places array
      final places = day['places'] as List?;
      if (places != null) {
        final index = places.indexWhere(
            (p) => (p['poi_id']?.toString() ?? p['name']) == oldId);
        if (index != -1) {
          places[index] = newRestaurant;
          return;
        }
      }
    }
  }

  /// Add new restaurant to first day of trip
  static void addNewRestaurant({
    required Map<String, dynamic> trip,
    required Map<String, dynamic> restaurant,
  }) {
    final itinerary = trip['itinerary'] as List?;
    if (itinerary == null || itinerary.isEmpty) return;

    final firstDay = itinerary[0] as Map<String, dynamic>;
    final places = firstDay['places'] as List? ?? [];
    places.add(restaurant);
    firstDay['places'] = places;
  }

  /// Get restaurants preview (first N restaurants)
  static List<Map<String, dynamic>> getRestaurantsPreview(
    List<Map<String, dynamic>> restaurants, {
    int count = 4,
  }) {
    return restaurants.take(count).toList();
  }
}
