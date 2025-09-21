// lib/presentation/screens/onboarding/widgets/onboarding_buttons.dart
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/color_constants.dart';
import '../constants/onboarding_constants.dart';

class OnboardingButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const OnboardingButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: OnboardingConstants.buttonWidth,
        height: OnboardingConstants.buttonHeight,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? AppColors.primary : Colors.transparent,
            foregroundColor: isPrimary ? Colors.white : AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(OnboardingConstants.borderRadius),
              side: isPrimary
                  ? BorderSide.none
                  : BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: isPrimary
                  ? OnboardingConstants.primaryButtonFontSize
                  : OnboardingConstants.secondaryButtonFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class SkipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SkipButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: OnboardingConstants.skipButtonTop,
        right: OnboardingConstants.skipButtonRight,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onPressed,
          child: Text(
            'Skip',
            style: TextStyle(
              fontSize: OnboardingConstants.skipButtonFontSize,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class PageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;

  const PageIndicator({
    Key? key,
    required this.controller,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: ExpandingDotsEffect(
        dotHeight: OnboardingConstants.indicatorDotSize,
        dotWidth: OnboardingConstants.indicatorDotSize,
        expansionFactor: OnboardingConstants.indicatorExpansion,
        spacing: OnboardingConstants.indicatorDotSpacing,
        activeDotColor: AppColors.primary,
        dotColor: Colors.grey[300]!,
      ),
    );
  }
}

class LoginLink extends StatelessWidget {
  final VoidCallback onPressed;

  const LoginLink({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: OnboardingConstants.loginLinkPadding,
          ),
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontSize: OnboardingConstants.loginLinkFontSize,
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
