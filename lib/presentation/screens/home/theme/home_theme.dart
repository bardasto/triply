import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';

/// Theme constants and decorations for the Home screen.
class HomeTheme {
  HomeTheme._();

  // ══════════════════════════════════════════════════════════════════════════
  // LAYOUT CONSTANTS
  // ══════════════════════════════════════════════════════════════════════════

  static const double maxScrollForOpacity = 10.0;
  static const double nearbyTripsRadius = 3000.0;
  static const double searchFieldFullHeight = 36.0;
  static const double searchScrollThreshold = 50.0;
  static const double pullToSearchThreshold = 100.0;
  static const double headerContentHeight = 56.0;

  // ══════════════════════════════════════════════════════════════════════════
  // COLORS
  // ══════════════════════════════════════════════════════════════════════════

  static const Color searchFieldBackground = Color(0xFF0A0A0C);
  static const Color searchFieldDark = Color(0xFF1C1C1E);

  // ══════════════════════════════════════════════════════════════════════════
  // GRADIENT COLORS
  // ══════════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════════
  // DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static BoxDecoration get searchFieldDecoration => BoxDecoration(
    color: searchFieldBackground,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: AppColors.primary.withValues(alpha: 0.4),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.15),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration locationButtonDecoration(double alpha) => BoxDecoration(
    color: Colors.white.withValues(alpha: alpha),
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration profileAvatarDecoration(double alpha) => BoxDecoration(
    color: Colors.white.withValues(alpha: alpha),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIVITY MAP
  // ══════════════════════════════════════════════════════════════════════════

  static const Map<int, String> activityMap = {
    0: 'cycling',
    1: 'beach',
    2: 'skiing',
    3: 'mountains',
    4: 'hiking',
    5: 'sailing',
    6: 'desert',
    7: 'camping',
    8: 'city',
    9: 'wellness',
    10: 'road_trip',
  };
}
