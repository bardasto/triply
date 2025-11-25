import 'package:flutter/cupertino.dart';

/// Single action item for context menu.
class ContextMenuAction {
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  final bool isDestructive;

  /// If true, tapping this action will show an input field instead of closing the menu.
  final bool showsInput;

  /// Placeholder text for the input field (when showsInput is true).
  final String? inputPlaceholder;

  /// Callback when user submits text from the input field.
  final Function(String)? onInputSubmit;

  const ContextMenuAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
    this.isDestructive = false,
    this.showsInput = false,
    this.inputPlaceholder,
    this.onInputSubmit,
  });
}
