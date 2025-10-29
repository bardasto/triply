import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/constants/color_constants.dart';

class TripSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onTap;
  final Function(bool)? onFocusChanged;

  const TripSearchBar({
    Key? key,
    required this.onSearch,
    required this.onTap,
    this.onFocusChanged,
  }) : super(key: key);

  @override
  State<TripSearchBar> createState() => _TripSearchBarState();
}

class _TripSearchBarState extends State<TripSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    widget.onFocusChanged?.call(_isFocused);
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }

  void _handleGoPressed() {
    if (_hasText) {
      widget.onSearch(_controller.text);
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isFocused ? 0.15 : 0.08),
            blurRadius: _isFocused ? 20 : 12,
            offset: Offset(0, _isFocused ? 8 : 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          _focusNode.requestFocus();
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isFocused
                  ? [
                      Colors.white,
                      const Color(0xFFF8F9FA),
                    ]
                  : [
                      Colors.white,
                      Colors.grey[50]!,
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isFocused
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.white,
              width: _isFocused ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              // ✅ АНИМИРОВАННАЯ ИКОНКА ПОИСКА
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _isFocused
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.grey[200]!.withOpacity(0.5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: _isFocused ? AppColors.primary : Colors.grey,
                  size: 20,
                ),
              ),

              // ✅ ПОЛЕ ВВОДА
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Where would you like to go?',
                    hintStyle: TextStyle(
                      color: _isFocused
                          ? AppColors.primary.withOpacity(0.6)
                          : Colors.grey,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      widget.onSearch(value);
                    }
                  },
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                ),
              ),

              // ✅ ДИНАМИЧЕСКАЯ КНОПКА С PRIMARY ЦВЕТОМ
              GestureDetector(
                onTap: _hasText
                    ? _handleGoPressed
                    : () {
                        print('🎤 Voice search tapped');
                        // TODO: Интеграция с голосовым поиском
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary, // ✅ PRIMARY цвет для обеих кнопок
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(_isFocused ? 0.6 : 0.4),
                        blurRadius: _isFocused ? 12 : 8,
                        offset: Offset(0, _isFocused ? 6 : 4),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 2,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _hasText
                        ? const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
                            key: ValueKey('go'),
                          )
                        : const Icon(
                            Icons.mic_rounded,
                            color: Colors.white,
                            size: 18,
                            key: ValueKey('mic'),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
