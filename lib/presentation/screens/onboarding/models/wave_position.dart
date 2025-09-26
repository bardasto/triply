// lib/presentation/screens/onboarding/models/wave_position.dart
import 'package:flutter/material.dart';

/// Класс для одной волны
class WavePosition {
  final String svgPath;
  final double width;
  final double height;
  final double x;
  final double y;
  final bool ignoresSafeArea;
  final BoxFit fit;
  final double opacity;
  final int zIndex; // ✅ НОВОЕ - для контроля слоев

  const WavePosition({
    required this.svgPath,
    this.width = 1.0,
    this.height = 0.7,
    this.x = 0.0,
    this.y = -1.0,
    this.ignoresSafeArea = false,
    this.fit = BoxFit.contain,
    this.opacity = 1.0,
    this.zIndex = 0, // по умолчанию нижний слой
  });

  // Все существующие статические методы остаются, но добавляем zIndex параметр

  static WavePosition top({
    required String svgPath,
    double width = 1.0,
    double height = 0.6,
    double moveLeft = 0.0,
    double moveUp = 0.0,
    bool ignoresSafeArea = false,
    BoxFit fit = BoxFit.fitWidth,
    double opacity = 1.0,
    int zIndex = 0, // ✅ НОВЫЙ ПАРАМЕТР
  }) {
    return WavePosition(
      svgPath: svgPath,
      width: width,
      height: height,
      x: moveLeft,
      y: -1.0 + moveUp,
      ignoresSafeArea: ignoresSafeArea,
      fit: fit,
      opacity: opacity,
      zIndex: zIndex,
    );
  }

  static WavePosition bottom({
    required String svgPath,
    double width = 1.0,
    double height = 0.6,
    double moveLeft = 0.0,
    double moveDown = 0.0,
    bool ignoresSafeArea = false,
    BoxFit fit = BoxFit.fitWidth,
    double opacity = 1.0,
    int zIndex = 0,
  }) {
    return WavePosition(
      svgPath: svgPath,
      width: width,
      height: height,
      x: moveLeft,
      y: 1.0 + moveDown,
      ignoresSafeArea: ignoresSafeArea,
      fit: fit,
      opacity: opacity,
      zIndex: zIndex,
    );
  }

  static WavePosition center({
    required String svgPath,
    double width = 1.0,
    double height = 0.7,
    double moveLeft = 0.0,
    double moveUp = 0.0,
    BoxFit fit = BoxFit.contain,
    double opacity = 1.0,
    int zIndex = 0,
  }) {
    return WavePosition(
      svgPath: svgPath,
      width: width,
      height: height,
      x: moveLeft,
      y: moveUp,
      fit: fit,
      opacity: opacity,
      zIndex: zIndex,
    );
  }

  static WavePosition fullscreen({
    required String svgPath,
    double moveLeft = 0.0,
    double moveUp = 0.0,
    BoxFit fit = BoxFit.cover,
    double opacity = 1.0,
    int zIndex = 0,
  }) {
    return WavePosition(
      svgPath: svgPath,
      width: 1.0,
      height: 1.0,
      x: moveLeft,
      y: moveUp,
      ignoresSafeArea: true,
      fit: fit,
      opacity: opacity,
      zIndex: zIndex,
    );
  }
}

/// ✅ НОВЫЙ КЛАСС - коллекция волн для слайда
class MultipleWaves {
  final List<WavePosition> waves;

  const MultipleWaves(this.waves);

  /// Создать множественные волны из списка
  factory MultipleWaves.fromList(List<WavePosition> waves) {
    return MultipleWaves(waves);
  }

  /// Быстрый способ создать две волны
  factory MultipleWaves.dual({
    required WavePosition firstWave,
    required WavePosition secondWave,
  }) {
    return MultipleWaves([firstWave, secondWave]);
  }

  /// Получить отсортированные волны по zIndex (сначала задние слои)
  List<WavePosition> get sortedWaves {
    final sorted = List<WavePosition>.from(waves);
    sorted.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return sorted;
  }
}
