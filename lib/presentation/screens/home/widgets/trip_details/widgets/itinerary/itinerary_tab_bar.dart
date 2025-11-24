import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';

/// Custom styled tab bar for itinerary section.
class ItineraryTabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;
  final List<String> tabs;

  const ItineraryTabBar({
    super.key,
    required this.controller,
    required this.isDark,
    this.tabs = const ['Places', 'Restaurants'],
  });

  @override
  Widget build(BuildContext context) {
    final theme = TripDetailsTheme.of(isDark);

    return Container(
      decoration: theme.surfaceDecoration,
      child: TabBar(
        controller: controller,
        labelColor: AppColors.primary,
        unselectedLabelColor: theme.textSecondary,
        indicator: BoxDecoration(
          color: theme.tabIndicatorColor,
          borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}
