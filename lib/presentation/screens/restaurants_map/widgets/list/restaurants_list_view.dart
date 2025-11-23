import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../common/sticky_header_delegate.dart';
import 'filters_row.dart';
import 'restaurant_card.dart';
import '../../utils/restaurant_formatters.dart';
import '../../utils/opening_hours_helper.dart';
import '../../../../../../core/constants/color_constants.dart';

/// Restaurants List View with filters
class RestaurantsListView extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  final ScrollController scrollController;
  final String? editingRestaurantId;
  final Function(Map<String, dynamic>, int) onRestaurantTapped;

  const RestaurantsListView({
    super.key,
    required this.restaurants,
    required this.scrollController,
    this.editingRestaurantId,
    required this.onRestaurantTapped,
  });

  @override
  State<RestaurantsListView> createState() => _RestaurantsListViewState();
}

class _RestaurantsListViewState extends State<RestaurantsListView> {
  String? _priceSortOrder;
  bool _topRatedFilter = false;
  bool _openNowFilter = false;
  String? _selectedCuisine;

  List<String> _getAvailableCuisines() {
    final Set<String> cuisines = {};
    for (var restaurant in widget.restaurants) {
      final cuisine = restaurant['cuisine'] as String?;
      if (cuisine != null && cuisine.isNotEmpty) {
        cuisines.add(cuisine);
      }
    }
    return cuisines.toList()..sort();
  }

  List<Map<String, dynamic>> _getFilteredRestaurants() {
    List<Map<String, dynamic>> filtered = List.from(widget.restaurants);

    if (_openNowFilter) {
      filtered = filtered.where((r) {
        return OpeningHoursHelper.isRestaurantOpen(r['opening_hours']);
      }).toList();
    }

    if (_selectedCuisine != null) {
      filtered = filtered.where((r) {
        final cuisine = r['cuisine'] as String?;
        return cuisine == _selectedCuisine;
      }).toList();
    }

    if (_priceSortOrder != null) {
      filtered.sort((a, b) {
        final priceA = RestaurantFormatters.getPriceLevel(a['price_level']);
        final priceB = RestaurantFormatters.getPriceLevel(b['price_level']);

        if (_priceSortOrder == 'asc') {
          return priceA.compareTo(priceB);
        } else {
          return priceB.compareTo(priceA);
        }
      });
    }

    if (_topRatedFilter) {
      filtered.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return ratingB.compareTo(ratingA);
      });
    }

    return filtered;
  }

  void _showCuisineFilter() {
    final cuisines = _getAvailableCuisines();
    if (cuisines.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C).withValues(alpha: 0.99),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Select Cuisine',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (_selectedCuisine != null)
                  ListTile(
                    leading: const Icon(Icons.clear, color: Colors.red),
                    title: const Text(
                      'Clear filter',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCuisine = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ...cuisines.map((cuisine) => ListTile(
                      leading: Icon(
                        Icons.restaurant,
                        color: _selectedCuisine == cuisine
                            ? AppColors.primary
                            : Colors.white70,
                      ),
                      title: Text(
                        cuisine,
                        style: TextStyle(
                          color: _selectedCuisine == cuisine
                              ? AppColors.primary
                              : Colors.white,
                          fontWeight: _selectedCuisine == cuisine
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedCuisine = cuisine;
                        });
                        Navigator.pop(context);
                      },
                    )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRestaurants = _getFilteredRestaurants();

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: StickyHeaderDelegate(
            minHeight: 140,
            maxHeight: 140,
            child: Container(
              color: const Color(0xFF1C1C1E),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetHandle(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Restaurants',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FiltersRow(
                    openNowFilter: _openNowFilter,
                    topRatedFilter: _topRatedFilter,
                    priceSortOrder: _priceSortOrder,
                    selectedCuisine: _selectedCuisine,
                    availableCuisines: _getAvailableCuisines(),
                    onOpenNowToggle: () {
                      setState(() {
                        _openNowFilter = !_openNowFilter;
                      });
                    },
                    onTopRatedToggle: () {
                      setState(() {
                        _topRatedFilter = !_topRatedFilter;
                      });
                    },
                    onPriceSort: () {
                      setState(() {
                        if (_priceSortOrder == null) {
                          _priceSortOrder = 'asc';
                        } else if (_priceSortOrder == 'asc') {
                          _priceSortOrder = 'desc';
                        } else {
                          _priceSortOrder = null;
                        }
                      });
                    },
                    onCuisineFilter: _showCuisineFilter,
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _buildRestaurantCard(filteredRestaurants, index),
                    ],
                  );
                }
                return _buildRestaurantCard(filteredRestaurants, index);
              },
              childCount: filteredRestaurants.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(
      List<Map<String, dynamic>> filteredRestaurants, int index) {
    final restaurant = filteredRestaurants[index];
    final restaurantId = restaurant['poi_id']?.toString() ?? restaurant['name'];
    final isBeingEdited = widget.editingRestaurantId == restaurantId;

    return RestaurantCard(
      restaurant: restaurant,
      isBeingEdited: isBeingEdited,
      isLast: index == filteredRestaurants.length - 1,
      onTap: () => widget.onRestaurantTapped(restaurant, index),
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 60,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
