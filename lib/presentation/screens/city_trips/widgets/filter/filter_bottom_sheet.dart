import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../models/activity_item.dart';
import '../../theme/city_trips_theme.dart';
import 'price_histogram.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<ActivityItem> activities;
  final Set<int> selectedActivityIndices;
  final int Function(String) getTripCount;
  final ValueChanged<int> onActivitySelected;
  final VoidCallback onClearFilter;
  final RangeValues priceRange;
  final double minPrice;
  final double maxPrice;
  final ValueChanged<RangeValues> onPriceRangeChanged;
  final List<double> priceDistribution;
  final int filteredCount;
  final VoidCallback onShowResults;

  const FilterBottomSheet({
    super.key,
    required this.activities,
    required this.selectedActivityIndices,
    required this.getTripCount,
    required this.onActivitySelected,
    required this.onClearFilter,
    required this.priceRange,
    required this.minPrice,
    required this.maxPrice,
    required this.onPriceRangeChanged,
    required this.priceDistribution,
    required this.filteredCount,
    required this.onShowResults,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rightPadding = MediaQuery.of(context).padding.right;

    return Container(
      decoration: const BoxDecoration(
        color: CityTripsTheme.filterSheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildHandle(),
              _buildHeader(rightPadding),
              _buildDivider(rightPadding),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.only(right: rightPadding, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPriceSection(),
                      const SizedBox(height: 16),
                      _buildSectionDivider(rightPadding),
                      const SizedBox(height: 16),
                      _buildActivitySection(rightPadding),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 40,
            right: 40,
            bottom: 30,
            child: _buildShowResultsButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(double rightPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20 + rightPadding, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: widget.onClearFilter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Clear all',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(double rightPadding) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20 + rightPadding),
      height: 0.5,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _buildSectionDivider(double rightPadding) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20 + rightPadding),
      height: 0.5,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _buildShowResultsButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onShowResults();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CityTripsTheme.filterButtonRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: CityTripsTheme.filterButtonHeight,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(CityTripsTheme.filterButtonRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Show ${widget.filteredCount} results',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(PhosphorIconsBold.currencyEur, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Price Range',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '€ ${widget.priceRange.start.toInt()} - € ${widget.priceRange.end.toInt()}${widget.priceRange.end >= widget.maxPrice ? ' +' : ''}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: PriceHistogram(
              distribution: widget.priceDistribution,
              rangeStart: (widget.priceRange.start - widget.minPrice) /
                  (widget.maxPrice - widget.minPrice),
              rangeEnd: (widget.priceRange.end - widget.minPrice) /
                  (widget.maxPrice - widget.minPrice),
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: RangeSlider(
              values: widget.priceRange,
              min: widget.minPrice,
              max: widget.maxPrice,
              onChanged: widget.onPriceRangeChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(double rightPadding) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20 + rightPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(PhosphorIconsBold.compass, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Activity Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.activities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              final tripCount = widget.getTripCount(activity.id);
              final isSelected = widget.selectedActivityIndices.contains(index);

              return _ActivityChip(
                activity: activity,
                tripCount: tripCount,
                isSelected: isSelected,
                screenWidth: MediaQuery.of(context).size.width,
                rightPadding: rightPadding,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onActivitySelected(index);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  final ActivityItem activity;
  final int tripCount;
  final bool isSelected;
  final double screenWidth;
  final double rightPadding;
  final VoidCallback onTap;

  const _ActivityChip({
    required this.activity,
    required this.tripCount,
    required this.isSelected,
    required this.screenWidth,
    required this.rightPadding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (screenWidth - 40 - rightPadding - 10) / 2,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activity.color.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(
                    color: activity.color.withValues(alpha: 0.5),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? activity.color.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  activity.icon,
                  color: isSelected ? activity.color : Colors.white70,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? activity.color : Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$tripCount trips',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: tripCount > 0
                            ? (isSelected
                                ? activity.color.withValues(alpha: 0.8)
                                : Colors.white54)
                            : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: activity.color,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
