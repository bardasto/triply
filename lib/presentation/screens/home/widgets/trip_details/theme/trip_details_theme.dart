import 'package:flutter/material.dart';
import '../../../../../../core/constants/color_constants.dart';

/// Centralized theme configuration for TripDetails components.
/// Provides consistent styling across light and dark modes.
class TripDetailsTheme {
  final bool isDark;

  const TripDetailsTheme({required this.isDark});

  // Background colors
  Color get backgroundColor => isDark ? AppColors.darkScaffoldBackground : Colors.white;
  Color get surfaceColor =>
      isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]!;
  Color get cardColor =>
      isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50]!;

  // Text colors
  Color get textPrimary => isDark ? Colors.white : AppColors.text;
  Color get textSecondary => isDark ? Colors.white70 : AppColors.textSecondary;

  // Border colors
  Color get dividerColor => isDark ? Colors.white12 : Colors.grey[200]!;
  Color get borderColor =>
      isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey[200]!;

  // Overlay colors
  Color get overlayDark => Colors.black.withValues(alpha: 0.3);
  Color get overlayMedium => Colors.black.withValues(alpha: 0.2);
  Color get overlayLight => Colors.black.withValues(alpha: 0.7);

  // Selected state colors
  Color get selectedBackground => AppColors.primary.withValues(alpha: 0.08);
  Color get selectedBorder => AppColors.primary.withValues(alpha: 0.4);

  // Tab indicator colors
  Color get tabIndicatorColor => AppColors.primary.withValues(alpha: 0.1);

  // Common border radius values
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusSheet = 32.0;

  // Common padding values
  static const EdgeInsets paddingHorizontal =
      EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets paddingAll = EdgeInsets.all(20);
  static const EdgeInsets paddingCard = EdgeInsets.all(12);

  // Text styles
  TextStyle get titleLarge => TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  TextStyle get titleMedium => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  TextStyle get titleSmall => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  TextStyle get bodyLarge => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  TextStyle get bodyMedium => TextStyle(
        fontSize: 15,
        height: 1.5,
        color: textSecondary,
      );

  TextStyle get bodySmall => TextStyle(
        fontSize: 14,
        color: textSecondary,
      );

  TextStyle get labelMedium => TextStyle(
        fontSize: 13,
        color: textSecondary,
      );

  // Decoration helpers
  BoxDecoration get cardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(color: borderColor, width: 1),
      );

  BoxDecoration selectedCardDecoration({bool isSelected = false}) =>
      BoxDecoration(
        color: isSelected ? selectedBackground : cardColor,
        borderRadius: BorderRadius.circular(radiusMedium),
        border: Border.all(
          color: isSelected ? selectedBorder : borderColor,
          width: isSelected ? 2 : 1,
        ),
      );

  BoxDecoration get surfaceDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radiusMedium),
      );

  BoxDecoration get sheetDecoration => BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(radiusSheet),
          topRight: Radius.circular(radiusSheet),
        ),
      );

  // Static factory for convenience
  static TripDetailsTheme of(bool isDark) => TripDetailsTheme(isDark: isDark);
}
