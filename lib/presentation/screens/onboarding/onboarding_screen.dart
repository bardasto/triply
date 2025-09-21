// lib/presentation/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'constants/onboarding_constants.dart';
import 'models/onboarding_data.dart';
import 'services/onboarding_navigation_service.dart';
import 'widgets/waves_background.dart';
import 'widgets/welcome_screen.dart';
import 'widgets/onboarding_slider.dart';

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
  late final OnboardingNavigationService _navigationService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeServices() {
    _navigationService = OnboardingNavigationService(context);
  }

  void _initializeControllers() {
    _pageController = PageController();
    _lottieController = AnimationController(vsync: this);
    _fadeController = AnimationController(
      duration: OnboardingConstants.fadeAnimationDuration,
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
      body: Stack(
        children: [
          // 🌊 WAVES BACKGROUND - только для Welcome Screen
          if (!_welcomeDone) const WavesBackground(),

          // 📱 MAIN CONTENT
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: _welcomeDone
                  ? _buildOnboardingSlider()
                  : _buildWelcomeScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return WelcomeScreen(
      data: OnboardingData.welcomePage,
      lottieController: _lottieController,
      onGetStarted: () => setState(() => _welcomeDone = true),
    );
  }

  Widget _buildOnboardingSlider() {
    return OnboardingSlider(
      slides: OnboardingData.slides,
      pageController: _pageController,
      currentPage: _currentPage,
      onPageChanged: (index) => setState(() => _currentPage = index),
      onNext: _handleNext,
    );
  }

  void _handleNext() {
    if (_currentPage == OnboardingData.slides.length - 1) {
      _navigationService.navigateToRegister();
    } else {
      _pageController.nextPage(
        duration: OnboardingConstants.pageTransitionDuration,
        curve: Curves.easeInOut,
      );
    }
  }
}
