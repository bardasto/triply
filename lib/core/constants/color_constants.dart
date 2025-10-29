import 'package:flutter/material.dart';

class AppColors {

  static const Color primary = Color(0xFF865cfe);
  static const Color secondary = Color(0xFF30284D);
  static const Color primaryOrange = Color(0xFFFC892E);
  static const Color darkBackground = Color.fromARGB(255, 23, 23, 23);


  static const Color background = Colors.white;
  static const Color text = Colors.black;
  static const Color textSecondary = Color(0xFF666666);
  static const Color accent = Color(0xFF4A90E2);
    // Дополнительные цвета
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF81C784);
  static const Color separator = Color.fromARGB(255, 127, 127, 127);


  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
