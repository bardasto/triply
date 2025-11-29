import 'package:flutter/material.dart';
import '../../theme/home_theme.dart';

/// Search field widget for home screen.
class HomeSearchField extends StatelessWidget {
  final VoidCallback onTap;

  const HomeSearchField({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: HomeTheme.searchFieldDecoration,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search,
                color: Colors.white.withValues(alpha: 0.4),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Search',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
