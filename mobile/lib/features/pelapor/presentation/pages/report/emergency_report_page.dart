import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Simplified Emergency Report Page for faster reporting.
/// Minimal required fields: Photo + Location (auto-detected).
class EmergencyReportPage extends StatefulWidget {
  const EmergencyReportPage({super.key});

  @override
  State<EmergencyReportPage> createState() => _EmergencyReportPageState();
}

class _EmergencyReportPageState extends State<EmergencyReportPage> {
  final _imagePicker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes; // For web compatibility
  String? _selectedBuilding;
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  final List<String> _buildings = [
    'Gedung A',
    'Gedung B',
    'Gedung C',
    'Gedung D',
    'Gedung E',
    'Gedung F',
    'Gedung G',
    'Gedung H',
    'Gedung I',
    'Gedung J',
    'Gedung K',
    'Gedung L',
    'Parkiran Motor',
    'Parkiran Mobil',
    'Masjid',
    'Gedung Acintya Prasada',
    'Taman Rumah Kita',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _latitude = -6.998576;
        _longitude = 110.423188;
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitEmergencyReport() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto bukti wajib disertakan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSubmitting = false);
      // Navigate to success, timer will start in report detail
      context.go('/report-success');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDC2626),
      appBar: AppBar(
        title: const Text("LAPOR DARURAT"),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.white.withOpacity(0.1),
              child: const Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: Colors.white),
                  Gap(12),
                  Expanded(
                    child: Text(
                      "Laporan darurat akan langsung diteruskan ke tim penanganan",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Section (Required)
                      const Text(
                        "1. Ambil Foto Bukti *",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Gap(8),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedImageBytes != null ? Colors.green : Colors.grey.shade300,
                              width: _selectedImageBytes != null ? 3 : 1,
                            ),
                          ),
                          child: _selectedImageBytes != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.memory(
                                        _selectedImageBytes!,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _selectedImage = null;
                                          _selectedImageBytes = null;
                                        }),
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.red,
                                          radius: 16,
                                          child: Icon(LucideIcons.x, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.camera, size: 48, color: Colors.grey.shade400),
                                    const Gap(8),
                                    Text("Ketuk untuk foto", style: TextStyle(color: Colors.grey.shade500)),
                                  ],
                                ),
                        ),
                      ),
                      const Gap(24),

                      // Location Section
                      const Text(
                        "2. Lokasi (Opsional)",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Gap(8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBuilding,
                        decoration: InputDecoration(
                          hintText: "Pilih gedung (opsional)",
                          prefixIcon: const Icon(LucideIcons.building),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _buildings.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (value) => setState(() => _selectedBuilding = value),
                      ),
                      const Gap(12),

                      // Map Preview
                      if (_latitude != null && _longitude != null && !_isFetchingLocation)
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(_latitude!, _longitude!),
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
                                // Center marker (fixed)
                                const Center(
                                  child: Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                                // Drag hint
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.move, color: Colors.white, size: 12),
                                        Gap(4),
                                        Text('Geser peta', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                                // Location info overlay
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    color: Colors.black.withOpacity(0.7),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.mapPin, color: Colors.white, size: 14),
                                        const Gap(6),
                                        Expanded(
                                          child: Text(
                                            'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                                            style: const TextStyle(color: Colors.white, fontSize: 10),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _fetchCurrentLocation,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(LucideIcons.locate, color: Colors.white, size: 12),
                                                Gap(4),
                                                Text('Reset', style: TextStyle(color: Colors.white, fontSize: 10)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_isFetchingLocation)
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                Gap(8),
                                Text('Mendeteksi lokasi...'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitEmergencyReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.send, size: 24),
                  label: Text(
                    _isSubmitting ? "MENGIRIM..." : "KIRIM LAPORAN DARURAT",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
