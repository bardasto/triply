import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';

class TripDetailsUtils {
  static Color getCategoryColor(String? category) {
    switch (category) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.deepPurple;
      case 'attraction':
        return AppColors.primary;
      default:
        return Colors.orange;
    }
  }

  static String getCategoryLabel(String? category) {
    switch (category) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'attraction':
        return 'Attraction';
      default:
        return 'Restaurant';
    }
  }

  static IconData getCategoryIcon(String? category) {
    switch (category) {
      case 'attraction':
        return Icons.museum;
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  static Widget buildCategoryIconWidget(String? category, {bool isDark = false}) {
    final icon = getCategoryIcon(category);
    final color = getCategoryColor(category);

    return Center(
      child: Icon(icon, size: 24, color: color),
    );
  }

  static String? getImageUrl(Map<String, dynamic> item) {
    String? imageUrl;

    // Try to get first image from images[] array
    if (item['images'] != null && item['images'] is List) {
      final images = item['images'] as List;
      if (images.isNotEmpty && images[0] is Map) {
        imageUrl = (images[0] as Map)['url']?.toString();
      }
    }

    // Fallback to image_url
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = item['image_url'] as String?;
    }

    return imageUrl;
  }

  static List<String> extractImagesFromTrip(Map<String, dynamic> trip) {
    final List<String> result = [];

    // 1. Hero image
    final heroUrl = trip['hero_image_url'];
    if (heroUrl != null && heroUrl is String && heroUrl.isNotEmpty) {
      result.add(heroUrl);
    }

    // 2. One photo per place in itinerary
    final itinerary = trip['itinerary'];
    if (itinerary != null && itinerary is List) {
      for (var day in itinerary) {
        if (day is! Map) continue;

        final places = day['places'];
        if (places != null && places is List) {
          for (var place in places) {
            if (place is! Map) continue;

            final imageUrl = getImageUrl(place as Map<String, dynamic>);
            if (imageUrl != null && imageUrl.isNotEmpty && !result.contains(imageUrl)) {
              result.add(imageUrl);
            }
          }
        }
      }
    }

    // 3. Fallback
    if (result.isEmpty) {
      final fallbackUrl = trip['image_url'] ??
          'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800';
      result.add(fallbackUrl as String);
    }

    return result;
  }
}
