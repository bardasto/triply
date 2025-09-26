// lib/presentation/screens/auth/register/constants/register_constants.dart
import 'package:flutter/material.dart';

class RegisterScreenConstants {
  // 📱 Основные отступы
  static const double topPadding = 0.0;
  static const double headerBottomPadding = 30.0;
  static const double bottomPadding = 0.0;

  // 🔤 Поля ввода
  static const double fieldSpacing = 10.0;
  static const double fieldMinHeight = 50.0;
  static const double fieldBorderRadius = 12.0;
  static const double fieldBorderWidth = 1.5;
  static const double fieldFocusBorderWidth = 2.0;
  static const EdgeInsets fieldPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  // 🎯 Кнопка Register
  static const double registerButtonHeight = 56.0;
  static const double registerButtonSpacing = 15.0;
  static const double registerButtonToSocial = 40.0;
  static const double registerButtonBorderRadius = 12.0;
  static const double registerButtonShadowBlur = 8.0;
  static const Offset registerButtonShadowOffset = Offset(0, 4);
  static const double registerButtonShadowOpacity = 0.3;

  // 🎪 Социальные кнопки
  static const double socialSectionSpacing = 24.0;
  static const double socialIconSize = 50.0;
  static const double socialIconSpacing = 30.0;
  static const double socialToSignInSpacing = 10.0;

  // 🎨 Размеры шрифтов
  static const double headerTitleSize = 48.0;
  static const double headerSubtitleSize = 16.0;
  static const double buttonTextSize = 16.0;
  static const double socialTextSize = 14.0;
  static const double fieldFontSize = 16.0;
  static const double signInLinkFontSize = 16.0;

  // 🎬 Анимации
  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
  static const Curve fadeAnimationCurve = Curves.easeOut;

  // 🎨 Цвета
  static const Color fieldBackgroundColor = Color(0xFFFAFAFA);
  static const Color fieldBorderColor = Color(0xFFE0E0E0);
  static const Color fieldIconColor = Color(0xFF757575);
  static const Color subtitleColor = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // 📏 Responsive
  static const double horizontalPadding = 32.0;
  static const double verticalPadding = 16.0;
}
