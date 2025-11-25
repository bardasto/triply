import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../city_trips/models/activity_item.dart';
import '../../../city_trips/widgets/header/activity_filter_button.dart';
import '../../../city_trips/widgets/header/view_toggle_button.dart';

/// Header widget with blur effect for My Trips screen.
class MyTripsHeader extends StatelessWidget {
  final double scrollOffset;
  final int tripsCount;
  final bool isGridView;
  final bool hasActiveFilter;
  final List<ActivityItem>? selectedActivities;
  final ValueChanged<bool> onToggleView;
  final VoidCallback onFilterPressed;

  const MyTripsHeader({
    super.key,
    required this.scrollOffset,
    required this.tripsCount,
    required this.isGridView,
    required this.hasActiveFilter,
    required this.selectedActivities,
    required this.onToggleView,
    required this.onFilterPressed,
  });

  // Precomputed blur layer configurations for smooth transition
  // Each layer: [topMultiplier, heightMultiplier, blurMultiplier]
  static const List<List<double>> _blurLayers = [
    [0.0, 0.35, 1.0],    // Top layer - strongest blur
    [0.25, 0.25, 0.85],  // Upper-mid layer
    [0.40, 0.20, 0.65],  // Mid layer
    [0.55, 0.18, 0.45],  // Lower-mid layer
    [0.68, 0.16, 0.25],  // Lower layer
    [0.80, 0.12, 0.12],  // Bottom layer - lightest blur
  ];

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
            // Build all blur layers from precomputed config
            for (final layer in _blurLayers)
              _buildBlurLayer(
                totalHeight * layer[0],
                totalHeight * layer[1],
                blur,
                layer[2],
              ),
            _buildGradientOverlay(blurOpacity),
          ],
          _buildHeaderContent(blurOpacity),
        ],
      ),
    );
  }

  Widget _buildBlurLayer(double top, double height, double blur, double multiplier) {
    // Skip rendering if blur would be imperceptible
    if (blur * multiplier < 0.5) return const SizedBox.shrink();

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur * multiplier,
            sigmaY: blur * multiplier,
            tileMode: TileMode.clamp,
          ),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay(double blurOpacity) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.darkBackground.withValues(alpha: 0.9 * blurOpacity),
                AppColors.darkBackground.withValues(alpha: 0.7 * blurOpacity),
                AppColors.darkBackground.withValues(alpha: 0.4 * blurOpacity),
                AppColors.darkBackground.withValues(alpha: 0.15 * blurOpacity),
                Colors.transparent,
              ],
              stops: const [0.0, 0.3, 0.55, 0.8, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent(double blurOpacity) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'My AI Trips',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$tripsCount ${tripsCount == 1 ? 'trip' : 'trips'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
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
    );
  }
}
