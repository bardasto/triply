import 'package:flutter/material.dart';
import '../common/zoomable_image.dart';

/// Photo Gallery widget for restaurant images
class PhotoGallery extends StatefulWidget {
  final List<String> images;
  final Widget Function(String?) placeholderBuilder;
  final Function(int) onPhotoChanged;

  const PhotoGallery({
    super.key,
    required this.images,
    required this.placeholderBuilder,
    required this.onPhotoChanged,
  });

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  int _selectedPhotoIndex = 0;
  final PageController _photoPageController = PageController();

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  void _handlePhotoTap(TapUpDetails details, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (details.localPosition.dx < width / 2) {
      if (_selectedPhotoIndex > 0) {
        _photoPageController.animateToPage(
          _selectedPhotoIndex - 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    } else {
      if (_selectedPhotoIndex < widget.images.length - 1) {
        _photoPageController.animateToPage(
          _selectedPhotoIndex + 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Main photo with swipe and zoom
        SizedBox(
          height: 360,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // PageView with Zoomable Images
              PageView.builder(
                controller: _photoPageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedPhotoIndex = index;
                  });
                  widget.onPhotoChanged(index);
                },
                itemCount: widget.images.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return ZoomableImage(
                    imageUrl: widget.images[index],
                    onTapUp: (details) => _handlePhotoTap(details, context),
                    placeholderWidget: widget.placeholderBuilder(null),
                  );
                },
              ),

              // Gradient for indicators visibility
              if (widget.images.length > 1)
                Positioned(
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
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Telegram-style Bar Indicators
              if (widget.images.length > 1)
                Positioned(
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
                              color: idx == _selectedPhotoIndex
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),

        // Horizontal thumbnail list
        if (widget.images.length > 1)
          Container(
            height: 80,
            margin: const EdgeInsets.only(top: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedPhotoIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPhotoIndex = index;
                    });
                    _photoPageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                    widget.onPhotoChanged(index);
                  },
                  child: Container(
                    width: 80,
                    margin: EdgeInsets.only(
                      right: index < widget.images.length - 1 ? 8 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Opacity(
                      opacity: isSelected ? 1.0 : 0.5,
                      child: Image.network(
                        widget.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            widget.placeholderBuilder(null),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
