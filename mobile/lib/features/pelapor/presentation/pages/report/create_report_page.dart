import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/theme.dart';

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
  final _notesController = TextEditingController();
  
  // State
  XFile? _selectedImage;
  String? _selectedBuilding;
  double? _latitude;
  double? _longitude;
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;

  // Data gedung FSM
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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImage == null) {
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
        backgroundColor: widget.isEmergency ? AppTheme.emergencyColor : Colors.white,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isEmergency ? Colors.red.shade100 : Colors.blue.shade100,
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
              const Text("Bukti Foto/Video *", style: TextStyle(fontWeight: FontWeight.w600)),
              const Gap(8),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImage != null ? AppTheme.primaryColor : Colors.grey.shade300,
                      width: _selectedImage != null ? 2 : 1,
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
                            const Gap(12),
                            Text("Ketuk untuk ambil foto bukti", style: TextStyle(color: Colors.grey.shade500)),
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

              // Subject
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: "Subjek Laporan *",
                  hintText: "Contoh: AC Bocor di Ruang E102",
                  helperText: "Tuliskan deskripsi singkat masalah",
                ),
                validator: (value) => value!.isEmpty ? "Subjek tidak boleh kosong" : null,
              ),
              const Gap(16),
              
              // Building Selection
              DropdownButtonFormField<String>(
                value: _selectedBuilding,
                decoration: const InputDecoration(
                  labelText: "Lokasi Gedung *",
                  prefixIcon: Icon(LucideIcons.building),
                ),
                items: _buildings.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (value) => setState(() => _selectedBuilding = value),
                validator: (value) => value == null ? "Pilih gedung" : null,
              ),
              const Gap(16),
              
              // GPS Location
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mapPin, color: AppTheme.primaryColor),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Koordinat GPS", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _isFetchingLocation
                                ? "Mendeteksi lokasi..."
                                : _latitude != null
                                    ? "$_latitude, $_longitude"
                                    : "Lokasi tidak tersedia",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: _isFetchingLocation 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(LucideIcons.refreshCw),
                      onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Deskripsi Detail *",
                  hintText: "Jelaskan kronologi atau kondisi kerusakan secara detail...",
                  alignLabelWithHint: true,
                ),
                validator: (value) => value!.isEmpty ? "Deskripsi tidak boleh kosong" : null,
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
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isEmergency ? AppTheme.emergencyColor : AppTheme.primaryColor,
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text("KIRIM LAPORAN"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
