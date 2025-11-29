import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../models/activity_item.dart';
import 'activity_filter_button.dart';
import 'view_toggle_button.dart';

class CityTripsHeader extends StatelessWidget {
  final double scrollOffset;
  final String title;
  final bool isGridView;
  final bool hasActiveFilter;
  final List<ActivityItem>? selectedActivities;
  final VoidCallback onBackPressed;
  final ValueChanged<bool> onToggleView;
  final VoidCallback onFilterPressed;

  const CityTripsHeader({
    super.key,
    required this.scrollOffset,
    required this.title,
    required this.isGridView,
    required this.hasActiveFilter,
    required this.selectedActivities,
    required this.onBackPressed,
    required this.onToggleView,
    required this.onFilterPressed,
  });

  static const double scrollThreshold = 50.0;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final totalHeight = topPadding + 56;

    // Background opacity based on scroll
    final backgroundOpacity = (scrollOffset / scrollThreshold).clamp(0.0, 1.0);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: totalHeight,
        color: AppColors.darkBackground.withValues(alpha: backgroundOpacity),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: onBackPressed,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title left-aligned
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ActivityFilterButton(
                        hasActiveFilter: hasActiveFilter,
                        selectedActivities: selectedActivities,
                        onPressed: onFilterPressed,
                        embedded: true,
                      ),
                      const SizedBox(width: 4),
                      ViewToggleButton(
                        isGridView: isGridView,
                        onToggle: onToggleView,
                        embedded: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
