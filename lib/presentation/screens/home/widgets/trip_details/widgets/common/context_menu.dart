import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../../core/constants/color_constants.dart';
import 'context_menu_action.dart';

/// Context menu with blur background.
/// Shows on long press with haptic feedback and bounce animation.
/// Supports iOS-style slide-to-select behavior.
/// The item stays at its original position on the blurred overlay.
class ContextMenu extends StatefulWidget {
  final Widget child;
  final List<ContextMenuAction> actions;
  final Widget? preview;
  final bool enabled;

  /// Duration of long press before menu opens (default: 200ms)
  final Duration longPressDuration;

  const ContextMenu({
    super.key,
    required this.child,
    required this.actions,
    this.preview,
    this.enabled = true,
    this.longPressDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu>
    with SingleTickerProviderStateMixin {
  final GlobalKey _childKey = GlobalKey();
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  bool _isMenuOpen = false;
  Offset? _currentPointerPosition;
  _ContextMenuOverlayState? _overlayState;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: widget.longPressDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _showContextMenu(Offset initialPointerPosition) {
    if (_isMenuOpen) return;
    _isMenuOpen = true;

    // Dismiss keyboard before showing context menu
    FocusManager.instance.primaryFocus?.unfocus();

    HapticFeedback.mediumImpact();

    // Get the position and size of the child widget
    final RenderBox? renderBox =
        _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      _isMenuOpen = false;
      return;
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    Navigator.of(context)
        .push(
      _ContextMenuRoute(
        actions: widget.actions,
        preview: widget.preview ?? widget.child,
        childPosition: position,
        childSize: size,
        initialPointerPosition: initialPointerPosition,
        onOverlayCreated: (state) {
          _overlayState = state;
        },
      ),
    )
        .then((_) {
      _isMenuOpen = false;
      _overlayState = null;
      _bounceController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      onLongPressStart: (details) {
        HapticFeedback.mediumImpact();
        _currentPointerPosition = details.globalPosition;
        _bounceController.forward().then((_) {
          // Use current position (may have moved during animation)
          _showContextMenu(_currentPointerPosition ?? details.globalPosition);
        });
      },
      onLongPressMoveUpdate: (details) {
        _currentPointerPosition = details.globalPosition;
        if (_isMenuOpen && _overlayState != null) {
          _overlayState!.updatePointerPosition(details.globalPosition);
        }
      },
      onLongPressEnd: (details) {
        if (_isMenuOpen && _overlayState != null) {
          _overlayState!.handlePointerUp(details.globalPosition);
        }
      },
      onLongPressCancel: () {
        _bounceController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: KeyedSubtree(
              key: _childKey,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Custom route for context menu with blur background.
class _ContextMenuRoute extends PopupRoute<void> {
  final List<ContextMenuAction> actions;
  final Widget preview;
  final Offset childPosition;
  final Size childSize;
  final Offset initialPointerPosition;
  final Function(_ContextMenuOverlayState)? onOverlayCreated;

  _ContextMenuRoute({
    required this.actions,
    required this.preview,
    required this.childPosition,
    required this.childSize,
    required this.initialPointerPosition,
    this.onOverlayCreated,
  });

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ContextMenuOverlay(
      actions: actions,
      preview: preview,
      animation: animation,
      childPosition: childPosition,
      childSize: childSize,
      initialPointerPosition: initialPointerPosition,
      onOverlayCreated: onOverlayCreated,
    );
  }
}

class _ContextMenuOverlay extends StatefulWidget {
  final List<ContextMenuAction> actions;
  final Widget preview;
  final Animation<double> animation;
  final Offset childPosition;
  final Size childSize;
  final Offset initialPointerPosition;
  final Function(_ContextMenuOverlayState)? onOverlayCreated;

  const _ContextMenuOverlay({
    required this.actions,
    required this.preview,
    required this.animation,
    required this.childPosition,
    required this.childSize,
    required this.initialPointerPosition,
    this.onOverlayCreated,
  });

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  bool _showInput = false;
  ContextMenuAction? _activeInputAction;
  late AnimationController _inputAnimationController;
  late Animation<double> _inputAnimation;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Slide-to-select state
  int? _hoveredIndex;
  final GlobalKey _menuKey = GlobalKey();
  bool _isSlideSelecting = false;

  // Store menu bounds for hit testing
  List<Rect> _itemBounds = [];

  // Constants for menu item heights
  static const double _menuItemHeight = 46.0;
  static const double _menuDividerHeight = 0.5;
  static const double _menuSpacing = 12.0;
  static const double _menuWidth = 0.7; // 70% of screen width

  // Cache for menu position calculation
  double? _cachedScreenWidth;
  double? _cachedScreenHeight;
  bool? _cachedShowMenuAbove;

  @override
  void initState() {
    super.initState();
    _inputAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _inputAnimation = CurvedAnimation(
      parent: _inputAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Notify parent immediately so it can forward events
    widget.onOverlayCreated?.call(this);

    // After first frame, calculate bounds and check initial position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start slide selecting immediately
      _isSlideSelecting = true;
      // Check initial position
      updatePointerPosition(widget.initialPointerPosition);
    });
  }

  @override
  void dispose() {
    _inputAnimationController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Calculate menu item bounds programmatically without relying on RenderBox
  void _calculateMenuBounds() {
    if (_cachedScreenWidth == null) return;

    final screenWidth = _cachedScreenWidth!;
    final showMenuAbove = _cachedShowMenuAbove ?? false;

    // Calculate menu position (same logic as in build method)
    final menuLeft = widget.childPosition.dx;
    final menuWidth = screenWidth * _menuWidth;

    double menuTop;
    if (showMenuAbove) {
      // Menu is above the preview
      final menuHeight = widget.actions.length * _menuItemHeight +
          (widget.actions.length - 1) * _menuDividerHeight;
      menuTop = widget.childPosition.dy - _menuSpacing - menuHeight;
    } else {
      // Menu is below the preview
      menuTop = widget.childPosition.dy +
          widget.childSize.height +
          _menuSpacing;
    }

    // Calculate bounds for each menu item
    _itemBounds = [];
    double currentY = menuTop;
    for (int i = 0; i < widget.actions.length; i++) {
      _itemBounds.add(Rect.fromLTWH(
        menuLeft,
        currentY,
        menuWidth,
        _menuItemHeight,
      ));
      currentY += _menuItemHeight;
      if (i < widget.actions.length - 1) {
        currentY += _menuDividerHeight;
      }
    }
  }

  /// Called when pointer position changes during slide-to-select
  void updatePointerPosition(Offset globalPosition) {
    if (_showInput) return;

    // 1. Находим RenderBox нашего меню по ключу
    final RenderBox? menuBox =
        _menuKey.currentContext?.findRenderObject() as RenderBox?;
    if (menuBox == null) return;

    // 2. Магия Flutter: переводим глобальные координаты экрана в локальные координаты меню.
    // Этот метод сам учтет все смещения, анимации и Transform.translate.
    final localOffset = menuBox.globalToLocal(globalPosition);

    final double width = menuBox.size.width;
    final double height = menuBox.size.height;

    // 3. Проверяем, находится ли палец внутри меню (с небольшим запасом по ширине для удобства)
    // Мы позволяем пальцу выходить за пределы ширины на 20px, чтобы не срывалось выделение
    bool isInsideMenu = localOffset.dx >= -20 &&
        localOffset.dx <= width + 20 &&
        localOffset.dy >= 0 &&
        localOffset.dy <= height;

    if (isInsideMenu) {
      _isSlideSelecting = true;

      // 4. Вычисляем индекс элемента математически.
      // Делим позицию пальца (Y) на высоту меню, чтобы понять процент смещения,
      // и умножаем на количество элементов. Это надежнее, чем фиксированные высоты.
      final double progress = localOffset.dy / height;
      int index = (progress * widget.actions.length).floor();

      // Ограничиваем индекс, чтобы не вылетел за пределы массива
      index = index.clamp(0, widget.actions.length - 1);

      // 5. Если индекс сменился — обновляем состояние и даем тактильный отклик
      if (_hoveredIndex != index) {
        setState(() {
          _hoveredIndex = index;
        });
        HapticFeedback.selectionClick(); // Эффект "трещотки" при переборе
      }
    } else {
      // Если палец ушел далеко от меню — снимаем выделение
      if (_hoveredIndex != null) {
        setState(() {
          _hoveredIndex = null;
        });
      }
    }
  }

  /// Called when pointer is released
  void handlePointerUp(Offset globalPosition) {
    if (_showInput) return;

    // Если у нас есть выделенный элемент (палец был на нем в момент отпускания)
    if (_hoveredIndex != null) {
      final action = widget.actions[_hoveredIndex!];

      // Подтверждаем выбор вибрацией
      HapticFeedback.mediumImpact();

      if (action.showsInput) {
        // Логика для поля ввода
        setState(() {
          _showInput = true;
          _activeInputAction = action;
          _hoveredIndex = null;
          _isSlideSelecting = false;
        });
        _inputAnimationController.forward();
        Future.delayed(const Duration(milliseconds: 100), () {
          _focusNode.requestFocus();
        });
      } else {
        // Обычное действие: закрываем меню и выполняем коллбек
        Navigator.of(context).pop();
        action.onTap();
      }
    } else {
      // Если палец отпустили в пустоте — просто закрываем меню
      Navigator.of(context).pop();
    }

    // Сбрасываем состояние
    setState(() {
      _hoveredIndex = null;
      _isSlideSelecting = false;
    });
  }

  void _showInputField(ContextMenuAction action, GlobalKey buttonKey) {
    setState(() {
      _showInput = true;
      _activeInputAction = action;
      _hoveredIndex = null;
    });

    _inputAnimationController.forward();

    // Focus the text field after animation starts
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });
  }

  void _hideInputField() {
    _inputAnimationController.reverse().then((_) {
      setState(() {
        _showInput = false;
        _activeInputAction = null;
        _textController.clear();
      });
    });
  }

  void _submitInput() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    if (_activeInputAction?.onInputSubmit != null) {
      _activeInputAction!.onInputSubmit!(text);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
    );

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    // Calculate if menu should be above or below
    final childCenterY = widget.childPosition.dy + widget.childSize.height / 2;
    final showMenuAbove = childCenterY > screenHeight / 2;

    // Cache values for bounds calculation
    if (_cachedScreenWidth != screenWidth ||
        _cachedScreenHeight != screenHeight ||
        _cachedShowMenuAbove != showMenuAbove) {
      _cachedScreenWidth = screenWidth;
      _cachedScreenHeight = screenHeight;
      _cachedShowMenuAbove = showMenuAbove;
      _itemBounds = []; // Force recalculation
      _calculateMenuBounds();
    }

    // Menu spacing
    const menuSpacing = 12.0;

    // Calculate vertical offset to keep ALL content above keyboard
    double keyboardOffset = 0;
    if (_showInput && keyboardHeight > 0) {
      const inputMinHeight = 62.0;
      const menuHeight = 100.0;
      const inputSpacing = 8.0;
      const bottomPadding = 20.0;

      // Calculate where input field bottom would be
      double inputBottomPosition;

      if (!showMenuAbove) {
        // Menu is below preview
        inputBottomPosition = widget.childPosition.dy +
            widget.childSize.height +
            menuSpacing +
            menuHeight +
            inputSpacing +
            inputMinHeight;
      } else {
        // Menu is above preview - input is still below menu which is above preview
        // So input bottom = preview top - menuSpacing (for menu) + some offset
        // Actually when showMenuAbove, input appears BELOW the preview
        inputBottomPosition = widget.childPosition.dy +
            widget.childSize.height +
            inputSpacing +
            inputMinHeight;
      }

      final maxAllowedBottom = screenHeight - keyboardHeight - bottomPadding;

      if (inputBottomPosition > maxAllowedBottom) {
        keyboardOffset = inputBottomPosition - maxAllowedBottom;
      }
    }

    return GestureDetector(
      onTap: () {
        if (_showInput) {
          _hideInputField();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: AnimatedBuilder(
        animation: curvedAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Blur background
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 20 * curvedAnimation.value,
                    sigmaY: 20 * curvedAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.4 * curvedAnimation.value,
                    ),
                  ),
                ),
              ),

              // All content wrapped in AnimatedContainer for keyboard animation
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                top: -keyboardOffset,
                bottom: keyboardOffset,
                child: Stack(
                  children: [
                    // Preview card at original position
                    Positioned(
                      left: widget.childPosition.dx,
                      top: widget.childPosition.dy,
                      width: widget.childSize.width,
                      child: Transform.scale(
                        scale: 0.96 + (0.04 * curvedAnimation.value),
                        child: Opacity(
                          opacity: curvedAnimation.value,
                          child: widget.preview,
                        ),
                      ),
                    ),

                    // Actions menu - positioned above or below the preview, aligned to left edge
                    Positioned(
                      left: widget.childPosition.dx,
                      top: showMenuAbove
                          ? null
                          : widget.childPosition.dy +
                              widget.childSize.height +
                              menuSpacing,
                      bottom: showMenuAbove
                          ? screenHeight - widget.childPosition.dy + menuSpacing
                          : null,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          showMenuAbove
                              ? -20 * (1 - curvedAnimation.value)
                              : 20 * (1 - curvedAnimation.value),
                        ),
                        child: Opacity(
                          opacity: curvedAnimation.value,
                          child: _buildActionsMenu(context, screenWidth, showMenuAbove),
                        ),
                      ),
                    ),

                    // Input field - appears when Edit is tapped
                    if (_showInput)
                      _buildInputField(
                          context, screenWidth, screenHeight, showMenuAbove),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionsMenu(
      BuildContext context, double screenWidth, bool showMenuAbove) {
    return Container(
      key: _menuKey,
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < widget.actions.length; i++) ...[
            _ContextMenuItem(
              action: widget.actions[i],
              isFirst: i == 0,
              isLast: i == widget.actions.length - 1,
              onShowInput: _showInputField,
              isHovered: _hoveredIndex == i,
            ),
            if (i < widget.actions.length - 1)
              Container(
                height: 0.5,
                color: Colors.white.withValues(alpha: 0.1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context, double screenWidth,
      double screenHeight, bool showMenuAbove) {
    // Position input field - always at the first menu item (Edit) position
    const menuSpacing = 12.0;
    const menuItemHeight = 46.0;
    const menuDividerHeight = 0.5;

    // Calculate menu height based on number of actions
    final menuHeight = widget.actions.length * menuItemHeight +
        (widget.actions.length - 1) * menuDividerHeight;

    // Same width as menu
    final menuMaxWidth = screenWidth * 0.7;

    // Calculate the position where the Edit button (first menu item) is located
    // Input field should always appear at this position (top of menu)
    double inputTop;

    if (!showMenuAbove) {
      // Menu below preview -> Edit is at top of menu (just below preview)
      inputTop = widget.childPosition.dy +
          widget.childSize.height +
          menuSpacing;
    } else {
      // Menu above preview -> Edit is at top of menu (above preview)
      // Menu bottom is at: widget.childPosition.dy - menuSpacing
      // Menu top (where Edit is) is at: menu bottom - menuHeight
      inputTop = widget.childPosition.dy - menuSpacing - menuHeight;
    }

    return AnimatedBuilder(
      animation: _inputAnimation,
      builder: (context, child) {
        return Positioned(
          left: widget.childPosition.dx,
          top: inputTop,
          child: Transform.translate(
            offset: Offset(
              0,
              showMenuAbove
                  ? -20 * (1 - _inputAnimation.value)
                  : 20 * (1 - _inputAnimation.value),
            ),
            child: Opacity(
              opacity: _inputAnimation.value,
              child: GestureDetector(
                onTap: () {}, // Prevent tap from closing
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: menuMaxWidth,
                      minHeight: 46,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            keyboardAppearance: Brightness.dark,
                            maxLines: 5,
                            minLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              decoration: TextDecoration.none,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: _activeInputAction?.inputPlaceholder ??
                                  'Enter your prompt...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 16,
                                decoration: TextDecoration.none,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildSendButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _textController,
      builder: (context, value, child) {
        final hasText = value.text.trim().isNotEmpty;
        return _BounceableSendButton(
          enabled: hasText,
          onTap: _submitInput,
        );
      },
    );
  }
}

class _BounceableSendButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _BounceableSendButton({
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_BounceableSendButton> createState() => _BounceableSendButtonState();
}

class _BounceableSendButtonState extends State<_BounceableSendButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _bounceController.forward() : null,
      onTapUp: widget.enabled
          ? (_) => _bounceController.reverse().then((_) => _handleTap())
          : null,
      onTapCancel: widget.enabled ? () => _bounceController.reverse() : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.enabled
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.arrow_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ContextMenuItem extends StatefulWidget {
  final ContextMenuAction action;
  final bool isFirst;
  final bool isLast;
  final Function(ContextMenuAction action, GlobalKey buttonKey)? onShowInput;
  final bool isHovered;

  const _ContextMenuItem({
    required this.action,
    required this.isFirst,
    required this.isLast,
    this.onShowInput,
    this.isHovered = false,
  });

  @override
  State<_ContextMenuItem> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<_ContextMenuItem>
    with SingleTickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();

    if (widget.action.showsInput && widget.onShowInput != null) {
      // Show input field instead of closing
      widget.onShowInput!(widget.action, _buttonKey);
    } else {
      Navigator.of(context).pop();
      widget.action.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.action.isDestructive
        ? Colors.red
        : (widget.action.color ?? Colors.white);

    // Show hover effect through background color
    final backgroundColor = widget.isHovered
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.transparent;

    return GestureDetector(
      onTapDown: (_) => _bounceController.forward(),
      onTapUp: (_) {
        _bounceController.reverse().then((_) => _handleTap());
      },
      onTapCancel: () => _bounceController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isHovered ? 1.0 : _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              key: _buttonKey,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.vertical(
                  top: widget.isFirst ? const Radius.circular(14) : Radius.zero,
                  bottom:
                      widget.isLast ? const Radius.circular(14) : Radius.zero,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.action.icon, color: color, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.action.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.none,
                      ),
                    ),
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
