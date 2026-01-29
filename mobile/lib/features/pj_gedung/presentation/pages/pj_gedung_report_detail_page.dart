import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/models/report_log.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/data/mock_report_data.dart';

class PJGedungReportDetailPage extends StatefulWidget {
  final String reportId;

  const PJGedungReportDetailPage({super.key, required this.reportId});

  @override
  State<PJGedungReportDetailPage> createState() =>
      _PJGedungReportDetailPageState();
}

class _PJGedungReportDetailPageState extends State<PJGedungReportDetailPage> {
  Report? _report;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
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

  void _handleVerification(bool approve) async {
    if (_report == null) return;
    setState(() => _isProcessing = true);

    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final staffId = user['id'];
        bool success = false;
        
        if (approve) {
          success = await reportService.verifyReport(_report!.id, staffId, role: 'pj');
        } else {
          success = await reportService.rejectReport(_report!.id, staffId, 'Ditolak oleh PJ Gedung');
        }

        if (success && mounted) {
          await _loadReport(); // Reload to get updated status and logs
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(approve ? 'Laporan berhasil diverifikasi.' : 'Laporan ditolak.'),
              backgroundColor: approve ? Colors.green : Colors.red,
            ),
          );
          if (!approve) context.pop();
        }
      }
    } catch (e) {
      debugPrint('Error processing verification: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_report == null) {
      return const Scaffold(body: Center(child: Text('Laporan tidak ditemukan')));
    }

    return ReportDetailBase(
      report: _report!,
      viewerRole: UserRole.pjGedung,
      appBarColor: const Color(0xFF059669), // PJ Gedung Theme Color
      // Inject Action Buttons for PJ Gedung
      actionButtons: _buildActionButtons(),
    );
  }

  List<Widget>? _buildActionButtons() {
    final r = _report;
    if (r == null) return null;

    // Only show Verify/Reject for Pending reports that are NOT emergency
    // (Emergency reports bypass verification)
    if (r.status == ReportStatus.pending && !r.isEmergency) {
      return [
        OutlinedButton.icon(
          onPressed: _isProcessing ? null : () => _handleVerification(false),
          icon: const Icon(LucideIcons.xCircle),
          label: const Text('Tolak'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Colors.red),
            foregroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : () => _handleVerification(true),
          icon: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.checkCircle),
          label: _isProcessing
              ? const Text('Proses...')
              : const Text('Verifikasi'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: const Color(0xFFF59E0B), // PJ Color
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ];
    }
    return null;
  }
}
