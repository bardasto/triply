// lib/presentation/screens/auth/register/widgets/register_form.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../providers/auth_provider.dart';
import '../constants/register_constants.dart';
import '../services/register_auth_service.dart';

class RegisterForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final RegisterAuthService authService;

  const RegisterForm({
    Key? key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.authService,
  }) : super(key: key);

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 👤 NAME FIELD
        _buildNameField(),
        SizedBox(height: RegisterScreenConstants.fieldSpacing),

        // 📧 EMAIL FIELD
        _buildEmailField(),
        SizedBox(height: RegisterScreenConstants.fieldSpacing),

        // 🔒 PASSWORD FIELD
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildNameField() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: RegisterScreenConstants.fieldMinHeight,
      ),
      child: TextFormField(
        controller: widget.nameController,
        textInputAction: TextInputAction.next,
        style: TextStyle(fontSize: RegisterScreenConstants.fieldFontSize),
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

  Widget _buildEmailField() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: RegisterScreenConstants.fieldMinHeight,
      ),
      child: TextFormField(
        controller: widget.emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        style: TextStyle(fontSize: RegisterScreenConstants.fieldFontSize),
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

  Widget _buildPasswordField() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: RegisterScreenConstants.fieldMinHeight,
      ),
      child: TextFormField(
        controller: widget.passwordController,
        obscureText: !_isPasswordVisible,
        textInputAction: TextInputAction.done,
        style: TextStyle(fontSize: RegisterScreenConstants.fieldFontSize),
        onFieldSubmitted: (_) {
          if (widget.formKey.currentState!.validate()) {
            _handleRegister();
          }
        },
        decoration: _buildInputDecoration(
          labelText: 'Password',
          hintText: 'Create a strong password',
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: RegisterScreenConstants.fieldIconColor,
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
      prefixIcon:
          Icon(prefixIcon, color: RegisterScreenConstants.fieldIconColor),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(RegisterScreenConstants.fieldBorderRadius),
        borderSide: BorderSide(
          color: RegisterScreenConstants.fieldBorderColor,
          width: RegisterScreenConstants.fieldBorderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(RegisterScreenConstants.fieldBorderRadius),
        borderSide: BorderSide(
          color: RegisterScreenConstants.fieldBorderColor,
          width: RegisterScreenConstants.fieldBorderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(RegisterScreenConstants.fieldBorderRadius),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: RegisterScreenConstants.fieldFocusBorderWidth,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(RegisterScreenConstants.fieldBorderRadius),
        borderSide: BorderSide(
          color: Colors.red,
          width: RegisterScreenConstants.fieldBorderWidth,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(RegisterScreenConstants.fieldBorderRadius),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: RegisterScreenConstants.fieldBackgroundColor,
      contentPadding: RegisterScreenConstants.fieldPadding,
      errorText: errorText,
      errorMaxLines: 2,
      helperText: ' ',
    );
  }

  Future<void> _handleRegister() async {
    if (widget.formKey.currentState?.validate() ?? false) {
      await widget.authService.register(
        email: widget.emailController.text,
        password: widget.passwordController.text,
        displayName: widget.nameController.text,
      );
    }
  }
}
