// lib/presentation/screens/auth/login/login_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import 'constants/login_constants.dart';
import 'services/login_scroll_service.dart';
import 'services/login_auth_service.dart';
import 'widgets/login_header.dart';
import 'widgets/login_form.dart';
import 'widgets/login_actions.dart';

class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({Key? key}) : super(key: key);

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late LoginScrollService _scrollService;
  late LoginAuthService _authService;

  @override
  void initState() {
    super.initState();
    _initServices();
    _initAnimations();
    _setupFieldListeners();
    _setupFocusListeners();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollService.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _initServices() {
    _scrollService = LoginScrollService(_scrollController);
    _authService = LoginAuthService(context);
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: LoginBottomSheetConstants.slideAnimationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: LoginBottomSheetConstants.slideAnimationBegin,
      end: LoginBottomSheetConstants.slideAnimationEnd,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: LoginBottomSheetConstants.slideAnimationCurve,
    ));

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

  void _setupFocusListeners() {
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        _scrollService.smartScrollToField('email', context);
      }
    });

    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        _scrollService.smartScrollToField('password', context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isTablet =
        screenSize.width > LoginBottomSheetConstants.tabletBreakpoint;

    double bottomSheetHeight =
        _calculateBottomSheetHeight(screenSize, keyboardHeight);
    final horizontalPadding = _getHorizontalPadding(isTablet);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, bottomSheetHeight * _slideAnimation.value),
          child: Container(
            height: bottomSheetHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(LoginBottomSheetConstants.borderRadius),
              ),
            ),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  _buildDragHandle(),
                  Expanded(
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        _authService.handleAuthStateChanges(auth);
                        return _buildScrollableContent(
                            horizontalPadding, isTablet);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _calculateBottomSheetHeight(Size screenSize, double keyboardHeight) {
    double height;
    if (keyboardHeight > 0) {
      height =
          screenSize.height * LoginBottomSheetConstants.keyboardOpenHeightRatio;
    } else {
      height = screenSize.height * LoginBottomSheetConstants.heightRatio;
    }
    return height.clamp(
        LoginBottomSheetConstants.minHeight, screenSize.height * 0.98);
  }

  double _getHorizontalPadding(bool isTablet) {
    return isTablet
        ? LoginBottomSheetConstants.tabletHorizontalPadding
        : LoginBottomSheetConstants.horizontalPadding;
  }

  Widget _buildDragHandle() {
    return Container(
      margin: EdgeInsets.only(
        top: LoginBottomSheetConstants.dragHandleTopMargin,
        bottom: LoginBottomSheetConstants.dragHandleBottomMargin,
      ),
      width: LoginBottomSheetConstants.dragHandleWidth,
      height: LoginBottomSheetConstants.dragHandleHeight,
      decoration: BoxDecoration(
        color: LoginBottomSheetConstants.dragHandleColor,
        borderRadius: BorderRadius.circular(
            LoginBottomSheetConstants.dragHandleBorderRadius),
      ),
    );
  }

  Widget _buildScrollableContent(double horizontalPadding, bool isTablet) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: IntrinsicHeight(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: LoginBottomSheetConstants.topContentPadding),
                LoginHeader(isTablet: isTablet),
                SizedBox(height: LoginBottomSheetConstants.headerBottomSpacing),
                LoginForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  emailFocusNode: _emailFocusNode,
                  passwordFocusNode: _passwordFocusNode,
                  scrollService: _scrollService,
                  authService: _authService,
                ),
                LoginActions(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  authService: _authService,
                ),
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom > 0
                      ? LoginBottomSheetConstants.bottomContentPadding * 2
                      : LoginBottomSheetConstants.bottomContentPadding,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
