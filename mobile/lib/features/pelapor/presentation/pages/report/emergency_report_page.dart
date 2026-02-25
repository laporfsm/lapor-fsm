import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/location_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/media_viewer_modal.dart';
import 'package:mobile/core/widgets/bouncing_button.dart';

/// Simplified Emergency Report Page for faster reporting.
/// Minimal required fields: Photo + Location (auto-detected).
class EmergencyReportPage extends StatefulWidget {
  const EmergencyReportPage({super.key});

  @override
  State<EmergencyReportPage> createState() => _EmergencyReportPageState();
}

class _EmergencyReportPageState extends State<EmergencyReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  final List<XFile> _selectedImages = [];
  final List<Uint8List> _selectedImagesBytes = []; // For web compatibility
  String? _selectedBuilding;
  final _locationDetailController = TextEditingController();
  final _titleController = TextEditingController(text: "Laporan Darurat");
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  // Fetched from API
  List<String> _buildings = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _fetchBuildings();
  }

  Future<void> _fetchBuildings() async {
    try {
      final buildings = await reportService.getLocations();
      if (mounted) {
        setState(() {
          _buildings = buildings.map((b) => b['name'] as String).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching buildings: $e');
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      final position = await locationService.getCurrentPosition();
      if (mounted && position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _imagePicker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 70,
        );

        if (images.isNotEmpty) {
          for (var image in images) {
            if (_selectedImages.length >= 3) break;
            final bytes = await image.readAsBytes();
            if (bytes.lengthInBytes > 50 * 1024 * 1024) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ukuran file ${image.name} melebihi 50MB'),
                  ),
                );
              }
              continue;
            }
            setState(() {
              _selectedImages.add(image);
              _selectedImagesBytes.add(bytes);
            });
          }
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 70,
        );
        if (image != null) {
          final bytes = await image.readAsBytes();
          if (bytes.lengthInBytes > 50 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ukuran file melebihi 50MB')),
              );
            }
            return;
          }
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

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        final bytes = await video.readAsBytes();
        if (bytes.lengthInBytes > 50 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ukuran video melebihi 50MB')),
            );
          }
          return;
        }
        setState(() {
          _selectedImages.add(video);
          _selectedImagesBytes.add(bytes);
        });
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  void _showImageSourceDialog() {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maksimal 3 foto/video')));
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
              leading: const Icon(LucideIcons.video),
              title: const Text('Rekam Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Pilih Foto dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.film),
              title: const Text('Pilih Video dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitEmergencyReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto bukti wajib disertakan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload Images
      List<String> mediaUrls = [];
      for (var image in _selectedImages) {
        final url = await reportService.uploadImage(image);
        if (url != null) mediaUrls.add(url);
      }

      // 2. Get 'Darurat' Category ID (Dynamic)
      String? emergencyCategoryId;
      try {
        final categories = await reportService.getCategories();
        final emergencyCat = categories.firstWhere(
          (c) => c['name'].toString().toLowerCase().contains('darurat'),
          orElse: () => categories.firstWhere(
            (c) => c['name'].toString().toLowerCase().contains('lainnya'),
            orElse: () => {'id': '1'}, // Fallback to ID 1 if mostly nothing
          ),
        );
        emergencyCategoryId = emergencyCat['id'].toString();
      } catch (e) {
        debugPrint('Error finding emergency category: $e');
      }

      // 0. Get current user
      final userAccount = await authService.getCurrentUser();
      final currentUserId = userAccount?['id'];

      // 3. Submit Report
      final result = await reportService.createReport(
        userId: currentUserId,
        title: _titleController.text,
        description: "LAPORAN DARURAT: ${_locationDetailController.text}",
        location: _selectedBuilding ?? "Lokasi Darurat",
        locationDetail: _locationDetailController.text,
        latitude: _latitude,
        longitude: _longitude,
        mediaUrls: mediaUrls,
        isEmergency: true,
        categoryId: emergencyCategoryId, // Auto-assign 'Darurat' category
        status: 'pending',
      );

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (result != null) {
          if (mounted) {
            context.go('/report-success');
          }
        } else {
          throw Exception('Gagal membuat laporan (API returned null)');
        }
      }
    } catch (e) {
      debugPrint('Error submitting emergency report: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim laporan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDC2626),
      appBar: AppBar(
        title: const Text(
          "LAPOR DARURAT",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFDC2626),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.white.withValues(alpha: 0.1),
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
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject / Title (New)
                        const Text(
                          "Judul / Subjek Laporan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(8),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: "Contoh: Kebakaran di Lab Kimia",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Subjek wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const Gap(24),

                        // Photo Section (Required)
                        const Text(
                          "1. Ambil Foto Bukti *",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Maksimal 3 foto/video (video Maks 50MB)",
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
                                return GestureDetector(
                                  onTap: _showImageSourceDialog,
                                  child: Container(
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                    child: GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          useSafeArea: true,
                                          backgroundColor: Colors.black,
                                          builder: (context) =>
                                              MediaViewerModal(
                                                mediaUrls: _selectedImages
                                                    .map((e) => e.path)
                                                    .toList(),
                                                initialIndex: index,
                                              ),
                                        );
                                      },
                                      child:
                                          _selectedImages[index].name
                                                  .toLowerCase()
                                                  .endsWith('.mp4') ||
                                              _selectedImages[index].name
                                                  .toLowerCase()
                                                  .endsWith('.mov')
                                          ? Container(
                                              width: 120,
                                              height: 120,
                                              color: Colors.black,
                                              child: const Center(
                                                child: Icon(
                                                  LucideIcons.playCircle,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                              ),
                                            )
                                          : Image.memory(
                                              _selectedImagesBytes[index],
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
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

                        // Location Section
                        const Text(
                          "2. Lokasi (Opsional)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBuilding,
                          decoration: InputDecoration(
                            labelText: "Pilih Lokasi (Opsional)",
                            hintText: "Pilih Lokasi",
                            prefixIcon: const Icon(LucideIcons.building),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _buildings
                              .map(
                                (b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(
                                    b,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedBuilding = value),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const Gap(12),

                        // Location Detail (New)
                        TextFormField(
                          controller: _locationDetailController,
                          maxLength: 50,
                          decoration: InputDecoration(
                            labelText: "Detail Lokasi (Opsional)",
                            hintText: "Contoh: Lt 2, Ruang 204",
                            prefixIcon: const Icon(LucideIcons.mapPin),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const Gap(12),

                        // Map Preview - Interactive
                        const Text(
                          "Lokasi *",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Gap(4),
                        Text(
                          'Geser peta untuk menyesuaikan lokasi',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
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
                              border: Border.all(
                                color: AppTheme
                                    .emergencyColor, // Use emergency color
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                children: [
                                  FlutterMap(
                                    options: MapOptions(
                                      initialCenter: LatLng(
                                        _latitude!,
                                        _longitude!,
                                      ),
                                      initialZoom: 17,
                                      onPositionChanged:
                                          (position, hasGesture) {
                                            if (hasGesture) {
                                              setState(() {
                                                _latitude =
                                                    position.center.latitude;
                                                _longitude =
                                                    position.center.longitude;
                                              });
                                            }
                                          },
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate:
                                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName:
                                            'com.laporfsm.mobile',
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
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: BouncingButton(
                  onTap: _isSubmitting ? null : _submitEmergencyReport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.emergencyColor,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  LucideIcons.send,
                                  size: 20,
                                  color: Color(0xFFDC2626),
                                ),
                                Gap(8),
                                Text(
                                  "KIRIM LAPORAN DARURAT",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                    ),
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
