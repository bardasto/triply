import 'package:flutter/material.dart';
import '../../../../../../core/constants/color_constants.dart';

/// Filters row for restaurant list
class FiltersRow extends StatelessWidget {
  final bool openNowFilter;
  final bool topRatedFilter;
  final String? priceSortOrder;
  final String? selectedCuisine;
  final List<String> availableCuisines;
  final VoidCallback onOpenNowToggle;
  final VoidCallback onTopRatedToggle;
  final VoidCallback onPriceSort;
  final VoidCallback onCuisineFilter;

  const FiltersRow({
    super.key,
    required this.openNowFilter,
    required this.topRatedFilter,
    required this.priceSortOrder,
    required this.selectedCuisine,
    required this.availableCuisines,
    required this.onOpenNowToggle,
    required this.onTopRatedToggle,
    required this.onPriceSort,
    required this.onCuisineFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildFilterChip(
                icon: Icons.access_time,
                label: 'Open now',
                isActive: openNowFilter,
                onTap: onOpenNowToggle,
              ),
              const SizedBox(width: 8),
              _buildPriceFilterChip(),
              const SizedBox(width: 8),
              _buildFilterChip(
                icon: Icons.star,
                label: 'Top rated',
                isActive: topRatedFilter,
                onTap: onTopRatedToggle,
              ),
              const SizedBox(width: 8),
              _buildCuisineFilterChip(context),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    IconData? trailingIcon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceFilterChip() {
    IconData? trailingIcon;
    if (priceSortOrder == 'asc') {
      trailingIcon = Icons.arrow_downward;
    } else if (priceSortOrder == 'desc') {
      trailingIcon = Icons.arrow_upward;
    }

    return _buildFilterChip(
      icon: Icons.euro,
      label: 'Price',
      isActive: priceSortOrder != null,
      trailingIcon: trailingIcon,
      onTap: onPriceSort,
    );
  }

  Widget _buildCuisineFilterChip(BuildContext context) {
    return _buildFilterChip(
      icon: Icons.restaurant_menu,
      label: selectedCuisine ?? 'Cuisine',
      isActive: selectedCuisine != null,
      onTap: () {
        if (availableCuisines.isEmpty) return;
        onCuisineFilter();
      },
    );
  }
}
