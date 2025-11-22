import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';

class TripDetailsSections {
  static Widget buildAboutSection({
    required Map<String, dynamic> trip,
    required bool isDark,
  }) {
    final textPrimary = isDark ? Colors.white : AppColors.text;
    final textSecondary = isDark ? Colors.white70 : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            trip['description'] ?? 'No description available.',
            style: TextStyle(fontSize: 15, height: 1.5, color: textSecondary),
          ),
        ],
      ),
    );
  }

  static Widget buildIncludesSection({
    required Map<String, dynamic> trip,
    required bool isDark,
  }) {
    final textPrimary = isDark ? Colors.white : AppColors.text;
    final textSecondary = isDark ? Colors.white70 : AppColors.textSecondary;
    final includes = trip['includes'] as List?;

    if (includes == null || includes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s Included',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...includes.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.toString(),
                        style: TextStyle(fontSize: 15, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static Widget buildBookButton({
    required VoidCallback onBook,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onBook,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Book Now',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
