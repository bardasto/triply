// lib/presentation/screens/auth/login/widgets/login_header.dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import '../constants/login_constants.dart';

class LoginHeader extends StatelessWidget {
  final bool isTablet;

  const LoginHeader({
    Key? key,
    required this.isTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final titleSize = isTablet
        ? LoginBottomSheetConstants.tabletHeaderTitleSize
        : LoginBottomSheetConstants.headerTitleSize;

    return Column(
      children: [
        Text(
          'WELCOME BACK',
          style: TextStyle(
            fontFamily: "NerkoOne-Regular",
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: LoginBottomSheetConstants.headerLetterSpacing,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: LoginBottomSheetConstants.headerTitleSpacing),
        Text(
          'Sign in to continue your journey',
          style: TextStyle(
            fontSize: LoginBottomSheetConstants.headerSubtitleSize,
            color: LoginBottomSheetConstants.subtitleColor,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
