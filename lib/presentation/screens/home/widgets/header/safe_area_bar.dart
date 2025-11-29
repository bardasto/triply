import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';

/// Animated safe area bar that fades in on scroll.
class SafeAreaBar extends StatelessWidget {
  final double opacity;

  const SafeAreaBar({super.key, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: MediaQuery.of(context).padding.top,
        decoration: BoxDecoration(
          color: AppColors.darkBackground.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
