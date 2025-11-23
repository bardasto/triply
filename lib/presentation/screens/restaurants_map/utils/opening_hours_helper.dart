/// Utilities for handling restaurant opening hours
class OpeningHoursHelper {
  /// Get opening status text (e.g., "Open", "Closed", or time string)
  static String getOpeningStatus(dynamic openingHours) {
    if (openingHours == null) {
      return 'Hours not available';
    }

    // Handle String format (e.g., "9:00 - 18:00")
    if (openingHours is String) {
      if (openingHours.trim().isEmpty) {
        return 'Hours not available';
      }
      return openingHours;
    }

    // Handle Map format (Google Places API format)
    if (openingHours is Map<String, dynamic>) {
      final openNow = openingHours['open_now'] as bool?;
      final weekdayText = openingHours['weekday_text'] as List?;

      if (weekdayText == null || weekdayText.isEmpty) {
        return 'Hours not available';
      }

      // Get current day (0 = Sunday, 1 = Monday, etc.)
      final now = DateTime.now();
      final currentDay = now.weekday % 7;

      // Get today's hours from weekday_text
      String todayHours = '';
      if (weekdayText.length > currentDay) {
        todayHours = weekdayText[currentDay].toString();
        if (todayHours.contains(':')) {
          todayHours = todayHours.split(':').skip(1).join(':').trim();
        }
      }

      if (todayHours.toLowerCase().contains('closed')) {
        return 'Closed';
      }

      if (openNow == true) {
        return 'Open';
      } else {
        return 'Closed';
      }
    }

    return 'Hours not available';
  }

  /// Get list of weekday hours
  static List<String> getWeekdayHours(dynamic openingHours) {
    if (openingHours == null) {
      return [];
    }

    // If it's a String, we don't have detailed weekday hours
    if (openingHours is String) {
      return [];
    }

    // If it's a Map, try to get weekday_text
    if (openingHours is Map<String, dynamic>) {
      final weekdayText = openingHours['weekday_text'] as List?;
      if (weekdayText == null || weekdayText.isEmpty) {
        return [];
      }
      return weekdayText.map((e) => e.toString()).toList();
    }

    return [];
  }

  /// Check if restaurant is currently open
  static bool isRestaurantOpen(dynamic openingHours) {
    if (openingHours == null) return false;

    // Handle Map format (Google Places API format)
    if (openingHours is Map<String, dynamic>) {
      final openNow = openingHours['open_now'] as bool?;
      return openNow ?? false;
    }

    // Handle String format - check if it contains "Open"
    if (openingHours is String) {
      final status = getOpeningStatus(openingHours);
      return status.toLowerCase().contains('open');
    }

    return false;
  }
}
