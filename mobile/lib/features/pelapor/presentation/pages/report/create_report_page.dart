import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
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
  
  // Controllers
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController(text: "Gedung E, Lantai 1 (Detected)"); // Mock Auto-location

  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate Network Request
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSubmitting = false);
      // Navigate to Success/Detail Page
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
              GestureDetector(
                onTap: () {
                  // Todo: Implement Camera Picker
                },
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.camera, size: 48, color: Colors.grey.shade400),
                      const Gap(12),
                      Text("Ketuk untuk ambil foto bukti", style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
              const Gap(24),

              // Inputs
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: "Subjek Laporan",
                  hintText: "Contoh: AC Bocor di R. E102",
                ),
                validator: (value) => value!.isEmpty ? "Subjek tidak boleh kosong" : null,
              ),
              const Gap(16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Deskripsi Detail",
                  hintText: "Jelaskan kronologi atau kondisi kerusakan...",
                  alignLabelWithHint: true,
                ),
                validator: (value) => value!.isEmpty ? "Deskripsi tidak boleh kosong" : null,
              ),
              const Gap(16),
              TextFormField(
                controller: _locationController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Lokasi Terdeteksi",
                  prefixIcon: const Icon(LucideIcons.mapPin),
                  suffixIcon: IconButton(
                    icon: const Icon(LucideIcons.refreshCw),
                    onPressed: () {}, // Refresh Location
                  ),
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
                    ? const CircularProgressIndicator(color: Colors.white)
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
