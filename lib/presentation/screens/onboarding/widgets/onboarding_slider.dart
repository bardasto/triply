// lib/presentation/screens/onboarding/widgets/onboarding_slider.dart
import 'package:flutter/material.dart';
import '../constants/onboarding_constants.dart';
import '../models/onboarding_data.dart';
import '../services/onboarding_navigation_service.dart';
import 'onboarding_page.dart';
import 'onboarding_buttons.dart';

class OnboardingSlider extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final navigationService = OnboardingNavigationService(context);

    return Column(
      children: [
        // ⏭️ SKIP BUTTON
        SkipButton(onPressed: navigationService.navigateToRegister),

        // 📱 PAGE VIEW
        Expanded(
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: slides.length,
            itemBuilder: (context, index) => OnboardingPage(
              data: slides[index],
            ),
          ),
        ),

        // 🔘 PAGE INDICATOR
        PageIndicator(
          controller: pageController,
          count: slides.length,
        ),

        const SizedBox(height: OnboardingConstants.pageIndicatorSpacing),

        // 🎯 ACTION BUTTONS
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OnboardingConstants.horizontalPadding,
          ),
          child: Column(
            children: [
              OnboardingButton(
                text: currentPage == slides.length - 1
                    ? 'Start exploring'
                    : 'Next',
                onPressed: onNext,
                isPrimary: true,
              ),
              const SizedBox(height: OnboardingConstants.buttonSpacing),
              LoginLink(onPressed: navigationService.navigateToLogin),
            ],
          ),
        ),

        const SizedBox(height: OnboardingConstants.bottomSafeArea),
      ],
    );
  }
}
