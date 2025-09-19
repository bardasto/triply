// lib/presentation/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/color_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/smart_scroll_view.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'login_screen.dart';

// constants for spacing and sizes
class _RegisterScreenConstants {
  // 📱 Основные отступы
  static const double topPadding = 0.0; // upper padding
  static const double headerBottomPadding = 30.0; // after header
  static const double bottomPadding = 0.0; // lower padding

  // 🔤 Поля ввода
  static const double fieldSpacing = 10.0; // between fields
  static const double fieldMinHeight =
      50.0; // minimum height of input fields

  // 🎯 Кнопка Register
  static const double registerButtonHeight = 56.0; // height of register button
  static const double registerButtonSpacing =15.0; // spacing after last field
  static const double registerButtonToSocial =
      40.0; // spacing from button to social buttons

  // 🎪 Социальные кнопки
  static const double socialSectionSpacing = 24.0; // inside social section
  static const double socialIconSize = 50.0; // size of icons
  static const double socialIconSpacing = 30.0; // spacing between icons
  static const double socialToSignInSpacing = 10.0; // to "Sign In" link

  // 🎨 Размеры шрифтов
  static const double headerTitleSize = 35.0; // size of "CREATE ACCOUNT"
  static const double headerSubtitleSize = 16.0; // size of subtitle
  static const double buttonTextSize = 16.0; // size of button text
  static const double socialTextSize = 14.0; // size of "OR continue with"
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // ✅ Убираем _confirmPasswordController полностью
  final _scrollController = ScrollController();

  bool _isPasswordVisible = false;
  // ✅ Убираем _isConfirmVisible

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupFieldListeners();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    // ✅ Убираем _confirmPasswordController.dispose()
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => _goToStart(context),
        ),
      ),
      body: WillPopScope(
        onWillPop: () async {
          _goToStart(context);
          return false;
        },
        child: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (auth.isAuthenticated) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              });

              return _buildBody(auth);
            },
          ),
        ),
      ),
    );
  }

  // ✅ Body with SmartScrollView and bounce-to-top effect
  Widget _buildBody(AuthProvider auth) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SmartScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        bounceBackType: BounceBackType.toTop, // ✅ Bounce к началу экрана
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
          const SizedBox(height: _RegisterScreenConstants.topPadding),
          _buildHeader(),
          const SizedBox(height: _RegisterScreenConstants.headerBottomPadding),
          _buildNameField(),
          const SizedBox(height: _RegisterScreenConstants.fieldSpacing),
          _buildEmailField(),
          const SizedBox(height: _RegisterScreenConstants.fieldSpacing),
          _buildPasswordField(),
          // ✅ Убираем Confirm Password поле
          const SizedBox(
              height: _RegisterScreenConstants.registerButtonSpacing),
          _buildRegisterButton(auth),
          const SizedBox(
              height: _RegisterScreenConstants.registerButtonToSocial),
          _buildSocialSection(),
          const SizedBox(
              height: _RegisterScreenConstants.socialToSignInSpacing),
          _buildSignInLink(),
          const SizedBox(height: _RegisterScreenConstants.bottomPadding),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'CREATE ACCOUNT',
          style: TextStyle(
            fontSize: _RegisterScreenConstants.headerTitleSize,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign up to start your travel journey',
          style: TextStyle(
            fontSize: _RegisterScreenConstants.headerSubtitleSize,
            color: Colors.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ✅ Поле Full Name без фиксированной высоты
  Widget _buildNameField() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight:
            _RegisterScreenConstants.fieldMinHeight, // ✅ Минимальная высота
      ),
      child: TextFormField(
        controller: _nameController,
        textInputAction: TextInputAction.next,
        style: const TextStyle(fontSize: 16),
        decoration: _buildInputDecoration(
          labelText: 'Full name',
          hintText: 'Enter your full name',
          prefixIcon: Icons.person_outline,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Name is required';
          if (v.trim().length < 2) return 'Name must be at least 2 characters';
          return null;
        },
      ),
    );
  }

  // ✅ Email поле без фиксированной высоты
  Widget _buildEmailField() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight:
            _RegisterScreenConstants.fieldMinHeight, // ✅ Минимальная высота
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        style: const TextStyle(fontSize: 16),
        decoration: _buildInputDecoration(
          labelText: 'Email',
          hintText: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          errorText: context.watch<AuthProvider>().emailFieldError,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Email is required';
          final re = RegExp(r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$');
          if (!re.hasMatch(v.trim())) return 'Enter a valid email';
          return null;
        },
      ),
    );
  }

  // ✅ Password поле без фиксированной высоты
  Widget _buildPasswordField() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight:
            _RegisterScreenConstants.fieldMinHeight, // ✅ Минимальная высота
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        textInputAction: TextInputAction
            .done, // ✅ Изменено на done так как это последнее поле
        style: const TextStyle(fontSize: 16),
        decoration: _buildInputDecoration(
          labelText: 'Password',
          hintText: 'Create a strong password',
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Password is required';
          if (v.length < 8) return 'At least 8 characters';
          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(v)) {
            return 'Must contain upper, lower case and a number';
          }
          return null;
        },
      ),
    );
  }

  // ✅ Confirm Password поле - закомментированное для возможного использования в будущем
  /*
  Widget _buildConfirmPasswordField() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: _RegisterScreenConstants.fieldMinHeight,
      ),
      child: TextFormField(
        controller: _confirmPasswordController,
        obscureText: !_isConfirmVisible,
        textInputAction: TextInputAction.done,
        style: const TextStyle(fontSize: 16),
        decoration: _buildInputDecoration(
          labelText: 'Confirm password',
          hintText: 'Re-enter your password',
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[600],
            ),
            onPressed: () =>
                setState(() => _isConfirmVisible = !_isConfirmVisible),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Please confirm password';
          if (v != _passwordController.text) return 'Passwords do not match';
          return null;
        },
      ),
    );
  }
  */

  Widget _buildRegisterButton(AuthProvider auth) {
    return Container(
      height: _RegisterScreenConstants.registerButtonHeight,
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
        onPressed: auth.isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  fontSize: _RegisterScreenConstants.buttonTextSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR continue with',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: _RegisterScreenConstants.socialTextSize,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
        const SizedBox(height: _RegisterScreenConstants.socialSectionSpacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(
              assetPath: 'assets/images/google_logo.png',
              onPressed: _handleGoogleRegister,
              tooltip: 'Sign up with Google',
            ),
            const SizedBox(width: _RegisterScreenConstants.socialIconSpacing),
            _buildSocialIcon(
              assetPath: 'assets/images/facebook_logo.png',
              onPressed: _handleFacebookRegister,
              tooltip: 'Sign up with Facebook',
            ),
          ],
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
      iconSize: _RegisterScreenConstants.socialIconSize,
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      icon: Image.asset(
        assetPath,
        width: _RegisterScreenConstants.socialIconSize,
        height: _RegisterScreenConstants.socialIconSize,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            assetPath.contains('google') ? Icons.g_mobiledata : Icons.facebook,
            size: _RegisterScreenConstants.socialIconSize,
            color: assetPath.contains('google') ? Colors.red : Colors.blue,
          );
        },
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: _navigateToLogin,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            'Sign In',
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

  // ✅ InputDecoration с лучшей обработкой ошибок
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
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      errorText: errorText,
      errorMaxLines: 2, // ✅ Позволяет многострочные ошибки
      helperText: ' ', // ✅ Резервируем место для ошибок даже когда их нет
    );
  }

  // Event Handlers
  Future<void> _handleRegister() async {
    final auth = context.read<AuthProvider>();
    if (_formKey.currentState?.validate() ?? false) {
      await auth.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      final err = auth.error;
      if (err != null && err.trim().isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleRegister() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-up failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleFacebookRegister() async {
    try {
      await context.read<AuthProvider>().signInWithFacebook();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Facebook sign-up failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _goToStart(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const OnboardingScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const LoginScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
