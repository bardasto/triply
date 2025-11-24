import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';

/// Primary action button for booking the trip.
class BookButton extends StatelessWidget {
  final VoidCallback onBook;
  final bool isDark;
  final String text;

  const BookButton({
    super.key,
    required this.onBook,
    required this.isDark,
    this.text = 'Book Now',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: TripDetailsTheme.paddingHorizontal,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onBook,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(TripDetailsTheme.radiusLarge),
            ),
            elevation: 0,
          ),
          child: Text(
            text,
            style: const TextStyle(
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
