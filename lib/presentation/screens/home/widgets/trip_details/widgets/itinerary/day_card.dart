import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';
import '../../utils/trip_details_utils.dart';
import 'place_card.dart';

/// Expandable card for a single day in the itinerary.
/// Uses iOS-style animation and chevron icons.
class DayCard extends StatelessWidget {
  final Map<String, dynamic> day;
  final int index;
  final bool isExpanded;
  final bool isDark;
  final Map<String, dynamic> trip;
  final Set<String> selectedPlaceIds;
  final VoidCallback onToggleExpand;
  final VoidCallback onAddPlace;
  final Function(Map<String, dynamic>) onEditPlace;
  final Function(Map<String, dynamic>) onDeletePlace;
  final Function(Map<String, dynamic>) onReplacePlace;
  final Function(String) onToggleSelection;
  final Function(Map<String, dynamic>)? onPlaceLongPress;

  const DayCard({
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
    required this.onReplacePlace,
    required this.onToggleSelection,
    this.onPlaceLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TripDetailsTheme.of(isDark);
    final dayNumber = day['day'] ?? (index + 1);
    final dayTitle = day['title'] ?? 'Day ${index + 1}';
    final places = day['places'] as List?;

    return Column(
      children: [
        _buildDayHeader(theme, dayNumber, dayTitle),
        _buildExpandableContent(theme, places),
      ],
    );
  }

  Widget _buildDayHeader(
    TripDetailsTheme theme,
    dynamic dayNumber,
    String dayTitle,
  ) {
    return InkWell(
      onTap: onToggleExpand,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildDayBadge(dayNumber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dayTitle,
                style: theme.bodyLarge,
              ),
            ),
            if (isExpanded)
              IconButton(
                icon: const Icon(CupertinoIcons.add_circled, size: 22),
                color: AppColors.primary,
                onPressed: onAddPlace,
                tooltip: 'Add place',
              ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Icon(
                CupertinoIcons.chevron_down,
                color: theme.textSecondary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayBadge(dynamic dayNumber) {
    return Container(
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
    );
  }

  Widget _buildExpandableContent(TripDetailsTheme theme, List? places) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      sizeCurve: Curves.easeOutCubic,
      firstCurve: Curves.easeOut,
      secondCurve: Curves.easeIn,
      crossFadeState:
          isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox(width: double.infinity, height: 0),
      secondChild: Padding(
        padding: const EdgeInsets.only(left: 0, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (places != null && places.isNotEmpty)
              ...places.map((place) => _buildPlaceCard(place))
            else
              _buildEmptyPlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(dynamic place) {
    final placeMap = place as Map<String, dynamic>;
    final placeId = TripDetailsUtils.getPlaceId(placeMap);
    final isSelected = selectedPlaceIds.contains(placeId);

    return PlaceCard(
      place: placeMap,
      trip: trip,
      isDark: isDark,
      isSelected: isSelected,
      onEdit: () => onEditPlace(placeMap),
      onDelete: () => onDeletePlace(placeMap),
      onReplace: () => onReplacePlace(placeMap),
      onToggleSelection:
          placeMap['image_url'] != null ? () => onToggleSelection(placeId) : null,
      onLongPress:
          onPlaceLongPress != null ? () => onPlaceLongPress!(placeMap) : null,
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Padding(
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
    );
  }
}
