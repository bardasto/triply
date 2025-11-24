/// Trip Details module exports.
///
/// Provides a modular architecture for displaying trip details in a bottom sheet.
///
/// Usage:
/// ```dart
/// import 'trip_details/trip_details.dart';
///
/// TripDetailsBottomSheet.show(
///   context,
///   trip: tripData,
///   isDarkMode: isDark,
/// );
/// ```
library trip_details;

// Main entry point
export 'trip_details_bottom_sheet.dart';

// Controller
export 'controller/trip_details_controller.dart';

// Models
export 'models/trip_details_state.dart';

// Theme
export 'theme/trip_details_theme.dart';

// Utils
export 'utils/trip_details_utils.dart';
export 'utils/restaurant_helpers.dart';

// Common widgets
export 'widgets/common/bounceable_button.dart';
export 'widgets/common/zoomable_image.dart';
export 'widgets/common/context_menu.dart';
export 'widgets/common/context_menu_action.dart';

// Header widgets
export 'widgets/header/sheet_drag_handle.dart';
export 'widgets/header/sheet_close_button.dart';

// Gallery widgets
export 'widgets/gallery/trip_details_image_gallery.dart';

// Content widgets
export 'widgets/content/trip_info_header.dart';
export 'widgets/content/trip_description_section.dart';
export 'widgets/content/trip_includes_section.dart';
export 'widgets/content/book_button.dart';

// Itinerary widgets
export 'widgets/itinerary/itinerary_section.dart';
export 'widgets/itinerary/itinerary_tab_bar.dart';
export 'widgets/itinerary/places_tab.dart';
export 'widgets/itinerary/restaurants_tab.dart';
export 'widgets/itinerary/day_card.dart';
export 'widgets/itinerary/place_card.dart';
export 'widgets/itinerary/restaurant_card.dart';

// Dialogs
export 'widgets/dialogs/trip_details_dialogs.dart';
export 'widgets/dialogs/edit_place_sheet.dart';
export 'widgets/dialogs/place_selection_sheet.dart';
