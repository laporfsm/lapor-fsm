import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
// Redundant dart:io removed

class TeknisiCompleteReportPage extends StatefulWidget {
  final String reportId;

  const TeknisiCompleteReportPage({super.key, required this.reportId});

  @override
  State<TeknisiCompleteReportPage> createState() =>
      _TeknisiCompleteReportPageState();
}

class _TeknisiCompleteReportPageState extends State<TeknisiCompleteReportPage> {
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedMedia = [];
  final List<Uint8List> _selectedMediaBytes = []; // For web compatibility
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (image != null) {
        if (_selectedMedia.length >= 3) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maksimal 3 foto/video')),
            );
          }
          return;
        }
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedMedia.add(image);
          _selectedMediaBytes.add(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        if (_selectedMedia.length >= 3) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maksimal 3 foto/video')),
            );
          }
          return;
        }
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
          _selectedMedia.add(video);
          _selectedMediaBytes.add(bytes);
        });
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
    }
  }

  void _showImageSourceDialog() {
    if (_selectedMedia.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maksimal 3 foto/video')));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(20),
            const Text(
              'Tambah Bukti Penanganan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: LucideIcons.camera,
                    label: 'Foto',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: LucideIcons.video,
                    label: 'Video',
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo(ImageSource.camera);
                    },
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: LucideIcons.image,
                    label: 'Galeri Foto',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: LucideIcons.film,
                    label: 'Galeri Video',
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.primaryColor),
            const Gap(8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCompletion() async {
    if (_selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto/video bukti penanganan wajib disertakan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final staffId = int.parse(user['id'].toString());

        // 1. Upload Media Files
        final List<String> uploadedUrls = [];
        for (var mediaFile in _selectedMedia) {
          final url = await reportService.uploadMedia(mediaFile);
          if (url != null) {
            uploadedUrls.add(url);
          }
        }

        if (uploadedUrls.isEmpty) {
          throw Exception('Gagal mengunggah bukti penanganan');
        }

        // 2. Complete Report
        await reportService.completeTask(
          widget.reportId,
          staffId,
          _notesController.text,
          uploadedUrls,
        );

        if (mounted) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.checkCircle2,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const Gap(16),
                  const Text(
                    'Penanganan Selesai!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Gap(8),
                  Text(
                    'Laporan telah ditandai selesai dan menunggu review dari Supervisor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Gap(24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/teknisi');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Kembali ke Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyelesaikan laporan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Selesaikan Penanganan'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: Colors.blue),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'Unggah foto sebagai bukti bahwa penanganan sudah selesai dilakukan.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Photo Upload Section
            const Text(
              'Foto Bukti Penanganan *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Gap(12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedMediaBytes.length < 3
                    ? _selectedMediaBytes.length + 1
                    : _selectedMediaBytes.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  // Add Button
                  if (index == _selectedMediaBytes.length) {
                    return GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.plus,
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

                  // Media Thumbnail
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child:
                              _selectedMedia[index].name.toLowerCase().endsWith(
                                    '.mp4',
                                  ) ||
                                  _selectedMedia[index].name
                                      .toLowerCase()
                                      .endsWith('.mov')
                              ? const Center(
                                  child: Icon(
                                    LucideIcons.playCircle,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                )
                              : Image.memory(
                                  _selectedMediaBytes[index],
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
                          onTap: () {
                            setState(() {
                              _selectedMedia.removeAt(index);
                              _selectedMediaBytes.removeAt(index);
                            });
                          },
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

            // Notes Section
            const Text(
              'Catatan Penanganan (Opsional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Gap(12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Tuliskan catatan terkait penanganan yang dilakukan...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const Gap(32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitCompletion,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(LucideIcons.checkCircle2),
                label: Text(
                  _isSubmitting ? 'Mengirim...' : 'Selesaikan Laporan',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }
}
