import 'dart:ui';
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

  @override
  Widget build(BuildContext context) {
    final blurOpacity = ((scrollOffset - 20) / 80).clamp(0.0, 1.0);
    final blur = 20.0 * blurOpacity;
    final topPadding = MediaQuery.of(context).padding.top;
    final totalHeight = topPadding + 56 + 20;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: totalHeight,
      child: Stack(
        children: [
          if (blurOpacity > 0) ...[
            // Layer 1 - strongest blur at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: totalHeight * 0.6,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blur,
                    sigmaY: blur,
                    tileMode: TileMode.clamp,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Layer 2 - medium blur
            Positioned(
              top: totalHeight * 0.5,
              left: 0,
              right: 0,
              height: totalHeight * 0.25,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blur * 0.6,
                    sigmaY: blur * 0.6,
                    tileMode: TileMode.clamp,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Layer 3 - light blur
            Positioned(
              top: totalHeight * 0.7,
              left: 0,
              right: 0,
              height: totalHeight * 0.2,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blur * 0.3,
                    sigmaY: blur * 0.3,
                    tileMode: TileMode.clamp,
                  ),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Color overlay with gradient
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.darkBackground.withValues(alpha: 0.85 * blurOpacity),
                        AppColors.darkBackground.withValues(alpha: 0.6 * blurOpacity),
                        AppColors.darkBackground.withValues(alpha: 0.2 * blurOpacity),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
          // Header content
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBackPressed,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActivityFilterButton(
                    hasActiveFilter: hasActiveFilter,
                    selectedActivities: selectedActivities,
                    onPressed: onFilterPressed,
                  ),
                  const SizedBox(width: 8),
                  ViewToggleButton(
                    isGridView: isGridView,
                    onToggle: onToggleView,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
