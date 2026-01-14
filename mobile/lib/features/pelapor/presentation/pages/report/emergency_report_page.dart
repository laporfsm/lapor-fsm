import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

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
  String? _selectedBuilding;
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  // Stopwatch for timer display
  final Stopwatch _stopwatch = Stopwatch();
  int _elapsedSeconds = 0;

  final List<String> _buildings = [
    'Gedung A - Dekanat',
    'Gedung B - Matematika',
    'Gedung C - Fisika',
    'Gedung D - Kimia',
    'Gedung E - Biologi',
    'Gedung F - Statistika',
    'Gedung G - Informatika',
    'Gedung H - Lab Terpadu',
    'Area Outdoor / Taman',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _startTimer();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _updateTimer();
  }

  void _updateTimer() {
    if (!mounted) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _stopwatch.isRunning) {
        setState(() => _elapsedSeconds = _stopwatch.elapsed.inSeconds);
        _updateTimer();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
        setState(() => _selectedImage = image);
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
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto bukti wajib disertakan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _stopwatch.stop();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isSubmitting = false);
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
        actions: [
          // Timer display
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.clock, size: 16, color: Colors.white),
                const Gap(6),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                              color: _selectedImage != null ? Colors.green : Colors.grey.shade300,
                              width: _selectedImage != null ? 3 : 1,
                            ),
                            image: _selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(File(_selectedImage!.path)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _selectedImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.camera, size: 48, color: Colors.grey.shade400),
                                    const Gap(8),
                                    Text("Ketuk untuk foto", style: TextStyle(color: Colors.grey.shade500)),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    icon: const CircleAvatar(
                                      backgroundColor: Colors.red,
                                      child: Icon(LucideIcons.x, color: Colors.white, size: 16),
                                    ),
                                    onPressed: () => setState(() => _selectedImage = null),
                                  ),
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
                        value: _selectedBuilding,
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
                          height: 150,
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
                                    interactionOptions: const InteractionOptions(
                                      flags: InteractiveFlag.none, // Disable interactions for preview
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.laporfsm.mobile',
                                    ),
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: LatLng(_latitude!, _longitude!),
                                          width: 40,
                                          height: 40,
                                          child: const Icon(
                                            Icons.location_pin,
                                            color: Colors.red,
                                            size: 40,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // Location info overlay
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    color: Colors.black.withOpacity(0.6),
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
                                        const Icon(LucideIcons.check, color: Colors.green, size: 14),
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
