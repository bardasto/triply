import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';
import '../../utils/trip_details_utils.dart';

/// Header displaying trip title, duration, rating, and price.
class TripInfoHeader extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isDark;

  const TripInfoHeader({
    super.key,
    required this.trip,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TripDetailsTheme.of(isDark);
    final formattedPrice = TripDetailsUtils.formatPrice(trip['price']);

    return Padding(
      padding: TripDetailsTheme.paddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip['title'] ?? 'Untitled Trip',
            style: theme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildMetaRow(theme),
          const SizedBox(height: 12),
          _buildPriceRow(theme, formattedPrice),
        ],
      ),
    );
  }

  Widget _buildMetaRow(TripDetailsTheme theme) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: theme.textSecondary),
        const SizedBox(width: 4),
        Text(
          trip['duration'] ?? '7 days',
          style: theme.bodySmall,
        ),
        const SizedBox(width: 12),
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          '${trip['rating'] ?? 0.0}',
          style: theme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildPriceRow(TripDetailsTheme theme, String formattedPrice) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          color: theme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        children: [
          const TextSpan(text: 'from '),
          TextSpan(
            text: formattedPrice,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
