// lib/presentation/screens/auth/login/widgets/login_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../providers/auth_provider.dart';
import '../constants/login_constants.dart';
import '../services/login_scroll_service.dart';
import '../services/login_auth_service.dart';
import '../dialogs/forgot_password_dialog.dart';

class LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final LoginScrollService scrollService;
  final LoginAuthService authService;

  const LoginForm({
    Key? key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.scrollService,
    required this.authService,
  }) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 📝 EMAIL FIELD
        _buildEmailField(),
        SizedBox(height: LoginBottomSheetConstants.fieldSpacing),

        // 🔒 PASSWORD FIELD
        _buildPasswordField(),
        SizedBox(height: LoginBottomSheetConstants.forgotPasswordTopSpacing),

        // 🔗 FORGOT PASSWORD
        _buildForgotPasswordButton(),
        SizedBox(height: LoginBottomSheetConstants.forgotPasswordBottomSpacing),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: widget.emailController,
      focusNode: widget.emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(fontSize: LoginBottomSheetConstants.fieldFontSize),
      onFieldSubmitted: (_) {
        FocusScope.of(context).requestFocus(widget.passwordFocusNode);
      },
      decoration: _buildInputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email',
        prefixIcon: Icons.email_outlined,
        errorText: context.watch<AuthProvider>().emailFieldError,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required';
        if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$').hasMatch(v.trim())) {
          return 'Enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: widget.passwordController,
      focusNode: widget.passwordFocusNode,
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      style: TextStyle(fontSize: LoginBottomSheetConstants.fieldFontSize),
      onFieldSubmitted: (_) {
        if (widget.formKey.currentState!.validate()) {
          _handleLogin();
        }
      },
      decoration: _buildInputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: Icons.lock_outline,
        errorText: context.watch<AuthProvider>().passwordFieldError,
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: LoginBottomSheetConstants.fieldIconColor,
            size: LoginBottomSheetConstants.fieldIconSize,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        return null;
      },
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => ForgotPasswordDialog.show(context, widget.authService),
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: LoginBottomSheetConstants.forgotPasswordFontSize,
          ),
        ),
      ),
    );
  }

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
      prefixIcon: Icon(
        prefixIcon,
        color: LoginBottomSheetConstants.fieldIconColor,
        size: LoginBottomSheetConstants.fieldIconSize,
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(LoginBottomSheetConstants.fieldBorderRadius),
        borderSide: BorderSide(
          color: LoginBottomSheetConstants.fieldBorderColor,
          width: LoginBottomSheetConstants.fieldBorderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(LoginBottomSheetConstants.fieldBorderRadius),
        borderSide: BorderSide(
          color: LoginBottomSheetConstants.fieldBorderColor,
          width: LoginBottomSheetConstants.fieldBorderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(LoginBottomSheetConstants.fieldBorderRadius),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: LoginBottomSheetConstants.fieldFocusBorderWidth,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(LoginBottomSheetConstants.fieldBorderRadius),
        borderSide: BorderSide(
          color: Colors.red,
          width: LoginBottomSheetConstants.fieldBorderWidth,
        ),
      ),
      filled: true,
      fillColor: LoginBottomSheetConstants.fieldBackgroundColor,
      contentPadding: LoginBottomSheetConstants.fieldPadding,
      errorText: errorText,
      errorMaxLines: 2,
    );
  }

  // ✅ ТЕПЕРЬ ЕСТЬ ДОСТУП К context ЧЕРЕЗ STATE
  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (widget.formKey.currentState!.validate()) {
      await widget.authService.login(
        widget.emailController.text,
        widget.passwordController.text,
      );
    }
  }
}
