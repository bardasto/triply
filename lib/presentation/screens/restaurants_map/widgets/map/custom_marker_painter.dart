import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../core/constants/color_constants.dart';

/// Custom marker painter for restaurant markers
class CustomMarkerPainter {
  /// Create marker with rating badge
  static Future<BitmapDescriptor> createMarkerWithRating({
    required double? rating,
    required bool isSelected,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    const double height = 24;
    const double iconSize = 25;
    const double padding = 6;

    final double width = rating != null && rating > 0
        ? iconSize + padding * 2 + 32
        : iconSize + padding * 2;

    final Color bgColor = isSelected
        ? AppColors.primary
        : const Color(0xFFEA4335);

    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final shadowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, width, height),
          const Radius.circular(18),
        ),
      );
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw background
    final bgPaint = Paint()..color = bgColor;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(18),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Draw restaurant icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.restaurant.codePoint),
        style: TextStyle(
          fontSize: 18,
          fontFamily: Icons.restaurant.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        padding + (iconSize - 18) / 2,
        (height - iconPainter.height) / 2,
      ),
    );

    // Draw rating if available
    if (rating != null && rating > 0) {
      final ratingPainter = TextPainter(
        text: TextSpan(
          text: rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      ratingPainter.layout();
      ratingPainter.paint(
        canvas,
        Offset(
          iconSize + padding + 4,
          (height - ratingPainter.height) / 2,
        ),
      );
    }

    // Draw arrow
    final trianglePath = Path();
    trianglePath.moveTo(width / 2 - 6, height);
    trianglePath.lineTo(width / 2, height + 10);
    trianglePath.lineTo(width / 2 + 6, height);
    trianglePath.close();
    canvas.drawPath(trianglePath, bgPaint);

    final img = await pictureRecorder.endRecording().toImage(
          width.toInt(),
          (height + 10).toInt(),
        );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }
}
