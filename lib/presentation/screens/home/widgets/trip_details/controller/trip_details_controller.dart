import 'package:flutter/material.dart';
import '../../../../../../core/data/repositories/restaurant_repository.dart';
import '../models/trip_details_state.dart';
import '../utils/trip_details_utils.dart';
import '../utils/restaurant_helpers.dart';

/// Controller managing all business logic for TripDetails.
/// Separates concerns from UI widgets for better testability.
class TripDetailsController {
  final Map<String, dynamic> trip;
  final RestaurantRepository _restaurantRepository;
  final TripDetailsStateNotifier stateNotifier;
  final PageController pageController;
  final TabController tabController;

  TripDetailsController({
    required this.trip,
    required this.tabController,
    RestaurantRepository? restaurantRepository,
  })  : _restaurantRepository = restaurantRepository ?? RestaurantRepository(),
        stateNotifier = TripDetailsStateNotifier(),
        pageController = PageController() {
    _initTabListener();
  }

  void _initTabListener() {
    tabController.addListener(() {
      stateNotifier.updateTabIndex(tabController.index);
    });
  }

  TripDetailsState get state => stateNotifier.value;

  /// Get current images based on selection state
  List<String> get currentImages {
    if (state.hasSelectedPlaces) {
      return state.filteredImages;
    }
    return TripDetailsUtils.extractImagesFromTrip(trip);
  }

  /// Load restaurants from database
  Future<void> loadRestaurantsFromDatabase() async {
    final city = trip['city'] as String?;
    if (city == null || city.isEmpty) return;

    stateNotifier.setLoadingRestaurants(true);

    try {
      final restaurants =
          await _restaurantRepository.getRestaurantsAsPlaceMaps(city);
      stateNotifier.setDatabaseRestaurants(restaurants);
    } catch (e) {
      stateNotifier.setLoadingRestaurants(false);
    }
  }

  /// Handle image page change
  void onImageChanged(int index) {
    stateNotifier.updateImageIndex(index);
  }

  /// Toggle description expansion
  void toggleDescription() {
    stateNotifier.toggleDescription();
  }

  /// Toggle place selection for photo filtering
  void togglePlaceSelection(String placeId) {
    stateNotifier.togglePlaceSelection(placeId);
    _updateFilteredImages();

    if (state.filteredImages.isNotEmpty) {
      pageController.jumpToPage(0);
    }
  }

  /// Clear all place selections
  void clearPlaceSelection() {
    stateNotifier.clearPlaceSelection();
  }

  /// Update filtered images based on selected places
  void _updateFilteredImages() {
    final filteredImages = <String>[];

    if (!state.hasSelectedPlaces) {
      stateNotifier.setFilteredImages([]);
      return;
    }

    final itinerary = trip['itinerary'] as List?;
    if (itinerary == null) {
      stateNotifier.setFilteredImages([]);
      return;
    }

    for (var day in itinerary) {
      final places = day['places'] as List?;
      if (places == null) continue;

      for (var place in places) {
        final placeId = place['poi_id']?.toString() ?? place['name'];
        if (state.isPlaceSelected(placeId)) {
          final imageUrl = TripDetailsUtils.getImageUrl(place);
          if (imageUrl != null && imageUrl.isNotEmpty) {
            filteredImages.add(imageUrl);
          }
        }
      }
    }

    if (filteredImages.isEmpty && trip['hero_image_url'] != null) {
      filteredImages.add(trip['hero_image_url'] as String);
    }

    stateNotifier.setFilteredImages(filteredImages);
  }

  /// Toggle day expansion
  void toggleDayExpanded(int dayNumber) {
    stateNotifier.toggleDayExpanded(dayNumber);
  }

  /// Delete a place from itinerary
  void deletePlace(Map<String, dynamic> place) {
    final itinerary = trip['itinerary'] as List?;
    if (itinerary != null) {
      for (var day in itinerary) {
        final places = day['places'] as List?;
        if (places != null) {
          places.removeWhere((p) =>
              (p['poi_id']?.toString() ?? p['name']) ==
              (place['poi_id']?.toString() ?? place['name']));
        }
      }
    }

    final placeId = place['poi_id']?.toString() ?? place['name'];
    if (state.isPlaceSelected(placeId)) {
      togglePlaceSelection(placeId);
    }
    _updateFilteredImages();
  }

  /// Get all place IDs currently in the trip (excluding restaurants)
  Set<String> getAllPlaceIdsInTrip() {
    final ids = <String>{};
    final itinerary = trip['itinerary'] as List?;

    if (itinerary != null) {
      for (var day in itinerary) {
        final places = day['places'] as List?;
        if (places != null) {
          for (var place in places) {
            final category = place['category'] as String? ?? 'attraction';
            // Exclude restaurants
            if (category != 'restaurant' &&
                category != 'cafe' &&
                category != 'bar') {
              final placeId = place['poi_id']?.toString() ?? place['name'];
              ids.add(placeId);
            }
          }
        }
      }
    }

    return ids;
  }

  /// Replace a place in itinerary with a new one
  void replacePlace(
    Map<String, dynamic> oldPlace,
    Map<String, dynamic> newPlace,
  ) {
    final oldPlaceId = oldPlace['poi_id']?.toString() ?? oldPlace['name'];
    final itinerary = trip['itinerary'] as List?;

    if (itinerary != null) {
      for (var day in itinerary) {
        final places = day['places'] as List?;
        if (places != null) {
          final index = places.indexWhere(
              (p) => (p['poi_id']?.toString() ?? p['name']) == oldPlaceId);
          if (index != -1) {
            places[index] = Map<String, dynamic>.from(newPlace);
            break;
          }
        }
      }
    }

    // Update selection if needed
    if (state.isPlaceSelected(oldPlaceId)) {
      togglePlaceSelection(oldPlaceId);
      final newPlaceId = newPlace['poi_id']?.toString() ?? newPlace['name'];
      togglePlaceSelection(newPlaceId);
    }
    _updateFilteredImages();
  }

  /// Edit place data
  void editPlace(
      Map<String, dynamic> place, String name, int? durationMinutes) {
    place['name'] = name;
    if (durationMinutes != null) {
      place['duration_minutes'] = durationMinutes;
    }
  }

  /// Add new place to a day
  void addPlaceToDay(
    Map<String, dynamic> day,
    String name,
    String category,
    int? durationMinutes,
  ) {
    final places = day['places'] as List? ?? [];
    places.add({
      'name': name,
      'category': category,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
    });
    day['places'] = places;
  }

  /// Delete restaurant from itinerary
  void deleteRestaurant(Map<String, dynamic> restaurant) {
    final restaurantId =
        restaurant['poi_id']?.toString() ?? restaurant['name'];
    final itinerary = trip['itinerary'] as List?;

    if (itinerary != null) {
      for (var day in itinerary) {
        final dayRestaurants = day['restaurants'] as List?;
        if (dayRestaurants != null) {
          dayRestaurants.removeWhere(
              (r) => (r['poi_id']?.toString() ?? r['name']) == restaurantId);
        }

        final places = day['places'] as List?;
        if (places != null) {
          places.removeWhere(
              (p) => (p['poi_id']?.toString() ?? p['name']) == restaurantId);
        }
      }
    }
  }

  /// Replace restaurant in itinerary
  void replaceRestaurant(
    Map<String, dynamic> oldRestaurant,
    Map<String, dynamic> newRestaurant,
  ) {
    RestaurantHelpers.replaceRestaurant(
      trip: trip,
      oldRestaurant: oldRestaurant,
      newRestaurant: newRestaurant,
    );
  }

  /// Add new restaurant to trip
  void addRestaurant(Map<String, dynamic> restaurant) {
    RestaurantHelpers.addNewRestaurant(trip: trip, restaurant: restaurant);
  }

  /// Get all available restaurants
  List<Map<String, dynamic>> getAllAvailableRestaurants() {
    if (state.databaseRestaurants.isNotEmpty) {
      return state.databaseRestaurants;
    }
    return RestaurantHelpers.getRestaurantsFromItinerary(trip);
  }

  /// Get restaurants currently in trip
  List<Map<String, dynamic>> getRestaurantsInTrip() {
    return RestaurantHelpers.getRestaurantsInTrip(trip);
  }

  /// Get available restaurants not in trip
  List<Map<String, dynamic>> getAvailableRestaurantsNotInTrip() {
    return RestaurantHelpers.getAvailableRestaurantsNotInTrip(
      allAvailable: getAllAvailableRestaurants(),
      inTrip: getRestaurantsInTrip(),
    );
  }

  /// Get filtered restaurants for replacement (excluding current one)
  List<Map<String, dynamic>> getRestaurantsForReplacement(
      String currentRestaurantId) {
    return RestaurantHelpers.getRestaurantsForReplacement(
      allAvailable: getAllAvailableRestaurants(),
      inTrip: getRestaurantsInTrip(),
      currentRestaurantId: currentRestaurantId,
    );
  }

  /// Mark sheet as closing
  void setClosing() {
    stateNotifier.setClosing(true);
  }

  /// Dispose resources
  void dispose() {
    pageController.dispose();
    stateNotifier.dispose();
  }
}
