import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';

/// Collection of dialog builders for TripDetails interactions.
class TripDetailsDialogs {
  TripDetailsDialogs._();

  /// Show delete place confirmation dialog
  static Future<bool> showDeleteConfirmation(
    BuildContext context, {
    required Map<String, dynamic> place,
    required bool isDark,
  }) async {
    final theme = TripDetailsTheme.of(isDark);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.backgroundColor,
            title: Text('Delete Place?',
                style: TextStyle(color: theme.textPrimary)),
            content: Text(
              'Are you sure you want to remove "${place['name']}" from the itinerary?',
              style: TextStyle(color: theme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    Text('Cancel', style: TextStyle(color: theme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show delete restaurant confirmation dialog
  static Future<bool> showDeleteRestaurantConfirmation(
    BuildContext context, {
    required Map<String, dynamic> restaurant,
    required bool isDark,
  }) async {
    final theme = TripDetailsTheme.of(isDark);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.backgroundColor,
            title: Text('Delete Restaurant?',
                style: TextStyle(color: theme.textPrimary)),
            content: Text(
              'Are you sure you want to remove "${restaurant['name']}" from the itinerary?',
              style: TextStyle(color: theme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    Text('Cancel', style: TextStyle(color: theme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show edit place dialog
  static void showEditPlaceDialog(
    BuildContext context, {
    required Map<String, dynamic> place,
    required bool isDark,
    required Function(String name, int? duration) onSave,
  }) {
    final theme = TripDetailsTheme.of(isDark);

    final nameController = TextEditingController(text: place['name']);
    final durationController = TextEditingController(
      text: place['duration_minutes']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundColor,
        title: Text('Edit Place', style: TextStyle(color: theme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: theme.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                style: TextStyle(color: theme.textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  labelStyle: TextStyle(color: theme.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final duration = durationController.text.isEmpty
                  ? null
                  : int.tryParse(durationController.text);
              onSave(nameController.text, duration);
              Navigator.pop(context);
            },
            child:
                const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  /// Show add place dialog
  static void showAddPlaceDialog(
    BuildContext context, {
    required bool isDark,
    required Function(String name, String category, int? duration) onAdd,
  }) {
    final theme = TripDetailsTheme.of(isDark);

    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundColor,
        title:
            Text('Add New Place', style: TextStyle(color: theme.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Place Name',
                  labelStyle: TextStyle(color: theme.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: theme.backgroundColor,
                style: TextStyle(color: theme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: theme.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                ),
                items: ['attraction', 'breakfast', 'lunch', 'dinner']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  categoryController.text = value ?? 'attraction';
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                style: TextStyle(color: theme.textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  labelStyle: TextStyle(color: theme.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a place name'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final duration = durationController.text.isEmpty
                  ? null
                  : int.tryParse(durationController.text);
              final category = categoryController.text.isEmpty
                  ? 'attraction'
                  : categoryController.text;

              onAdd(nameController.text, category, duration);
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
