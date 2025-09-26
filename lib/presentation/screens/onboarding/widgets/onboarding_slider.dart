// lib/presentation/screens/onboarding/widgets/onboarding_slider.dart
import 'package:flutter/material.dart';
import '../constants/onboarding_constants.dart';
import '../models/onboarding_data.dart';
import '../services/onboarding_navigation_service.dart';
import 'onboarding_page.dart';
import 'onboarding_buttons.dart';

class OnboardingSlider extends StatefulWidget {
  final List<OnboardingData> slides;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onNext;

  const OnboardingSlider({
    Key? key,
    required this.slides,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onNext,
  }) : super(key: key);

  @override
  State<OnboardingSlider> createState() => _OnboardingSliderState();
}

class _OnboardingSliderState extends State<OnboardingSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initBackgroundAnimation();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _initBackgroundAnimation() {
    _backgroundAnimationController = AnimationController(
      duration: OnboardingConstants.backgroundTransitionDuration,
      vsync: this,
    );

    _backgroundFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: OnboardingConstants.backgroundTransitionCurve,
    ));

    _backgroundAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = OnboardingNavigationService(context);

    // ✅ ПРАВИЛЬНАЯ СТРУКТУРА - Stack сразу содержит Positioned
    return Stack(
      children: [
        // 📱 PAGE VIEW - НА ПОЛНЫЙ ЭКРАН
        AnimatedBuilder(
          animation: _backgroundFadeAnimation,
          builder: (context, child) {
            return PageView.builder(
              controller: widget.pageController,
              onPageChanged: _handlePageChanged,
              itemCount: widget.slides.length,
              itemBuilder: (context, index) => OnboardingPage(
                data: widget.slides[index],
              ),
            );
          },
        ),

        // ⏭️ SKIP BUTTON - ПРАВИЛЬНО В Stack
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: OnboardingConstants.skipButtonTop,
                right: OnboardingConstants.skipButtonRight,
              ),
              child:
                  SkipButton(onPressed: navigationService.navigateToRegister),
            ),
          ),
        ),

        // 🔘 НИЖНЯЯ ПАНЕЛЬ - ПРАВИЛЬНО В Stack
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: _buildBottomPanel(navigationService),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(OnboardingNavigationService navigationService) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OnboardingConstants.horizontalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔘 PAGE INDICATOR
          PageIndicator(
            controller: widget.pageController,
            count: widget.slides.length,
          ),

          const SizedBox(height: OnboardingConstants.pageIndicatorSpacing),

          // 🎯 ACTION BUTTONS
          OnboardingButton(
            text: widget.currentPage == widget.slides.length - 1
                ? 'Start exploring'
                : 'Next',
            onPressed: widget.onNext,
            isPrimary: true,
          ),

          const SizedBox(height: OnboardingConstants.buttonSpacing),

          LoginLink(onPressed: navigationService.navigateToLogin),

          const SizedBox(height: OnboardingConstants.bottomSafeArea),
        ],
      ),
    );
  }

  void _handlePageChanged(int index) {
    _backgroundAnimationController.reset();
    _backgroundAnimationController.forward();

    widget.onPageChanged(index);
  }
}
