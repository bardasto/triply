import '../../../../core/models/trip.dart';
import '../../../../core/models/trip_model.dart';

/// Utility functions for trip data processing.
class TripDataUtils {
  TripDataUtils._();

  /// Parse price string to double.
  static double? parsePrice(String? priceStr) {
    if (priceStr == null || priceStr.isEmpty) return null;
    final cleaned = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned);
  }

  /// Convert Trip or TripModel to Map for TripDetailsBottomSheet.
  static Map<String, dynamic>? toTripData(dynamic trip) {
    if (trip is Trip) {
      return _tripToMap(trip);
    } else if (trip is TripModel) {
      return _tripModelToMap(trip);
    }
    return null;
  }

  static Map<String, dynamic> _tripToMap(Trip trip) {
    List<Map<String, dynamic>> itineraryData = [];
    if (trip.itinerary != null) {
      itineraryData = trip.itinerary!.map((day) => day.toJson()).toList();
    }

    return {
      'id': trip.id,
      'title': trip.title,
      'description': trip.description,
      'duration': trip.duration,
      'price': trip.price,
      'rating': trip.rating,
      'reviews': trip.reviews,
      'images': trip.images?.map((img) => img.url).toList() ?? [],
      'includes': trip.includes ?? [],
      'highlights': trip.highlights ?? [],
      'itinerary': itineraryData,
      'image_url': trip.primaryImageUrl,
      'hero_image_url': trip.heroImageUrl ?? trip.primaryImageUrl,
      'city': trip.city,
      'country': trip.country,
      'latitude': trip.latitude,
      'longitude': trip.longitude,
    };
  }

  static Map<String, dynamic> _tripModelToMap(TripModel trip) {
    return {
      'id': trip.id,
      'title': trip.title,
      'description': trip.description,
      'duration': trip.duration,
      'price': trip.price,
      'rating': trip.rating,
      'reviews': trip.reviews,
      'images': trip.images,
      'includes': trip.includes,
      'highlights': trip.highlights ?? [],
      'itinerary': trip.itinerary ?? [],
      'image_url': trip.imageUrl,
      'hero_image_url': trip.imageUrl,
      'city': trip.city,
      'country': trip.country,
      'latitude': trip.latitude,
      'longitude': trip.longitude,
    };
  }

  /// Get images from trip with fallback handling.
  static List<String> getImages(dynamic trip, {int maxImages = 5}) {
    if (trip is Trip) {
      return _getTripImages(trip, maxImages);
    } else if (trip is TripModel) {
      return trip.images ?? const [];
    }
    return [];
  }

  static List<String> _getTripImages(Trip trip, int maxImages) {
    List<String> images = [];

    // 1. Hero image first
    if (trip.heroImageUrl != null && trip.heroImageUrl!.isNotEmpty) {
      images.add(trip.heroImageUrl!);
    }

    // 2. Get images from trip.images array
    if (trip.images != null && trip.images!.isNotEmpty) {
      final tripImages = trip.images!.map((img) => img.url).toList();
      for (var url in tripImages) {
        if (!images.contains(url)) {
          images.add(url);
        }
      }
    }

    // 3. Extract from itinerary places if we need more images
    if (images.length < maxImages && trip.itinerary != null) {
      for (var day in trip.itinerary!) {
        if (day.places != null) {
          for (var place in day.places!) {
            if (place.images != null && place.images!.isNotEmpty) {
              final imageUrl = place.images![0]['url']?.toString();
              if (imageUrl != null &&
                  imageUrl.isNotEmpty &&
                  !images.contains(imageUrl)) {
                images.add(imageUrl);
                if (images.length >= maxImages) break;
              }
            } else if (place.imageUrl != null &&
                place.imageUrl!.isNotEmpty &&
                !images.contains(place.imageUrl!)) {
              images.add(place.imageUrl!);
              if (images.length >= maxImages) break;
            }
          }
        }
        if (images.length >= maxImages) break;
      }
    }

    return images;
  }

  /// Get first image from trip.
  static String? getFirstImage(dynamic trip) {
    if (trip is Trip) {
      final heroImage = trip.heroImageUrl;
      if (heroImage != null && heroImage.isNotEmpty) {
        return heroImage;
      }
      final tripImages = trip.images;
      if (tripImages != null && tripImages.isNotEmpty) {
        return tripImages[0].url;
      }
    } else if (trip is TripModel) {
      final images = trip.images;
      if (images != null && images.isNotEmpty) {
        return images.first;
      }
      return trip.imageUrl;
    }
    return null;
  }

  /// Get trip title.
  static String getTitle(dynamic trip) {
    if (trip is Trip) return trip.title;
    if (trip is TripModel) return trip.title;
    return '';
  }

  /// Get trip location string.
  static String getLocation(dynamic trip) {
    if (trip is Trip) return '${trip.city}, ${trip.country}';
    if (trip is TripModel) return '${trip.city}, ${trip.country}';
    return '';
  }

  /// Get trip duration.
  static String? getDuration(dynamic trip) {
    if (trip is Trip) return trip.duration;
    if (trip is TripModel) return trip.duration;
    return null;
  }

  /// Get trip price.
  static String? getPrice(dynamic trip) {
    if (trip is Trip) return trip.price;
    if (trip is TripModel) return trip.price;
    return null;
  }

  /// Get trip rating.
  static double? getRating(dynamic trip) {
    if (trip is Trip) return trip.rating;
    if (trip is TripModel) return trip.rating;
    return null;
  }

  /// Get trip activity type.
  static String? getActivityType(dynamic trip) {
    if (trip is Trip) return trip.activityType;
    if (trip is TripModel) return trip.activityType;
    return null;
  }
}
