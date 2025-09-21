// lib/presentation/screens/auth/login/services/login_auth_service.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
// import '../../../home/home_screen.dart';

class LoginAuthService {
  final BuildContext context;
  bool _hasNavigated = false;

  LoginAuthService(this.context);

  /// Обработка изменений состояния аутентификации
  void handleAuthStateChanges(AuthProvider auth) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (auth.isAuthenticated && !_hasNavigated && context.mounted) {
        _hasNavigated = true;
        Navigator.of(context).pop();
      }
    });
  }

  /// Вход по email и паролю
  Future<void> login(String email, String password) async {
    final auth = context.read<AuthProvider>();
    await auth.login(email: email.trim(), password: password);

    final error = auth.error;
    if (error != null && error.trim().isNotEmpty) {
      _showErrorMessage(error);
    }
  }

  /// Вход через Google
  Future<void> signInWithGoogle() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      _showErrorMessage('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Вход через Facebook
  Future<void> signInWithFacebook() async {
    try {
      await context.read<AuthProvider>().signInWithFacebook();
    } catch (e) {
      _showErrorMessage('Facebook sign-in failed: ${e.toString()}');
    }
  }

  /// Отправка письма для сброса пароля
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(email.trim());
      _showSuccessMessage('Password reset email sent. Check your inbox.');
    } catch (e) {
      _showErrorMessage('Error: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
