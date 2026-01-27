import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/models/report_log.dart';
import 'package:mobile/core/data/mock_report_data.dart';

class PJGedungReportDetailPage extends StatefulWidget {
  final String reportId;

  const PJGedungReportDetailPage({super.key, required this.reportId});

  @override
  State<PJGedungReportDetailPage> createState() =>
      _PJGedungReportDetailPageState();
}

class _PJGedungReportDetailPageState extends State<PJGedungReportDetailPage> {
  late Report _report;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  void _loadReport() {
    // Simulate API call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _report = MockReportData.getReportOrDefault(widget.reportId);
          _isLoading = false;
        });
      }
    });
  }

  void _handleVerification(bool approve) async {
    setState(() => _isProcessing = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

    if (mounted) {
      if (approve) {
        setState(() {
          _report = _report.copyWith(
            status:
                ReportStatus.verifikasi, // Or terverifikasi depending on flow
            verifiedAt: DateTime.now(),
            logs: [
              ReportLog(
                id: 'verify_${DateTime.now().millisecondsSinceEpoch}',
                fromStatus: _report.status,
                toStatus: ReportStatus.verifikasi,
                action: ReportAction.verified,
                actorId: 'pj1',
                actorName: 'PJ Gedung',
                actorRole: 'PJ Gedung',
                timestamp: DateTime.now(),
              ),
              ..._report.logs,
            ],
          );
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve ? 'Laporan berhasil diverifikasi.' : 'Laporan ditolak.',
          ),
          backgroundColor: approve ? Colors.green : Colors.red,
        ),
      );

      if (!approve) context.pop(); // Pop if rejected
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ReportDetailBase(
      report: _report,
      viewerRole: UserRole.pjGedung,
      appBarColor: const Color(0xFF059669), // PJ Gedung Theme Color
      // Inject Action Buttons for PJ Gedung
      actionButtons: _buildActionButtons(),
    );
  }

  List<Widget>? _buildActionButtons() {
    // Only show Verify/Reject for Pending reports that are NOT emergency
    // (Emergency reports bypass verification)
    if (_report.status == ReportStatus.pending && !_report.isEmergency) {
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
