// lib/presentation/widgets/common/smart_scroll_view.dart
import 'package:flutter/material.dart';

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

// ✅ SmartScrollView с bounce-back эффектом
class SmartScrollView extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const SmartScrollView({
    Key? key,
    required this.child,
    this.controller,
    this.padding,
    this.physics,
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

    // ✅ При overscroll вниз (дошли до конца) делаем bounce назад
    if (notification.overscroll > 0 &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent) {
      // Плавно возвращаемся назад на 30 пикселей
      _bounceBack();
    }
  }

  void _bounceBack() {
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final targetPosition = (maxExtent - 30).clamp(0.0, maxExtent);

    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack, // ✅ Красивая bounce кривая
    );
  }
}
