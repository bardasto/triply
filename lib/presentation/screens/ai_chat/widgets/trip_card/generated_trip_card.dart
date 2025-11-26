import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../../home/widgets/trip_details/widgets/common/context_menu.dart';
import '../../../home/widgets/trip_details/widgets/common/context_menu_action.dart';
import '../../../my_trips/utils/trip_data_utils.dart';
import '../../theme/ai_chat_theme.dart';
import 'trip_card_image_carousel.dart';

/// A card displaying a generated trip in the chat.
class GeneratedTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onTap;
  final VoidCallback onRegenerate;

  const GeneratedTripCard({
    super.key,
    required this.trip,
    required this.onTap,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final images = MyTripDataUtils.getImages(trip, maxImages: 4);
    final title = MyTripDataUtils.getTitle(trip);
    final location = MyTripDataUtils.getLocation(trip);
    final duration = MyTripDataUtils.getDuration(trip);
    final priceStr = MyTripDataUtils.getPriceString(trip);
    final rating = MyTripDataUtils.getRating(trip);

    return _buildCard(
      images: images,
      title: title,
      location: location,
      duration: duration,
      priceStr: priceStr,
      rating: rating,
    );
  }

  Widget _buildCard({
    required List<String> images,
    required String title,
    required String location,
    required String? duration,
    required String? priceStr,
    required double? rating,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: AiChatTheme.tripCardWidthFactor,
          child: ContextMenu(
            actions: [
              ContextMenuAction(
                label: 'Regenerate',
                icon: CupertinoIcons.refresh,
                onTap: onRegenerate,
              ),
              ContextMenuAction(
                label: 'View Details',
                icon: CupertinoIcons.eye,
                onTap: onTap,
              ),
            ],
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: AiChatTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(images),
                    _buildInfoSection(
                      title: title,
                      location: location,
                      duration: duration,
                      priceStr: priceStr,
                      rating: rating,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: AiChatTheme.tripCardImageHeight,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AiChatTheme.cardBorderRadius),
          ),
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.flight_takeoff,
            size: 48,
            color: Colors.white,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AiChatTheme.cardBorderRadius),
      ),
      child: SizedBox(
        height: AiChatTheme.tripCardImageHeight,
        child: images.length == 1
            ? Image.network(
                images[0],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
              )
            : TripCardImageCarousel(images: images),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String location,
    required String? duration,
    required String? priceStr,
    required double? rating,
  }) {
    return Padding(
      padding: AiChatTheme.cardContentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(title, rating),
          const SizedBox(height: 6),
          _buildLocationRow(location),
          const SizedBox(height: 10),
          _buildDurationPriceRow(duration, priceStr),
          const SizedBox(height: 10),
          _buildViewButton(),
        ],
      ),
    );
  }

  Widget _buildTitleRow(String title, double? rating) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (rating != null && rating > 0) ...[
          const SizedBox(width: 6),
          _buildRatingBadge(rating),
        ],
      ],
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 13, color: Colors.amber),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.amber,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String location) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 15,
          color: Colors.white.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            location,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
              decoration: TextDecoration.none,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationPriceRow(String? duration, String? priceStr) {
    return Row(
      children: [
        if (duration != null) ...[
          _buildDurationBadge(duration),
          const Spacer(),
        ],
        if (priceStr != null)
          Text(
            priceStr,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              decoration: TextDecoration.none,
            ),
          ),
      ],
    );
  }

  Widget _buildDurationBadge(String duration) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 13,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            duration,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AiChatTheme.messageBorderRadius),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'View Trip Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_rounded,
            size: 17,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

}
