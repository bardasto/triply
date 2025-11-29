import 'package:flutter/material.dart';
import '../../../../../../core/constants/color_constants.dart';

/// Theme constants and decorations for the Search modal.
class SearchTheme {
  SearchTheme._();

  // ══════════════════════════════════════════════════════════════════════════
  // LAYOUT CONSTANTS
  // ══════════════════════════════════════════════════════════════════════════

  static const double sheetRadius = 32.0;
  static const double compactHeight = 380.0;
  static const double expandedHeightFactor = 0.85;
  static const double headerSpacing = 56.0;
  static const double contentPadding = 16.0;
  static const double elementSpacing = 12.0;
  static const double borderRadius = 20.0;

  // Drag handle dimensions
  static const double dragHandleTop = 12.0;
  static const double dragHandleWidth = 50.0;
  static const double dragHandleHeight = 24.0;
  static const double dragHandleBarWidth = 32.0;
  static const double dragHandleBarHeight = 4.0;
  static const double dragHandleBlur = 10.0;

  // Close button dimensions
  static const double closeButtonTop = 12.0;
  static const double closeButtonRight = 16.0;
  static const double closeButtonSize = 36.0;
  static const double closeButtonBlur = 8.0;
  static const double closeButtonIconSize = 20.0;

  // ══════════════════════════════════════════════════════════════════════════
  // COLORS
  // ══════════════════════════════════════════════════════════════════════════

  static const Color sheetBackground = Color(0xFF1A1A1C);
  static const double sheetBackgroundAlpha = 0.85;

  static const Color elementBackground = Color(0xFF151517);
  static const Color suggestionBackground = Color(0xFF0A0A0C);
  static const Color calendarDayBackground = Color(0xFF0A0A0C);

  // ══════════════════════════════════════════════════════════════════════════
  // DECORATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static BoxDecoration get sheetDecoration => BoxDecoration(
    color: sheetBackground.withValues(alpha: sheetBackgroundAlpha),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(sheetRadius)),
  );

  static BoxDecoration get elementDecoration => BoxDecoration(
    color: elementBackground,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: AppColors.primary.withValues(alpha: 0.3),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.12),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration get suggestionContainerDecoration => BoxDecoration(
    color: suggestionBackground,
    borderRadius: BorderRadius.circular(borderRadius),
  );

  static BoxDecoration get dragHandleDecoration => BoxDecoration(
    color: Colors.black.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(20),
  );

  static BoxDecoration get dragHandleBarDecoration => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.9),
    borderRadius: BorderRadius.circular(dragHandleBarHeight / 2),
  );

  static BoxDecoration get closeButtonDecoration => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.15),
    shape: BoxShape.circle,
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.2),
      width: 0.5,
    ),
  );

  static BoxDecoration calendarDayDecoration({
    required bool isDisabled,
    required bool isStartDate,
    required bool isEndDate,
    required bool isInRange,
  }) {
    Color bgColor;
    if (isDisabled) {
      bgColor = Colors.transparent;
    } else if (isStartDate || isEndDate) {
      bgColor = AppColors.primary;
    } else if (isInRange) {
      bgColor = AppColors.primary.withValues(alpha: 0.3);
    } else {
      bgColor = calendarDayBackground;
    }

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEXT STYLES
  // ══════════════════════════════════════════════════════════════════════════

  static TextStyle get sectionTitleStyle => TextStyle(
    color: Colors.white.withValues(alpha: 0.6),
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle searchInputStyle = TextStyle(
    color: Colors.white,
    fontSize: 17,
  );

  static TextStyle get searchHintStyle => TextStyle(
    color: Colors.white.withValues(alpha: 0.5),
    fontSize: 17,
  );

  static const TextStyle whenTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get whenValueStyle => TextStyle(
    color: Colors.white.withValues(alpha: 0.5),
    fontSize: 15,
  );

  static const TextStyle suggestionTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get suggestionSubtitleStyle => TextStyle(
    color: Colors.white.withValues(alpha: 0.5),
    fontSize: 13,
  );

  static const TextStyle calendarMonthStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get calendarDayLabelStyle => TextStyle(
    color: Colors.white.withValues(alpha: 0.5),
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static TextStyle calendarDayStyle({required bool isDisabled, required bool isSelected}) => TextStyle(
    color: isDisabled ? Colors.white.withValues(alpha: 0.2) : Colors.white,
    fontSize: 14,
    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
  );

  static TextStyle get clearAllStyle => TextStyle(
    color: Colors.white.withValues(alpha: 0.7),
    fontSize: 15,
    decoration: TextDecoration.underline,
    decorationColor: Colors.white.withValues(alpha: 0.7),
  );
}
