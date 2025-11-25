import 'dart:ui';
import 'package:flutter/material.dart';

/// Blur header that appears when scrolling down.
/// Optimized for 60fps performance with single BackdropFilter.
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
                // Single optimized blur layer
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blur,
                      sigmaY: blur,
                      tileMode: TileMode.clamp,
                    ),
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),

                // Gradient overlay for smooth fade-out effect
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          bgColor.withValues(alpha: 0.7 * opacity),
                          bgColor.withValues(alpha: 0.4 * opacity),
                          bgColor.withValues(alpha: 0.15 * opacity),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35, 0.7, 1.0],
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
}
