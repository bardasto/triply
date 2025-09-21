import 'package:flutter/material.dart';

class AppColors {

  static const Color primary = Color(0xFF6a994e);
  static const Color secondary = Color(0xFFa3b18a);


  static const Color background = Colors.white;
  static const Color text = Colors.black;
  static const Color textSecondary = Color(0xFF666666);
  static const Color accent = Color(0xFF4A90E2);


  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
