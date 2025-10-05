// lib/presentation/screens/auth/password_recovery_dialog.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/color_constants.dart';

class PasswordRecoveryDialog extends StatefulWidget {
  final Session session;

  const PasswordRecoveryDialog({Key? key, required this.session})
      : super(key: key);

  @override
  State<PasswordRecoveryDialog> createState() => _PasswordRecoveryDialogState();

  static Future<void> show(BuildContext context, Session session) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          PasswordRecoveryDialog(session: session),
    );
  }
}

class _PasswordRecoveryDialogState extends State<PasswordRecoveryDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _scrollController = ScrollController();

  // ✅ FOCUS NODES ДЛЯ УПРАВЛЕНИЯ ФОКУСОМ
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupFocusListeners();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  // ✅ НАСТРОЙКА СЛУШАТЕЛЕЙ ФОКУСА ДЛЯ АВТОСКРОЛЛИНГА
  void _setupFocusListeners() {
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        _scrollToField('password');
      }
    });

    _confirmPasswordFocusNode.addListener(() {
      if (_confirmPasswordFocusNode.hasFocus) {
        _scrollToField('confirmPassword');
      }
    });
  }

  // ✅ УМНЫЙ АВТОСКРОЛЛИНГ ДЛЯ ВИДИМОСТИ ПОЛЕЙ И КНОПКИ
  void _scrollToField(String fieldType) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients && mounted) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

        if (keyboardHeight > 0) {
          double scrollPosition;

          switch (fieldType) {
            case 'password':
              // Легкий скролл для первого поля
              scrollPosition = 30.0;
              break;
            case 'confirmPassword':
              // Скролл чтобы видеть поле и кнопки
              scrollPosition = 120.0;
              break;
            default:
              scrollPosition = 0.0;
          }

          _scrollController.animateTo(
            scrollPosition.clamp(
                0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildResponsiveDialog(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ОСНОВНОЙ ДИАЛОГ С ПРАВИЛЬНЫМ ПОЗИЦИОНИРОВАНИЕМ
  Widget _buildResponsiveDialog() {
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      // ✅ КОГДА КЛАВИАТУРА ОТКРЫТА - ПОДНИМАЕМСЯ ВВЕРХ
      alignment: keyboardHeight > 0 ? Alignment.topCenter : Alignment.center,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 340,
          maxHeight: screenSize.height * 0.85, // Максимум 85% экрана
        ),
        margin: EdgeInsets.only(
          left: 20,
          right: 20,
          // ✅ ДИНАМИЧЕСКИЙ ОТСТУП СВЕРХУ ДЛЯ КЛАВИАТУРЫ
          top: keyboardHeight > 0
              ? 60 // Когда клавиатура открыта - меньше отступ сверху
              : (screenSize.height * 0.15), // Когда закрыта - по центру
          bottom: 20,
        ),
        child: _buildDialogContent(),
      ),
    );
  }

  Widget _buildDialogContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ ФИКСИРОВАННЫЙ ЗАГОЛОВОК
          _buildHeader(),

          // ✅ СКРОЛЛИРУЕМЫЙ КОНТЕНТ
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    _buildPasswordField(),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    // ✅ ДОПОЛНИТЕЛЬНОЕ ПРОСТРАНСТВО ВНИЗУ
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(28, 28, 28, 20), // ✅ Меньше отступ снизу
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ Минимальный размер
        children: [
          Container(
            width: 70, // ✅ Чуть меньше иконка
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              size: 35, // ✅ Меньше размер иконки
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16), // ✅ Меньше отступ
          Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 22, // ✅ Немного меньше заголовок
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 6), // ✅ Меньше отступ
          Text(
            'Create a new password for your account',
            style: TextStyle(
              fontSize: 14, // ✅ Меньше подзаголовок
              color: Colors.grey[600],
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            widget.session.user.email ?? '',
            style: TextStyle(
              fontSize: 13, // ✅ Меньше email
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 16),
      onFieldSubmitted: (_) {
        // ✅ ПЕРЕХОД К СЛЕДУЮЩЕМУ ПОЛЮ
        FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
      },
      decoration: InputDecoration(
        labelText: 'New Password',
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600], size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
            size: 22,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14), // ✅ Меньше padding
        isDense: true, // ✅ Компактное поле
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a new password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocusNode,
      obscureText: !_isConfirmPasswordVisible,
      textInputAction: TextInputAction.done,
      style: const TextStyle(fontSize: 16),
      onFieldSubmitted: (_) {
        // ✅ АВТОМАТИЧЕСКАЯ ОТПРАВКА ФОРМЫ
        if (_formKey.currentState!.validate()) {
          _handlePasswordUpdate();
        }
      },
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600], size: 22),
        suffixIcon: IconButton(
          icon: Icon(
            _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
            size: 22,
          ),
          onPressed: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14), // ✅ Меньше padding
        isDense: true, // ✅ Компактное поле
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handlePasswordUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Update Password',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isLoading ? null : _handleCancel, // НОВЫЙ ОБРАБОТЧИК
          style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20)),
          child: Text(
            'Cancel',
            style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePasswordUpdate() async {
    FocusScope.of(context).unfocus(); // ✅ Скрываем клавиатуру

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final password = _passwordController.text.trim();

      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Password updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pop();
        await Supabase.instance.client.auth.signOut();
      } else {
        throw Exception('Failed to update password');
      }
    } catch (e) {
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
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCancel() async {
    try {
      // УСТАНАВЛИВАЕМ СОСТОЯНИЕ unauthenticated В PROVIDER
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout(); // Это установит состояние unauthenticated

      // ЗАКРЫВАЕМ ДИАЛОГ
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('❌ Error in cancel: $e');
      // В СЛУЧАЕ ОШИБКИ ПРОСТО ЗАКРЫВАЕМ ДИАЛОГ
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
