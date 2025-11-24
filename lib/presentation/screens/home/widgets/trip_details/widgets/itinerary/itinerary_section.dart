import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';
import 'itinerary_tab_bar.dart';
import 'places_tab.dart';
import 'restaurants_tab.dart';

/// Complete itinerary section with tabs for places and restaurants.
class ItinerarySection extends StatelessWidget {
  final List<dynamic>? itinerary;
  final bool isDark;
  final Map<String, dynamic> trip;
  final TabController tabController;
  final Set<String> selectedPlaceIds;
  final Map<int, bool> expandedDays;
  final VoidCallback onClearSelection;
  final Function(int) onToggleDayExpanded;
  final Function(Map<String, dynamic>) onAddPlaceToDay;
  final Function(Map<String, dynamic>) onEditPlace;
  final Function(Map<String, dynamic>) onDeletePlace;
  final Function(Map<String, dynamic>) onReplacePlace;
  final Function(String) onToggleSelection;
  final Function(Map<String, dynamic>)? onPlaceLongPress;
  final Function(Map<String, dynamic>) onReplaceRestaurant;
  final Function(Map<String, dynamic>) onDeleteRestaurant;
  final VoidCallback onViewAllRestaurantsOnMap;

  const ItinerarySection({
    super.key,
    required this.itinerary,
    required this.isDark,
    required this.trip,
    required this.tabController,
    required this.selectedPlaceIds,
    required this.expandedDays,
    required this.onClearSelection,
    required this.onToggleDayExpanded,
    required this.onAddPlaceToDay,
    required this.onEditPlace,
    required this.onDeletePlace,
    required this.onReplacePlace,
    required this.onToggleSelection,
    this.onPlaceLongPress,
    required this.onReplaceRestaurant,
    required this.onDeleteRestaurant,
    required this.onViewAllRestaurantsOnMap,
  });

  @override
  Widget build(BuildContext context) {
    if (itinerary == null || itinerary!.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedPlaceIds.isNotEmpty) _buildClearFilterButton(),
          ItineraryTabBar(
            controller: tabController,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = TripDetailsTheme.of(isDark);

    return Padding(
      padding: TripDetailsTheme.paddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Itinerary', style: theme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: theme.surfaceDecoration,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Detailed itinerary coming soon',
                    style: theme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearFilterButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Spacer(),
          TextButton.icon(
            onPressed: onClearSelection,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Clear filter'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (tabController.index == 0) {
      return PlacesTab(
        itinerary: itinerary!,
        isDark: isDark,
        trip: trip,
        selectedPlaceIds: selectedPlaceIds,
        expandedDays: expandedDays,
        onToggleDayExpanded: onToggleDayExpanded,
        onAddPlaceToDay: onAddPlaceToDay,
        onEditPlace: onEditPlace,
        onDeletePlace: onDeletePlace,
        onReplacePlace: onReplacePlace,
        onToggleSelection: onToggleSelection,
        onPlaceLongPress: onPlaceLongPress,
      );
    }

    return RestaurantsTab(
      itinerary: itinerary!,
      isDark: isDark,
      trip: trip,
      onReplaceRestaurant: onReplaceRestaurant,
      onDeleteRestaurant: onDeleteRestaurant,
      onViewAllOnMap: onViewAllRestaurantsOnMap,
    );
  }
}
