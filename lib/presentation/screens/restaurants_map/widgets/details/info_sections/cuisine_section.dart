import 'package:flutter/material.dart';

/// Cuisine Section widget
class CuisineSection extends StatelessWidget {
  final String cuisine;

  const CuisineSection({
    super.key,
    required this.cuisine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.restaurant_menu,
            color: Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Cuisine - ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: cuisine,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
