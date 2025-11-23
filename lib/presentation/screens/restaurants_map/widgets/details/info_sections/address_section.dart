import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../utils/map_utils.dart';

/// Address Section widget with options menu
class AddressSection extends StatelessWidget {
  final String address;
  final double lat;
  final double lng;

  const AddressSection({
    super.key,
    required this.address,
    required this.lat,
    required this.lng,
  });

  void _showAddressOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C).withValues(alpha: 0.99),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOptionTile(
                  context,
                  icon: Icons.content_copy,
                  title: 'Copy address',
                  onTap: () {
                    Navigator.pop(context);
                    MapUtils.copyAddress(context, address);
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.gps_fixed,
                  title: 'Copy GPS coordinates',
                  onTap: () {
                    Navigator.pop(context);
                    MapUtils.copyCoordinates(context, lat, lng);
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.map,
                  title: 'Open in Apple Maps',
                  onTap: () {
                    Navigator.pop(context);
                    MapUtils.openInAppleMaps(context, lat, lng);
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.map_outlined,
                  title: 'Open in Google Maps',
                  onTap: () {
                    Navigator.pop(context);
                    MapUtils.openInGoogleMaps(context, lat, lng);
                  },
                ),
                const Divider(height: 1),
                _buildOptionTile(
                  context,
                  icon: Icons.close,
                  title: 'Cancel',
                  onTap: () => Navigator.pop(context),
                  isCancel: true,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isCancel = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isCancel ? Colors.red : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isCancel ? Colors.red : Colors.white,
          fontWeight: isCancel ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddressOptions(context),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                address,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.4),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
