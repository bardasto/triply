// lib/presentation/screens/auth/login/widgets/login_actions.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../providers/auth_provider.dart';
import '../constants/login_constants.dart';
import '../services/login_auth_service.dart';
import 'login_social.dart';
import '../../register/register_screen.dart';

class LoginActions extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final LoginAuthService authService;

  const LoginActions({
    Key? key,
    required this.formKey,
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
            // 🎯 LOGIN BUTTON
            _buildLoginButton(context, auth),
            SizedBox(
                height: LoginBottomSheetConstants.loginButtonBottomSpacing),

            // ⭕ OR DIVIDER
            _buildOrDivider(),
            SizedBox(height: LoginBottomSheetConstants.dividerBottomSpacing),

            // 🎪 SOCIAL BUTTONS
            LoginSocialButtons(authService: authService),
            SizedBox(
                height: LoginBottomSheetConstants.socialSectionBottomSpacing),

            // 📝 SIGN UP LINK
            _buildSignUpLink(context),
          ],
        );
      },
    );
  }

  Widget _buildLoginButton(BuildContext context, AuthProvider auth) {
    return Container(
      width: double.infinity,
      height: LoginBottomSheetConstants.loginButtonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
            LoginBottomSheetConstants.loginButtonBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(
                LoginBottomSheetConstants.loginButtonShadowOpacity),
            blurRadius: LoginBottomSheetConstants.loginButtonShadowBlur,
            offset: LoginBottomSheetConstants.loginButtonShadowOffset,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : () => _handleLogin(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                LoginBottomSheetConstants.loginButtonBorderRadius),
          ),
          elevation: 0,
        ),
        child: auth.isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Sign In',
                style: TextStyle(
                  fontSize: LoginBottomSheetConstants.loginButtonFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: LoginBottomSheetConstants.dividerColor,
            thickness: LoginBottomSheetConstants.dividerThickness,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: LoginBottomSheetConstants.dividerTextSpacing,
          ),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: LoginBottomSheetConstants.dividerTextFontSize,
              color: LoginBottomSheetConstants.dividerTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: LoginBottomSheetConstants.dividerColor,
            thickness: LoginBottomSheetConstants.dividerThickness,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            fontSize: LoginBottomSheetConstants.signUpLinkFontSize,
            color: LoginBottomSheetConstants.subtitleColor,
          ),
        ),
        TextButton(
          onPressed: () => _navigateToRegister(context),
          child: Text(
            'Sign Up',
            style: TextStyle(
              fontSize: LoginBottomSheetConstants.signUpLinkFontSize,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ МЕТОДЫ С ПАРАМЕТРОМ CONTEXT
  Future<void> _handleLogin(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (formKey.currentState!.validate()) {
      await authService.login(
        emailController.text,
        passwordController.text,
      );
    }
  }

  void _navigateToRegister(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }
}
