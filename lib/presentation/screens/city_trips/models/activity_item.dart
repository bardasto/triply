import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Model representing an activity filter item.
class ActivityItem {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const ActivityItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Predefined list of all available activities.
class ActivityItems {
  ActivityItems._();

  static const List<ActivityItem> all = [
    ActivityItem(
      id: 'cycling',
      label: 'Cycling',
      icon: PhosphorIconsBold.bicycle,
      color: Color(0xFFA8E6CF),
    ),
    ActivityItem(
      id: 'beach',
      label: 'Beach',
      icon: PhosphorIconsBold.island,
      color: Color(0xFF87CEEB),
    ),
    ActivityItem(
      id: 'skiing',
      label: 'Skiing',
      icon: PhosphorIconsBold.personSimpleSki,
      color: Color(0xFFB8D4E8),
    ),
    ActivityItem(
      id: 'mountains',
      label: 'Mountains',
      icon: PhosphorIconsBold.mountains,
      color: Color(0xFFD4D4D4),
    ),
    ActivityItem(
      id: 'hiking',
      label: 'Hiking',
      icon: PhosphorIconsBold.personSimpleHike,
      color: Color(0xFF98D8C8),
    ),
    ActivityItem(
      id: 'sailing',
      label: 'Sailing',
      icon: PhosphorIconsBold.sailboat,
      color: Color(0xFF7FCDCD),
    ),
    ActivityItem(
      id: 'desert',
      label: 'Desert',
      icon: PhosphorIconsBold.cactus,
      color: Color(0xFFFDD17B),
    ),
    ActivityItem(
      id: 'camping',
      label: 'Camping',
      icon: PhosphorIconsBold.tipi,
      color: Color(0xFFD4A574),
    ),
    ActivityItem(
      id: 'city',
      label: 'City',
      icon: PhosphorIconsBold.city,
      color: Color(0xFFB8B8B8),
    ),
    ActivityItem(
      id: 'wellness',
      label: 'Wellness',
      icon: PhosphorIconsBold.personSimpleTaiChi,
      color: Color(0xFFDDA0DD),
    ),
    ActivityItem(
      id: 'road_trip',
      label: 'Road Trip',
      icon: PhosphorIconsBold.roadHorizon,
      color: Color(0xFFFFC8A2),
    ),
  ];

  static const Map<String, String> activityNames = {
    'cycling': 'Cycling',
    'beach': 'Beach',
    'skiing': 'Skiing',
    'mountains': 'Mountains',
    'hiking': 'Hiking',
    'sailing': 'Sailing',
    'desert': 'Desert',
    'camping': 'Camping',
    'city': 'City',
    'wellness': 'Wellness',
    'road_trip': 'Road Trip',
  };

  static String getName(String activityType) {
    return activityNames[activityType.toLowerCase()] ?? activityType;
  }
}
