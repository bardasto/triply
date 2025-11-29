import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../theme/my_trips_theme.dart';
import '../place_details/place_details_bottom_sheet.dart';

/// Large place card with image carousel for list view.
class MyPlaceCard extends StatefulWidget {
  final Map<String, dynamic> place;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const MyPlaceCard({
    super.key,
    required this.place,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  State<MyPlaceCard> createState() => _MyPlaceCardState();
}

class _MyPlaceCardState extends State<MyPlaceCard> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get _name => widget.place['name'] ?? 'Unknown Place';
  String get _location {
    final city = widget.place['city'] ?? '';
    final country = widget.place['country'] ?? '';
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    if (city.isNotEmpty) return city;
    return country;
  }
  String get _placeType => widget.place['place_type'] ?? widget.place['category'] ?? 'Place';
  String get _priceDisplay {
    // First try estimated_price which has real prices like "€17", "€25-35 per person"
    final estimatedPrice = widget.place['estimated_price']?.toString();
    if (estimatedPrice != null && estimatedPrice.isNotEmpty && estimatedPrice != 'null') {
      return estimatedPrice;
    }
    // Fallback to price_range
    final priceRange = widget.place['price_range']?.toString();
    if (priceRange != null && priceRange.isNotEmpty && priceRange != 'null') {
      return priceRange;
    }
    return '';
  }
  double get _rating => (widget.place['rating'] as num?)?.toDouble() ?? 0.0;
  bool get _isFavorite => widget.place['is_favorite'] ?? false;

  List<String> get _images {
    final images = <String>[];
    final imageUrl = widget.place['image_url'];
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      images.add(imageUrl);
    }
    final imagesList = widget.place['images'] as List<dynamic>?;
    if (imagesList != null) {
      for (final img in imagesList) {
        if (img != null && img.toString().isNotEmpty && !images.contains(img)) {
          images.add(img.toString());
        }
      }
    }
    return images.take(MyTripsTheme.maxCarouselImages).toList();
  }

  List<Map<String, dynamic>> get _alternatives {
    final alts = widget.place['alternatives'] as List<dynamic>?;
    if (alts == null) return [];
    return alts.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void _onPlaceTap() {
    PlaceDetailsBottomSheet.show(
      context,
      place: widget.place,
      alternatives: _alternatives,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MyTripsTheme.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(),
          const SizedBox(height: 12),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: MyTripsTheme.listCardImageHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MyTripsTheme.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MyTripsTheme.cardBorderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_images.isNotEmpty)
              _buildImageCarousel()
            else
              _buildPlaceholderImage(),
            if (_images.length > 1) ...[
              _buildGradientOverlay(),
              _buildPageIndicators(),
            ],
            _buildDeleteButton(),
            _buildFavoriteButton(),
            _buildPlaceTypeBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return PageView.builder(
      controller: _pageController,
      physics: const AlwaysScrollableScrollPhysics(),
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: _onPlaceTap,
          child: Image.network(
            _images[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return GestureDetector(
      onTap: _onPlaceTap,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Center(
          child: Icon(
            _getPlaceTypeIcon(),
            size: 48,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  IconData _getPlaceTypeIcon() {
    switch (_placeType.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'bar':
        return Icons.local_bar;
      case 'hotel':
        return Icons.hotel;
      case 'museum':
        return Icons.museum;
      case 'park':
        return Icons.park;
      case 'attraction':
        return Icons.attractions;
      case 'shop':
        return Icons.shopping_bag;
      default:
        return Icons.place;
    }
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Row(
        children: List.generate(_images.length, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: MyTripsTheme.indicatorHeight,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Positioned(
      top: 12,
      left: 12,
      child: GestureDetector(
        onTap: _showDeleteDialog,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Delete Place?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this place?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: GestureDetector(
        onTap: widget.onToggleFavorite,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceTypeBadge() {
    return Positioned(
      bottom: _images.length > 1 ? 36 : 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _formatPlaceType(_placeType),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _formatPlaceType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  Widget _buildInfoSection() {
    return GestureDetector(
      onTap: _onPlaceTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_rating > 0) ...[
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      _rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (_location.isNotEmpty)
            Text(
              _location,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                _getPlaceTypeIcon(),
                size: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                _formatPlaceType(_placeType),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              if (_priceDisplay.isNotEmpty)
                Text(
                  _priceDisplay,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
