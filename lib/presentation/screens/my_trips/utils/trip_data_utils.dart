/// Utility functions for My Trips data processing.
class MyTripDataUtils {
  MyTripDataUtils._();

  /// Restaurant categories to exclude from photos
  static const _restaurantCategories = ['breakfast', 'lunch', 'dinner'];

  /// Check if a place is a restaurant
  static bool _isRestaurant(Map<String, dynamic> place) {
    final category = place['category'] as String?;
    return _restaurantCategories.contains(category);
  }

  /// Parse price from various formats to double.
  static double? parsePrice(dynamic priceValue) {
    if (priceValue == null) return null;
    if (priceValue is num) return priceValue.toDouble();
    if (priceValue is String) {
      final cleaned = priceValue.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  /// Get activity type from trip data.
  static String? getActivityType(Map<String, dynamic> trip) {
    return trip['activity_type']?.toString();
  }

  /// Get trip title with fallback.
  static String getTitle(Map<String, dynamic> trip) {
    return trip['title'] ?? trip['name'] ?? 'Untitled Trip';
  }

  /// Get trip location string.
  static String getLocation(Map<String, dynamic> trip) {
    final city = trip['city'] ?? '';
    final country = trip['country'] ?? '';

    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    } else if (city.isNotEmpty) {
      return city;
    } else if (country.isNotEmpty) {
      return country;
    }
    return 'Unknown location';
  }

  /// Get duration string.
  static String? getDuration(Map<String, dynamic> trip) {
    final durationDays = trip['duration_days'];
    return durationDays != null ? '$durationDays days' : null;
  }

  /// Get formatted price string.
  static String? getPriceString(Map<String, dynamic> trip) {
    final price = trip['price'];
    final currency = trip['currency'] ?? 'EUR';
    if (price == null) return null;
    return '${currency == 'EUR' ? '€' : '\$'}$price';
  }

  /// Get trip rating.
  static double? getRating(Map<String, dynamic> trip) {
    final rating = trip['rating'];
    if (rating == null) return null;
    if (rating is num) return rating.toDouble();
    return null;
  }

  /// Check if trip is favorite.
  static bool isFavorite(Map<String, dynamic> trip) {
    return trip['is_favorite'] ?? false;
  }

  /// Get images list from trip with fallback handling.
  /// Returns up to [maxImages] images from various sources.
  static List<String> getImages(Map<String, dynamic> trip, {int maxImages = 4}) {
    List<String> images = [];

    // 1. Hero image first
    final heroImage = trip['hero_image_url'];
    if (heroImage != null && heroImage.toString().isNotEmpty) {
      images.add(heroImage.toString());
    }

    // 2. Get LIMITED images from trip.images array
    if (images.length < maxImages) {
      final tripImages = trip['images'];
      if (tripImages != null && tripImages is List) {
        int count = 0;
        for (var img in tripImages) {
          if (count >= 2) break; // Take only 2 photos from trip.images
          final url = img is String ? img : img['url']?.toString();
          if (url != null && url.isNotEmpty && !images.contains(url)) {
            images.add(url);
            count++;
            if (images.length >= maxImages) break;
          }
        }
      }
    }

    // 3. Extract from itinerary places (only FIRST image from each place, excluding restaurants)
    if (images.length < maxImages) {
      final itinerary = trip['itinerary'];
      if (itinerary != null && itinerary is List) {
        for (var day in itinerary) {
          if (images.length >= maxImages) break;

          final places = day['places'];
          if (places != null && places is List) {
            for (var place in places) {
              if (images.length >= maxImages) break;

              // Skip restaurants - only include places
              if (place is Map<String, dynamic> && _isRestaurant(place)) continue;

              // Take only FIRST image from place
              final placeImages = place['images'];
              if (placeImages != null && placeImages is List && placeImages.isNotEmpty) {
                final imageUrl = placeImages[0] is String
                    ? placeImages[0]
                    : placeImages[0]['url']?.toString();
                if (imageUrl != null &&
                    imageUrl.isNotEmpty &&
                    !images.contains(imageUrl)) {
                  images.add(imageUrl);
                  continue;
                }
              }

              // Fallback to image_url
              if (images.length < maxImages) {
                final imageUrl = place['image_url'];
                if (imageUrl != null &&
                    imageUrl.toString().isNotEmpty &&
                    !images.contains(imageUrl.toString())) {
                  images.add(imageUrl.toString());
                  continue;
                }
              }
            }
          }
        }
      }
    }

    return images;
  }

  /// Get first image from trip (excluding restaurant photos).
  static String? getFirstImage(Map<String, dynamic> trip) {
    // 1. Hero image first
    final heroImage = trip['hero_image_url'];
    if (heroImage != null && heroImage.toString().isNotEmpty) {
      return heroImage.toString();
    }

    // 2. First image from trip.images
    final tripImages = trip['images'];
    if (tripImages != null && tripImages is List && tripImages.isNotEmpty) {
      final img = tripImages[0];
      final url = img is String ? img : img['url']?.toString();
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    // 3. First image from itinerary (excluding restaurants)
    final itinerary = trip['itinerary'];
    if (itinerary != null && itinerary is List) {
      for (var day in itinerary) {
        final places = day['places'];
        if (places != null && places is List) {
          for (var place in places) {
            // Skip restaurants - only include places
            if (place is Map<String, dynamic> && _isRestaurant(place)) continue;

            final placeImages = place['images'];
            if (placeImages != null && placeImages is List && placeImages.isNotEmpty) {
              final imageUrl = placeImages[0] is String
                  ? placeImages[0]
                  : placeImages[0]['url']?.toString();
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return imageUrl;
              }
            }
            final imageUrl = place['image_url'];
            if (imageUrl != null && imageUrl.toString().isNotEmpty) {
              return imageUrl.toString();
            }
          }
        }
      }
    }

    return null;
  }
}
