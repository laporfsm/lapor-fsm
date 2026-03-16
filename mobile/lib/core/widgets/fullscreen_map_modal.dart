import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fullscreen map modal with interactive controls
class FullscreenMapModal extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String locationName;
  final LatLng? technicianLatLng;
  final LatLng? reporterLatLng;

  const FullscreenMapModal({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.technicianLatLng,
    this.reporterLatLng,
  });

  void _openInGoogleMaps() async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportPos = LatLng(latitude, longitude);
    final markers = <Marker>[];

    // 1. Report/Pelapor Marker
    markers.add(
      Marker(
        point: reporterLatLng ?? reportPos,
        width: 70,
        height: 80,
        child: _buildMarkerIcon(
          icon: LucideIcons.user,
          color: AppTheme.emergencyColor,
          label: 'Pelapor',
        ),
      ),
    );

    // 2. Technician Marker
    if (technicianLatLng != null) {
      markers.add(
        Marker(
          point: technicianLatLng!,
          width: 70,
          height: 80,
          child: _buildMarkerIcon(
            icon: LucideIcons.wrench,
            color: Colors.blue,
            label: 'Teknisi',
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            // Full screen map
            FlutterMap(
              options: MapOptions(
                initialCenter: reportPos,
                initialZoom: 17,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.laporfsm.mobile',
                ),
                MarkerLayer(markers: markers),
              ],
            ),

            // Top bar with close button and location name
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.arrowLeft),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi Laporan',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            locationName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button to open in Google Maps
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: _openInGoogleMaps,
                icon: const Icon(LucideIcons.navigation),
                label: const Text('Buka di Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerIcon({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Icon(icon, color: color, size: 30),
      ],
    );
  }
}
