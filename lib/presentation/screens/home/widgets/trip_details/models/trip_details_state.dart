import 'package:flutter/material.dart';

/// Immutable state model for TripDetails.
/// Separates state from UI for better testability and maintainability.
class TripDetailsState {
  final int currentImageIndex;
  final bool isDescriptionExpanded;
  final Set<String> selectedPlaceIds;
  final List<String> filteredImages;
  final Map<int, bool> expandedDays;
  final List<Map<String, dynamic>> databaseRestaurants;
  final bool isLoadingRestaurants;
  final bool isClosing;
  final int currentTabIndex;

  const TripDetailsState({
    this.currentImageIndex = 0,
    this.isDescriptionExpanded = false,
    this.selectedPlaceIds = const {},
    this.filteredImages = const [],
    this.expandedDays = const {},
    this.databaseRestaurants = const [],
    this.isLoadingRestaurants = false,
    this.isClosing = false,
    this.currentTabIndex = 0,
  });

  /// Creates a copy with modified fields
  TripDetailsState copyWith({
    int? currentImageIndex,
    bool? isDescriptionExpanded,
    Set<String>? selectedPlaceIds,
    List<String>? filteredImages,
    Map<int, bool>? expandedDays,
    List<Map<String, dynamic>>? databaseRestaurants,
    bool? isLoadingRestaurants,
    bool? isClosing,
    int? currentTabIndex,
  }) {
    return TripDetailsState(
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
      isDescriptionExpanded:
          isDescriptionExpanded ?? this.isDescriptionExpanded,
      selectedPlaceIds: selectedPlaceIds ?? this.selectedPlaceIds,
      filteredImages: filteredImages ?? this.filteredImages,
      expandedDays: expandedDays ?? this.expandedDays,
      databaseRestaurants: databaseRestaurants ?? this.databaseRestaurants,
      isLoadingRestaurants: isLoadingRestaurants ?? this.isLoadingRestaurants,
      isClosing: isClosing ?? this.isClosing,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
    );
  }

  /// Check if any place is selected
  bool get hasSelectedPlaces => selectedPlaceIds.isNotEmpty;

  /// Check if a specific day is expanded
  bool isDayExpanded(int dayNumber) => expandedDays[dayNumber] ?? false;

  /// Check if a specific place is selected
  bool isPlaceSelected(String placeId) => selectedPlaceIds.contains(placeId);
}

/// Controller callbacks interface for dependency injection
abstract class TripDetailsCallbacks {
  void onImageChanged(int index);
  void onToggleDescription();
  void onTogglePlaceSelection(String placeId);
  void onClearPlaceSelection();
  void onToggleDayExpanded(int dayNumber);
  void onTabChanged(int index);
  void onDeletePlace(Map<String, dynamic> place);
  void onEditPlace(Map<String, dynamic> place);
  void onAddPlaceToDay(Map<String, dynamic> day);
  void onDeleteRestaurant(Map<String, dynamic> restaurant);
  void onReplaceRestaurant(Map<String, dynamic> restaurant);
  void onAddRestaurant(Map<String, dynamic> restaurant);
  void onBookTrip();
  void onClose();
}

/// Notifier for state changes using ValueNotifier pattern
class TripDetailsStateNotifier extends ValueNotifier<TripDetailsState> {
  TripDetailsStateNotifier([TripDetailsState? initialState])
      : super(initialState ?? const TripDetailsState());

  void updateImageIndex(int index) {
    value = value.copyWith(currentImageIndex: index);
  }

  void toggleDescription() {
    value = value.copyWith(isDescriptionExpanded: !value.isDescriptionExpanded);
  }

  void togglePlaceSelection(String placeId) {
    final newSet = Set<String>.from(value.selectedPlaceIds);
    if (newSet.contains(placeId)) {
      newSet.remove(placeId);
    } else {
      newSet.add(placeId);
    }
    value = value.copyWith(selectedPlaceIds: newSet);
  }

  void clearPlaceSelection() {
    value = value.copyWith(
      selectedPlaceIds: {},
      filteredImages: [],
      currentImageIndex: 0,
    );
  }

  void toggleDayExpanded(int dayNumber) {
    final newMap = Map<int, bool>.from(value.expandedDays);
    newMap[dayNumber] = !(newMap[dayNumber] ?? false);
    value = value.copyWith(expandedDays: newMap);
  }

  void updateTabIndex(int index) {
    value = value.copyWith(currentTabIndex: index);
  }

  void setFilteredImages(List<String> images) {
    value = value.copyWith(
      filteredImages: images,
      currentImageIndex: 0,
    );
  }

  void setLoadingRestaurants(bool loading) {
    value = value.copyWith(isLoadingRestaurants: loading);
  }

  void setDatabaseRestaurants(List<Map<String, dynamic>> restaurants) {
    value = value.copyWith(
      databaseRestaurants: restaurants,
      isLoadingRestaurants: false,
    );
  }

  void setClosing(bool closing) {
    value = value.copyWith(isClosing: closing);
  }
}
