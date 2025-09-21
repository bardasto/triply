// lib/presentation/screens/auth/login/constants/login_constants.dart
import 'package:flutter/material.dart';

class LoginBottomSheetConstants {
  // 📐 РАЗМЕРЫ МОДАЛЬНОГО ОКНА
  static const double heightRatio = 0.75;
  static const double maxHeight = 700.0;
  static const double minHeight = 500.0;
  static const double borderRadius = 25.0;

  // ⌨️ KEYBOARD HANDLING
  static const double keyboardPadding = 20.0;
  static const double keyboardOpenHeightRatio = 0.90;
  static const Duration scrollAnimationDuration = Duration(milliseconds: 250);
  static const Curve scrollAnimationCurve = Curves.easeOut;
  static const double scrollDelay = 300.0;

  // 🎯 SCROLL POSITIONS
  static const double emailScrollRatio = 0.15;
  static const double passwordScrollRatio = 0.45;
  static const double buttonScrollRatio = 0.65;
  static const double maxScrollRatio = 1.0;

  // 🎯 DRAG HANDLE
  static const double dragHandleWidth = 40.0;
  static const double dragHandleHeight = 4.0;
  static const double dragHandleTopMargin = 12.0;
  static const double dragHandleBottomMargin = 8.0;
  static const double dragHandleBorderRadius = 2.0;

  // 📱 ОСНОВНЫЕ ОТСТУПЫ
  static const double horizontalPadding = 32.0;
  static const double topContentPadding = 30.0;
  static const double bottomContentPadding = 20.0;

  // 📝 ЗАГОЛОВОК
  static const double headerTitleSize = 50.0;
  static const double headerSubtitleSize = 15.0;
  static const double headerTitleSpacing = 5.0;
  static const double headerBottomSpacing = 24.0;
  static const double headerLetterSpacing = 1.8;

  // 🔤 ПОЛЯ ВВОДА
  static const double fieldSpacing = 14.0;
  static const double fieldHeight = 56.0;
  static const double fieldBorderRadius = 12.0;
  static const double fieldBorderWidth = 1.5;
  static const double fieldFocusBorderWidth = 2.0;
  static const double fieldFontSize = 16.0;
  static const double fieldIconSize = 24.0;
  static const EdgeInsets fieldPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 14);

  // 🔗 FORGOT PASSWORD
  static const double forgotPasswordFontSize = 14.0;
  static const double forgotPasswordBottomSpacing = 24.0;
  static const double forgotPasswordTopSpacing = 8.0;

  // 🎯 LOGIN BUTTON
  static const double loginButtonHeight = 52.0;
  static const double loginButtonBorderRadius = 12.0;
  static const double loginButtonFontSize = 17.0;
  static const double loginButtonBottomSpacing = 16.0;
  static const double loginButtonShadowBlur = 8.0;
  static const Offset loginButtonShadowOffset = Offset(0, 4);
  static const double loginButtonShadowOpacity = 0.3;

  // 🎪 СОЦИАЛЬНЫЕ КНОПКИ
  static const double socialIconSize = 46.0;
  static const double socialIconSpacing = 28.0;
  static const double socialSectionBottomSpacing = 10.0;

  // ⭕ OR DIVIDER
  static const double dividerThickness = 1.0;
  static const double dividerTextFontSize = 16.0;
  static const double dividerTextSpacing = 14.0;
  static const double dividerBottomSpacing = 30.0;

  // 📝 SIGN UP LINK
  static const double signUpLinkFontSize = 15.0;
  static const double signUpLinkBottomSpacing = 20.0;

  // 🎬 АНИМАЦИИ
  static const Duration slideAnimationDuration = Duration(milliseconds: 300);
  static const Curve slideAnimationCurve = Curves.easeOutQuart;
  static const double slideAnimationBegin = 1.0;
  static const double slideAnimationEnd = 0.0;

  // 🎨 ЦВЕТА И СТИЛИ
  static const Color dragHandleColor = Color(0xFFE0E0E0);
  static const Color fieldBackgroundColor = Color(0xFFFAFAFA);
  static const Color fieldBorderColor = Color(0xFFE0E0E0);
  static const Color fieldIconColor = Color(0xFF757575);
  static const Color subtitleColor = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color dividerTextColor = Color(0xFF9E9E9E);

  // 📏 RESPONSIVE BREAKPOINTS
  static const double tabletBreakpoint = 600.0;
  static const double tabletHorizontalPadding = 48.0;
  static const double tabletHeaderTitleSize = 48.0;
}
