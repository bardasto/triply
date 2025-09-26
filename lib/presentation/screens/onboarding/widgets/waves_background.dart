// lib/presentation/screens/onboarding/widgets/waves_background.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/wave_position.dart';
import '../models/onboarding_data.dart';

/// Виджет для отображения одной волны
class SingleWaveBackground extends StatelessWidget {
  final WavePosition wave;

  const SingleWaveBackground({
    Key? key,
    required this.wave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    return Positioned(
      top: _calculateTop(screenSize, safeArea),
      left: _calculateLeft(screenSize, safeArea),
      child: Container(
        width: screenSize.width * wave.width,
        height: screenSize.height * wave.height,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: Opacity(
          opacity: wave.opacity,
          child: _buildSvgContent(screenSize),
        ),
      ),
    );
  }

  Widget _buildSvgContent(Size screenSize) {
    final containerWidth = screenSize.width * wave.width;
    final containerHeight = screenSize.height * wave.height;

    return SvgPicture.asset(
      wave.svgPath,
      width: containerWidth,
      height: containerHeight,
      fit: wave.fit,
      allowDrawingOutsideViewBox: true,
      placeholderBuilder: (context) =>
          _buildPlaceholder(containerWidth, containerHeight),
    );
  }

  double _calculateTop(Size screenSize, EdgeInsets safeArea) {
    final availableHeight = screenSize.height;
    final waveHeight = availableHeight * wave.height;

    double topPosition =
        ((wave.y + 1.0) / 2.0) * (availableHeight - waveHeight);

    if (!wave.ignoresSafeArea && wave.y < 0) {
      topPosition += safeArea.top;
    }

    return topPosition;
  }

  double _calculateLeft(Size screenSize, EdgeInsets safeArea) {
    final availableWidth = screenSize.width;
    final waveWidth = availableWidth * wave.width;

    double leftPosition = ((wave.x + 1.0) / 2.0) * (availableWidth - waveWidth);

    if (!wave.ignoresSafeArea && wave.x < 0) {
      leftPosition += safeArea.left;
    }

    return leftPosition;
  }

  Widget _buildPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waves, color: Colors.grey[400], size: 24),
          const SizedBox(height: 4),
          Text(
            'Wave\n${wave.svgPath.split('/').last}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
          ),
          Text(
            'z:${wave.zIndex}',
            style: TextStyle(color: Colors.grey[500], fontSize: 8),
          ),
        ],
      ),
    );
  }
}

/// ✅ НОВЫЙ ВИДЖЕТ - для множественных волн
class MultipleWavesBackground extends StatelessWidget {
  final List<WavePosition> waves;


  const MultipleWavesBackground({
    Key? key,
    required this.waves,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (waves.isEmpty) {
      return const SizedBox.shrink();
    }

    // Сортируем волны по zIndex (задние слои рендерятся первыми)
    final sortedWaves = List<WavePosition>.from(waves);
    sortedWaves.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return Stack(
      children: [
        // Рендерим все волны в правильном порядке
        ...sortedWaves.map((wave) => SingleWaveBackground(wave: wave)),
      ],
    );
  }

  
}

/// ✅ ОБНОВЛЕННЫЙ ВИДЖЕТ - для слайдов с поддержкой множественных волн
class SlideWavesBackground extends StatelessWidget {
  final OnboardingData data;

  const SlideWavesBackground({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!data.hasWaves) {
      return const SizedBox.shrink();
    }

    return MultipleWavesBackground(
      waves: data.allWaves,
    );
  }
}

/// ✅ СОВМЕСТИМОСТЬ - старый виджет для одной волны
class WavesBackground extends StatelessWidget {
  final WavePosition waves;

  const WavesBackground({
    Key? key,
    required this.waves,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleWaveBackground(wave: waves);
  }
}
