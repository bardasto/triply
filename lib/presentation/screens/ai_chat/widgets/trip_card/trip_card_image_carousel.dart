import 'package:flutter/material.dart';

import '../../../../../core/constants/color_constants.dart';

/// Image carousel for the trip card.
class TripCardImageCarousel extends StatefulWidget {
  final List<String> images;

  const TripCardImageCarousel({
    super.key,
    required this.images,
  });

  @override
  State<TripCardImageCarousel> createState() => _TripCardImageCarouselState();
}

class _TripCardImageCarouselState extends State<TripCardImageCarousel> {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            return Image.network(
              widget.images[index],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
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
          },
        ),
        // Gradient overlay at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        // Page indicators
        Positioned(
          left: 12,
          right: 12,
          bottom: 10,
          child: Row(
            children: List.generate(widget.images.length, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
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
        ),
      ],
    );
  }
}
