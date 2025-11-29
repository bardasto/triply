import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../../home/widgets/trip_details/widgets/common/context_menu.dart';
import '../../../home/widgets/trip_details/widgets/common/context_menu_action.dart';
import '../../theme/ai_chat_theme.dart';

/// A card displaying generated place recommendations as a horizontal carousel.
/// The focused card scales up while others remain smaller.
class GeneratedPlaceCard extends StatefulWidget {
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
  State<GeneratedPlaceCard> createState() => _GeneratedPlaceCardState();
}

class _GeneratedPlaceCardState extends State<GeneratedPlaceCard> {
  late PageController _pageController;
  double _currentPage = 0;

  // Card dimensions
  static const double _cardWidth = 240.0;
  static const double _cardHeight = 300.0;
  static const double _scaleFactor = 0.88;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.52,
      initialPage: 0,
    );
    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.placeData['place'] as Map<String, dynamic>? ?? {};
    final alternatives =
        widget.placeData['alternatives'] as List<dynamic>? ?? [];

    final hasAlternatives = alternatives.isNotEmpty;

    // Build list of all cards (main + alternatives)
    final allCards = <Map<String, dynamic>>[
      {...place, '_isMain': true},
      ...alternatives.map((alt) => {...(alt as Map<String, dynamic>), '_isMain': false}),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carousel
          SizedBox(
            height: _cardHeight + 20,
            child: hasAlternatives
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: allCards.length,
                    clipBehavior: Clip.none,
                    padEnds: false,
                    itemBuilder: (context, index) {
                      return _buildAnimatedCard(
                        context: context,
                        cardData: allCards[index],
                        index: index,
                        mainPlace: place,
                      );
                    },
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: _buildSingleCard(
                        context: context,
                        cardData: allCards[0],
                      ),
                    ),
                  ),
          ),
          // Page indicator
          if (hasAlternatives)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  allCards.length,
                  (index) => _buildPageIndicator(index),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard({
    required BuildContext context,
    required Map<String, dynamic> cardData,
    required int index,
    required Map<String, dynamic> mainPlace,
  }) {
    // Calculate scale based on distance from current page
    final distance = (_currentPage - index).abs();
    final scale = (1 - (distance * (1 - _scaleFactor))).clamp(_scaleFactor, 1.0);
    final opacity = (1 - (distance * 0.25)).clamp(0.7, 1.0);

    // For alternatives, merge with main place data for missing fields
    final isMain = cardData['_isMain'] as bool? ?? false;
    final enrichedData = isMain ? cardData : _enrichAlternativeData(cardData, mainPlace);

    return Padding(
      padding: EdgeInsets.only(left: index == 0 ? 16 : 0),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: scale, end: scale),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            alignment: Alignment.centerLeft,
            child: Opacity(
              opacity: opacity,
              child: _buildCardContent(
                context: context,
                cardData: enrichedData,
                isActive: distance < 0.5,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Enrich alternative data with main place info for missing fields
  Map<String, dynamic> _enrichAlternativeData(
    Map<String, dynamic> altData,
    Map<String, dynamic> mainPlace,
  ) {
    return {
      ...altData,
      // Use main place's city/country if not present in alternative
      'city': altData['city'] ?? mainPlace['city'] ?? '',
      'country': altData['country'] ?? mainPlace['country'] ?? '',
      'place_type': altData['place_type'] ?? mainPlace['place_type'] ?? 'place',
    };
  }

  Widget _buildSingleCard({
    required BuildContext context,
    required Map<String, dynamic> cardData,
  }) {
    return SizedBox(
      width: _cardWidth,
      height: _cardHeight,
      child: _buildCardContent(
        context: context,
        cardData: cardData,
        isActive: true,
      ),
    );
  }

  Widget _buildCardContent({
    required BuildContext context,
    required Map<String, dynamic> cardData,
    required bool isActive,
  }) {
    final isMain = cardData['_isMain'] as bool? ?? false;
    final name = cardData['name'] as String? ?? 'Unknown Place';
    final placeType = cardData['place_type'] as String? ?? cardData['category'] as String? ?? 'place';
    final city = cardData['city'] as String? ?? '';
    final country = cardData['country'] as String? ?? '';
    final rating = (cardData['rating'] as num?)?.toDouble() ?? 0.0;
    final priceLevel = cardData['price_level'] as String? ?? '';
    final imageUrl = cardData['image_url'] as String?;

    final location = city.isNotEmpty && country.isNotEmpty
        ? '$city, $country'
        : city.isNotEmpty
            ? city
            : '';

    final card = Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        color: AiChatTheme.cardBackground,
        borderRadius: BorderRadius.circular(AiChatTheme.cardBorderRadius),
        border: isMain && isActive
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2)
            : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with badge
          Stack(
            children: [
              _buildImageSection(imageUrl, placeType, height: 150),
              if (isMain)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Best Match',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and rating
                  Row(
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
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (rating > 0) ...[
                        const SizedBox(width: 6),
                        _buildRatingBadge(rating),
                      ],
                    ],
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildLocationRow(location),
                  ],
                  const Spacer(),
                  // Type and price row
                  Row(
                    children: [
                      _buildTypeBadge(placeType),
                      const Spacer(),
                      if (priceLevel.isNotEmpty)
                        Text(
                          priceLevel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // View button
                  _buildViewButton(isMain),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isMain) {
      return ContextMenu(
        actions: [
          ContextMenuAction(
            label: 'Regenerate',
            icon: CupertinoIcons.refresh,
            onTap: widget.onRegenerate,
          ),
          ContextMenuAction(
            label: 'View Details',
            icon: CupertinoIcons.eye,
            onTap: widget.onTap,
          ),
        ],
        child: GestureDetector(
          onTap: widget.onTap,
          child: card,
        ),
      );
    }

    return GestureDetector(
      onTap: () => widget.onAlternativeTap?.call(cardData),
      child: card,
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = (_currentPage - index).abs() < 0.5;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: isActive ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildImageSection(String? imageUrl, String placeType, {double height = 150}) {
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
            errorBuilder: (_, __, ___) => _buildImagePlaceholder(icon, height: height),
          ),
        ),
      );
    }

    return _buildImagePlaceholder(icon, height: height);
  }

  Widget _buildImagePlaceholder(IconData icon, {double height = 150}) {
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
        child: Icon(icon, size: 40, color: Colors.white),
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
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

  Widget _buildTypeBadge(String placeType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPlaceTypeIcon(placeType),
            size: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
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

  Widget _buildViewButton(bool isMain) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isMain ? AppColors.primary : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'View Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isMain ? Colors.white : Colors.white.withValues(alpha: 0.9),
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: isMain ? Colors.white : Colors.white.withValues(alpha: 0.9),
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
