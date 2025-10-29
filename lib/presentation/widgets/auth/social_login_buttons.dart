import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import '../../../core/constants/color_constants.dart';
import '../../../providers/auth_provider.dart';

class SocialLoginButtons extends StatelessWidget {
  final bool isRegister;

  const SocialLoginButtons({
    Key? key,
    this.isRegister = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actionText = isRegister ? 'Sign up' : 'Sign in';

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            // Google кнопка
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: authProvider.isLoading
                    ? null
                    : () {
                        authProvider.signInWithGoogle();
                      },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Container(
                  width: 20,
                  height: 20,
                  child: Image.network(
                    'https://developers.google.com/identity/images/g-logo.png',
                    errorBuilder: (context, error, stackTrace) {
                      return const FaIcon(
                        FontAwesomeIcons.google,
                        size: 20,
                        color: Colors.red,
                      );
                    },
                  ),
                ),
                label: authProvider.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.grey[600],
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        '$actionText with Google',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Facebook кнопка
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: authProvider.isLoading
                    ? null
                    : () {
                        authProvider.signInWithFacebook();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const FaIcon(
                  FontAwesomeIcons.facebookF,
                  size: 20,
                ),
                label: authProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        '$actionText with Facebook',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
