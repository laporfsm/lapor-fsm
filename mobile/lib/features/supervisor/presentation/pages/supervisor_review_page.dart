import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';

// Supervisor theme color
const Color _supervisorColor = Color(0xFF059669);

class SupervisorReviewPage extends StatefulWidget {
  final String reportId;

  const SupervisorReviewPage({super.key, required this.reportId});

  @override
  State<SupervisorReviewPage> createState() => _SupervisorReviewPageState();
}

class _SupervisorReviewPageState extends State<SupervisorReviewPage> {
  bool _isLoading = true;
  late Map<String, dynamic> _report;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _loadReport() {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _report = {
          'id': widget.reportId,
          'title': 'AC Mati di Lab Komputer',
          'description':
              'AC di Lab Komputer ruang 201 tidak menyala sejak pagi. Sudah dicoba restart tapi tetap tidak berfungsi.',
          'category': 'Kelistrikan',
          'building': 'Gedung G, Lt 2, Ruang 201',
          'imageUrl':
              'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400',
          'handlerMediaUrl':
              'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=400',
          'status': 'selesai',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
          'assignedAt': DateTime.now().subtract(
            const Duration(hours: 1, minutes: 45),
          ),
          'handledAt': DateTime.now().subtract(
            const Duration(hours: 1, minutes: 30),
          ),
          'completedAt': DateTime.now().subtract(const Duration(hours: 1)),
          'reporterName': 'Ahmad Fauzi',
          'reporterEmail': 'ahmad.fauzi@students.undip.ac.id',
          'teknisiName': 'Budi Teknisi',
          'handlerNotes':
              'AC sudah diperbaiki. Masalah pada kapasitor yang perlu diganti. Sudah berfungsi normal kembali.',
          'logs': [
            {
              'action': 'created',
              'time': DateTime.now().subtract(const Duration(hours: 2)),
              'notes': 'Laporan dibuat',
            },
            {
              'action': 'verified',
              'time': DateTime.now().subtract(
                const Duration(hours: 1, minutes: 45),
              ),
              'actor': 'Budi Teknisi',
              'notes': 'Laporan diverifikasi',
            },
            {
              'action': 'handling',
              'time': DateTime.now().subtract(
                const Duration(hours: 1, minutes: 30),
              ),
              'actor': 'Budi Teknisi',
              'notes': 'Mulai penanganan',
            },
            {
              'action': 'completed',
              'time': DateTime.now().subtract(const Duration(hours: 1)),
              'actor': 'Budi Teknisi',
              'notes': 'Penanganan selesai',
            },
          ],
        };
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _supervisorColor,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.arrowLeft,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(_report['imageUrl'], fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SELESAI - MENUNGGU REVIEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Gap(8),
                        Text(
                          _report['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duration Summary
                  _buildDurationCard(),
                  const Gap(16),

                  // Handler Proof
                  _buildProofCard(),
                  const Gap(16),

                  // Handler Notes
                  _buildNotesCard(),
                  const Gap(16),

                  // Report Details
                  _buildDetailsCard(),
                  const Gap(16),

                  // Timeline
                  _buildTimelineCard(),
                  const Gap(100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildDurationCard() {
    final duration = _report['completedAt'].difference(_report['handledAt']);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _supervisorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.timer,
              color: _supervisorColor,
              size: 24,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Durasi Penanganan',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  hours > 0 ? '$hours jam $minutes menit' : '$minutes menit',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Teknisi',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                _report['teknisiName'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProofCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.camera, size: 18, color: _supervisorColor),
              Gap(8),
              Text(
                'Bukti Penanganan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Gap(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _report['handlerMediaUrl'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                LucideIcons.messageSquare,
                size: 18,
                color: _supervisorColor,
              ),
              Gap(8),
              Text(
                'Catatan Teknisi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Gap(12),
          Text(
            _report['handlerNotes'],
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.fileText, size: 18, color: _supervisorColor),
              Gap(8),
              Text(
                'Detail Laporan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildDetailRow('Kategori', _report['category']),
          _buildDetailRow('Lokasi', _report['building']),
          _buildDetailRow('Pelapor', _report['reporterName']),
          _buildDetailRow('Email', _report['reporterEmail']),
          const Gap(8),
          Text(
            _report['description'],
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    final logs = _report['logs'] as List;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.clock, size: 18, color: _supervisorColor),
              Gap(8),
              Text('Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          ...logs.asMap().entries.map((entry) {
            final index = entry.key;
            final log = entry.value;
            final isLast = index == logs.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _supervisorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: Colors.grey.shade300,
                      ),
                  ],
                ),
                const Gap(12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['notes'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _formatDateTime(log['time']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showRecallDialog,
                icon: const Icon(LucideIcons.refreshCw),
                label: const Text('Panggil Ulang'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _approveReport,
                icon: const Icon(LucideIcons.checkCircle2),
                label: const Text('Setujui'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Panggil Ulang Teknisi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berikan alasan mengapa penanganan perlu diulang:'),
            const Gap(16),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan alasan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _recallTechnician();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Panggil Ulang'),
          ),
        ],
      ),
    );
  }

  void _recallTechnician() {
    // TODO: Call API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teknisi dipanggil kembali untuk penanganan ulang'),
        backgroundColor: Colors.orange,
      ),
    );
    context.pop();
  }

  void _approveReport() {
    // TODO: Call API
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
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
              'Laporan Disetujui!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Text(
              'Penanganan telah diverifikasi dan disetujui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/supervisor');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kembali ke Dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
