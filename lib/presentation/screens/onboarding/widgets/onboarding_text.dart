// lib/presentation/screens/onboarding/widgets/onboarding_text.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';
import '../constants/onboarding_constants.dart';

class WelcomeTitle extends StatelessWidget {
  final String title;

  const WelcomeTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -6),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'NerkoOne-Regular',
          fontSize: OnboardingConstants.logoFontSize.toDouble(),
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: OnboardingConstants.logoLetterSpacing,
          height: OnboardingConstants.welcomeTitleHeight,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class OnboardingTitle extends StatelessWidget {
  final String title;

  const OnboardingTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: "NerkoOne-Regular",
        fontSize: OnboardingConstants.slideTitleSize,
        fontWeight: FontWeight.normal,
        color: Colors.black,
        height: OnboardingConstants.slideTitleHeight,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class OnboardingSubtitle extends StatelessWidget {
  final String subtitle;
  final double fontSize;

  const OnboardingSubtitle({
    Key? key,
    required this.subtitle,
    required this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.grey[600],
        height: _getTextHeight(),
        fontWeight: _getFontWeight(),
      ),
      textAlign: TextAlign.center,
    );
  }

  double _getTextHeight() {
    return fontSize == OnboardingConstants.welcomeSubtitleSize
        ? OnboardingConstants.welcomeSubtitleHeight
        : OnboardingConstants.slideSubtitleHeight;
  }

  FontWeight _getFontWeight() {
    return fontSize == OnboardingConstants.welcomeSubtitleSize
        ? FontWeight.w400
        : FontWeight.normal;
  }
}
