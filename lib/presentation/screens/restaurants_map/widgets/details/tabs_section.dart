import 'package:flutter/material.dart';
import '../../../../../../core/constants/color_constants.dart';

/// Tabs section for restaurant details
class TabsSection extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const TabsSection({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildTab('Overview', 0),
        _buildTab('Menu', 1),
        _buildTab('Reviews', 2),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
