import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';

class TripDetailsImageGallery extends StatelessWidget {
  final List<String> images;
  final int currentImageIndex;
  final PageController pageController;
  final Function(int) onPageChanged;
  final bool isDark;

  const TripDetailsImageGallery({
    super.key,
    required this.images,
    required this.currentImageIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main photo with swipe
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey[100],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.white, size: 50),
                          ),
                        ),
                      ),
                      // Photo counter
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${currentImageIndex + 1}/${images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Horizontal thumbnail list
        if (images.length > 1)
          Container(
            height: 80,
            margin: const EdgeInsets.only(top: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final isSelected = index == currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: EdgeInsets.only(
                      right: index < images.length - 1 ? 8 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey[100],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Opacity(
                      opacity: isSelected ? 1.0 : 0.5,
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.white, size: 30),
                          ),
                        ),
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
