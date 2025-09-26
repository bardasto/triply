// lib/presentation/screens/onboarding/constants/onboarding_constants.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';

class OnboardingConstants {
  // 📱 ОСНОВНЫЕ РАЗМЕРЫ ЭКРАНА
  static const double horizontalPadding = 32.0;

  // 🎯 КНОПКИ
  static const double buttonHeight = 60.0;
  static const double buttonWidth = 220.0;
  static const double borderRadius = 12.0;
  static const double buttonSpacing = 16.0;

  // 🎪 МЕДИА (анимации и изображения)
  static const double animationSize = 400.0;
  static const double lottieVerticalOffset = -60.0;
  static const double lottieVerticalAdjustment = 0.0; 
  static const double svgSize = 300.0;
  static const double mediaTopPadding = 10.0;
  static const double welcomeMediaTopPadding = 0.0;

  // 📝 ЗАГОЛОВКИ И ТЕКСТ
  // Welcome Screen
  static const int logoFontSize = 100;
  static const double logoLetterSpacing = 5.0;
  static const double logoToSubtitle = 12.0;
  static const double welcomeSubtitleSize = 18.0;

  // 🎨 СТИЛИ ТЕКСТА
  static const double welcomeTitleHeight = 0.95;
  static const double slideTitleHeight = 1.1;
  static const double welcomeSubtitleHeight = 1.35;
  static const double slideSubtitleHeight = 1.4;

  // Onboarding Slides
  static const double slideTitleSize = 40.0;
  static const double slideSubtitleSize = 16.0;
  static const double titleToSubtitle = 20.0;
  static const double mediaToTitle = 10.0;
  static const double subtitleToBottom = 220.0;

  // 🎨 НАВИГАЦИЯ И ИНДИКАТОРЫ
  static const double skipButtonTop = 0.0;
  static const double skipButtonRight = 20.0;
  static const double pageIndicatorSpacing = 25.0;
  static const double indicatorDotSize = 8.0;
  static const double indicatorDotSpacing = 8.0;
  static const double indicatorExpansion = 3.0;

  // 📏 ПРОПОРЦИИ ЭКРАНА
  static const int mediaFlexRatio = 6;
  static const int contentFlexRatio = 4;

  // 🕐 АНИМАЦИИ
  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration navigationTransitionDuration =
      Duration(milliseconds: 500);

static const String wavesAssetPath =
      'assets/svg/svg_background.svg'; // дефолтный фон

  // ✅ ПУТИ К ФОНАМ ДЛЯ СЛАЙДОВ (можешь легко менять)
  static const Map<String, String> slideBackgrounds = {
    'welcome': 'assets/svg/svg_background.svg', // Welcome экран
    'slide1': 'assets/svg/waves_slide1.svg', // Plan Your Trip
    'slide2': 'assets/svg/waves_slide2.svg', // Book Your Stay
    'slide3': 'assets/svg/waves_slide3.svg', // Design Adventure
  };

  static const double wavesHeightRatio = 0.7;
  static const double wavesWidthRatio = 1.0;
  static const double wavesTopOffset = 0.0;
  static const double wavesLeftOffset = 0.0;
  static const double wavesOpacity = 1.0;
  static const Color wavesColor = AppColors.primary;

  // ✅ НОВЫЕ НАСТРОЙКИ ДЛЯ АНИМАЦИИ СМЕНЫ ФОНОВ
  static const Duration backgroundTransitionDuration =
      Duration(milliseconds: 300);
  static const Curve backgroundTransitionCurve = Curves.easeInOut;

  // 📱 ОТСТУПЫ И ПРОСТРАНСТВО
  static const double bottomSafeArea = 0.0;
  static const double welcomeToButton = 0.0;
  static const double buttonToLogin = 16.0;
  static const double loginLinkPadding = 12.0;

  // 🎯 КНОПКИ И ИНТЕРАКТИВНЫЕ ЭЛЕМЕНТЫ
  static const double primaryButtonFontSize = 20.0;
  static const double secondaryButtonFontSize = 16.0;
  static const double skipButtonFontSize = 16.0;
  static const double loginLinkFontSize = 16.0;
}
