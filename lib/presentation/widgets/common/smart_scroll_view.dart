// lib/presentation/widgets/common/smart_scroll_view.dart
import 'package:flutter/material.dart';

// ✅ Enum для типов bounce поведения
enum BounceBackType {
  toTop, // К началу (позиция 0)
  partial, // Назад на N пикселей
  none, // Без bounce-back
}

// ✅ Определяем класс NoGlowScrollBehavior
class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // ✅ Убираем серый overscroll glow effect
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // ✅ Используем bouncing physics для плавности
    return const BouncingScrollPhysics();
  }
}

// ✅ SmartScrollView с настраиваемым bounce поведением
class SmartScrollView extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final BounceBackType bounceBackType; // ✅ Новый параметр
  final double bounceBackPixels; // ✅ Количество пикселей для partial режима

  const SmartScrollView({
    Key? key,
    required this.child,
    this.controller,
    this.padding,
    this.physics,
    this.bounceBackType = BounceBackType.toTop, // ✅ По умолчанию к началу
    this.bounceBackPixels = 30.0,
  }) : super(key: key);

  @override
  State<SmartScrollView> createState() => _SmartScrollViewState();
}

class _SmartScrollViewState extends State<SmartScrollView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: NoGlowScrollBehavior(), // ✅ Применяем кастомное поведение
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          // ✅ Обрабатываем overscroll для bounce-back эффекта
          if (notification is OverscrollNotification) {
            _handleOverscroll(notification);
          }
          return false;
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: widget.physics ?? const BouncingScrollPhysics(),
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }

  void _handleOverscroll(OverscrollNotification notification) {
    if (!_scrollController.hasClients) return;

    // ✅ При overscroll вниз (дошли до конца) выбираем поведение
    if (notification.overscroll > 0 &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent) {
      // ✅ Выбираем поведение в зависимости от настройки
      switch (widget.bounceBackType) {
        case BounceBackType.toTop:
          _bounceToTop();
          break;
        case BounceBackType.partial:
          _bounceBack();
          break;
        case BounceBackType.none:
          // Ничего не делаем
          break;
      }
    }
  }

  // ✅ Bounce к началу экрана
  void _bounceToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0.0, // ✅ Самый верх - позиция 0
      duration: const Duration(milliseconds: 600), // ✅ Плавная анимация
      curve: Curves.easeOutBack, // ✅ Красивая bounce кривая
    );
  }

  // ✅ Bounce назад на указанное количество пикселей
  void _bounceBack() {
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final targetPosition =
        (maxExtent - widget.bounceBackPixels).clamp(0.0, maxExtent);

    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
    );
  }
}
