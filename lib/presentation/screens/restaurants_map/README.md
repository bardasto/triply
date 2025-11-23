# Restaurants Map Module - Architecture Documentation

## Overview
This module provides a fullscreen map view for displaying and interacting with restaurants from a trip. The codebase has been refactored following clean architecture principles with a clear separation of concerns.

## Directory Structure

```
lib/presentation/screens/restaurants_map/
├── fullscreen_restaurants_map.dart          # Main screen orchestrator
├── utils/                                   # Utility functions
│   ├── restaurant_formatters.dart          # Restaurant data formatting
│   ├── opening_hours_helper.dart           # Opening hours logic
│   └── map_utils.dart                      # Map operations & URL launchers
└── widgets/                                 # UI Components
    ├── common/                              # Reusable widgets
    │   ├── zoomable_image.dart             # Telegram-style zoomable image
    │   └── sticky_header_delegate.dart     # Sticky header implementations
    ├── map/                                 # Map-related widgets
    │   └── custom_marker_painter.dart      # Custom map marker creation
    ├── list/                                # Restaurant list widgets
    │   ├── restaurants_list_view.dart      # List view with filtering
    │   ├── restaurant_card.dart            # Individual restaurant card
    │   └── filters_row.dart                # Filter chips row
    └── details/                             # Restaurant details widgets
        ├── restaurant_details_sheet.dart   # Main details sheet
        ├── photo_gallery.dart              # Photo gallery with thumbnails
        ├── tabs_section.dart               # Overview/Menu/Reviews tabs
        ├── reviews_section.dart            # Ratings and reviews display
        └── info_sections/                   # Information sections
            ├── unified_info_block.dart     # Container for all info sections
            ├── opening_hours_section.dart  # Opening hours (expandable)
            ├── address_section.dart        # Address with map options
            ├── website_section.dart        # Website link
            ├── price_section.dart          # Price level display
            └── cuisine_section.dart        # Cuisine type display
```

## Key Components

### 1. Main Screen (`fullscreen_restaurants_map.dart`)
- **Purpose**: Orchestrates the map view and bottom sheet
- **Responsibilities**:
  - Map controller management
  - Marker creation and updates
  - Restaurant selection handling
  - Sheet animation control
- **Size**: ~300 lines (down from 2,765)

### 2. Utilities

#### `restaurant_formatters.dart`
Handles all restaurant data formatting:
- Price level conversion (int → "€€€")
- Cuisine types formatting
- Category labels, colors, and icons
- Image extraction from restaurant data

#### `opening_hours_helper.dart`
Manages opening hours logic:
- Status determination (Open/Closed)
- Weekday hours parsing
- Current time checking

#### `map_utils.dart`
Map and navigation utilities:
- Dark map style configuration
- Camera positioning
- Bounds calculation
- URL launching (Maps, websites)
- Clipboard operations

### 3. Widgets

#### Common Widgets
- **`zoomable_image.dart`**: Telegram-style pinch-to-zoom functionality
- **`sticky_header_delegate.dart`**: Sticky headers for lists

#### Map Widgets
- **`custom_marker_painter.dart`**: Creates custom markers with ratings using Canvas API

#### List Widgets
- **`restaurants_list_view.dart`**: Main list with filtering/sorting logic
- **`restaurant_card.dart`**: Individual restaurant display
- **`filters_row.dart`**: Horizontal filter chips

#### Details Widgets
- **`restaurant_details_sheet.dart`**: Main details view with tabs
- **`photo_gallery.dart`**: Swipeable photo gallery with thumbnails
- **`reviews_section.dart`**: Rating breakdown visualization
- **Info sections**: Modular information display components

## Design Patterns

### 1. Separation of Concerns
- **Presentation**: Widget composition and UI logic
- **Formatting**: Data transformation utilities
- **Business Logic**: Opening hours, filtering, sorting

### 2. Single Responsibility Principle
Each file has one clear purpose:
- Formatters only format data
- Helpers only contain helper logic
- Widgets only render UI

### 3. Composition over Inheritance
Widgets are composed from smaller, reusable components rather than using deep inheritance hierarchies.

### 4. Dependency Injection
Main screen injects dependencies (callbacks, data) into child widgets.

## Benefits of This Architecture

1. **Maintainability**: Each component is small and focused (50-400 lines vs 2,765)
2. **Testability**: Utilities and helpers can be unit tested independently
3. **Reusability**: Common widgets can be used across the app
4. **Readability**: Clear file structure makes code easy to navigate
5. **Scalability**: Easy to add new features without modifying existing code
6. **Performance**: Extracted widgets can be optimized independently

## Migration Guide

### Old Import
```dart
import 'package:travel_ai/presentation/screens/home/widgets/fullscreen_restaurants_map.dart';
```

### New Import
```dart
import 'package:travel_ai/presentation/screens/restaurants_map/fullscreen_restaurants_map.dart';
```

The API remains the same - no changes to constructor parameters or callbacks needed.

## Future Improvements

1. **State Management**: Consider adding BLoC/Riverpod for complex state
2. **Repository Pattern**: Extract data fetching to a repository layer
3. **Testing**: Add unit tests for utilities and widget tests for components
4. **Accessibility**: Add semantic labels and screen reader support
5. **Internationalization**: Extract strings to localization files
6. **Performance**: Implement virtual scrolling for large restaurant lists

## Code Metrics

- **Original file**: 2,765 lines
- **Refactored main**: ~300 lines (89% reduction)
- **Total files created**: 20
- **Average file size**: ~200 lines
- **No breaking changes**: Same public API

---

*Refactored following SOLID principles and Clean Architecture guidelines*
