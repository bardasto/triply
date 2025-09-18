// lib/presentation/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/color_constants.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════

class _OnboardingConstants {
  static const double horizontalPadding = 32.0;
  static const double buttonHeight = 56.0;
  static const double buttonWidth = 220.0;
  static const double borderRadius = 12.0;
  static const double animationSize = 300.0;
  static const double svgSize = 280.0;

  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);

  static const int logoFontSize = 60;
  static const double logoLetterSpacing = 2.0;
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
      backgroundColor: const Color(0xFFdad7cd),
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
        transitionDuration: const Duration(milliseconds: 300),
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
        transitionDuration: const Duration(milliseconds: 500),
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
          const SizedBox(height: 24),

          // Animation Section
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.topCenter,
              child: _OnboardingMedia(
                data: data,
                lottieController: lottieController,
                size: _OnboardingConstants.animationSize,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title Section
          _WelcomeTitle(title: data.title),

          const SizedBox(height: 8),

          // Subtitle
          _OnboardingSubtitle(subtitle: data.subtitle, fontSize: 18),

          const Spacer(),

          // Get Started Button
          _OnboardingButton(
            text: 'Get started',
            onPressed: onGetStarted,
            isPrimary: true,
          ),

          const SizedBox(height: 16),

          // Login Link
          _LoginLink(onPressed: onLogin),

          const SizedBox(height: 24),
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

        const SizedBox(height: 32),

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
              const SizedBox(height: 16),
              _LoginLink(onPressed: onLogin),
            ],
          ),
        ),

        const SizedBox(height: 24),
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
          const SizedBox(height: 40),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.topCenter,
              child: _OnboardingMedia(
                data: data,
                size: _OnboardingConstants.svgSize,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _OnboardingTitle(title: data.title),
          const SizedBox(height: 12),
          _OnboardingSubtitle(subtitle: data.subtitle, fontSize: 14),
          const SizedBox(height: 40),
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
          fontSize: _OnboardingConstants.logoFontSize.toDouble(),
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
          letterSpacing: _OnboardingConstants.logoLetterSpacing,
          height: 1.1,
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
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        height: 1.1,
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
        height: fontSize == 18 ? 1.35 : 1.4,
        fontWeight: fontSize == 18 ? FontWeight.w400 : FontWeight.normal,
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
              fontSize: isPrimary ? 20 : 16,
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
      padding: const EdgeInsets.only(top: 16, right: 24),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onPressed,
          child: Text(
            'Skip',
            style: TextStyle(
              fontSize: 16,
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
        dotHeight: 8,
        dotWidth: 8,
        expansionFactor: 3,
        spacing: 8,
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
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.grey),
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
