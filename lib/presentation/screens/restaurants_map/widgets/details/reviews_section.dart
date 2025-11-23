import 'package:flutter/material.dart';

/// Reviews Section with rating breakdown
class ReviewsSection extends StatelessWidget {
  final double? rating;
  final int reviewCount;

  const ReviewsSection({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == null || rating == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No ratings available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < rating!.floor()
                            ? Icons.star
                            : (index < rating! ? Icons.star_half : Icons.star_border),
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$reviewCount reviews',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.7, reviewCount),
                    const SizedBox(height: 8),
                    _buildRatingBar(4, 0.2, reviewCount),
                    const SizedBox(height: 8),
                    _buildRatingBar(3, 0.07, reviewCount),
                    const SizedBox(height: 8),
                    _buildRatingBar(2, 0.02, reviewCount),
                    const SizedBox(height: 8),
                    _buildRatingBar(1, 0.01, reviewCount),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(int stars, double percentage, int totalReviews) {
    final count = (totalReviews * percentage).round();

    return Row(
      children: [
        Text(
          '$stars',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            count > 0 ? '$count' : '',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
