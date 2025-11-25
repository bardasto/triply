import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';

/// Theme constants for the City Trips screen.
class CityTripsTheme {
  CityTripsTheme._();

  // Layout
  static const double headerHeight = 56.0;
  static const double horizontalPadding = 20.0;
  static const double cardBorderRadius = 24.0;
  static const double gridCardBorderRadius = 20.0;

  // Card dimensions
  static const double listCardImageHeight = 300.0;
  static const double gridAspectRatio = 0.56;
  static const int gridCrossAxisCount = 2;
  static const double gridCrossAxisSpacing = 12.0;
  static const double gridMainAxisSpacing = 16.0;
  static const double listCardSpacing = 32.0;

  // Filter bottom sheet
  static const double filterSheetHeightFactor = 0.85;
  static const double filterButtonHeight = 56.0;
  static const double filterButtonRadius = 28.0;

  // Gradient header colors
  static final List<Color> gradientColors = [
    const Color.fromARGB(255, 56, 22, 116).withValues(alpha: 0.3),
    const Color.fromARGB(255, 51, 20, 103).withValues(alpha: 0.3),
    const Color.fromARGB(255, 66, 27, 133).withValues(alpha: 0.3),
    const Color.fromARGB(255, 78, 27, 161).withValues(alpha: 0.25),
    const Color.fromARGB(255, 69, 23, 142).withValues(alpha: 0.2),
    const Color.fromARGB(255, 56, 39, 2).withValues(alpha: 0.15),
    const Color.fromARGB(255, 90, 40, 1).withValues(alpha: 0.1),
    const Color(0xFF2E0052).withValues(alpha: 0.07),
    const Color(0xFF1A0033).withValues(alpha: 0.04),
    AppColors.darkBackground.withValues(alpha: 0.02),
    AppColors.darkBackground.withValues(alpha: 0.0),
  ];

  static const List<double> gradientStops = [
    0.0,
    0.12,
    0.25,
    0.38,
    0.5,
    0.62,
    0.72,
    0.82,
    0.9,
    0.96,
    1.0,
  ];

  // Colors
  static const Color filterSheetBackground = Color(0xFF1E1E1E);
  static const Color dividerColor = Colors.white10;
}
