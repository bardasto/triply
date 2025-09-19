// lib/presentation/screens/auth/login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/color_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/smart_scroll_view.dart'; // ✅ Используем SmartScrollView
import '../home/home_screen.dart';
import 'register_screen.dart';

// 🎯 Константы для настройки высот и отступов Login Screen
class _LoginScreenConstants {
  // 📱 Основные отступы
  static const double topPadding = 0.0; // Верхний отступ от AppBar
  static const double headerBottomPadding = 32.0; // Отступ после заголовка
  static const double bottomPadding = 5.0; // Нижний отступ

  // 🔤 Поля ввода
  static const double fieldSpacing = 16.0; // Расстояние между полями
  static const double fieldHeight = 50.0; // Высота полей ввода
  static const double forgotPasswordSpacing =
      12.0; // Отступ до "Forgot Password?"

  // 🎯 Кнопка Sign In
  static const double loginButtonHeight = 52.0; // Высота кнопки входа
  static const double loginButtonSpacing =
      150.0; // Отступ после "Forgot Password?"
  static const double loginButtonToOr =
      12.0; // ✅ БЛИЗКО к "or" - главное значение!

  // 🎪 Социальные кнопки
  static const double orToSocialSpacing = 16.0; // Отступ от "or" до иконок
  static const double socialIconSize = 48.0; // Размер иконок
  static const double socialIconSpacing = 32.0; // Расстояние между иконками
  static const double socialToSignUpSpacing =
      24.0; // Отступ до ссылки "Sign Up"

  // 🎨 Размеры шрифтов
  static const double headerTitleSize = 38.0; // Размер "WELCOME BACK"
  static const double headerSubtitleSize = 18.0; // Размер подзаголовка
  static const double buttonTextSize = 17.0; // Размер текста кнопок
  static const double orTextSize = 16.0; // Размер текста "or"
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupFieldListeners();
    _initAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  void _setupFieldListeners() {
    _emailController.addListener(() {
      context.read<AuthProvider>().clearEmailError();
    });
    _passwordController.addListener(() {
      context.read<AuthProvider>().clearPasswordError();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) {
            _handleAuthStateChanges(auth);
            return _buildBody(auth);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // ✅ Body с SmartScrollView и bounce эффектом
  Widget _buildBody(AuthProvider auth) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SmartScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: _buildScrollContent(auth),
      ),
    );
  }

  Widget _buildScrollContent(AuthProvider auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: _LoginScreenConstants.topPadding),
          _buildHeader(),
          const SizedBox(height: _LoginScreenConstants.headerBottomPadding),
          _buildEmailField(),
          const SizedBox(height: _LoginScreenConstants.fieldSpacing),
          _buildPasswordField(),
          const SizedBox(height: _LoginScreenConstants.forgotPasswordSpacing),
          _buildForgotPasswordButton(),
          const SizedBox(height: _LoginScreenConstants.loginButtonSpacing),
          _buildLoginButton(auth),
          const SizedBox(height: _LoginScreenConstants.loginButtonToOr),
          _buildOrText(),
          const SizedBox(height: _LoginScreenConstants.orToSocialSpacing),
          _buildSocialLoginIcons(),
          const SizedBox(height: _LoginScreenConstants.socialToSignUpSpacing),
          _buildSignUpLink(),
          const SizedBox(height: _LoginScreenConstants.bottomPadding),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'WELCOME BACK',
          style: TextStyle(
            fontSize: _LoginScreenConstants.headerTitleSize,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Sign in to continue your journey',
          style: TextStyle(
            fontSize: _LoginScreenConstants.headerSubtitleSize,
            color: Colors.grey[600],
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return SizedBox(
      height: _LoginScreenConstants.fieldHeight,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontSize: 16),
        decoration: _buildInputDecoration(
          labelText: 'Email',
          hintText: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          errorText: context.watch<AuthProvider>().emailFieldError,
        ),
        validator: _validateEmail,
      ),
    );
  }

  Widget _buildPasswordField() {
    return SizedBox(
      height: _LoginScreenConstants.fieldHeight,
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        style: const TextStyle(fontSize: 16),
        decoration: _buildInputDecoration(
          labelText: 'Password',
          hintText: 'Enter your password',
          prefixIcon: Icons.lock_outline,
          errorText: context.watch<AuthProvider>().passwordFieldError,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
        validator: _validatePassword,
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _showPasswordResetDialog,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(AuthProvider auth) {
    return Container(
      height: _LoginScreenConstants.loginButtonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: auth.isLoading
            ? _buildLoadingIndicator()
            : Text(
                'Sign In',
                style: TextStyle(
                  fontSize: _LoginScreenConstants.buttonTextSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildOrText() {
    return Text(
      'or',
      style: TextStyle(
        fontSize: _LoginScreenConstants.orTextSize,
        color: Colors.grey[500],
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSocialLoginIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(
          assetPath: 'assets/images/google_logo.png',
          onPressed: _handleGoogleLogin,
        ),
        SizedBox(width: _LoginScreenConstants.socialIconSpacing),
        _buildSocialIcon(
          assetPath: 'assets/images/facebook_logo.png',
          onPressed: _handleFacebookLogin,
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
      iconSize: _LoginScreenConstants.socialIconSize,
      padding: EdgeInsets.zero,
      icon: Image.asset(
        assetPath,
        width: _LoginScreenConstants.socialIconSize,
        height: _LoginScreenConstants.socialIconSize,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            assetPath.contains('google') ? Icons.g_mobiledata : Icons.facebook,
            size: _LoginScreenConstants.socialIconSize,
            color: assetPath.contains('google') ? Colors.red : Colors.blue,
          );
        },
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: _navigateToRegister,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Sign Up',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Helper Methods
  // ═══════════════════════════════════════════════════════════════

  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorText: errorText,
    );
  }

  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 2.5,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Event Handlers (остаются без изменений)
  // ═══════════════════════════════════════════════════════════════

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  void _handleAuthStateChanges(AuthProvider auth) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (auth.isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  Future<void> _handleLogin() async {
    final auth = context.read<AuthProvider>();
    if (_formKey.currentState!.validate()) {
      await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final error = auth.error;
      if (error != null && error.trim().isNotEmpty) {
        _showErrorMessage(error);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      _showErrorMessage('Google sign-in failed: ${e.toString()}');
    }
  }

  Future<void> _handleFacebookLogin() async {
    try {
      await context.read<AuthProvider>().signInWithFacebook();
    } catch (e) {
      _showErrorMessage('Facebook sign-in failed: ${e.toString()}');
    }
  }

  void _showPasswordResetDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Reset Password',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Form(
            key: formKey,
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
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    prefixIcon: Icons.email_outlined,
                  ),
                  validator: _validateEmail,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  _sendPasswordResetEmail(emailController, formKey),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Send Reset Link',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail(
    TextEditingController emailController,
    GlobalKey<FormState> formKey,
  ) async {
    if (formKey.currentState!.validate()) {
      try {
        await context.read<AuthProvider>().sendPasswordResetEmail(
              emailController.text.trim(),
            );
        Navigator.of(context).pop();
        _showSuccessMessage('Password reset email sent. Check your inbox.');
      } catch (e) {
        Navigator.of(context).pop();
        _showErrorMessage('Error: ${e.toString()}');
      }
    }
  }

  void _navigateToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
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
