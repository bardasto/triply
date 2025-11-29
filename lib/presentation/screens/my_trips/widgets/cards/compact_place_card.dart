import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../theme/my_trips_theme.dart';
import '../place_details/place_details_bottom_sheet.dart';

/// Compact place card for grid view.
class CompactPlaceCard extends StatelessWidget {
  final Map<String, dynamic> place;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const CompactPlaceCard({
    super.key,
    required this.place,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  String get _name => place['name'] ?? 'Unknown Place';
  String get _location {
    final city = place['city'] ?? '';
    final country = place['country'] ?? '';
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    if (city.isNotEmpty) return city;
    return country;
  }
  String get _placeType => place['place_type'] ?? place['category'] ?? 'Place';
  String get _priceDisplay {
    // First try estimated_price which has real prices like "€17", "€25-35 per person"
    final estimatedPrice = place['estimated_price']?.toString();
    if (estimatedPrice != null && estimatedPrice.isNotEmpty && estimatedPrice != 'null') {
      return estimatedPrice;
    }
    // Fallback to price_range
    final priceRange = place['price_range']?.toString();
    if (priceRange != null && priceRange.isNotEmpty && priceRange != 'null') {
      return priceRange;
    }
    return '';
  }
  double get _rating => (place['rating'] as num?)?.toDouble() ?? 0.0;
  bool get _isFavorite => place['is_favorite'] ?? false;

  String? get _imageUrl {
    final img = place['image_url'];
    if (img != null && img.toString().isNotEmpty) return img;
    final images = place['images'] as List<dynamic>?;
    if (images != null && images.isNotEmpty) return images.first?.toString();
    return null;
  }

  List<Map<String, dynamic>> get _alternatives {
    final alts = place['alternatives'] as List<dynamic>?;
    if (alts == null) return [];
    return alts.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void _onPlaceTap(BuildContext context) {
    PlaceDetailsBottomSheet.show(
      context,
      place: place,
      alternatives: _alternatives,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onPlaceTap(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(),
          const SizedBox(height: 8),
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(MyTripsTheme.gridCardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MyTripsTheme.gridCardBorderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_imageUrl != null)
                Image.network(
                  _imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),
              _buildFavoriteButton(),
              _buildPlaceTypeBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Center(
        child: Icon(
          _getPlaceTypeIcon(),
          size: 32,
          color: Colors.white.withValues(alpha: 0.8),
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
      default:
        return Icons.place;
    }
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: GestureDetector(
        onTap: onToggleFavorite,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceTypeBadge() {
    return Positioned(
      bottom: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _formatPlaceType(_placeType),
          style: const TextStyle(
            fontSize: 10,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        if (_location.isNotEmpty)
          Text(
            _location,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (_rating > 0) ...[
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                _rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (_priceDisplay.isNotEmpty)
              Text(
                _priceDisplay,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
