import 'package:flutter/material.dart';
import '../../../../../../core/constants/color_constants.dart';
import '../common/sticky_header_delegate.dart';
import '../../utils/restaurant_formatters.dart';
import 'photo_gallery.dart';
import 'tabs_section.dart';
import 'reviews_section.dart';
import 'info_sections/unified_info_block.dart';

/// Restaurant Details Sheet widget
class RestaurantDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  final ScrollController scrollController;
  final VoidCallback onClose;
  final VoidCallback? onAdd;

  const RestaurantDetailsSheet({
    super.key,
    required this.restaurant,
    required this.scrollController,
    required this.onClose,
    this.onAdd,
  });

  @override
  State<RestaurantDetailsSheet> createState() => _RestaurantDetailsSheetState();
}

class _RestaurantDetailsSheetState extends State<RestaurantDetailsSheet> {
  int _selectedPhotoIndex = 0;
  int _selectedTabIndex = 0;
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final category = restaurant['category'] as String?;
    final cuisine = restaurant['cuisine'] as String?;
    final rating = restaurant['rating'] as double?;
    final price = restaurant['price'] as String?;
    final description = restaurant['description'] as String?;
    final address = restaurant['address'] as String?;
    final images = RestaurantFormatters.extractImages(restaurant);
    final lat = (restaurant['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (restaurant['longitude'] as num?)?.toDouble() ?? 0.0;

    return Stack(
      children: [
        CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            // Photo Gallery
            if (images.isNotEmpty)
              SliverToBoxAdapter(
                child: PhotoGallery(
                  images: images,
                  placeholderBuilder: (cat) => _buildPlaceholderImage(category),
                  onPhotoChanged: (index) {
                    setState(() {
                      _selectedPhotoIndex = index;
                    });
                  },
                ),
              ),

            // Restaurant Name
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  restaurant['name'] as String,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyTabBarDelegate(
                minHeight: 50,
                maxHeight: 50,
                child: Container(
                  color: const Color(0xFF1C1C1E),
                  child: TabsSection(
                    selectedIndex: _selectedTabIndex,
                    onTabSelected: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMetadata(rating, price, cuisine, category),
                  const SizedBox(height: 24),
                  _buildTabContent(
                    description: description,
                    address: address,
                    rating: rating,
                    lat: lat,
                    lng: lng,
                  ),
                ]),
              ),
            ),
          ],
        ),

        // Sheet Handle
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),

        // Action Buttons
        Positioned(
          top: 36,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onAdd != null) ...[
                  _buildActionButton(
                    icon: Icons.add_circle_outline,
                    onPressed: widget.onAdd!,
                  ),
                  const SizedBox(width: 8),
                ],
                _buildActionButton(
                  icon: Icons.close,
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMetadata(double? rating, String? price, String? cuisine, String? category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (rating != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 19),
                  const SizedBox(width: 4),
                  Text(
                    '$rating',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '·',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
            if (price != null) ...[
              Text(
                price,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                '·',
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
            if (cuisine != null && cuisine.isNotEmpty)
              Text(
                cuisine,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (category != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: RestaurantFormatters.getCategoryColor(category)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  RestaurantFormatters.getCategoryIcon(category),
                  size: 17,
                  color: RestaurantFormatters.getCategoryColor(category),
                ),
                const SizedBox(width: 6),
                Text(
                  RestaurantFormatters.getCategoryLabel(category),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: RestaurantFormatters.getCategoryColor(category),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTabContent({
    String? description,
    String? address,
    double? rating,
    required double lat,
    required double lng,
  }) {
    switch (_selectedTabIndex) {
      case 0: // Overview
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null && description.isNotEmpty) ...[
              const Text(
                'About this place',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: _isDescriptionExpanded ? null : 3,
                      overflow: _isDescriptionExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  ),
                  if (description.length > 100) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Text(
                        _isDescriptionExpanded ? 'See less' : 'See more',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
            ],
            UnifiedInfoBlock(
              openingHours: widget.restaurant['opening_hours'],
              address: address,
              website: widget.restaurant['website'] as String?,
              price: RestaurantFormatters.formatPriceLevel(
                  widget.restaurant['price_level']),
              cuisine: RestaurantFormatters.formatCuisineTypes(
                  widget.restaurant['cuisine_types']),
              lat: lat,
              lng: lng,
            ),
            const SizedBox(height: 24),
            const Text(
              'Ratings & reviews',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ReviewsSection(
              rating: rating,
              reviewCount: widget.restaurant['review_count'] as int? ??
                  widget.restaurant['google_review_count'] as int? ??
                  0,
            ),
          ],
        );

      case 1: // Menu
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'Menu not available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
          ),
        );

      case 2: // Reviews
        return ReviewsSection(
          rating: rating,
          reviewCount: widget.restaurant['review_count'] as int? ??
              widget.restaurant['google_review_count'] as int? ??
              0,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceholderImage(String? category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          RestaurantFormatters.getCategoryIcon(category),
          size: 40,
          color: RestaurantFormatters.getCategoryColor(category),
        ),
      ),
    );
  }
}
