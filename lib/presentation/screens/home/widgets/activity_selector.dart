import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/color_constants.dart';

class ActivityModel {
  final IconData icon;
  final String id;
  final String label;
  final Color color;

  const ActivityModel({
    required this.icon,
    required this.id,
    required this.label,
    required this.color,
  });
}

class ActivitySelector extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onActivitySelected;
  final bool isDarkMode;

  const ActivitySelector({
    Key? key,
    required this.selectedIndex,
    required this.onActivitySelected,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<ActivitySelector> createState() => _ActivitySelectorState();
}

class _ActivitySelectorState extends State<ActivitySelector>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _scaleController;
  int? _pressedIndex;

  static const List<ActivityModel> activities = [
    ActivityModel(
      icon: PhosphorIconsBold.bicycle,
      id: 'cycling',
      label: 'Cycling',
      color: Color(0xFFA8E6CF), // Мятный
    ),
    ActivityModel(
      icon: PhosphorIconsBold.island,
      id: 'beach',
      label: 'Beach',
      color: Color(0xFF87CEEB), // Голубой
    ),
    ActivityModel(
      icon: PhosphorIconsBold.personSimpleSki,
      id: 'skiing',
      label: 'Skiing',
      color: Color(0xFFB8D4E8), // Снежный
    ),
    ActivityModel(
      icon: PhosphorIconsBold.mountains,
      id: 'mountains',
      label: 'Mountains',
      color: Color(0xFFD4D4D4), // Серебристый
    ),
    ActivityModel(
      icon: PhosphorIconsBold.personSimpleHike,
      id: 'hiking',
      label: 'Hiking',
      color: Color(0xFF98D8C8), // Зеленый
    ),
    ActivityModel(
      icon: PhosphorIconsBold.sailboat,
      id: 'sailing',
      label: 'Sailing',
      color: Color(0xFF7FCDCD), // Бирюзовый
    ),
    ActivityModel(
      icon: PhosphorIconsBold.cactus,
      id: 'desert',
      label: 'Desert',
      color: Color(0xFFFDD17B), // Песочный
    ),
    ActivityModel(
      icon: PhosphorIconsBold.tipi,
      id: 'camping',
      label: 'Camping',
      color: Color(0xFFD4A574), // Коричневый
    ),
    ActivityModel(
      icon: PhosphorIconsBold.city,
      id: 'city',
      label: 'City',
      color: Color(0xFFB8B8B8), // Серый
    ),
    ActivityModel(
      icon: PhosphorIconsBold.personSimpleTaiChi,
      id: 'wellness',
      label: 'Wellness',
      color: Color(0xFFDDA0DD), // Лавандовый
    ),
    ActivityModel(
      icon: PhosphorIconsBold.roadHorizon,
      id: 'road_trip',
      label: 'Road Trip',
      color: Color(0xFFFFC8A2), // Персиковый
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void didUpdateWidget(ActivitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToIndex(widget.selectedIndex);
    }
  }

  void _scrollToIndex(int index) {
    if (_scrollController.hasClients) {
      final targetOffset = index * 70.0 - 100;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleTapDown(int index) {
    setState(() => _pressedIndex = index);
    _scaleController.forward();
  }

  void _handleTapUp(int index) {
    setState(() => _pressedIndex = null);
    _scaleController.reverse();
    widget.onActivitySelected(index);
  }

  void _handleTapCancel() {
    setState(() => _pressedIndex = null);
    _scaleController.reverse();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 0, right: 0),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          return _buildActivityItem(index);
        },
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    final isSelected = widget.selectedIndex == index;
    final isPressed = _pressedIndex == index;
    final activity = activities[index];

    return GestureDetector(
      onTapDown: (_) => _handleTapDown(index),
      onTapUp: (_) => _handleTapUp(index),
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          final scale = isPressed ? 1.0 - (_scaleController.value * 0.15) : 1.0;

          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              height: 48,
              margin: EdgeInsets.only(
                left: index == 0 ? 20 : 4,
                right: index == activities.length - 1 ? 20 : 4,
              ),
              padding: EdgeInsets.only(
                left: isSelected ? 12 : 14,
                right: isSelected ? 16 : 14,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? activity.color.withOpacity(0.85)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Icon(
                    activity.icon,
                    size: 26,
                    color: isSelected
                        ? Colors.white
                        : AppColors.primary.withOpacity(0.6),
                  ),
                  // Label
                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    child: isSelected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              activity.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
