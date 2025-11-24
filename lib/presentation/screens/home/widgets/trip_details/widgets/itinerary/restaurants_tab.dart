import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';
import '../../utils/restaurant_helpers.dart';
import 'restaurant_card.dart';

/// Tab content displaying restaurants from the itinerary.
class RestaurantsTab extends StatelessWidget {
  final List<dynamic> itinerary;
  final bool isDark;
  final Map<String, dynamic> trip;
  final Function(Map<String, dynamic>) onReplaceRestaurant;
  final Function(Map<String, dynamic>) onDeleteRestaurant;
  final VoidCallback onViewAllOnMap;
  final int previewCount;

  const RestaurantsTab({
    super.key,
    required this.itinerary,
    required this.isDark,
    required this.trip,
    required this.onReplaceRestaurant,
    required this.onDeleteRestaurant,
    required this.onViewAllOnMap,
    this.previewCount = 4,
  });

  List<Map<String, dynamic>> get _restaurants {
    return RestaurantHelpers.getRestaurantsFromItinerary(trip);
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = _restaurants;

    if (restaurants.isEmpty) {
      return _buildEmptyState();
    }

    final previewRestaurants =
        RestaurantHelpers.getRestaurantsPreview(restaurants, count: previewCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...previewRestaurants.map((restaurant) => RestaurantCard(
              restaurant: restaurant,
              trip: trip,
              isDark: isDark,
              onReplace: () => onReplaceRestaurant(restaurant),
              onDelete: () => onDeleteRestaurant(restaurant),
            )),
        const SizedBox(height: 8),
        _buildViewAllButton(),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = TripDetailsTheme.of(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: theme.surfaceDecoration,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: theme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No restaurants added yet',
              style: theme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton() {
    return InkWell(
      onTap: onViewAllOnMap,
      borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'View All Restaurants on Map',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
