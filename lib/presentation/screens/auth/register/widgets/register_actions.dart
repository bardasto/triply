// lib/presentation/screens/auth/register/widgets/register_actions.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../providers/auth_provider.dart';
import '../constants/register_constants.dart';
import '../services/register_auth_service.dart';
import 'register_social.dart';
import '../../login/login_bottom_sheet.dart';

class RegisterActions extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final RegisterAuthService authService;

  const RegisterActions({
    Key? key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.authService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Column(
          children: [
            // 🎯 REGISTER BUTTON
            _buildRegisterButton(context, auth),
            SizedBox(height: RegisterScreenConstants.registerButtonToSocial),

            // 🎪 SOCIAL SECTION
            RegisterSocialSection(authService: authService),
            SizedBox(height: RegisterScreenConstants.socialToSignInSpacing),

            // 📝 SIGN IN LINK
            _buildSignInLink(context),
          ],
        );
      },
    );
  }

  Widget _buildRegisterButton(BuildContext context, AuthProvider auth) {
    return Container(
      height: RegisterScreenConstants.registerButtonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
            RegisterScreenConstants.registerButtonBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(
                RegisterScreenConstants.registerButtonShadowOpacity),
            blurRadius: RegisterScreenConstants.registerButtonShadowBlur,
            offset: RegisterScreenConstants.registerButtonShadowOffset,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : () => _handleRegister(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                RegisterScreenConstants.registerButtonBorderRadius),
          ),
          elevation: 0,
        ),
        child: auth.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Create Account',
                style: TextStyle(
                  fontSize: RegisterScreenConstants.buttonTextSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSignInLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            fontSize: RegisterScreenConstants.signInLinkFontSize,
            color: RegisterScreenConstants.subtitleColor,
          ),
        ),
        TextButton(
          onPressed: () => _navigateToLogin(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            'Sign In',
            style: TextStyle(
              fontSize: RegisterScreenConstants.signInLinkFontSize,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister(BuildContext context) async {
    if (formKey.currentState?.validate() ?? false) {
      await authService.register(
        email: emailController.text,
        password: passwordController.text,
        displayName: nameController.text,
      );
    }
  }

  void _navigateToLogin(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const LoginBottomSheet(),
    );
  }
}
