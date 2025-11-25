import 'dart:math' show sin;
import 'package:flutter/material.dart';
import '../../theme/city_trips_theme.dart';

class AnimatedGradientHeader extends StatelessWidget {
  final double opacity;

  const AnimatedGradientHeader({
    super.key,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        opacity: opacity,
        child: ClipPath(
          clipper: const _WavyBottomClipper(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: CityTripsTheme.gradientColors,
                stops: CityTripsTheme.gradientStops,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WavyBottomClipper extends CustomClipper<Path> {
  const _WavyBottomClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    path
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height * 0.65);

    const waveCount = 4;
    const amplitude = 25.0;
    const pi = 3.14159;

    for (int i = 0; i <= 100; i++) {
      final x = width - (width / 100) * i;
      final normalizedX = i / 100.0;

      final wave1 = amplitude * 0.8 * sin(normalizedX * waveCount * pi);
      final wave2 = amplitude * 0.5 * sin(normalizedX * waveCount * 2 * pi);
      final wave3 = amplitude * 0.3 * sin(normalizedX * waveCount * 3 * pi);

      final y = height * 0.75 + wave1 + wave2 + wave3;
      path.lineTo(x, y);
    }

    path
      ..lineTo(0, height * 0.75)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
