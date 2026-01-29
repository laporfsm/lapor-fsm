import 'package:flutter/material.dart';
import 'package:mobile/features/report_common/domain/enums/user_role.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/admin/services/admin_service.dart';

class AdminReportDetailPage extends StatefulWidget {
  final String reportId;

  const AdminReportDetailPage({super.key, required this.reportId});

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage> {
  Report? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    try {
      final data = await reportService.getReportDetail(widget.reportId);
      if (data != null && mounted) {
        setState(() {
          _report = Report.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForceCloseDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Close Laporan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tindakan ini akan membatalkan proses yang sedang berjalan dan status laporan akan menjadi SELESAI. Harap berikan alasan.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan Penutupan',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();

              final success = await adminService.forceCloseReport(
                widget.reportId,
                reasonController.text,
              );

              if (success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Laporan berhasil ditutup paksa'),
                  ),
                );
                _fetchReport(); // Refresh
              } else {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Gagal menutup laporan')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tutup Paksa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_report == null) {
      return const Scaffold(
        body: Center(child: Text('Laporan tidak ditemukan')),
      );
    }

    final bool canForceClose =
        _report!.status != ReportStatus.selesai &&
        _report!.status != ReportStatus.ditolak &&
        _report!.status !=
            ReportStatus
                .approved; // Approved is final? No, approved is verified. Completed is 'selesai'.
    // Logic: Force close if strictly NOT selesai. Can force close from pending, assigned, working, etc.
    // 'approved' is Selesai? No, 'selesai' is completed. 'approved' is verified by PJ.

    return ReportDetailBase(
      report: _report!,
      viewerRole: UserRole.admin,
      actionButtons: canForceClose
          ? [
              ElevatedButton(
                onPressed: _showForceCloseDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Admin Force Close'),
              ),
            ]
          : null,
    );
  }
}
