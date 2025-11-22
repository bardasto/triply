import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';

class TripDetailsHeader extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isDark;

  const TripDetailsHeader({
    super.key,
    required this.trip,
    required this.isDark,
  });

  String get _formattedPrice {
    final price = trip['price']?.toString() ?? '\$999';
    return price.replaceFirst('from ', '').replaceFirst('From ', '');
  }

  Color get _textPrimary => isDark ? Colors.white : AppColors.text;
  Color get _textSecondary => isDark ? Colors.white70 : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip['title'] ?? 'Untitled Trip',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: _textSecondary),
              const SizedBox(width: 4),
              Text(
                trip['duration'] ?? '7 days',
                style: TextStyle(fontSize: 14, color: _textSecondary),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '${trip['rating'] ?? 0.0}',
                style: TextStyle(fontSize: 14, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: 'from '),
                TextSpan(
                  text: _formattedPrice,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
