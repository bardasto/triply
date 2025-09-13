import 'package:flutter/material.dart';

class AppColors {
  // Основная цветовая палитра
  static const Color primary = Color(0xFFBC986A);        // #BC986A - коричневый
  static const Color secondary = Color(0xFFDAAD86);      // #DAAD86 - светло-коричневый  
  static const Color accent = Color(0xFFFBEEC1);         // #FBEEC1 - кремовый
  
  // Дополнительные цвета
  static const Color background = Color(0xFFFFFBF5);     // Очень светлый кремовый
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Градиенты
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFBEEC1),  // Светлый кремовый
      Color(0xFFDAAD86),  // Светло-коричневый
      Color(0xFFBC986A),  // Коричневый
    ],
  );
  
  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFBEEC1),  // Кремовый
      Color(0xFFFFFBF5),  // Очень светлый кремовый
    ],
  );
}
