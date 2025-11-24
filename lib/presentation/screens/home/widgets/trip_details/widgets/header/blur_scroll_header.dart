import 'dart:ui';
import 'package:flutter/material.dart';

/// Blur header that appears when scrolling down.
/// Creates a Telegram-style blur effect with ultra-smooth gradient transition.
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

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: Stack(
            children: [
              // Layer 1: Maximum blur at very top (0-15%)
              _buildBlurLayer(0, 0.15, 1.0, opacity),

              // Layer 2: Strong blur (10-25%)
              _buildBlurLayer(0.10, 0.15, 0.85, opacity),

              // Layer 3: High-medium blur (20-35%)
              _buildBlurLayer(0.20, 0.15, 0.70, opacity),

              // Layer 4: Medium blur (30-50%)
              _buildBlurLayer(0.30, 0.20, 0.55, opacity),

              // Layer 5: Low-medium blur (45-65%)
              _buildBlurLayer(0.45, 0.20, 0.40, opacity),

              // Layer 6: Light blur (60-80%)
              _buildBlurLayer(0.60, 0.20, 0.25, opacity),

              // Layer 7: Very light blur (75-95%)
              _buildBlurLayer(0.75, 0.20, 0.12, opacity),

              // Layer 8: Minimal blur at bottom (90-100%)
              _buildBlurLayer(0.90, 0.10, 0.05, opacity),

              // Gradient overlay for color tint
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _bgColor.withValues(alpha: 0.65 * opacity),
                      _bgColor.withValues(alpha: 0.45 * opacity),
                      _bgColor.withValues(alpha: 0.30 * opacity),
                      _bgColor.withValues(alpha: 0.18 * opacity),
                      _bgColor.withValues(alpha: 0.08 * opacity),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _bgColor => isDark ? const Color(0xFF1E1E1E) : Colors.white;

  Widget _buildBlurLayer(
    double topPercent,
    double heightPercent,
    double blurIntensity,
    double opacity,
  ) {
    final blur = maxBlur * blurIntensity * opacity;

    return Positioned(
      top: height * topPercent,
      left: 0,
      right: 0,
      height: height * heightPercent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
