import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../restaurants_map/fullscreen_restaurants_map.dart';
import 'controller/trip_details_controller.dart';
import 'theme/trip_details_theme.dart';
import 'widgets/content/book_button.dart';
import 'widgets/content/trip_description_section.dart';
import 'widgets/content/trip_includes_section.dart';
import 'widgets/content/trip_info_header.dart';
import 'widgets/dialogs/trip_details_dialogs.dart';
import 'widgets/dialogs/edit_place_sheet.dart';
import 'widgets/dialogs/place_selection_sheet.dart';
import 'widgets/gallery/trip_details_image_gallery.dart';
import 'widgets/header/blur_scroll_header.dart';
import 'widgets/header/sheet_close_button.dart';
import 'widgets/header/sheet_drag_handle.dart';
import 'widgets/itinerary/itinerary_section.dart';

/// Entry point for showing trip details bottom sheet.
/// Uses modular architecture with separated controller, theme, and widgets.
class TripDetailsBottomSheet {
  TripDetailsBottomSheet._();

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> trip,
    required bool isDarkMode,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TripDetailsContent(
        trip: trip,
        isDarkMode: isDarkMode,
      ),
    );
  }
}

class _TripDetailsContent extends StatefulWidget {
  final Map<String, dynamic> trip;
  final bool isDarkMode;

  const _TripDetailsContent({
    required this.trip,
    required this.isDarkMode,
  });

  @override
  State<_TripDetailsContent> createState() => _TripDetailsContentState();
}

class _TripDetailsContentState extends State<_TripDetailsContent>
    with SingleTickerProviderStateMixin {
  late TripDetailsController _controller;
  late TabController _tabController;
  late TripDetailsTheme _theme;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = TripDetailsController(
      trip: widget.trip,
      tabController: _tabController,
    );
    _theme = TripDetailsTheme.of(widget.isDarkMode);
    _controller.loadRestaurantsFromDatabase();

    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: _handleScrollNotification,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.85,
        minChildSize: 0.0,
        expand: false,
        snap: true,
        snapSizes: const [0.85],
        builder: (context, scrollController) {
          return Container(
            decoration: _theme.sheetDecoration,
            child: Stack(
              children: [
                _buildScrollableContent(scrollController),
                BlurScrollHeader(
                  scrollOffset: _scrollOffset,
                  isDark: widget.isDarkMode,
                ),
                const SheetDragHandle(),
                SheetCloseButton(onClose: () => Navigator.pop(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _handleScrollNotification(DraggableScrollableNotification notification) {
    if (notification.extent <= 0.05 &&
        !_controller.state.isClosing) {
      _controller.setClosing();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
    }
    return false;
  }

  Widget _buildScrollableContent(ScrollController scrollController) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(TripDetailsTheme.radiusSheet),
        topRight: Radius.circular(TripDetailsTheme.radiusSheet),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            setState(() {
              _scrollOffset = notification.metrics.pixels;
            });
          }
          return false;
        },
        child: CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
          SliverToBoxAdapter(
            child: ValueListenableBuilder(
              valueListenable: _controller.stateNotifier,
              builder: (context, state, _) {
                return TripDetailsImageGallery(
                  images: _controller.currentImages,
                  currentImageIndex: state.currentImageIndex,
                  pageController: _controller.pageController,
                  onPageChanged: _controller.onImageChanged,
                  isDark: widget.isDarkMode,
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _buildContentSections(),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildContentSections() {
    return ValueListenableBuilder(
      valueListenable: _controller.stateNotifier,
      builder: (context, state, _) {
        final includes = widget.trip['includes'] as List? ?? [];
        final description = widget.trip['description'] as String? ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            TripInfoHeader(trip: widget.trip, isDark: widget.isDarkMode),
            Divider(height: 1, color: _theme.dividerColor),
            TripDescriptionSection(
              description: description,
              isExpanded: state.isDescriptionExpanded,
              onToggle: () => setState(() => _controller.toggleDescription()),
              isDark: widget.isDarkMode,
            ),
            Divider(height: 1, color: _theme.dividerColor),
            if (includes.isNotEmpty) ...[
              TripIncludesSection(
                includes: includes,
                isDark: widget.isDarkMode,
              ),
              Divider(height: 1, color: _theme.dividerColor),
            ],
            ItinerarySection(
              itinerary: widget.trip['itinerary'] as List?,
              isDark: widget.isDarkMode,
              trip: widget.trip,
              tabController: _tabController,
              selectedPlaceIds: state.selectedPlaceIds,
              expandedDays: state.expandedDays,
              onClearSelection: () =>
                  setState(() => _controller.clearPlaceSelection()),
              onToggleDayExpanded: (dayNumber) =>
                  setState(() => _controller.toggleDayExpanded(dayNumber)),
              onAddPlaceToDay: _handleAddPlaceToDay,
              onEditPlace: _handleEditPlace,
              onDeletePlace: _handleDeletePlace,
              onReplacePlace: _handleReplacePlace,
              onToggleSelection: (placeId) =>
                  setState(() => _controller.togglePlaceSelection(placeId)),
              onReplaceRestaurant: _handleReplaceRestaurant,
              onDeleteRestaurant: _handleDeleteRestaurant,
              onViewAllRestaurantsOnMap: _handleViewAllRestaurants,
            ),
            const SizedBox(height: 20),
            BookButton(
              onBook: _handleBooking,
              isDark: widget.isDarkMode,
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  void _handleBooking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking functionality coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _handleAddPlaceToDay(Map<String, dynamic> day) {
    TripDetailsDialogs.showAddPlaceDialog(
      context,
      isDark: widget.isDarkMode,
      onAdd: (name, category, duration) {
        setState(() {
          _controller.addPlaceToDay(day, name, category, duration);
        });
      },
    );
  }

  void _handleEditPlace(Map<String, dynamic> place) {
    EditPlaceSheet.show(
      context,
      initialName: place['name'] as String? ?? '',
      initialDuration: place['duration_minutes'] as int?,
      isDark: widget.isDarkMode,
      onSave: (name, duration) {
        setState(() {
          _controller.editPlace(place, name, duration);
        });
      },
    );
  }

  Future<void> _handleDeletePlace(Map<String, dynamic> place) async {
    final confirm = await TripDetailsDialogs.showDeleteConfirmation(
      context,
      place: place,
      isDark: widget.isDarkMode,
    );

    if (!confirm) return;

    setState(() => _controller.deletePlace(place));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${place['name']} removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleReplacePlace(Map<String, dynamic> place) async {
    final city = widget.trip['city'] as String? ?? '';
    final category = place['category'] as String? ?? 'attraction';

    // Get all place IDs currently in the trip
    final excludeIds = _controller.getAllPlaceIdsInTrip();

    final selectedPlace = await PlaceSelectionSheet.show(
      context,
      city: city,
      category: category,
      excludePlaceIds: excludeIds,
      isDark: widget.isDarkMode,
    );

    if (selectedPlace != null && mounted) {
      setState(() {
        _controller.replacePlace(place, selectedPlace);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedPlace['name']} replaced ${place['name']}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteRestaurant(Map<String, dynamic> restaurant) async {
    final confirm = await TripDetailsDialogs.showDeleteRestaurantConfirmation(
      context,
      restaurant: restaurant,
      isDark: widget.isDarkMode,
    );

    if (!confirm) return;

    setState(() => _controller.deleteRestaurant(restaurant));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${restaurant['name']} removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleReplaceRestaurant(
      Map<String, dynamic> restaurant) async {
    final restaurantId =
        restaurant['poi_id']?.toString() ?? restaurant['name'];
    final availableRestaurants =
        _controller.getRestaurantsForReplacement(restaurantId);

    final selectedRestaurant =
        await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => FullscreenRestaurantsMap(
          restaurants: availableRestaurants,
          isDark: widget.isDarkMode,
          tripCity: widget.trip['city'] as String?,
          editingRestaurantId: restaurantId,
          onRestaurantSelected: (newRestaurant) {
            Navigator.of(context).pop(newRestaurant);
          },
        ),
      ),
    );

    if (selectedRestaurant != null && mounted) {
      setState(() {
        _controller.replaceRestaurant(restaurant, selectedRestaurant);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${selectedRestaurant['name']} replaced ${restaurant['name']}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _handleViewAllRestaurants() async {
    final availableRestaurants =
        _controller.getAvailableRestaurantsNotInTrip();

    final selectedRestaurant =
        await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => FullscreenRestaurantsMap(
          restaurants: availableRestaurants,
          isDark: widget.isDarkMode,
          tripCity: widget.trip['city'] as String?,
          onRestaurantSelected: (newRestaurant) {
            Navigator.of(context).pop(newRestaurant);
          },
        ),
      ),
    );

    if (selectedRestaurant != null && mounted) {
      setState(() {
        _controller.addRestaurant(selectedRestaurant);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedRestaurant['name']} added to trip'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }
}
