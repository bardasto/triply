import 'package:flutter/material.dart';

import '../../../../../core/constants/color_constants.dart';
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
            top: isFirst ? const Radius.circular(20) : const Radius.circular(4),
            bottom: isLast ? const Radius.circular(20) : const Radius.circular(4),
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
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ],
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
                const SizedBox(height: 10),
            ],
          );
        }),
      ),
    );
  }
}
