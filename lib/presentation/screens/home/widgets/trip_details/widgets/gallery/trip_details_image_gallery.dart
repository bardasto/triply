import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';
import '../common/bounceable_button.dart';
import '../common/zoomable_image.dart';

/// Full-featured image gallery with zoom, swipe, and thumbnail navigation.
/// Telegram-style bar indicators and smooth animations.
class TripDetailsImageGallery extends StatefulWidget {
  final List<String> images;
  final int currentImageIndex;
  final PageController pageController;
  final Function(int) onPageChanged;
  final bool isDark;
  final double mainImageHeight;
  final double thumbnailHeight;

  const TripDetailsImageGallery({
    super.key,
    required this.images,
    required this.currentImageIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.isDark,
    this.mainImageHeight = 360,
    this.thumbnailHeight = 80,
  });

  @override
  State<TripDetailsImageGallery> createState() =>
      _TripDetailsImageGalleryState();
}

class _TripDetailsImageGalleryState extends State<TripDetailsImageGallery> {
  late TripDetailsTheme _theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = TripDetailsTheme.of(widget.isDark);
  }

  @override
  void didUpdateWidget(TripDetailsImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      _theme = TripDetailsTheme.of(widget.isDark);
    }
  }

  void _nextImage() {
    if (widget.currentImageIndex < widget.images.length - 1) {
      widget.pageController.animateToPage(
        widget.currentImageIndex + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevImage() {
    if (widget.currentImageIndex > 0) {
      widget.pageController.animateToPage(
        widget.currentImageIndex - 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleTap(TapUpDetails details, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (details.localPosition.dx < width / 2) {
      _prevImage();
    } else {
      _nextImage();
    }
  }

  void _goToImage(int index) {
    widget.pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMainGallery(context),
        if (widget.images.length > 1) _buildThumbnailList(),
      ],
    );
  }

  Widget _buildMainGallery(BuildContext context) {
    return SizedBox(
      height: widget.mainImageHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPageView(context),
          if (widget.images.length > 1) ...[
            _buildGradientOverlay(),
            _buildBarIndicators(),
          ],
        ],
      ),
    );
  }

  Widget _buildPageView(BuildContext context) {
    return PageView.builder(
      controller: widget.pageController,
      onPageChanged: widget.onPageChanged,
      itemCount: widget.images.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return ZoomableImage(
          imageUrl: widget.images[index],
          onTapUp: (details) => _handleTap(details, context),
        );
      },
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _theme.overlayLight,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarIndicators() {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Row(
        children: List.generate(widget.images.length, (idx) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2.5,
                decoration: BoxDecoration(
                  color: idx == widget.currentImageIndex
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

  Widget _buildThumbnailList() {
    return Container(
      height: widget.thumbnailHeight,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 0, right: 20),
        itemCount: widget.images.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final isSelected = index == widget.currentImageIndex;
          return _buildThumbnailItem(index, isSelected);
        },
      ),
    );
  }

  Widget _buildThumbnailItem(int index, bool isSelected) {
    return BounceableButton(
      onTap: () => _goToImage(index),
      child: Container(
        width: 80,
        margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TripDetailsTheme.radiusSmall),
          color: _theme.surfaceColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: Opacity(
          opacity: isSelected ? 1.0 : 0.5,
          child: Image.network(
            widget.images[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildThumbnailError(),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailError() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.white, size: 30),
      ),
    );
  }
}
