import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../utils/trip_data_utils.dart';
import '../../../home/widgets/trip_details_bottom_sheet.dart';

class CompactTripCard extends StatelessWidget {
  final dynamic trip;
  final bool isDarkMode;

  const CompactTripCard({
    super.key,
    required this.trip,
    required this.isDarkMode,
  });

  void _onTripTap(BuildContext context) {
    final tripData = TripDataUtils.toTripData(trip);
    if (tripData == null) return;

    TripDetailsBottomSheet.show(
      context,
      trip: tripData,
      isDarkMode: isDarkMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = TripDataUtils.getFirstImage(trip);
    final title = TripDataUtils.getTitle(trip);
    final location = TripDataUtils.getLocation(trip);
    final duration = TripDataUtils.getDuration(trip);
    final price = TripDataUtils.getPrice(trip);
    final rating = TripDataUtils.getRating(trip);

    return GestureDetector(
      onTap: () => _onTripTap(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(image),
          const SizedBox(height: 8),
          _buildInfoSection(title, location, duration, price, rating),
        ],
      ),
    );
  }

  Widget _buildImageSection(String? image) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
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

  Widget _buildInfoSection(
    String title,
    String location,
    String? duration,
    String? price,
    double? rating,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.text,
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
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.7)
                : AppColors.textSecondary,
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : AppColors.text,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (duration != null && duration.isNotEmpty) ...[
              Icon(
                Icons.access_time,
                size: 12,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  duration,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        if (price != null && price.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            price,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.text,
            ),
          ),
        ],
      ],
    );
  }
}
