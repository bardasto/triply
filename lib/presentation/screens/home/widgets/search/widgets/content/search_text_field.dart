import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/search_theme.dart';

/// Search text field for destinations.
class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;

  const SearchTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onClear,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SearchTheme.elementDecoration,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: false,
        keyboardAppearance: Brightness.dark,
        style: SearchTheme.searchInputStyle,
        decoration: InputDecoration(
          hintText: 'Search destinations',
          hintStyle: SearchTheme.searchHintStyle,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.5),
            size: 22,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onClear?.call();
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}
