// lib/presentation/screens/onboarding/widgets/onboarding_media.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import '../models/onboarding_data.dart';

class OnboardingMedia extends StatelessWidget {
  final OnboardingData data;
  final AnimationController? lottieController;
  final double size;

  const OnboardingMedia({
    Key? key,
    required this.data,
    this.lottieController,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.useAnimation && data.animationPath != null) {
      return _buildLottieAnimation();
    }

    if (data.svgPath != null) {
      return _buildSvgImage();
    }

    return const SizedBox.shrink();
  }

  Widget _buildLottieAnimation() {
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

  Widget _buildSvgImage() {
    return SvgPicture.asset(
      data.svgPath!,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
