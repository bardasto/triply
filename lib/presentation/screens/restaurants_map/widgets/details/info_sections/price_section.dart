import 'package:flutter/material.dart';

/// Price Section widget
class PriceSection extends StatelessWidget {
  final String price;

  const PriceSection({
    super.key,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.euro,
            color: Colors.green,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Price - ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: '$price per person',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
