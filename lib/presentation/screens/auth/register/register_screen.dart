// lib/presentation/screens/auth/register/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../widgets/common/smart_scroll_view.dart';
import '../../onboarding/onboarding_screen.dart';
import 'constants/register_constants.dart';
import 'services/register_auth_service.dart';
import 'widgets/register_header.dart';
import 'widgets/register_form.dart';
import 'widgets/register_actions.dart';

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
  final _scrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late RegisterAuthService _authService;

  @override
  void initState() {
    super.initState();
    _initServices();
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
    super.dispose();
  }

  void _initServices() {
    _authService = RegisterAuthService(context);
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: RegisterScreenConstants.fadeAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: RegisterScreenConstants.fadeAnimationCurve,
      ),
    );

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
      body: WillPopScope(
        onWillPop: () async {
          _goToStart(context);
          return false;
        },
        child: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              _authService.handleAuthStateChanges(auth);
              return _buildBody(auth);
            },
          ),
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
        onPressed: () => _goToStart(context),
      ),
    );
  }

  Widget _buildBody(AuthProvider auth) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SmartScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(
          horizontal: RegisterScreenConstants.horizontalPadding,
          vertical: RegisterScreenConstants.verticalPadding,
        ),
        bounceBackType: BounceBackType.toTop,
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
          SizedBox(height: RegisterScreenConstants.topPadding),

          // 📝 HEADER
          const RegisterHeader(),
          SizedBox(height: RegisterScreenConstants.headerBottomPadding),

          // 📋 FORM
          RegisterForm(
            formKey: _formKey,
            nameController: _nameController,
            emailController: _emailController,
            passwordController: _passwordController,
            authService: _authService,
          ),
          SizedBox(height: RegisterScreenConstants.registerButtonSpacing),

          // 🎯 ACTIONS
          RegisterActions(
            formKey: _formKey,
            nameController: _nameController,
            emailController: _emailController,
            passwordController: _passwordController,
            authService: _authService,
          ),

          SizedBox(height: RegisterScreenConstants.bottomPadding),
        ],
      ),
    );
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
}
