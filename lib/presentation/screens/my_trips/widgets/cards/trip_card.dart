import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../home/widgets/trip_details_bottom_sheet.dart';
import '../../theme/my_trips_theme.dart';
import '../../utils/trip_data_utils.dart';

/// Large trip card with image carousel for list view.
class MyTripCard extends StatefulWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const MyTripCard({
    super.key,
    required this.trip,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  State<MyTripCard> createState() => _MyTripCardState();
}

class _MyTripCardState extends State<MyTripCard> {
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

  void _onTripTap() {
    TripDetailsBottomSheet.show(
      context,
      trip: widget.trip,
      isDarkMode: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = MyTripDataUtils.getImages(
      widget.trip,
      maxImages: MyTripsTheme.maxCarouselImages,
    );
    final title = MyTripDataUtils.getTitle(widget.trip);
    final location = MyTripDataUtils.getLocation(widget.trip);
    final duration = MyTripDataUtils.getDuration(widget.trip);
    final priceStr = MyTripDataUtils.getPriceString(widget.trip);
    final rating = MyTripDataUtils.getRating(widget.trip);
    final isFavorite = MyTripDataUtils.isFavorite(widget.trip);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MyTripsTheme.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(images, isFavorite),
          const SizedBox(height: 12),
          _buildInfoSection(title, location, duration, priceStr, rating),
        ],
      ),
    );
  }

  Widget _buildImageSection(List<String> images, bool isFavorite) {
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
            if (images.isNotEmpty)
              _buildImageCarousel(images)
            else
              _buildPlaceholderImage(),
            if (images.length > 1) ...[
              _buildGradientOverlay(),
              _buildPageIndicators(images.length),
            ],
            _buildDeleteButton(),
            _buildFavoriteButton(isFavorite),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    return PageView.builder(
      controller: _pageController,
      physics: const AlwaysScrollableScrollPhysics(),
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: _onTripTap,
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return GestureDetector(
      onTap: _onTripTap,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: const Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
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

  Widget _buildPageIndicators(int count) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Row(
        children: List.generate(count, (index) {
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
          'Delete Trip?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this trip?',
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

  Widget _buildFavoriteButton(bool isFavorite) {
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
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.white,
            size: 20,
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
    return GestureDetector(
      onTap: _onTripTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (rating != null && rating > 0) ...[
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
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
          Text(
            location,
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
              if (duration != null) ...[
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (priceStr != null)
                Expanded(
                  child: Text(
                    priceStr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
