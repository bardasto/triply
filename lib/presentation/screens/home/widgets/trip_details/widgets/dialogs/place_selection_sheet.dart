import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../../../../../../core/data/repositories/place_repository.dart';
import '../../theme/trip_details_theme.dart';
import '../../utils/trip_details_utils.dart';

/// Bottom sheet for selecting a place from available places.
class PlaceSelectionSheet extends StatefulWidget {
  final String city;
  final String category;
  final Set<String> excludePlaceIds;
  final bool isDark;
  final Function(Map<String, dynamic>) onPlaceSelected;

  const PlaceSelectionSheet({
    super.key,
    required this.city,
    required this.category,
    required this.excludePlaceIds,
    required this.isDark,
    required this.onPlaceSelected,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String city,
    required String category,
    required Set<String> excludePlaceIds,
    required bool isDark,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceSelectionSheet(
        city: city,
        category: category,
        excludePlaceIds: excludePlaceIds,
        isDark: isDark,
        onPlaceSelected: (place) => Navigator.of(context).pop(place),
      ),
    );
  }

  @override
  State<PlaceSelectionSheet> createState() => _PlaceSelectionSheetState();
}

class _PlaceSelectionSheetState extends State<PlaceSelectionSheet> {
  final PlaceRepository _repository = PlaceRepository();
  List<Map<String, dynamic>> _places = [];
  bool _isLoading = true;
  String _searchQuery = '';

  Color get _backgroundColor =>
      widget.isDark ? const Color(0xFF1C1C1E) : Colors.white;
  Color get _textColor => widget.isDark ? Colors.white : Colors.black;
  Color get _secondaryTextColor =>
      widget.isDark ? Colors.white70 : Colors.black54;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    final places = await _repository.getPlacesByCityAndCategory(
      city: widget.city,
      category: widget.category,
      strictCategoryMatch: true, // Exact category match for replacements
    );

    // Filter out places already in trip
    final filteredPlaces = places.where((place) {
      final placeId = place['poi_id']?.toString() ?? place['name'];
      return !widget.excludePlaceIds.contains(placeId);
    }).toList();

    if (mounted) {
      setState(() {
        _places = filteredPlaces;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPlaces {
    if (_searchQuery.isEmpty) return _places;

    return _places.where((place) {
      final name = (place['name'] as String? ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TripDetailsTheme.of(widget.isDark);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildDragHandle(),
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: _isLoading ? _buildLoading() : _buildPlacesList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 36,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 17,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Choose Place',
            style: TextStyle(
              color: _textColor,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          style: TextStyle(color: _textColor, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search places...',
            hintStyle: TextStyle(
              color: _secondaryTextColor,
              fontSize: 16,
            ),
            prefixIcon: Icon(
              CupertinoIcons.search,
              color: _secondaryTextColor,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildPlacesList(TripDetailsTheme theme) {
    final places = _filteredPlaces;

    if (places.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: places.length,
      itemBuilder: (context, index) => _buildPlaceItem(places[index], theme),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.map_pin_slash,
            size: 48,
            color: _secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No places available'
                : 'No places found for "$_searchQuery"',
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 16,
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'All places of this category are\nalready in your trip',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryTextColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceItem(Map<String, dynamic> place, TripDetailsTheme theme) {
    final name = place['name'] as String? ?? 'Unknown';
    final category = place['category'] as String? ?? 'attraction';
    final rating = place['rating'];
    final imageUrl = TripDetailsUtils.getImageUrl(place);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onPlaceSelected(place),
          borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: theme.cardDecoration,
            child: Row(
              children: [
                _buildPlaceImage(imageUrl, category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildCategoryBadge(category),
                          if (rating != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '$rating',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: _secondaryTextColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceImage(String? imageUrl, String category) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TripDetailsTheme.radiusSmall),
        color: widget.isDark ? const Color(0xFF2C2C2E) : Colors.grey[200],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  TripDetailsUtils.buildCategoryIconWidget(category,
                      isDark: widget.isDark),
            )
          : TripDetailsUtils.buildCategoryIconWidget(category,
              isDark: widget.isDark),
    );
  }

  Widget _buildCategoryBadge(String category) {
    final color = TripDetailsUtils.getCategoryColor(category);
    final label = TripDetailsUtils.getCategoryLabel(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
