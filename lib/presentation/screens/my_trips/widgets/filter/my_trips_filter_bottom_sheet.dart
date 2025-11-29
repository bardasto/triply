import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../city_trips/models/activity_item.dart';
import '../../../city_trips/widgets/filter/price_histogram.dart';
import '../../theme/my_trips_theme.dart';

class MyTripsFilterBottomSheet extends StatefulWidget {
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
  // Search
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<String> searchSuggestions;

  const MyTripsFilterBottomSheet({
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
    required this.searchQuery,
    required this.onSearchChanged,
    required this.searchSuggestions,
  });

  @override
  State<MyTripsFilterBottomSheet> createState() => _MyTripsFilterBottomSheetState();
}

class _MyTripsFilterBottomSheetState extends State<MyTripsFilterBottomSheet> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController(text: widget.searchQuery);
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(MyTripsFilterBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _searchController.text != widget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus &&
          widget.searchSuggestions.isNotEmpty;
    });
  }

  void _onSearchTextChanged(String value) {
    widget.onSearchChanged(value);
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus &&
          widget.searchSuggestions.isNotEmpty;
    });
  }

  void _onSuggestionSelected(String suggestion) {
    _searchController.text = suggestion;
    widget.onSearchChanged(suggestion);
    _searchFocusNode.unfocus();
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
    final rightPadding = MediaQuery.of(context).padding.right;

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: MyTripsTheme.filterSheetBlur,
            sigmaY: MyTripsTheme.filterSheetBlur,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: MyTripsTheme.filterSheetBackground
                  .withValues(alpha: MyTripsTheme.filterSheetBackgroundAlpha),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
          children: [
            // Main scrollable content
            Column(
              children: [
                _buildHeaderWithHandle(rightPadding),
                _buildDivider(rightPadding),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      right: rightPadding,
                      bottom: 100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchSection(rightPadding),
                        const SizedBox(height: 16),
                        _buildSectionDivider(rightPadding),
                        const SizedBox(height: 16),
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
            // Show results button
            Positioned(
              left: 40,
              right: 40,
              bottom: 30,
              child: _buildShowResultsButton(),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithHandle(double rightPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20 + rightPadding, 12),
      child: Row(
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Drag handle in center
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 50,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              _searchController.clear();
              widget.onClearFilter();
            },
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
        borderRadius: BorderRadius.circular(MyTripsTheme.filterButtonRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MyTripsTheme.filterButtonHeight,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(MyTripsTheme.filterButtonRadius),
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

  Widget _buildSearchSection(double rightPadding) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20 + rightPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(PhosphorIconsBold.magnifyingGlass, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                'Search',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSearchField(),
          if (_showSuggestions && widget.searchSuggestions.isNotEmpty)
            _buildSuggestions(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchFocusNode.hasFocus
              ? AppColors.primary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchTextChanged,
        keyboardAppearance: Brightness.dark,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'City, country or keyword...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            PhosphorIconsRegular.magnifyingGlass,
            color: Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    widget.onSearchChanged('');
                  },
                  child: Icon(
                    PhosphorIconsRegular.x,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = widget.searchSuggestions.take(5).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            final isLast = index == suggestions.length - 1;

            return _SuggestionItem(
              suggestion: suggestion,
              searchQuery: _searchController.text,
              isLast: isLast,
              onTap: () => _onSuggestionSelected(suggestion),
            );
          }).toList(),
        ),
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

class _SuggestionItem extends StatelessWidget {
  final String suggestion;
  final String searchQuery;
  final bool isLast;
  final VoidCallback onTap;

  const _SuggestionItem({
    required this.suggestion,
    required this.searchQuery,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIconsRegular.mapPin,
              color: AppColors.primary.withValues(alpha: 0.7),
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHighlightedText(suggestion, searchQuery),
            ),
            Icon(
              PhosphorIconsRegular.arrowUpLeft,
              color: Colors.white.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);

    if (startIndex == -1) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final endIndex = startIndex + query.length;
    final beforeMatch = text.substring(0, startIndex);
    final match = text.substring(startIndex, endIndex);
    final afterMatch = text.substring(endIndex);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: beforeMatch,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          TextSpan(
            text: match,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: afterMatch,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
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
