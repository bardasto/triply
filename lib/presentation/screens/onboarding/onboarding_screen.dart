// lib/presentation/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/color_constants.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DETAILED LAYOUT CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════

class _OnboardingConstants {
  // 📱 ОСНОВНЫЕ РАЗМЕРЫ ЭКРАНА
  static const double horizontalPadding = 32.0; // Горизонтальные отступы экрана

  // 🎯 КНОПКИ
  static const double buttonHeight = 60.0; // Высота основных кнопок
  static const double buttonWidth = 220.0; // Ширина основных кнопок
  static const double borderRadius = 12.0; // Радиус скругления кнопок
  static const double buttonSpacing = 16.0; // Расстояние между кнопками

  // 🎪 МЕДИА (анимации и изображения)
  static const double animationSize =
      400.0; // Размер Lottie анимации на welcome screen
  static const double svgSize = 280.0; // Размер SVG изображений на слайдах
  static const double mediaTopPadding =
      0.0; // Отступ сверху для медиа на слайдах
  static const double welcomeMediaTopPadding =
      0.0; // Отступ сверху для медиа на welcome screen

  // 📝 ЗАГОЛОВКИ И ТЕКСТ
  // Welcome Screen
  static const int logoFontSize = 65; // ✅ Увеличен для Lazydog
  static const double logoLetterSpacing = 3.0; // ✅ Больше spacing для Lazydog
  static const double logoToSubtitle = 12.0; // ✅ Больше отступ
  static const double welcomeSubtitleSize = 18.0;

  // 🎨 СТИЛИ ТЕКСТА - обновленные
  static const double welcomeTitleHeight =
      0.95; // ✅ Меньше для Lazydog (он выше)
  static const double slideTitleHeight = 1.1;
  static const double welcomeSubtitleHeight = 1.35;
  static const double slideSubtitleHeight = 1.4;

  // Onboarding Slides
  static const double slideTitleSize = 30.0; // Размер заголовков на слайдах
  static const double slideSubtitleSize =
      15.0; // Размер подзаголовков на слайдах
  static const double titleToSubtitle =
      12.0; // От заголовка до подзаголовка на слайдах
  static const double mediaToTitle = 32.0; // От медиа до заголовка на слайдах
  static const double subtitleToBottom =
      20.0; // От подзаголовка до низа контента

  // 🎨 НАВИГАЦИЯ И ИНДИКАТОРЫ
  static const double skipButtonTop = 0.0; // Отступ кнопки Skip сверху
  static const double skipButtonRight = 20.0; // Отступ кнопки Skip справа
  static const double pageIndicatorSpacing = 25.0; // Отступ до page indicator
  static const double indicatorDotSize = 8.0; // Размер точек индикатора
  static const double indicatorDotSpacing = 8.0; // Расстояние между точками
  static const double indicatorExpansion =
      3.0; // Коэффициент расширения активной точки

  // 📏 ПРОПОРЦИИ ЭКРАНА
  static const int mediaFlexRatio = 6; // Пропорция для медиа секции
  static const int contentFlexRatio = 4; // Пропорция для контентной секции

  // 🕐 АНИМАЦИИ
  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration navigationTransitionDuration =
      Duration(milliseconds: 500);


  // 📱 ОТСТУПЫ И ПРОСТРАНСТВО
  static const double bottomSafeArea = 0.0; // Нижний безопасный отступ
  static const double welcomeToButton =
      0.0; // Расстояние до кнопки на welcome (Spacer)
  static const double buttonToLogin = 16.0; // От кнопки до login ссылки
  static const double loginLinkPadding =
      12.0; // Вертикальный padding login ссылки

  // 🎯 КНОПКИ И ИНТЕРАКТИВНЫЕ ЭЛЕМЕНТЫ
  static const double primaryButtonFontSize =
      20.0; // Размер шрифта основных кнопок
  static const double secondaryButtonFontSize =
      16.0; // Размер шрифта вторичных кнопок
  static const double skipButtonFontSize = 16.0; // Размер шрифта кнопки Skip
  static const double loginLinkFontSize = 16.0; // Размер шрифта login ссылки
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class OnboardingData {
  final String title;
  final String subtitle;
  final String? svgPath;
  final String? animationPath;
  final bool useAnimation;
  final bool isWelcomeScreen;

  const OnboardingData({
    required this.title,
    required this.subtitle,
    this.svgPath,
    this.animationPath,
    this.useAnimation = false,
    this.isWelcomeScreen = false,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN ONBOARDING SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // State Variables
  bool _welcomeDone = false;
  int _currentPage = 0;

  // Controllers
  late final PageController _pageController;
  late final AnimationController _lottieController;
  late final AnimationController _fadeController;

  // Data
  static const List<OnboardingData> _pages = [
    OnboardingData(
      title: "TRIPLY",
      subtitle: "AI-Powered Travel",
      useAnimation: true,
      animationPath: "assets/animations/animation.json",
      isWelcomeScreen: true,
    ),
    OnboardingData(
      title: "Plan Your Trip\nWith AI",
      subtitle:
          "Enjoy personalized destinations with our intelligent travel assistant.",
      svgPath: "assets/svg/travel_destination.svg",
    ),
    OnboardingData(
      title: "Book Your\nPerfect Stay",
      subtitle:
          "Browse, pick, and book your ideal stay with just a few clicks.",
      svgPath: "assets/svg/booking_travel.svg",
    ),
    OnboardingData(
      title: "Design Your\nAdventure",
      subtitle:
          "Plan your walk with AI-powered directions and personalized highlights.",
      svgPath: "assets/svg/community_travel.svg",
    ),
  ];

  List<OnboardingData> get _slides => _pages.sublist(1);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    _pageController = PageController();
    _lottieController = AnimationController(vsync: this);
    _fadeController = AnimationController(
      duration: _OnboardingConstants.fadeAnimationDuration,
      vsync: this,
    )..forward();
  }

  void _disposeControllers() {
    _pageController.dispose();
    _lottieController.dispose();
    _fadeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: _welcomeDone
              ? _OnboardingSlider(
                  slides: _slides,
                  pageController: _pageController,
                  currentPage: _currentPage,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  onSkip: _navigateToRegister,
                  onNext: _handleNext,
                  onLogin: _navigateToLogin,
                )
              : _WelcomeScreen(
                  data: _pages.first,
                  lottieController: _lottieController,
                  onGetStarted: () => setState(() => _welcomeDone = true),
                  onLogin: _navigateToLogin,
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // NAVIGATION HANDLERS
  // ═══════════════════════════════════════════════════════════════════════════════

  void _handleNext() {
    if (_currentPage == _slides.length - 1) {
      _navigateToRegister();
    } else {
      _pageController.nextPage(
        duration: _OnboardingConstants.pageTransitionDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const LoginScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: _OnboardingConstants.pageTransitionDuration,
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const RegisterScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: _OnboardingConstants.navigationTransitionDuration,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WELCOME SCREEN WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _WelcomeScreen extends StatelessWidget {
  final OnboardingData data;
  final AnimationController lottieController;
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const _WelcomeScreen({
    required this.data,
    required this.lottieController,
    required this.onGetStarted,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _OnboardingConstants.horizontalPadding,
      ),
      child: Column(
        children: [
          const SizedBox(height: _OnboardingConstants.welcomeMediaTopPadding),

          // Animation Section
          Expanded(
            flex: _OnboardingConstants.mediaFlexRatio,
            child: Align(
              alignment: Alignment.topCenter,
              child: _OnboardingMedia(
                data: data,
                lottieController: lottieController,
                size: _OnboardingConstants.animationSize,
              ),
            ),
          ),

          const SizedBox(height: _OnboardingConstants.buttonToLogin),

          // Title Section
          _WelcomeTitle(title: data.title),

          const SizedBox(height: _OnboardingConstants.logoToSubtitle),

          // Subtitle
          _OnboardingSubtitle(
            subtitle: data.subtitle,
            fontSize: _OnboardingConstants.welcomeSubtitleSize,
          ),

          const Spacer(),

          // Get Started Button
          _OnboardingButton(
            text: 'Get started',
            onPressed: onGetStarted,
            isPrimary: true,
          ),

          const SizedBox(height: _OnboardingConstants.buttonSpacing),

          // Login Link
          _LoginLink(onPressed: onLogin),

          const SizedBox(height: _OnboardingConstants.bottomSafeArea),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ONBOARDING SLIDER WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _OnboardingSlider extends StatelessWidget {
  final List<OnboardingData> slides;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onLogin;

  const _OnboardingSlider({
    required this.slides,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onSkip,
    required this.onNext,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Skip Button
        _SkipButton(onPressed: onSkip),

        // Page View
        Expanded(
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: slides.length,
            itemBuilder: (context, index) => _OnboardingPage(
              data: slides[index],
            ),
          ),
        ),

        // Page Indicator
        _PageIndicator(
          controller: pageController,
          count: slides.length,
        ),

        const SizedBox(height: _OnboardingConstants.pageIndicatorSpacing),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _OnboardingConstants.horizontalPadding,
          ),
          child: Column(
            children: [
              _OnboardingButton(
                text: currentPage == slides.length - 1
                    ? 'Start exploring'
                    : 'Next',
                onPressed: onNext,
                isPrimary: true,
              ),
              const SizedBox(height: _OnboardingConstants.buttonSpacing),
              _LoginLink(onPressed: onLogin),
            ],
          ),
        ),

        const SizedBox(height: _OnboardingConstants.bottomSafeArea),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// INDIVIDUAL COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _OnboardingConstants.horizontalPadding,
      ),
      child: Column(
        children: [
          const SizedBox(height: _OnboardingConstants.mediaTopPadding),
          Expanded(
            flex: _OnboardingConstants.mediaFlexRatio,
            child: Align(
              alignment: Alignment.topCenter,
              child: _OnboardingMedia(
                data: data,
                size: _OnboardingConstants.svgSize,
              ),
            ),
          ),
          const SizedBox(height: _OnboardingConstants.mediaToTitle),
          _OnboardingTitle(title: data.title),
          const SizedBox(height: _OnboardingConstants.titleToSubtitle),
          _OnboardingSubtitle(
            subtitle: data.subtitle,
            fontSize: _OnboardingConstants.slideSubtitleSize,
          ),
          const SizedBox(height: _OnboardingConstants.subtitleToBottom),
        ],
      ),
    );
  }
}

class _OnboardingMedia extends StatelessWidget {
  final OnboardingData data;
  final AnimationController? lottieController;
  final double size;

  const _OnboardingMedia({
    required this.data,
    this.lottieController,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (data.useAnimation && data.animationPath != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Lottie.asset(
          data.animationPath!,
          controller: lottieController,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          frameRate: FrameRate.max,
          filterQuality: FilterQuality.high,
          addRepaintBoundary: true,
          onLoaded: (composition) {
            lottieController
              ?..duration = composition.duration
              ..repeat();
          },
        ),
      );
    }

    if (data.svgPath != null) {
      return SvgPicture.asset(
        data.svgPath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return const SizedBox.shrink();
  }
}

class _WelcomeTitle extends StatelessWidget {
  final String title;

  const _WelcomeTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -6),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'warmwinter', // ✅ Используем кастомный шрифт
          fontSize: _OnboardingConstants.logoFontSize.toDouble(),
          fontWeight: FontWeight.bold, // ✅ Lazydog обычно не требует bold
          color: AppColors.primary,
          letterSpacing: _OnboardingConstants.logoLetterSpacing,
          height: _OnboardingConstants.welcomeTitleHeight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}


class _OnboardingTitle extends StatelessWidget {
  final String title;

  const _OnboardingTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: _OnboardingConstants.slideTitleSize,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        height: _OnboardingConstants.slideTitleHeight,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _OnboardingSubtitle extends StatelessWidget {
  final String subtitle;
  final double fontSize;

  const _OnboardingSubtitle({
    required this.subtitle,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.grey[600],
        height: fontSize == _OnboardingConstants.welcomeSubtitleSize
            ? _OnboardingConstants.welcomeSubtitleHeight
            : _OnboardingConstants.slideSubtitleHeight,
        fontWeight: fontSize == _OnboardingConstants.welcomeSubtitleSize
            ? FontWeight.w400
            : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _OnboardingButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _OnboardingButton({
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _OnboardingConstants.buttonWidth,
        height: _OnboardingConstants.buttonHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? AppColors.primary : Colors.transparent,
            foregroundColor: isPrimary ? Colors.white : AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(_OnboardingConstants.borderRadius),
              side: isPrimary
                  ? BorderSide.none
                  : BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: isPrimary
                  ? _OnboardingConstants.primaryButtonFontSize
                  : _OnboardingConstants.secondaryButtonFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SkipButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: _OnboardingConstants.skipButtonTop,
        right: _OnboardingConstants.skipButtonRight,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onPressed,
          child: Text(
            'Skip',
            style: TextStyle(
              fontSize: _OnboardingConstants.skipButtonFontSize,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;

  const _PageIndicator({
    required this.controller,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: ExpandingDotsEffect(
        dotHeight: _OnboardingConstants.indicatorDotSize,
        dotWidth: _OnboardingConstants.indicatorDotSize,
        expansionFactor: _OnboardingConstants.indicatorExpansion,
        spacing: _OnboardingConstants.indicatorDotSpacing,
        activeDotColor: AppColors.primary,
        dotColor: Colors.grey[300]!,
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  final VoidCallback onPressed;

  const _LoginLink({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: _OnboardingConstants.loginLinkPadding,
          ),
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: _OnboardingConstants.loginLinkFontSize,
              color: Colors.grey,
            ),
            children: [
              const TextSpan(text: "Already have an account? "),
              TextSpan(
                text: "Login",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
