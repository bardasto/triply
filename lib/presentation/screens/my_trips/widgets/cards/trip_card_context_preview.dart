import 'package:flutter/material.dart';

/// Wrapper widget for trip cards when shown in context menu preview.
/// Removes yellow underlines by wrapping content in Material widget.
class TripCardContextPreview extends StatelessWidget {
  final Widget child;

  const TripCardContextPreview({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: child,
    );
  }
}
