// lib/presentation/screens/auth/login/widgets/login_social.dart
import 'package:flutter/material.dart';
import '../constants/login_constants.dart';
import '../services/login_auth_service.dart';

class LoginSocialButtons extends StatelessWidget {
  final LoginAuthService authService;

  const LoginSocialButtons({
    Key? key,
    required this.authService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(
          assetPath: 'assets/images/google_logo.png',
          onPressed: () => authService.signInWithGoogle(),
        ),
        SizedBox(width: LoginBottomSheetConstants.socialIconSpacing),
        _buildSocialIcon(
          assetPath: 'assets/images/facebook_logo.png',
          onPressed: () => authService.signInWithFacebook(),
        ),
      ],
    );
  }

  Widget _buildSocialIcon({
    required String assetPath,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      iconSize: LoginBottomSheetConstants.socialIconSize,
      padding: EdgeInsets.zero,
      icon: Image.asset(
        assetPath,
        width: LoginBottomSheetConstants.socialIconSize,
        height: LoginBottomSheetConstants.socialIconSize,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            assetPath.contains('google') ? Icons.g_mobiledata : Icons.facebook,
            size: LoginBottomSheetConstants.socialIconSize,
            color: assetPath.contains('google') ? Colors.red : Colors.blue,
          );
        },
      ),
    );
  }
}
