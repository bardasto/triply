import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';
import '../../utils/trip_details_utils.dart';
import 'restaurant_card.dart';

/// Tab content displaying restaurants from the itinerary grouped by days.
class RestaurantsTab extends StatefulWidget {
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

  @override
  State<RestaurantsTab> createState() => _RestaurantsTabState();
}

class _RestaurantsTabState extends State<RestaurantsTab> {
  final Map<int, bool> _expandedDays = {};

  /// Get restaurants for a specific day
  List<Map<String, dynamic>> _getRestaurantsForDay(Map<String, dynamic> day) {
    final List<Map<String, dynamic>> restaurants = [];

    // From restaurants array
    final dayRestaurants = day['restaurants'] as List?;
    if (dayRestaurants != null) {
      for (var r in dayRestaurants) {
        restaurants.add(r as Map<String, dynamic>);
      }
    }

    // From places with restaurant categories
    final places = day['places'] as List?;
    if (places != null) {
      final restaurantsFromPlaces = TripDetailsUtils.getRestaurantsFromPlaces(places);
      restaurants.addAll(restaurantsFromPlaces);
    }

    return restaurants;
  }

  @override
  Widget build(BuildContext context) {
    // Check if any day has restaurants
    bool hasAnyRestaurants = false;
    for (var day in widget.itinerary) {
      final restaurants = _getRestaurantsForDay(day as Map<String, dynamic>);
      if (restaurants.isNotEmpty) {
        hasAnyRestaurants = true;
        break;
      }
    }

    if (!hasAnyRestaurants) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Build day cards with restaurants
        ...widget.itinerary.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value as Map<String, dynamic>;
          final dayRestaurants = _getRestaurantsForDay(day);

          if (dayRestaurants.isEmpty) return const SizedBox.shrink();

          return _buildRestaurantDayCard(day, index, dayRestaurants);
        }),
        const SizedBox(height: 8),
        _buildViewAllButton(),
      ],
    );
  }

  Widget _buildRestaurantDayCard(
    Map<String, dynamic> day,
    int index,
    List<Map<String, dynamic>> restaurants,
  ) {
    final theme = TripDetailsTheme.of(widget.isDark);
    final dayNumber = day['day'] ?? (index + 1);
    final dayTitle = day['title'] ?? 'Day ${index + 1}';
    final isExpanded = _expandedDays[dayNumber] ?? false;

    return Column(
      children: [
        // Day header with bounce effect
        _RestaurantDayHeader(
          dayNumber: dayNumber,
          dayTitle: dayTitle,
          restaurantCount: restaurants.length,
          isExpanded: isExpanded,
          theme: theme,
          onToggle: () {
            setState(() {
              _expandedDays[dayNumber] = !isExpanded;
            });
          },
        ),
        // Expandable content
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          sizeCurve: Curves.easeOutCubic,
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: restaurants.map((restaurant) {
                return RestaurantCard(
                  restaurant: restaurant,
                  trip: widget.trip,
                  isDark: widget.isDark,
                  onReplace: () => widget.onReplaceRestaurant(restaurant),
                  onDelete: () => widget.onDeleteRestaurant(restaurant),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = TripDetailsTheme.of(widget.isDark);

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
      onTap: widget.onViewAllOnMap,
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

/// Day header for restaurants tab with bounce effect
class _RestaurantDayHeader extends StatefulWidget {
  final dynamic dayNumber;
  final String dayTitle;
  final int restaurantCount;
  final bool isExpanded;
  final TripDetailsTheme theme;
  final VoidCallback onToggle;

  const _RestaurantDayHeader({
    required this.dayNumber,
    required this.dayTitle,
    required this.restaurantCount,
    required this.isExpanded,
    required this.theme,
    required this.onToggle,
  });

  @override
  State<_RestaurantDayHeader> createState() => _RestaurantDayHeaderState();
}

class _RestaurantDayHeaderState extends State<_RestaurantDayHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _bounceController.forward(),
      onTapUp: (_) {
        _bounceController.reverse();
        widget.onToggle();
      },
      onTapCancel: () => _bounceController.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _buildDayBadge(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dayTitle,
                      style: widget.theme.bodyLarge,
                    ),
                    Text(
                      '${widget.restaurantCount} restaurant${widget.restaurantCount != 1 ? 's' : ''}',
                      style: widget.theme.bodySmall.copyWith(
                        color: widget.theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: widget.isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: widget.theme.textSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayBadge() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${widget.dayNumber}',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
