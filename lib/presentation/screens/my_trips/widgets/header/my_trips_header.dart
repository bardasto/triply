import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../city_trips/models/activity_item.dart';
import '../../../city_trips/widgets/header/view_toggle_button.dart';

/// Suggestion item for search.
class SearchSuggestion {
  final String label;
  final String type;
  final IconData icon;
  final Color color;

  const SearchSuggestion({
    required this.label,
    required this.type,
    required this.icon,
    required this.color,
  });
}

/// Header widget for My Trips screen with search field.
class MyTripsHeader extends StatefulWidget {
  final double scrollOffset;
  final int tripsCount;
  final bool isGridView;
  final bool hasActiveFilter;
  final List<ActivityItem>? selectedActivities;
  final ValueChanged<bool> onToggleView;
  final VoidCallback onFilterPressed;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<SearchSuggestion> suggestions;
  final ValueChanged<bool>? onSearchFocusChanged;

  const MyTripsHeader({
    super.key,
    required this.scrollOffset,
    required this.tripsCount,
    required this.isGridView,
    required this.hasActiveFilter,
    required this.selectedActivities,
    required this.onToggleView,
    required this.onFilterPressed,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.suggestions,
    this.onSearchFocusChanged,
  });

  static const double searchFieldFullHeight = 48.0;
  static const double scrollThreshold = 50.0;
  static const double expandedSearchHeight = 280.0;

  @override
  State<MyTripsHeader> createState() => _MyTripsHeaderState();
}

class _MyTripsHeaderState extends State<MyTripsHeader>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void didUpdateWidget(MyTripsHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery &&
        _controller.text != widget.searchQuery) {
      _controller.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus != _isSearchFocused) {
      setState(() => _isSearchFocused = hasFocus);
      if (hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
      widget.onSearchFocusChanged?.call(hasFocus);
    }
  }

  void _onSearchChanged(String value) {
    widget.onSearchChanged(value);
  }

  void _clearSearch() {
    HapticFeedback.lightImpact();
    _controller.clear();
    widget.onSearchChanged('');
  }

  void _cancelSearch() {
    HapticFeedback.lightImpact();
    _controller.clear();
    widget.onSearchChanged('');
    _focusNode.unfocus();
  }

  void _selectSuggestion(SearchSuggestion suggestion) {
    HapticFeedback.selectionClick();
    _controller.text = suggestion.label;
    widget.onSearchChanged(suggestion.label);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    final searchProgress = _isSearchFocused
        ? 0.0
        : (widget.scrollOffset / MyTripsHeader.scrollThreshold).clamp(0.0, 1.0);
    final searchFieldHeight =
        MyTripsHeader.searchFieldFullHeight * (1 - searchProgress);
    final searchFieldOpacity = (1 - searchProgress * 1.2).clamp(0.0, 1.0);
    final searchFieldScale = 1 - (searchProgress * 0.3);

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final expandProgress = _expandAnimation.value;
        final suggestionsHeight =
            MyTripsHeader.expandedSearchHeight * expandProgress;
        final totalHeight =
            topPadding + 56 + searchFieldHeight + suggestionsHeight;

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: totalHeight,
            color: Color.lerp(
              AppColors.darkBackground.withValues(alpha: searchProgress),
              AppColors.darkBackground,
              expandProgress,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top row
                  SizedBox(
                    height: 56,
                    child: Stack(
                      children: [
                        // Title
                        Opacity(
                          opacity: 1 - expandProgress,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'My Trips',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${widget.tripsCount} ${widget.tripsCount == 1 ? 'trip' : 'trips'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Buttons
                        Opacity(
                          opacity: 1 - expandProgress,
                          child: IgnorePointer(
                            ignoring: expandProgress > 0.5,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: _buildIconButton(
                                      icon: PhosphorIconsBold.funnel,
                                      isActive: widget.hasActiveFilter,
                                      onTap: widget.onFilterPressed,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ViewToggleButton(
                                      isGridView: widget.isGridView,
                                      onToggle: widget.onToggleView,
                                      embedded: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  ClipRect(
                    child: SizedBox(
                      height: searchFieldHeight,
                      child: Opacity(
                        opacity: searchFieldOpacity,
                        child: Transform.scale(
                          scale: searchFieldScale,
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 16, right: 16, top: 8),
                            child: _buildSearchField(expandProgress),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Suggestions
                  if (expandProgress > 0)
                    SizedBox(
                      height: suggestionsHeight,
                      child: Opacity(
                        opacity: expandProgress,
                        child: ClipRect(
                          child: _buildSuggestionsArea(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSearchField(double expandProgress) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    cursorColor: AppColors.primary,
                    keyboardAppearance: Brightness.dark,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 16,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 10),
              ],
            ),
          ),
        ),
        // Cancel button
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _isSearchFocused ? 65 : 0,
          curve: Curves.easeOut,
          child: ClipRect(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _isSearchFocused ? 1.0 : 0.0,
              child: GestureDetector(
                onTap: _cancelSearch,
                child: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'Cancel',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsArea() {
    final suggestions = widget.suggestions.take(5).toList();

    if (suggestions.isEmpty && widget.searchQuery.isNotEmpty) {
      return _buildNoResults();
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                widget.searchQuery.isEmpty ? 'Quick Search' : 'Results',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (suggestions.isEmpty)
              _buildEmptyState()
            else
              ...suggestions.map((s) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSuggestionTile(s),
                  if (s != suggestions.last)
                    Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                ],
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(SearchSuggestion suggestion) {
    return GestureDetector(
      onTap: () => _selectSuggestion(suggestion),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(
              suggestion.icon,
              color: suggestion.color,
              size: 18,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                suggestion.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              suggestion.type,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
            color: Colors.white.withValues(alpha: 0.15),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Type to search',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
            color: Colors.white.withValues(alpha: 0.15),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No results',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try different keywords',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
