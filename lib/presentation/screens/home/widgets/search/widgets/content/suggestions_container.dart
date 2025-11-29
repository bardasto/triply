import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../../../../../../core/models/city_model.dart';
import '../../theme/search_theme.dart';
import 'suggestion_item.dart';

/// Container for search suggestions.
class SuggestionsContainer extends StatelessWidget {
  final bool isLoading;
  final List<CityModel> suggestions;
  final ValueChanged<CityModel> onSuggestionSelected;

  const SuggestionsContainer({
    super.key,
    required this.isLoading,
    required this.suggestions,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SearchTheme.suggestionContainerDecoration,
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.white.withValues(alpha: 0.1),
                height: 1,
                indent: 56,
              ),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return SuggestionItem(
                  city: suggestion,
                  onTap: () => onSuggestionSelected(suggestion),
                );
              },
            ),
    );
  }
}
