import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/services/auth_service.dart';

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
  List<Map<String, dynamic>> _rejectedReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRejectedReports();
  }

  Future<void> _fetchRejectedReports() async {
    setState(() => _isLoading = true);
    try {
      // Assuming 'ditolak' status for rejected reports
      final reports = await reportService.getStaffReports(
        role: 'supervisor',
        status: 'ditolak',
      );
      if (mounted) {
        setState(() {
          _rejectedReports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error fetching rejected reports: $e');
      }
    }
  }

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
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rejectedReports.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchRejectedReports,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _rejectedReports.length,
                itemBuilder: (context, index) {
                  return _buildRejectedReportCard(_rejectedReports[index]);
                },
              ),
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
    // Helper to safely get string values
    String getStr(String key) => report[key]?.toString() ?? '-';
    bool isEmergency =
        report['isEmergency'] == true || report['isEmergency'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(color: Colors.red.shade100, width: 1),
      ),
      child: Column(
        children: [
          // Emergency Banner
          if (isEmergency)
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
                        getStr('category'),
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
                  getStr('title'),
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
                      getStr('location'),
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
                      getStr(
                        'reporterName',
                      ), // reporter -> reporterName as per typical API
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
                            'Ditolak oleh ${getStr('rejectedBy')}',
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
                        'Alasan: "${getStr('rejectionReason')}"', // Ensure backend sends rejectionReason
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
                          backgroundColor: AppTheme.supervisorColor,
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
              backgroundColor: AppTheme.supervisorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kembalikan'),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveReport(Map<String, dynamic> report) async {
    final user = await AuthService().getCurrentUser();
    final staffId = int.tryParse(user?['id']?.toString() ?? '0') ?? 0;

    final success = await reportService.archiveRejectedReport(
      report['id'].toString(),
      staffId,
    );
    if (!mounted) return;

    if (success) {
      setState(() {
        _rejectedReports.removeWhere((r) => r['id'] == report['id']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan "${report['title']}" telah diarsipkan'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengarsipkan laporan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _returnToQueue(Map<String, dynamic> report) async {
    final user = await AuthService().getCurrentUser();
    final staffId = int.tryParse(user?['id']?.toString() ?? '0') ?? 0;

    final success = await reportService.returnReportToQueue(
      report['id'].toString(),
      staffId,
    );
    if (!mounted) return;

    if (success) {
      setState(() {
        _rejectedReports.removeWhere((r) => r['id'] == report['id']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan dikembalikan ke antrian'),
          backgroundColor: AppTheme.supervisorColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengembalikan laporan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
