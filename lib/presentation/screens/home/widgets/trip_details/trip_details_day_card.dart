import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import 'trip_details_place_card.dart';

class TripDetailsDayCard extends StatelessWidget {
  final Map<String, dynamic> day;
  final int index;
  final bool isExpanded;
  final bool isDark;
  final Map<String, dynamic> trip;
  final Set<String> selectedPlaceIds;
  final VoidCallback onToggleExpand;
  final VoidCallback onAddPlace;
  final Function(Map<String, dynamic> place) onEditPlace;
  final Function(Map<String, dynamic> place) onDeletePlace;
  final Function(String placeId) onToggleSelection;
  final Function(Map<String, dynamic> place) onPlaceLongPress;

  const TripDetailsDayCard({
    super.key,
    required this.day,
    required this.index,
    required this.isExpanded,
    required this.isDark,
    required this.trip,
    required this.selectedPlaceIds,
    required this.onToggleExpand,
    required this.onAddPlace,
    required this.onEditPlace,
    required this.onDeletePlace,
    required this.onToggleSelection,
    required this.onPlaceLongPress,
  });

  Color get _textPrimary => isDark ? Colors.white : AppColors.text;
  Color get _textSecondary => isDark ? Colors.white70 : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final dayNumber = day['day'] ?? (index + 1);
    final dayTitle = day['title'] ?? 'Day ${index + 1}';
    final places = day['places'] as List?;

    return Column(
      children: [
        InkWell(
          onTap: onToggleExpand,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dayTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ),
                if (isExpanded)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    color: AppColors.primary,
                    onPressed: onAddPlace,
                    tooltip: 'Add place',
                  ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 0, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (places != null && places.isNotEmpty) ...[
                        ...places.map((place) {
                          final placeMap = place as Map<String, dynamic>;
                          final placeId = placeMap['poi_id']?.toString() ??
                              placeMap['name'];
                          final isSelected = selectedPlaceIds.contains(placeId);

                          return TripDetailsPlaceCard(
                            place: placeMap,
                            trip: trip,
                            isDark: isDark,
                            isSelected: isSelected,
                            onEdit: () => onEditPlace(placeMap),
                            onDelete: () => onDeletePlace(placeMap),
                            onToggleSelection: placeMap['image_url'] != null
                                ? () => onToggleSelection(placeId)
                                : null,
                            onLongPress: () => onPlaceLongPress(placeMap),
                          );
                        }),
                      ],
                      if (places == null || places.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: onAddPlace,
                              icon: const Icon(Icons.add_location_alt_outlined),
                              label: const Text('Add first place'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
