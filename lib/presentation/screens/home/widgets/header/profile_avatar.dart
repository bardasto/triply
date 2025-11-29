import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../../../providers/auth_provider.dart';
import '../../theme/home_theme.dart';

/// Profile avatar widget with blur effect.
class ProfileAvatar extends StatelessWidget {
  final VoidCallback onTap;

  const ProfileAvatar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final photoUrl = authProvider.user?.avatarUrl;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: HomeTheme.profileAvatarDecoration(0.15),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _DefaultAvatar(),
                          )
                        : const _DefaultAvatar(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
