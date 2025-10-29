// lib/presentation/screens/auth/register/services/register_auth_service.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../home/home_screen.dart';

class RegisterAuthService {
  final BuildContext context;
  bool _hasNavigated = false;

  RegisterAuthService(this.context);

  /// Обработка изменений состояния аутентификации
  void handleAuthStateChanges(AuthProvider auth) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (auth.isAuthenticated && !_hasNavigated && context.mounted) {
        _hasNavigated = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  /// Регистрация по email и паролю
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final auth = context.read<AuthProvider>();
    await auth.register(
      email: email.trim(),
      password: password,
      displayName: displayName.trim(),
    );

    final error = auth.error;
    if (error != null && error.trim().isNotEmpty) {
      _showErrorMessage(error);
    }
  }

  /// Регистрация через Google
  Future<void> signUpWithGoogle() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      _showErrorMessage('Google sign-up failed: ${e.toString()}');
    }
  }

  /// Регистрация через Facebook
  Future<void> signUpWithFacebook() async {
    try {
      await context.read<AuthProvider>().signInWithFacebook();
    } catch (e) {
      _showErrorMessage('Facebook sign-up failed: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(fontSize: 15))),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
