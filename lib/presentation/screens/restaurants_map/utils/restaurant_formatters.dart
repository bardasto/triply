import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';

/// Utilities for formatting restaurant data
class RestaurantFormatters {
  /// Format opening hours from Map or String to display string
  static String formatOpeningHours(dynamic openingHours) {
    if (openingHours == null) return '';

    if (openingHours is String) {
      return openingHours;
    }

    if (openingHours is Map<String, dynamic>) {
      if (openingHours.containsKey('weekday_text')) {
        final weekdayText = openingHours['weekday_text'];
        if (weekdayText is List && weekdayText.isNotEmpty) {
          return weekdayText.first.toString();
        }
      }
      return 'Hours available';
    }

    return '';
  }

  /// Format price level to euros string (e.g., 2 -> "€€")
  static String? formatPriceLevel(dynamic priceLevel) {
    if (priceLevel == null) return null;

    int level = 0;
    if (priceLevel is int) {
      level = priceLevel;
    } else if (priceLevel is String) {
      level = int.tryParse(priceLevel) ?? 0;
    } else if (priceLevel is double) {
      level = priceLevel.round();
    }

    if (level <= 0 || level > 4) return null;

    return '€' * level;
  }

  /// Format cuisine types array to display string
  static String? formatCuisineTypes(dynamic cuisineTypes) {
    if (cuisineTypes == null) return null;

    if (cuisineTypes is List && cuisineTypes.isNotEmpty) {
      final types = cuisineTypes
          .where((type) => type != null && type.toString().isNotEmpty)
          .map((type) => type.toString())
          .toList();

      if (types.isEmpty) return null;

      return types.join(', ');
    } else if (cuisineTypes is String && cuisineTypes.isNotEmpty) {
      return cuisineTypes;
    }

    return null;
  }

  /// Get category label
  static String getCategoryLabel(String? category) {
    switch (category) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return 'Restaurant';
    }
  }

  /// Get category color
  static Color getCategoryColor(String? category) {
    switch (category) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.amber;
      case 'dinner':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  /// Get category icon
  static IconData getCategoryIcon(String? category) {
    switch (category) {
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

  /// Get price level as int for sorting
  static int getPriceLevel(dynamic priceLevel) {
    if (priceLevel == null) return 0;

    if (priceLevel is int) {
      return priceLevel;
    } else if (priceLevel is String) {
      return int.tryParse(priceLevel) ?? 0;
    } else if (priceLevel is double) {
      return priceLevel.round();
    }

    return 0;
  }

  /// Extract images from restaurant data
  static List<String> extractImages(Map<String, dynamic> restaurant) {
    final List<String> images = [];

    if (restaurant['images'] != null && restaurant['images'] is List) {
      for (var img in restaurant['images'] as List) {
        if (img is Map && img['url'] != null) {
          final url = img['url'].toString();
          if (url.isNotEmpty) {
            images.add(url);
          }
        } else if (img is String && img.isNotEmpty) {
          images.add(img);
        }
      }
    } else if (restaurant['image_url'] != null) {
      images.add(restaurant['image_url'] as String);
    }

    return images;
  }
}
