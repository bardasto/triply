import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utilities for map operations
class MapUtils {
  /// Dark map style JSON
  static const String darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#212121"}]
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#212121"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#181818"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#616161"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#2c2c2c"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8a8a8a"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [{"color": "#373737"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#3c3c3c"}]
    },
    {
      "featureType": "road.highway.controlled_access",
      "elementType": "geometry",
      "stylers": [{"color": "#4e4e4e"}]
    },
    {
      "featureType": "road.local",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#616161"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#000000"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#3d3d3d"}]
    }
  ]
  ''';

  /// Fit map camera to show all markers
  static void fitMapToMarkers(
    GoogleMapController? controller,
    List<Map<String, dynamic>> restaurants,
  ) {
    if (restaurants.isEmpty || controller == null) return;

    double? minLat, maxLat, minLng, maxLng;

    for (var restaurant in restaurants) {
      final lat = (restaurant['latitude'] as num?)?.toDouble();
      final lng = (restaurant['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) continue;

      minLat = minLat == null ? lat : (lat < minLat ? lat : minLat);
      maxLat = maxLat == null ? lat : (lat > maxLat ? lat : maxLat);
      minLng = minLng == null ? lng : (lng < minLng ? lng : minLng);
      maxLng = maxLng == null ? lng : (lng > maxLng ? lng : maxLng);
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  /// Get initial camera position from restaurants
  static LatLng getInitialPosition(List<Map<String, dynamic>> restaurants) {
    if (restaurants.isEmpty) {
      return const LatLng(48.8566, 2.3522); // Paris default
    }

    final first = restaurants[0];
    final lat = (first['latitude'] as num?)?.toDouble() ?? 48.8566;
    final lng = (first['longitude'] as num?)?.toDouble() ?? 2.3522;
    return LatLng(lat, lng);
  }

  /// Copy address to clipboard
  static void copyAddress(BuildContext context, String? address) {
    if (address != null && address.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: address));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Copy GPS coordinates to clipboard
  static void copyCoordinates(BuildContext context, double lat, double lng) {
    final coordinates = '$lat, $lng';
    Clipboard.setData(ClipboardData(text: coordinates));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS coordinates copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Open website in browser
  static Future<void> openWebsite(BuildContext context, String? website) async {
    if (website == null || website.isEmpty) return;

    final url = Uri.parse(website);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open website')),
        );
      }
    }
  }

  /// Open directions to restaurant
  static Future<void> openDirections(BuildContext context, double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open directions')),
        );
      }
    }
  }

  /// Open in Apple Maps
  static Future<void> openInAppleMaps(BuildContext context, double lat, double lng) async {
    final url = Uri.parse('http://maps.apple.com?ll=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Apple Maps')),
        );
      }
    }
  }

  /// Open in Google Maps
  static Future<void> openInGoogleMaps(BuildContext context, double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }
}
