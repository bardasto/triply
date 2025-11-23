import 'package:flutter/material.dart';
import '../../utils/restaurant_formatters.dart';
import '../../utils/opening_hours_helper.dart';
import '../../utils/map_utils.dart';

/// Restaurant Card widget for list view
class RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final bool isBeingEdited;
  final bool isLast;
  final VoidCallback onTap;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.isBeingEdited,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = restaurant['category'] as String?;
    final cuisine = restaurant['cuisine'] as String?;
    final images = RestaurantFormatters.extractImages(restaurant);

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and editing badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isBeingEdited)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Editing',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Rating, Price, Cuisine
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (restaurant['rating'] != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${restaurant['rating']}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 15),
                        ],
                      ),
                      Text(
                        '·',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                    if (restaurant['price'] != null) ...[
                      Text(
                        restaurant['price'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '·',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                    if (cuisine != null && cuisine.isNotEmpty)
                      Text(
                        cuisine,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Category badge and opening status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: RestaurantFormatters.getCategoryColor(category)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        RestaurantFormatters.getCategoryLabel(category),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: RestaurantFormatters.getCategoryColor(category),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (restaurant['opening_hours'] != null)
                      Expanded(
                        child: Text(
                          OpeningHoursHelper.getOpeningStatus(
                              restaurant['opening_hours']),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getOpeningStatusColor(
                                restaurant['opening_hours']),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Photo gallery
                if (images.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: _buildPhotoGallery(images, category),
                  ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.directions,
                        label: 'Directions',
                        onTap: () {
                          final lat = (restaurant['latitude'] as num?)?.toDouble();
                          final lng = (restaurant['longitude'] as num?)?.toDouble();
                          if (lat != null && lng != null) {
                            MapUtils.openDirections(context, lat, lng);
                          }
                        },
                      ),
                    ),
                    if (restaurant['website'] != null &&
                        (restaurant['website'] as String).isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          context: context,
                          icon: Icons.language,
                          label: 'Website',
                          onTap: () {
                            MapUtils.openWebsite(context,
                                restaurant['website'] as String?);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // Divider
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
      ],
    );
  }

  Widget _buildPhotoGallery(List<String> images, String? category) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Container(
          width: 140,
          margin: EdgeInsets.only(right: index < images.length - 1 ? 8 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withValues(alpha: 0.1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholderImage(category),
          ),
        );
      },
    );
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

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF00D1FF), size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getOpeningStatusColor(dynamic openingHours) {
    final status = OpeningHoursHelper.getOpeningStatus(openingHours);
    if (status.toLowerCase().contains('open')) {
      return Colors.green;
    } else if (status.toLowerCase().contains('closed')) {
      return Colors.red;
    } else {
      return Colors.white.withValues(alpha: 0.6);
    }
  }
}
