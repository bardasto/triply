// lib/presentation/screens/onboarding/services/onboarding_navigation_service.dart
import 'package:flutter/material.dart';
import '../../auth/register/register_screen.dart';
import '../../auth/login/login_bottom_sheet.dart';
import '../constants/onboarding_constants.dart';

class OnboardingNavigationService {
  final BuildContext context;

  OnboardingNavigationService(this.context);

  /// Навигация к экрану регистрации
  void navigateToRegister() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const RegisterScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: OnboardingConstants.navigationTransitionDuration,
      ),
    );
  }

  /// Открытие Login Bottom Sheet
  void navigateToLogin() {
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
