import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/theme.dart';
import 'package:mobile/features/supervisor/presentation/pages/supervisor_shell_page.dart';

/// Halaman untuk Supervisor mereview laporan yang ditolak oleh Teknisi.
/// Supervisor dapat:
/// 1. Mengarsipkan laporan sebagai "ditolak"
/// 2. Membatalkan penolakan dan mengembalikan ke antrian teknisi
class SupervisorRejectedReportsPage extends StatefulWidget {
  const SupervisorRejectedReportsPage({super.key});

  @override
  State<SupervisorRejectedReportsPage> createState() =>
      _SupervisorRejectedReportsPageState();
}

class _SupervisorRejectedReportsPageState
    extends State<SupervisorRejectedReportsPage> {
  // TODO: [BACKEND] Fetch rejected reports from API
  final List<Map<String, dynamic>> _rejectedReports = [
    {
      'id': 101,
      'title': 'Atap Bocor di Koridor',
      'category': 'Sipil & Bangunan',
      'building': 'Gedung B, Lt 2',
      'reporter': 'Ahmad Fauzi',
      'reportedAt': DateTime.now().subtract(const Duration(days: 1)),
      'rejectedBy': 'Budi Teknisi',
      'rejectedAt': DateTime.now().subtract(const Duration(hours: 2)),
      'rejectionReason':
          'Memerlukan alat berat dan koordinasi dengan pihak ketiga. Bukan kapasitas teknisi internal.',
      'isEmergency': false,
    },
    {
      'id': 102,
      'title': 'Kerusakan Lift Barang',
      'category': 'Kelistrikan',
      'building': 'Gedung C',
      'reporter': 'Siti Rahayu',
      'reportedAt': DateTime.now().subtract(const Duration(days: 2)),
      'rejectedBy': 'Andi Teknisi',
      'rejectedAt': DateTime.now().subtract(const Duration(hours: 5)),
      'rejectionReason':
          'Lift memerlukan teknisi khusus dari vendor. Tidak bisa ditangani internal.',
      'isEmergency': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Laporan Ditolak'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
      ),
      body: _rejectedReports.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rejectedReports.length,
              itemBuilder: (context, index) {
                return _buildRejectedReportCard(_rejectedReports[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.checkCircle2, size: 64, color: Colors.grey.shade300),
          const Gap(16),
          Text(
            'Tidak ada laporan yang ditolak',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const Gap(8),
          Text(
            'Semua penolakan sudah ditinjau',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: Colors.red.shade100, width: 1),
      ),
      child: Column(
        children: [
          // Emergency Banner
          if (report['isEmergency'] == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.emergencyColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: Colors.white,
                    size: 14,
                  ),
                  Gap(6),
                  Text(
                    'LAPORAN DARURAT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.xCircle,
                            size: 12,
                            color: Colors.red.shade700,
                          ),
                          const Gap(4),
                          Text(
                            'Ditolak',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report['category'],
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(12),

                // Title
                Text(
                  report['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Gap(8),

                // Location & Reporter
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const Gap(4),
                    Text(
                      report['building'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const Gap(12),
                    Icon(
                      LucideIcons.user,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const Gap(4),
                    Text(
                      report['reporter'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                // Rejection Info Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.userX,
                            size: 14,
                            color: Colors.red.shade700,
                          ),
                          const Gap(6),
                          Text(
                            'Ditolak oleh ${report['rejectedBy']}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        'Alasan: "${report['rejectionReason']}"',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(16),

                // Action Buttons
                Row(
                  children: [
                    // Archive as Rejected
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showArchiveConfirmation(report),
                        icon: const Icon(LucideIcons.archive, size: 16),
                        label: const Text('Arsipkan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const Gap(12),
                    // Cancel Rejection - Return to Queue
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showReturnToQueueConfirmation(report),
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Kembalikan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: supervisorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showArchiveConfirmation(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arsipkan Laporan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laporan "${report['title']}" akan diarsipkan sebagai laporan yang ditolak.',
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: Colors.orange.shade700,
                    size: 18,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'Pelapor akan diberi notifikasi bahwa laporannya tidak dapat ditangani.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
              _archiveReport(report);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
  }

  void _showReturnToQueueConfirmation(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kembalikan ke Antrian?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laporan "${report['title']}" akan dikembalikan ke antrian Teknisi.',
            ),
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: Colors.blue.shade700, size: 18),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'Penolakan akan dibatalkan dan laporan bisa diambil teknisi lain.',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
              _returnToQueue(report);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: supervisorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kembalikan'),
          ),
        ],
      ),
    );
  }

  void _archiveReport(Map<String, dynamic> report) {
    // TODO: [BACKEND] API call to archive rejected report
    // - Update report status to 'archived_rejected'
    // - Send notification to reporter
    setState(() {
      _rejectedReports.removeWhere((r) => r['id'] == report['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Laporan "${report['title']}" telah diarsipkan'),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  void _returnToQueue(Map<String, dynamic> report) {
    // TODO: [BACKEND] API call to return report to queue
    // - Update report status back to 'pending' or 'verifikasi'
    // - Clear rejection info
    // - Notify technicians of available report
    setState(() {
      _rejectedReports.removeWhere((r) => r['id'] == report['id']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Laporan "${report['title']}" dikembalikan ke antrian'),
        backgroundColor: supervisorColor,
      ),
    );
  }
}
