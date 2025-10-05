// lib/presentation/screens/auth/forgot_password_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import '/../../core/constants/color_constants.dart';
import '../../login/constants/login_constants.dart';
import '../../login/services/login_auth_service.dart';
import 'email_sent_dialog.dart'; // НОВЫЙ ИМПОРТ

class ForgotPasswordDialog {
  static Future<void> show(BuildContext context, LoginAuthService authService) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ForgotPasswordDialogWidget(authService: authService),
    );
  }
}

class _ForgotPasswordDialogWidget extends StatefulWidget {
  final LoginAuthService authService;

  const _ForgotPasswordDialogWidget({
    Key? key,
    required this.authService,
  }) : super(key: key);

  @override
  State<_ForgotPasswordDialogWidget> createState() =>
      _ForgotPasswordDialogWidgetState();
}

class _ForgotPasswordDialogWidgetState
    extends State<_ForgotPasswordDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false; // ДОБАВЛЕН ФЛАГ ЗАГРУЗКИ

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration(),
                validator: _validateEmail,
                enabled: !_isLoading,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _sendPasswordResetEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Send Reset Link',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      labelText: 'Email',
      hintText: 'Enter your email',
      prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(LoginBottomSheetConstants.fieldBorderRadius),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(LoginBottomSheetConstants.fieldBorderRadius),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$').hasMatch(v.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  // ОБНОВЛЕННЫЙ МЕТОД ОТПРАВКИ С ПОКАЗОМ EmailSentDialog
  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();

      // ОТПРАВЛЯЕМ EMAIL
      await widget.authService.sendPasswordResetEmail(email);

      if (mounted) {
        // ЗАКРЫВАЕМ ТЕКУЩИЙ ДИАЛОГ
        Navigator.of(context).pop();

        // ПОКАЗЫВАЕМ ДИАЛОГ ПОДТВЕРЖДЕНИЯ
        final shouldResend = await EmailSentDialog.show(context, email);

        // ЕСЛИ ПОЛЬЗОВАТЕЛЬ НАЖАЛ "Resend" - ПОВТОРНО ОТПРАВЛЯЕМ
        if (shouldResend == true && mounted) {
          await _resendEmail(email);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // МЕТОД ДЛЯ ПОВТОРНОЙ ОТПРАВКИ EMAIL
  Future<void> _resendEmail(String email) async {
    try {
      await widget.authService.sendPasswordResetEmail(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Email sent again!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to resend: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
