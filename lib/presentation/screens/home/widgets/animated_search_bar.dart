import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../providers/trip_provider.dart';

class AnimatedSearchBar extends StatefulWidget {
  final ValueChanged<bool>? onExpansionChanged;
  final ScrollController? scrollController;

  const AnimatedSearchBar({
    super.key,
    this.onExpansionChanged,
    this.scrollController,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  late double _maxWidth;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    // Listen for keyboard dismissal (only collapse if search is empty)
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isExpanded && _searchController.text.isEmpty) {
        _collapse();
      }
    });

    // Listen for scroll (close search if empty and user scrolls)
    widget.scrollController?.addListener(() {
      if (_isExpanded && _searchController.text.isEmpty && !_focusNode.hasFocus) {
        _collapse();
      }
    });

    // Не делаем автоматический поиск при вводе
    // Поиск только при нажатии на иконку
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() {
      _isExpanded = true;
    });
    _animationController.forward();
    widget.onExpansionChanged?.call(true);
    // Delay focus to allow animation to start
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _handleSearchTap() {
    if (_isExpanded) {
      if (_focusNode.hasFocus) {
        // Закрыть клавиатуру и выполнить поиск
        _focusNode.unfocus();
        if (_searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
      } else {
        // Если клавиатура уже закрыта, закрыть поиск
        _collapse();
      }
    } else {
      // Открыть поле поиска
      _expand();
    }
  }

  void _collapse() {
    _focusNode.unfocus();
    setState(() {
      _isExpanded = false;
      _searchController.clear();
    });
    _animationController.reverse();
    widget.onExpansionChanged?.call(false);
    _clearSearch();
  }

  void _performSearch(String query) {
    final tripProvider = context.read<TripProvider>();
    tripProvider.searchTripsByCity(query);
  }

  void _clearSearch() {
    final tripProvider = context.read<TripProvider>();
    tripProvider.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate max width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    // Screen width - left padding (16) - right padding (16) - location display (~50) - spacing (12) - profile avatar (50) - extra margin (20)
    _maxWidth = screenWidth - 164;
    // Clamp between reasonable values
    _maxWidth = _maxWidth.clamp(200.0, 300.0);

    // Initialize animation if needed
    _widthAnimation = Tween<double>(
      begin: 50.0,
      end: _maxWidth,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final totalWidth = _widthAnimation.value;

        return SizedBox(
          width: totalWidth,
          height: 50,
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              // Expandable search field (slides from right to left with animation)
              if (totalWidth > 50)
                Positioned(
                  right: 0,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: totalWidth,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 60),
                            child: Center(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search cities...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                cursorColor: AppColors.primary,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (value) {
                                  // Close keyboard and perform search
                                  _focusNode.unfocus();
                                  if (value.isNotEmpty) {
                                    _performSearch(value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Search icon button (always visible, stays on right)
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: _handleSearchTap,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_isExpanded ? 0.08 : 0.02),
                      shape: BoxShape.circle,
                      border: _isExpanded
                          ? Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
