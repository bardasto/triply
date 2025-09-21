// lib/presentation/screens/onboarding/widgets/welcome_screen.dart
import 'package:flutter/material.dart';
import '../constants/onboarding_constants.dart';
import '../models/onboarding_data.dart';
import '../services/onboarding_navigation_service.dart';
import 'onboarding_media.dart';
import 'onboarding_text.dart';
import 'onboarding_buttons.dart';

class WelcomeScreen extends StatelessWidget {
  final OnboardingData data;
  final AnimationController lottieController;
  final VoidCallback onGetStarted;

  const WelcomeScreen({
    Key? key,
    required this.data,
    required this.lottieController,
    required this.onGetStarted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navigationService = OnboardingNavigationService(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OnboardingConstants.horizontalPadding,
      ),
      child: Column(
        children: [
          const SizedBox(height: OnboardingConstants.welcomeMediaTopPadding),

          // 🎪 ANIMATION SECTION
          Expanded(
            flex: OnboardingConstants.mediaFlexRatio,
            child: Align(
              alignment: Alignment.topCenter,
              child: OnboardingMedia(
                data: data,
                lottieController: lottieController,
                size: OnboardingConstants.animationSize,
              ),
            ),
          ),

          const SizedBox(height: OnboardingConstants.buttonToLogin),

          // 📝 TITLE SECTION
          WelcomeTitle(title: data.title),
          const SizedBox(height: OnboardingConstants.logoToSubtitle),

          // 📝 SUBTITLE
          OnboardingSubtitle(
            subtitle: data.subtitle,
            fontSize: OnboardingConstants.welcomeSubtitleSize,
          ),

          const Spacer(),

          // 🎯 GET STARTED BUTTON
          OnboardingButton(
            text: 'Get started',
            onPressed: onGetStarted,
            isPrimary: true,
          ),

          const SizedBox(height: OnboardingConstants.buttonSpacing),

          // 📝 LOGIN LINK
          LoginLink(onPressed: navigationService.navigateToLogin),

          const SizedBox(height: OnboardingConstants.bottomSafeArea),
        ],
      ),
    );
  }
}
