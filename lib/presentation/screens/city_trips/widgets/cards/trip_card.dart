import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../utils/trip_data_utils.dart';
import '../../../home/widgets/trip_details_bottom_sheet.dart';

class TripCard extends StatefulWidget {
  final dynamic trip;
  final bool isDarkMode;

  const TripCard({
    super.key,
    required this.trip,
    required this.isDarkMode,
  });

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  bool _isFavorite = false;
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
    final tripData = TripDataUtils.toTripData(widget.trip);
    if (tripData == null) return;

    TripDetailsBottomSheet.show(
      context,
      trip: tripData,
      isDarkMode: widget.isDarkMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = TripDataUtils.getImages(widget.trip);
    final title = TripDataUtils.getTitle(widget.trip);
    final location = TripDataUtils.getLocation(widget.trip);
    final duration = TripDataUtils.getDuration(widget.trip);
    final price = TripDataUtils.getPrice(widget.trip);
    final rating = TripDataUtils.getRating(widget.trip);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(images),
          const SizedBox(height: 12),
          _buildInfoSection(title, location, duration, price, rating),
        ],
      ),
    );
  }

  Widget _buildImageSection(List<String> images) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (images.isNotEmpty)
              _buildImagePageView(images)
            else
              _buildPlaceholderImage(),
            if (images.length > 1) _buildGradientOverlay(),
            if (images.length > 1) _buildPageIndicators(images.length),
            _buildFavoriteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePageView(List<String> images) {
    return Positioned.fill(
      child: PageView.builder(
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
              errorBuilder: (_, __, ___) => _buildErrorImage(),
            ),
          );
        },
      ),
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

  Widget _buildErrorImage() {
    return Container(
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
                height: 2.5,
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

  Widget _buildFavoriteButton() {
    return Positioned(
      top: 12,
      right: 12,
      child: GestureDetector(
        onTap: () => setState(() => _isFavorite = !_isFavorite),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
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
    String? price,
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
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white : AppColors.text,
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: widget.isDarkMode ? Colors.white : AppColors.text,
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
              color: widget.isDarkMode
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (duration != null && duration.isNotEmpty) ...[
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: widget.isDarkMode
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isDarkMode
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  price ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white : AppColors.text,
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
