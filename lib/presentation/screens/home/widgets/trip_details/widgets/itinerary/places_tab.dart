import 'package:flutter/material.dart';
import '../../utils/trip_details_utils.dart';
import 'day_card.dart';

/// Tab content displaying places organized by day.
class PlacesTab extends StatelessWidget {
  final List<dynamic> itinerary;
  final bool isDark;
  final Map<String, dynamic> trip;
  final Set<String> selectedPlaceIds;
  final Map<int, bool> expandedDays;
  final Function(int) onToggleDayExpanded;
  final Function(Map<String, dynamic>) onAddPlaceToDay;
  final Function(Map<String, dynamic>) onEditPlace;
  final Function(Map<String, dynamic>) onDeletePlace;
  final Function(Map<String, dynamic>) onReplacePlace;
  final Function(String) onToggleSelection;
  final Function(Map<String, dynamic>)? onPlaceLongPress;

  const PlacesTab({
    super.key,
    required this.itinerary,
    required this.isDark,
    required this.trip,
    required this.selectedPlaceIds,
    required this.expandedDays,
    required this.onToggleDayExpanded,
    required this.onAddPlaceToDay,
    required this.onEditPlace,
    required this.onDeletePlace,
    required this.onReplacePlace,
    required this.onToggleSelection,
    this.onPlaceLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: itinerary.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value as Map<String, dynamic>;

        return _buildDayCardFiltered(day, index);
      }).toList(),
    );
  }

  Widget _buildDayCardFiltered(Map<String, dynamic> day, int index) {
    final allPlaces = day['places'] as List?;

    if (allPlaces != null) {
      final filteredPlaces =
          TripDetailsUtils.filterPlacesExcludingRestaurants(allPlaces);

      if (filteredPlaces.isEmpty) {
        return const SizedBox.shrink();
      }

      final filteredDay = Map<String, dynamic>.from(day);
      filteredDay['places'] = filteredPlaces;

      return _buildDayCard(filteredDay, index);
    }

    return _buildDayCard(day, index);
  }

  Widget _buildDayCard(Map<String, dynamic> day, int index) {
    final dayNumber = day['day'] ?? (index + 1);
    final isExpanded = expandedDays[dayNumber] ?? false;

    return DayCard(
      day: day,
      index: index,
      isExpanded: isExpanded,
      isDark: isDark,
      trip: trip,
      selectedPlaceIds: selectedPlaceIds,
      onToggleExpand: () => onToggleDayExpanded(dayNumber),
      onAddPlace: () => onAddPlaceToDay(day),
      onEditPlace: onEditPlace,
      onDeletePlace: onDeletePlace,
      onReplacePlace: onReplacePlace,
      onToggleSelection: onToggleSelection,
      onPlaceLongPress: onPlaceLongPress,
    );
  }
}
