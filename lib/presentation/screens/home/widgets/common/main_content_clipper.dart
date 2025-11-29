import 'package:flutter/material.dart';

/// Custom clipper for main content with bottom navigation notch.
class MainContentClipper extends CustomClipper<Path> {
  final double bottomNavHeight;

  const MainContentClipper({this.bottomNavHeight = 80.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    const notchRadius = 35.0;

    path
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height - bottomNavHeight)
      ..lineTo(centerX + notchRadius + 20, height - bottomNavHeight)
      ..quadraticBezierTo(
        centerX + notchRadius,
        height - bottomNavHeight,
        centerX + notchRadius - 10,
        height - bottomNavHeight + 15,
      )
      ..quadraticBezierTo(
        centerX + 10,
        height - bottomNavHeight + 25,
        centerX,
        height - bottomNavHeight + 25,
      )
      ..quadraticBezierTo(
        centerX - 10,
        height - bottomNavHeight + 25,
        centerX - notchRadius + 10,
        height - bottomNavHeight + 15,
      )
      ..quadraticBezierTo(
        centerX - notchRadius,
        height - bottomNavHeight,
        centerX - notchRadius - 20,
        height - bottomNavHeight,
      )
      ..lineTo(0, height - bottomNavHeight)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(MainContentClipper oldClipper) =>
      bottomNavHeight != oldClipper.bottomNavHeight;
}
