// lib/presentation/screens/onboarding/widgets/waves_background.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/onboarding_constants.dart';

class WavesBackground extends StatelessWidget {
  const WavesBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final wavesHeight =
        screenSize.height * OnboardingConstants.wavesHeightRatio;
    final wavesWidth = screenSize.width * OnboardingConstants.wavesWidthRatio;

    return Positioned(
      top: OnboardingConstants.wavesTopOffset,
      left: OnboardingConstants.wavesLeftOffset,
      child: Container(
        width: wavesWidth,
        height: wavesHeight,
        child: SvgPicture.asset(
          OnboardingConstants.wavesAssetPath,
          width: wavesWidth,
          height: wavesHeight,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}
