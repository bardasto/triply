import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../../home/widgets/trip_details/widgets/common/context_menu.dart';
import '../../../home/widgets/trip_details/widgets/common/context_menu_action.dart';
import '../../theme/ai_chat_theme.dart';

/// A card displaying generated place recommendations as a horizontal carousel.
class GeneratedPlaceCard extends StatefulWidget {
  final Map<String, dynamic> placeData;
  final VoidCallback onTap;
  final VoidCallback onRegenerate;
  final Function(Map<String, dynamic>)? onAlternativeTap;
  /// Callback when user wants to create a trip from these places
  final VoidCallback? onCreateTrip;

  const GeneratedPlaceCard({
    super.key,
    required this.placeData,
    required this.onTap,
    required this.onRegenerate,
    this.onAlternativeTap,
    this.onCreateTrip,
  });

  @override
  State<GeneratedPlaceCard> createState() => _GeneratedPlaceCardState();
}

class _GeneratedPlaceCardState extends State<GeneratedPlaceCard> {
  late ScrollController _scrollController;
  int _currentIndex = 0;
  bool _isSnapping = false;

  // Card dimensions
  static const double _cardWidth = 280.0;
  static const double _cardHeight = 340.0;
  static const double _cardSpacing = 16.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isSnapping) return;
    final offset = _scrollController.offset;
    const itemWidth = _cardWidth + _cardSpacing;
    final newIndex = (offset / itemWidth).round();
    if (newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  void _snapToIndex(int index) {
    if (_isSnapping) return;
    _isSnapping = true;
    const itemWidth = _cardWidth + _cardSpacing;
    final targetOffset = index * itemWidth;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    ).then((_) {
      _isSnapping = false;
    });
  }

  void _onScrollEnd() {
    if (_isSnapping) return;
    final offset = _scrollController.offset;
    const itemWidth = _cardWidth + _cardSpacing;
    final targetIndex = (offset / itemWidth).round();
    _snapToIndex(targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.placeData['place'] as Map<String, dynamic>? ?? {};
    final alternatives = widget.placeData['alternatives'] as List<dynamic>? ?? [];
    final hasAlternatives = alternatives.isNotEmpty;

    // Build list of all cards (main + alternatives)
    final allCards = <Map<String, dynamic>>[
      <String, dynamic>{...place, '_isMain': true},
      ...alternatives.map((alt) {
        final altMap = alt as Map<String, dynamic>;
        return <String, dynamic>{...altMap, '_isMain': false};
      }),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carousel using ListView with snap scrolling
          SizedBox(
            height: _cardHeight,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification) {
                  _onScrollEnd();
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 16),
                itemCount: allCards.length,
                itemBuilder: (context, index) {
                  final cardData = allCards[index];
                  final isMain = cardData['_isMain'] as bool? ?? false;

                  // Enrich with main place data if needed
                  final enrichedData = isMain
                      ? cardData
                      : _enrichAlternativeData(cardData, place);

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < allCards.length - 1 ? _cardSpacing : 0,
                    ),
                    child: _buildCard(
                      context: context,
                      cardData: enrichedData,
                      isMain: isMain,
                      index: index,
                    ),
                  );
                },
              ),
            ),
          ),
          // Page indicator
          if (hasAlternatives)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  allCards.length,
                  (index) => _buildPageIndicator(index),
                ),
              ),
            ),
          // Create Trip button
          if (widget.onCreateTrip != null)
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
              child: _buildCreateTripButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateTripButton() {
    return GestureDetector(
      onTap: widget.onCreateTrip,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1), // Indigo
              Color(0xFF8B5CF6), // Purple
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.explore_rounded,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            const Text(
              'Create Full Trip',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'with these places',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _enrichAlternativeData(
    Map<String, dynamic> altData,
    Map<String, dynamic> mainPlace,
  ) {
    final enriched = Map<String, dynamic>.from(altData);

    // Fill missing fields from main place
    if (enriched['city'] == null || (enriched['city'] as String?)?.isEmpty == true) {
      enriched['city'] = mainPlace['city'] ?? '';
    }
    if (enriched['country'] == null || (enriched['country'] as String?)?.isEmpty == true) {
      enriched['country'] = mainPlace['country'] ?? '';
    }
    if (enriched['place_type'] == null || (enriched['place_type'] as String?)?.isEmpty == true) {
      enriched['place_type'] = mainPlace['place_type'] ?? 'place';
    }

    return enriched;
  }

  Widget _buildCard({
    required BuildContext context,
    required Map<String, dynamic> cardData,
    required bool isMain,
    required int index,
  }) {
    final name = cardData['name'] as String? ?? 'Unknown Place';
    final placeType = cardData['place_type'] as String? ?? 'place';
    final city = cardData['city'] as String? ?? '';
    final country = cardData['country'] as String? ?? '';
    final rating = (cardData['rating'] as num?)?.toDouble() ?? 0.0;
    // Use estimated_price for real price, fallback to price_level
    final estimatedPrice = cardData['estimated_price'] as String? ?? '';
    final priceLevel = estimatedPrice.isNotEmpty ? estimatedPrice : (cardData['price_level'] as String? ?? '');
    final imageUrl = cardData['image_url'] as String?;

    final location = city.isNotEmpty && country.isNotEmpty
        ? '$city, $country'
        : city.isNotEmpty
            ? city
            : '';

    final isActive = index == _currentIndex;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: _cardWidth,
      height: _cardHeight,
      transform: Matrix4.diagonal3Values(isActive ? 1.0 : 0.95, isActive ? 1.0 : 0.95, 1.0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: AiChatTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: isMain
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isActive ? 0.4 : 0.2),
            blurRadius: isActive ? 20 : 10,
            offset: Offset(0, isActive ? 10 : 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMain ? 18 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                _buildImageSection(imageUrl, placeType),
                if (isMain)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Best Match',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                // Rating badge on image
                if (rating > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                                decoration: TextDecoration.none,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    // Type and price row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
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
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (priceLevel.isNotEmpty)
                          Flexible(
                            child: Text(
                              priceLevel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                decoration: TextDecoration.none,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // View button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isMain ? AppColors.primary : Colors.white.withValues(alpha: 0.12),
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
                          const SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isMain ? Colors.white : Colors.white.withValues(alpha: 0.9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    final isActive = index == _currentIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildImageSection(String? imageUrl, String placeType) {
    final icon = _getPlaceTypeIcon(placeType);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return SizedBox(
        height: 160,
        width: double.infinity,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildImagePlaceholder(icon),
        ),
      );
    }

    return _buildImagePlaceholder(icon);
  }

  Widget _buildImagePlaceholder(IconData icon) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 48, color: Colors.white.withValues(alpha: 0.8)),
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
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}
