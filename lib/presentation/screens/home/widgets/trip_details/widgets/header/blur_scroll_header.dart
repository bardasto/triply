import 'dart:ui';
import 'package:flutter/material.dart';

/// Blur header that appears when scrolling down.
/// Uses multi-layer blur for smooth gradient transition.
/// Optimized for 60fps performance with conditional rendering.
class BlurScrollHeader extends StatelessWidget {
  final double scrollOffset;
  final bool isDark;
  final double height;
  final double maxBlur;

  const BlurScrollHeader({
    super.key,
    required this.scrollOffset,
    required this.isDark,
    this.height = 60,
    this.maxBlur = 20,
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
    // Calculate opacity based on scroll offset
    final opacity = ((scrollOffset - 30) / 90).clamp(0.0, 1.0);

    if (opacity <= 0) return const SizedBox.shrink();

    final blur = maxBlur * opacity;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            child: Stack(
              children: [
                // Multi-layer blur for smooth transition
                for (final layer in _blurLayers)
                  _buildBlurLayer(height, blur, layer),

                // Gradient overlay for smooth fade-out effect
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          bgColor.withValues(alpha: 0.9* opacity),
                          bgColor.withValues(alpha: 0.7 * opacity),
                          bgColor.withValues(alpha: 0.4 * opacity),
                          bgColor.withValues(alpha: 0.15 * opacity),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.55, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlurLayer(double totalHeight, double blur, List<double> config) {
    final blurValue = blur * config[2];

    // Skip rendering if blur would be imperceptible
    if (blurValue < 0.5) return const SizedBox.shrink();

    return Positioned(
      top: totalHeight * config[0],
      left: 0,
      right: 0,
      height: totalHeight * config[1],
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurValue,
            sigmaY: blurValue,
            tileMode: TileMode.clamp,
          ),
          child: const ColoredBox(color: Colors.transparent),
        ),
      ),
    );
  }
}
