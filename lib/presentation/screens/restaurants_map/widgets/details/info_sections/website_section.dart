import 'package:flutter/material.dart';
import '../../../../../../core/constants/color_constants.dart';
import '../../../utils/map_utils.dart';

/// Website Section widget
class WebsiteSection extends StatelessWidget {
  final String website;

  const WebsiteSection({
    super.key,
    required this.website,
  });

  @override
  Widget build(BuildContext context) {
    String displayUrl = website;
    try {
      final uri = Uri.parse(website);
      displayUrl = uri.host.replaceAll('www.', '');
    } catch (_) {}

    return GestureDetector(
      onTap: () => MapUtils.openWebsite(context, website),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.language,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayUrl,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: Colors.white.withValues(alpha: 0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
