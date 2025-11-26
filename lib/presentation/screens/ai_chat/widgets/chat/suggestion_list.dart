import 'package:flutter/material.dart';

import '../../theme/ai_chat_theme.dart';
import '../common/bounceable_button.dart';

/// A vertical list of trip suggestions.
class SuggestionList extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onSuggestionTap;

  const SuggestionList({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: List.generate(suggestions.length, (index) {
          final isFirst = index == 0;
          final isLast = index == suggestions.length - 1;

          final borderRadius = BorderRadius.vertical(
            top: isFirst ? const Radius.circular(24) : Radius.zero,
            bottom: isLast ? const Radius.circular(24) : Radius.zero,
          );

          return Column(
            children: [
              BounceableButton(
                onTap: () => onSuggestionTap(suggestions[index]),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AiChatTheme.inputBackground,
                    borderRadius: borderRadius,
                  ),
                  child: Text(
                    suggestions[index],
                    style: AiChatTheme.suggestionText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  height: 1,
                  color: Colors.black.withValues(alpha: 0.2),
                ),
            ],
          );
        }),
      ),
    );
  }
}
