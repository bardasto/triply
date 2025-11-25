import 'package:flutter/material.dart';

class PriceHistogram extends StatelessWidget {
  final List<double> distribution;
  final double rangeStart;
  final double rangeEnd;

  const PriceHistogram({
    super.key,
    required this.distribution,
    required this.rangeStart,
    required this.rangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) return const SizedBox.shrink();

    final maxValue = distribution.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(distribution.length, (index) {
        final normalizedIndex = index / distribution.length;
        final isInRange =
            normalizedIndex >= rangeStart && normalizedIndex <= rangeEnd;
        final height = (distribution[index] / maxValue) * 70 + 5;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            height: height,
            decoration: BoxDecoration(
              color: isInRange
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
