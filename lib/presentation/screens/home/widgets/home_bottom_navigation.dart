import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';


class HomeBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const HomeBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40, bottom: 30),
      child: Container(
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ✅ РАЗМЫТЫЙ ПРОЗРАЧНЫЙ ФОН БЕЗ ОКАНТОВКИ
            ClipPath(
              clipper: NotchedBottomBarClipper(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ✅ ЦЕНТРАЛЬНАЯ КНОПКА В ЯМКЕ
            Positioned(
              top: 5,
              left: (screenWidth - 80) / 2 - 30,
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: PhosphorIcon(
                    PhosphorIcons.openAiLogo(),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // ✅ НАВИГАЦИОННЫЕ КНОПКИ ПО ЦЕНТРУ
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    // Left items
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            icon: Icons.home_rounded,
                            index: 0,
                            isSelected: currentIndex == 0,
                          ),
                          _buildNavItem(
                            icon: Icons.favorite_rounded,
                            index: 1,
                            isSelected: currentIndex == 1,
                          ),
                        ],
                      ),
                    ),
                    // Center space
                    const SizedBox(width: 80),
                    // Right items
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(
                            icon: Icons.location_on_rounded,
                            index: 3,
                            isSelected: currentIndex == 3,
                          ),
                          _buildNavItem(
                            icon: Icons.person_rounded,
                            index: 4,
                            isSelected: currentIndex == 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.7) // ✅ БОЛЕЕ ПРОЗРАЧНЫЙ
              : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

// ✅ CLIPPER С ЯМКОЙ ТОЛЬКО СВЕРХУ
class NotchedBottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final notchDepth = 25.0;
    final notchWidth = 35.0;

    // Начинаем с верхнего левого угла
    path.moveTo(0, 0);

    // Левая часть до верхней ямки
    path.lineTo(centerX - notchWidth - 20, 0);

    // ✅ ВЕРХНЯЯ ЯМКА (ВЫРЕЗ ВНУТРЬ)
    path.quadraticBezierTo(
      centerX - notchWidth,
      0,
      centerX - notchWidth + 8,
      notchDepth * 0.6,
    );

    path.quadraticBezierTo(
      centerX - 8,
      notchDepth,
      centerX,
      notchDepth,
    );

    path.quadraticBezierTo(
      centerX + 8,
      notchDepth,
      centerX + notchWidth - 8,
      notchDepth * 0.6,
    );

    path.quadraticBezierTo(
      centerX + notchWidth,
      0,
      centerX + notchWidth + 20,
      0,
    );

    // Правая верхняя часть
    path.lineTo(width, 0);

    // Правый край
    path.lineTo(width, height);

    // Нижняя линия
    path.lineTo(0, height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
