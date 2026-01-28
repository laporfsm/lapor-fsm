import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';

class CreateReportPage extends StatefulWidget {
  final String category;
  final bool isEmergency;

  const CreateReportPage({
    super.key,
    required this.category,
    this.isEmergency = false,
  });

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Controllers
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();

  final _locationDetailController = TextEditingController(); // New Controller
  final _notesController = TextEditingController();

  // State
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _selectedImagesBytes = []; // For web compatibility
  String? _selectedBuilding;
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  // Data gedung FSM
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
    'Kantin',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    // Simulate GPS fetch (real implementation uses geolocator)
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _latitude = -6.998576; // Mock: FSM Undip coordinates
        _longitude = 110.423188;
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _imagePicker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 80,
        );

        if (images.isNotEmpty) {
          for (var image in images) {
            if (_selectedImages.length >= 3) break;
            final bytes = await image.readAsBytes();
            setState(() {
              _selectedImages.add(image);
              _selectedImagesBytes.add(bytes);
            });
          }
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 80,
        );
        if (image != null) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImages.add(image);
            _selectedImagesBytes.add(bytes);
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _selectedImagesBytes.removeAt(index);
    });
  }

  void _showImageSourceDialog() {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maksimal 3 foto')));
      return;
    }

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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti foto wajib disertakan!')),
      );
      return;
    }

    if (_selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih lokasi gedung terlebih dahulu!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate API call
    debugPrint("Submitting Report:");
    debugPrint("Building: $_selectedBuilding");
    debugPrint("Detail Lokasi: ${_locationDetailController.text}");

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSubmitting = false);
      context.go('/report-success');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEmergency ? "Lapor Darurat" : "Buat Laporan"),
        backgroundColor: widget.isEmergency
            ? AppTheme.emergencyColor
            : Colors.white,
        foregroundColor: widget.isEmergency ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.isEmergency
                      ? Colors.red.shade100
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isEmergency ? LucideIcons.siren : LucideIcons.info,
                      size: 16,
                      color: widget.isEmergency ? Colors.red : Colors.blue,
                    ),
                    const Gap(8),
                    Text(
                      widget.category.toUpperCase(),
                      style: TextStyle(
                        color: widget.isEmergency ? Colors.red : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(24),

              // Photo Upload Section
              const Text(
                "Bukti Foto/Video *",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Text(
                "Maksimal 3 foto",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Gap(8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImagesBytes.length < 3
                      ? _selectedImagesBytes.length + 1
                      : _selectedImagesBytes.length,
                  separatorBuilder: (context, index) => const Gap(12),
                  itemBuilder: (context, index) {
                    // Add Button
                    if (index == _selectedImagesBytes.length) {
                      return BouncingButton(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.camera,
                                size: 32,
                                color: Colors.grey.shade400,
                              ),
                              const Gap(8),
                              Text(
                                "Tambah",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Image Thumbnail
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            _selectedImagesBytes[index],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: BouncingButton(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.x,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Gap(24),

              // Subject
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: "Subjek Laporan *",
                  hintText: "Contoh: AC Bocor di Ruang E102",
                  helperText: "Tuliskan deskripsi singkat masalah",
                ),
                validator: (value) =>
                    value!.isEmpty ? "Subjek tidak boleh kosong" : null,
              ),
              const Gap(16),

              // Building Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedBuilding,
                decoration: const InputDecoration(
                  labelText: "Pilih Lokasi *",
                  prefixIcon: Icon(LucideIcons.building),
                ),
                items: _buildings
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedBuilding = value),
                validator: (value) => value == null ? "Pilih gedung" : null,
              ),
              const Gap(16),

              // Location Detail (New)
              TextFormField(
                controller: _locationDetailController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: "Detail Lokasi (Opsional)",
                  hintText: "Contoh: Lt 2, Ruang 204",
                  helperText: "Lantai atau nama ruangan spesifik",
                  prefixIcon: Icon(LucideIcons.mapPin),
                ),
              ),
              const Gap(16),

              // Map Preview - Interactive
              const Text(
                "Lokasi *",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Gap(4),
              Text(
                'Geser peta untuk menyesuaikan lokasi',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Gap(8),
              if (_latitude != null &&
                  _longitude != null &&
                  !_isFetchingLocation)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
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
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.laporfsm.mobile',
                            ),
                          ],
                        ),
                        // Center marker (fixed position)
                        const Center(
                          child: Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        // Location info overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            color: Colors.black.withOpacity(0.7),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const Gap(6),
                                Expanded(
                                  child: Text(
                                    'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _fetchCurrentLocation,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          LucideIcons.locate,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        Gap(4),
                                        Text(
                                          'Reset',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Drag hint overlay
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.move,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                Gap(4),
                                Text(
                                  'Geser peta',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
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
              else
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isFetchingLocation) ...[
                          const CircularProgressIndicator(),
                          const Gap(8),
                          const Text('Mendeteksi lokasi...'),
                        ] else ...[
                          const Icon(
                            LucideIcons.mapPin,
                            size: 32,
                            color: Colors.grey,
                          ),
                          const Gap(8),
                          const Text('Lokasi tidak tersedia'),
                          TextButton(
                            onPressed: _fetchCurrentLocation,
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const Gap(16),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Deskripsi Detail *",
                  hintText:
                      "Jelaskan kronologi atau kondisi kerusakan secara detail...",
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    value!.isEmpty ? "Deskripsi tidak boleh kosong" : null,
              ),
              const Gap(16),

              // Additional Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Catatan Tambahan (Opsional)",
                  hintText: "Informasi tambahan jika ada...",
                  alignLabelWithHint: true,
                ),
              ),

              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: BouncingButton(
                  onTap: _isSubmitting ? null : _submitReport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ), // Match standard button height
                    decoration: BoxDecoration(
                      color: widget.isEmergency
                          ? AppTheme.emergencyColor
                          : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(
                        24,
                      ), // Match standard rounded corners for buttons/badges
                      boxShadow: [
                        BoxShadow(
                          color:
                              (widget.isEmergency
                                      ? AppTheme.emergencyColor
                                      : AppTheme.primaryColor)
                                  .withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "KIRIM LAPORAN",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
