// lib/presentation/screens/onboarding/widgets/onboarding_page.dart
import 'package:flutter/material.dart';
import '../constants/onboarding_constants.dart';
import '../models/onboarding_data.dart';
import 'onboarding_media.dart';
import 'onboarding_text.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OnboardingConstants.horizontalPadding,
      ),
      child: Column(
        children: [
          const SizedBox(height: OnboardingConstants.mediaTopPadding),

          // 🎪 MEDIA SECTION
          Expanded(
            flex: OnboardingConstants.mediaFlexRatio,
            child: Align(
              alignment: Alignment.topCenter,
              child: OnboardingMedia(
                data: data,
                size: OnboardingConstants.svgSize,
              ),
            ),
          ),

          const SizedBox(height: OnboardingConstants.mediaToTitle),

          // 📝 TEXT SECTION
          OnboardingTitle(title: data.title),
          const SizedBox(height: OnboardingConstants.titleToSubtitle),
          OnboardingSubtitle(
            subtitle: data.subtitle,
            fontSize: OnboardingConstants.slideSubtitleSize,
          ),

          const SizedBox(height: OnboardingConstants.subtitleToBottom),
        ],
      ),
    );
  }
}
