import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../../../core/constants/color_constants.dart';

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
            // Blurred transparent background
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

            // Center AI chat button
            Positioned(
              top: -5,
              left: (screenWidth - 80) / 2 - 40,
              child: _CenterChatButton(
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),

            // Navigation items
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
                          _LottieNavItem(
                            assetName: 'home',
                            label: 'Home',
                            index: 0,
                            isSelected: currentIndex == 0,
                            onTap: onTap,
                          ),
                          _LottieNavItem(
                            assetName: 'explore',
                            label: 'Explore',
                            index: 1,
                            isSelected: currentIndex == 1,
                            onTap: onTap,
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
                          _LottieNavItem(
                            assetName: 'myTrips',
                            label: 'My trips',
                            index: 3,
                            isSelected: currentIndex == 3,
                            onTap: onTap,
                          ),
                          _LottieNavItem(
                            assetName: 'profile',
                            label: 'Profile',
                            index: 4,
                            isSelected: currentIndex == 4,
                            onTap: onTap,
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
}

// Lottie navigation item with animation
class _LottieNavItem extends StatefulWidget {
  final String assetName;
  final String label;
  final int index;
  final bool isSelected;
  final Function(int) onTap;

  const _LottieNavItem({
    required this.assetName,
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LottieNavItem> createState() => _LottieNavItemState();
}

class _LottieNavItemState extends State<_LottieNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _lottieController;
  bool _wasSelected = false;

  String get _assetPath {
    final folder = widget.isSelected ? 'dock-purple' : 'dock-white';
    return 'assets/animations/lottie/$folder/${widget.assetName}.json';
  }

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _wasSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(_LottieNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Play animation when becoming selected
    if (widget.isSelected && !_wasSelected) {
      _lottieController.reset();
      _lottieController.forward();
    }
    _wasSelected = widget.isSelected;
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? AppColors.primary : Colors.white;

    return _BounceableButton(
      onTap: () => widget.onTap(widget.index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Lottie.asset(
                _assetPath,
                controller: _lottieController,
                onLoaded: (composition) {
                  _lottieController.duration = composition.duration;
                  // Play once on initial load if selected
                  if (widget.isSelected) {
                    _lottieController.forward();
                  }
                },
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Center AI chat button with Lottie animation
class _CenterChatButton extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterChatButton({
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CenterChatButton> createState() => _CenterChatButtonState();
}

class _CenterChatButtonState extends State<_CenterChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _lottieController;
  bool _wasSelected = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _wasSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(_CenterChatButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !_wasSelected) {
      _lottieController.reset();
      _lottieController.forward();
    }
    _wasSelected = widget.isSelected;
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BounceableButton(
      onTap: widget.onTap,
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        color: Colors.transparent,
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
          child: Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: Lottie.asset(
                'assets/animations/lottie/dock-white/aiChat.json',
                controller: _lottieController,
                onLoaded: (composition) {
                  _lottieController.duration = composition.duration;
                  if (widget.isSelected) {
                    _lottieController.forward();
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Clipper with notch at top only
class NotchedBottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final notchDepth = 25.0;
    final notchWidth = 35.0;

    path.moveTo(0, 0);
    path.lineTo(centerX - notchWidth - 20, 0);

    // Top notch (cut inward)
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

    path.lineTo(width, 0);
    path.lineTo(width, height);
    path.lineTo(0, height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Bounce animation widget
class _BounceableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BounceableButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_BounceableButton> createState() => _BounceableButtonState();
}

class _BounceableButtonState extends State<_BounceableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _controller.forward().then((_) => _controller.reverse());
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
