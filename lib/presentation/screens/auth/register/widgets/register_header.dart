// lib/presentation/screens/auth/register/widgets/register_header.dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import '../constants/register_constants.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'CREATE ACCOUNT',
          style: TextStyle(
            fontSize: RegisterScreenConstants.headerTitleSize,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign up to start your travel journey',
          style: TextStyle(
            fontSize: RegisterScreenConstants.headerSubtitleSize,
            color: RegisterScreenConstants.subtitleColor,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
