// lib/presentation/screens/auth/register/widgets/register_social.dart
import 'package:flutter/material.dart';
import '../constants/register_constants.dart';
import '../services/register_auth_service.dart';

class RegisterSocialSection extends StatelessWidget {
  final RegisterAuthService authService;

  const RegisterSocialSection({
    Key? key,
    required this.authService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDivider(),
        SizedBox(height: RegisterScreenConstants.socialSectionSpacing),
        _buildSocialButtons(),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: RegisterScreenConstants.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR continue with',
            style: TextStyle(
              color: RegisterScreenConstants.subtitleColor,
              fontWeight: FontWeight.w500,
              fontSize: RegisterScreenConstants.socialTextSize,
            ),
          ),
        ),
        Expanded(child: Divider(color: RegisterScreenConstants.dividerColor)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(
          assetPath: 'assets/images/google_logo.png',
          onPressed: () => authService.signUpWithGoogle(),
          tooltip: 'Sign up with Google',
        ),
        SizedBox(width: RegisterScreenConstants.socialIconSpacing),
        _buildSocialIcon(
          assetPath: 'assets/images/facebook_logo.png',
          onPressed: () => authService.signUpWithFacebook(),
          tooltip: 'Sign up with Facebook',
        ),
      ],
    );
  }

  Widget _buildSocialIcon({
    required String assetPath,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      iconSize: RegisterScreenConstants.socialIconSize,
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      icon: Image.asset(
        assetPath,
        width: RegisterScreenConstants.socialIconSize,
        height: RegisterScreenConstants.socialIconSize,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            assetPath.contains('google') ? Icons.g_mobiledata : Icons.facebook,
            size: RegisterScreenConstants.socialIconSize,
            color: assetPath.contains('google') ? Colors.red : Colors.blue,
          );
        },
      ),
    );
  }
}
