import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';
import '../../utils/trip_details_utils.dart';
import 'place_card.dart';

/// Expandable card for a single day in the itinerary.
/// Uses iOS-style animation and chevron icons with bounce effect.
class DayCard extends StatefulWidget {
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
  State<DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<DayCard> with SingleTickerProviderStateMixin {
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

  void _handleTapDown(TapDownDetails details) {
    _bounceController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _bounceController.reverse();
    widget.onToggleExpand();
  }

  void _handleTapCancel() {
    _bounceController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TripDetailsTheme.of(widget.isDark);
    final dayNumber = widget.day['day'] ?? (widget.index + 1);
    final dayTitle = widget.day['title'] ?? 'Day ${widget.index + 1}';
    final places = widget.day['places'] as List?;

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
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
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
              if (widget.isExpanded)
                IconButton(
                  icon: const Icon(CupertinoIcons.add_circled, size: 22),
                  color: AppColors.primary,
                  onPressed: widget.onAddPlace,
                  tooltip: 'Add place',
                ),
              AnimatedRotation(
                turns: widget.isExpanded ? 0.5 : 0,
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
      crossFadeState: widget.isExpanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
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
    final isSelected = widget.selectedPlaceIds.contains(placeId);

    return PlaceCard(
      place: placeMap,
      trip: widget.trip,
      isDark: widget.isDark,
      isSelected: isSelected,
      onEdit: () => widget.onEditPlace(placeMap),
      onDelete: () => widget.onDeletePlace(placeMap),
      onReplace: () => widget.onReplacePlace(placeMap),
      onToggleSelection: placeMap['image_url'] != null
          ? () => widget.onToggleSelection(placeId)
          : null,
      onLongPress: widget.onPlaceLongPress != null
          ? () => widget.onPlaceLongPress!(placeMap)
          : null,
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: TextButton.icon(
          onPressed: widget.onAddPlace,
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
