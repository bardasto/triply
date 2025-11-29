import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../../../../../../core/models/city_model.dart';
import '../../theme/search_theme.dart';

/// Single suggestion item in the search suggestions list.
class SuggestionItem extends StatelessWidget {
  final CityModel city;
  final VoidCallback onTap;

  const SuggestionItem({
    super.key,
    required this.city,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    city.name,
                    style: SearchTheme.suggestionTitleStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    city.country,
                    style: SearchTheme.suggestionSubtitleStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
