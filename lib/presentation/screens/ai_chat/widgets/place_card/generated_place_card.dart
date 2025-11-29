import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../../home/widgets/trip_details/widgets/common/context_menu.dart';
import '../../../home/widgets/trip_details/widgets/common/context_menu_action.dart';
import '../../theme/ai_chat_theme.dart';

/// A minimalist card displaying a generated single place in the chat.
/// Shows the main place card on the left with alternatives as a horizontal list.
class GeneratedPlaceCard extends StatelessWidget {
  final Map<String, dynamic> placeData;
  final VoidCallback onTap;
  final VoidCallback onRegenerate;
  final Function(Map<String, dynamic>)? onAlternativeTap;

  const GeneratedPlaceCard({
    super.key,
    required this.placeData,
    required this.onTap,
    required this.onRegenerate,
    this.onAlternativeTap,
  });

  @override
  Widget build(BuildContext context) {
    final place = placeData['place'] as Map<String, dynamic>? ?? {};
    final alternatives =
        placeData['alternatives'] as List<dynamic>? ?? [];

    final name = place['name'] as String? ?? 'Unknown Place';
    final placeType = place['place_type'] as String? ?? 'place';
    final city = place['city'] as String? ?? '';
    final country = place['country'] as String? ?? '';
    final rating = (place['rating'] as num?)?.toDouble() ?? 0.0;
    final priceLevel = place['price_level'] as String? ?? '';
    final imageUrl = place['image_url'] as String?;

    final location = city.isNotEmpty && country.isNotEmpty
        ? '$city, $country'
        : city.isNotEmpty
            ? city
            : '';

    final hasAlternatives = alternatives.isNotEmpty;

    // Debug logging
    debugPrint('📋 PlaceCard: alternatives count = ${alternatives.length}, hasAlternatives = $hasAlternatives');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.92,
          child: hasAlternatives
              ? _buildWithAlternatives(
                  context: context,
                  name: name,
                  placeType: placeType,
                  location: location,
                  rating: rating,
                  priceLevel: priceLevel,
                  imageUrl: imageUrl,
                  alternatives: alternatives,
                )
              : _buildMainCardOnly(
                  context: context,
                  name: name,
                  placeType: placeType,
                  location: location,
                  rating: rating,
                  priceLevel: priceLevel,
                  imageUrl: imageUrl,
                ),
        ),
      ),
    );
  }

  /// Build layout with main card and alternatives
  Widget _buildWithAlternatives({
    required BuildContext context,
    required String name,
    required String placeType,
    required String location,
    required double rating,
    required String priceLevel,
    required String? imageUrl,
    required List<dynamic> alternatives,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main card - narrower width
        SizedBox(
          width: 180,
          child: _buildMainCard(
            name: name,
            placeType: placeType,
            location: location,
            rating: rating,
            priceLevel: priceLevel,
            imageUrl: imageUrl,
          ),
        ),
        const SizedBox(width: 10),
        // Alternatives horizontal list
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Alternatives',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              SizedBox(
                height: 195,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: alternatives.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final alt = alternatives[index] as Map<String, dynamic>;
                    return _buildAlternativeCard(context, alt);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build layout with only main card (no alternatives)
  Widget _buildMainCardOnly({
    required BuildContext context,
    required String name,
    required String placeType,
    required String location,
    required double rating,
    required String priceLevel,
    required String? imageUrl,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.55,
      child: _buildMainCard(
        name: name,
        placeType: placeType,
        location: location,
        rating: rating,
        priceLevel: priceLevel,
        imageUrl: imageUrl,
      ),
    );
  }

  /// Build the main place card
  Widget _buildMainCard({
    required String name,
    required String placeType,
    required String location,
    required double rating,
    required String priceLevel,
    required String? imageUrl,
  }) {
    return ContextMenu(
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
              _buildImageSection(imageUrl, placeType, height: 120),
              _buildInfoSection(
                name: name,
                placeType: placeType,
                location: location,
                rating: rating,
                priceLevel: priceLevel,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build an alternative card
  Widget _buildAlternativeCard(
      BuildContext context, Map<String, dynamic> alt) {
    final name = alt['name'] as String? ?? '';
    final rating = (alt['rating'] as num?)?.toDouble() ?? 0.0;
    final priceLevel = alt['price_level'] as String? ?? '';
    final imageUrl = alt['image_url'] as String?;

    return GestureDetector(
      onTap: () => onAlternativeTap?.call(alt),
      child: Container(
        width: 140,
        decoration: AiChatTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AiChatTheme.cardBorderRadius),
              ),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildAltImagePlaceholder(),
                      )
                    : _buildAltImagePlaceholder(),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (rating > 0) ...[
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (priceLevel.isNotEmpty)
                        Text(
                          priceLevel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAltImagePlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.place,
          size: 32,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildImageSection(String? imageUrl, String placeType,
      {double height = 140}) {
    final icon = _getPlaceTypeIcon(placeType);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AiChatTheme.cardBorderRadius),
        ),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildImagePlaceholder(icon, height: height),
          ),
        ),
      );
    }

    return _buildImagePlaceholder(icon, height: height);
  }

  Widget _buildImagePlaceholder(IconData icon, {double height = 140}) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AiChatTheme.cardBorderRadius),
        ),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String name,
    required String placeType,
    required String location,
    required double rating,
    required String priceLevel,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleRow(name, rating),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildLocationRow(location),
          ],
          const SizedBox(height: 8),
          _buildTypePriceRow(placeType, priceLevel),
          const SizedBox(height: 8),
          _buildViewButton(),
        ],
      ),
    );
  }

  Widget _buildTitleRow(String name, double rating) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (rating > 0) ...[
          const SizedBox(width: 4),
          _buildRatingBadge(rating),
        ],
      ],
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 11, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11,
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
          size: 13,
          color: Colors.white.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            location,
            style: TextStyle(
              fontSize: 12,
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

  Widget _buildTypePriceRow(String placeType, String priceLevel) {
    return Row(
      children: [
        _buildTypeBadge(placeType),
        const Spacer(),
        if (priceLevel.isNotEmpty)
          Text(
            priceLevel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              decoration: TextDecoration.none,
            ),
          ),
      ],
    );
  }

  Widget _buildTypeBadge(String placeType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPlaceTypeIcon(placeType),
            size: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 3),
          Text(
            _formatPlaceType(placeType),
            style: TextStyle(
              fontSize: 11,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'View Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(width: 4),
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  IconData _getPlaceTypeIcon(String placeType) {
    switch (placeType.toLowerCase()) {
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
      case 'nightclub':
        return Icons.nightlife;
      case 'spa':
        return Icons.spa;
      case 'beach':
        return Icons.beach_access;
      case 'viewpoint':
        return Icons.landscape;
      default:
        return Icons.place;
    }
  }

  String _formatPlaceType(String placeType) {
    return placeType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}
