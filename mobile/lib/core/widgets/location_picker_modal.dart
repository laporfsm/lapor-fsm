import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';

class LocationPickerModal extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const LocationPickerModal({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  late double _latitude;
  late double _longitude;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_latitude, _longitude),
                initialZoom: 17,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    setState(() {
                      _latitude = position.center.latitude;
                      _longitude = position.center.longitude;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.laporfsm.mobile',
                ),
              ],
            ),

            // Fixed Center Marker
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 35), // Offset for pin point
                child: Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 50,
                ),
              ),
            ),

            // Top Bar
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const Gap(16),
                    const Expanded(
                      child: Text(
                        'Pilih Lokasi Kejadian',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Confirm Button
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 16, color: AppTheme.primaryColor),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            'Lat: ${_latitude.toStringAsFixed(6)}, Lng: ${_longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, LatLng(_latitude, _longitude));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Konfirmasi Lokasi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
