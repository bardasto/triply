import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../home/widgets/trip_details_bottom_sheet.dart';
import '../../theme/my_trips_theme.dart';
import '../../utils/trip_data_utils.dart';

/// Compact trip card for grid view.
class CompactTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const CompactTripCard({
    super.key,
    required this.trip,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  void _onTripTap(BuildContext context) {
    TripDetailsBottomSheet.show(
      context,
      trip: trip,
      isDarkMode: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = MyTripDataUtils.getFirstImage(trip);
    final title = MyTripDataUtils.getTitle(trip);
    final location = MyTripDataUtils.getLocation(trip);
    final duration = MyTripDataUtils.getDuration(trip);
    final priceStr = MyTripDataUtils.getPriceString(trip);
    final rating = MyTripDataUtils.getRating(trip);
    final isFavorite = MyTripDataUtils.isFavorite(trip);

    return GestureDetector(
      onTap: () => _onTripTap(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(image, isFavorite),
          const SizedBox(height: 8),
          _buildInfoSection(title, location, duration, priceStr, rating),
        ],
      ),
    );
  }

  Widget _buildImageSection(String? image, bool isFavorite) {
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
              if (image != null)
                Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),
              _buildFavoriteButton(isFavorite),
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
      child: const Icon(
        Icons.image_not_supported,
        size: 32,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFavoriteButton(bool isFavorite) {
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
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    String location,
    String? duration,
    String? priceStr,
    double? rating,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
        Text(
          location,
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
            if (rating != null && rating > 0) ...[
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (duration != null) ...[
              Icon(
                Icons.access_time,
                size: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 2),
              Text(
                duration,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
        if (priceStr != null) ...[
          const SizedBox(height: 2),
          Text(
            priceStr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
