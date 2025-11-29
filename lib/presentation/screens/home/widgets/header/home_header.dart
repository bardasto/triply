import 'package:flutter/material.dart';
import 'location_display.dart';
import 'profile_avatar.dart';

/// Header widget for Home screen with location and profile avatar.
class HomeHeader extends StatelessWidget {
  final VoidCallback onProfileTap;

  const HomeHeader({
    super.key,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const LocationDisplay(),
          ProfileAvatar(onTap: onProfileTap),
        ],
      ),
    );
  }
}
