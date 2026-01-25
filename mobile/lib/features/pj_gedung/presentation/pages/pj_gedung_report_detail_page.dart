import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';

class PJGedungReportDetailPage extends StatefulWidget {
  final Report report;

  const PJGedungReportDetailPage({super.key, required this.report});

  @override
  State<PJGedungReportDetailPage> createState() =>
      _PJGedungReportDetailPageState();
}

class _PJGedungReportDetailPageState extends State<PJGedungReportDetailPage> {
  bool _isProcessing = false;

  void _handleVerification(bool approve) async {
    setState(() => _isProcessing = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Laporan berhasil diverifikasi. Teknisi akan segera ditugaskan.'
                : 'Laporan ditolak.',
          ),
          backgroundColor: approve ? Colors.green : Colors.red,
        ),
      );
      context.pop(true); // Return result to refresh list
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReportDetailBase(
      report: widget.report,
      viewerRole: UserRole.pjGedung,
      // Inject Action Buttons for PJ Gedung
      actionButtons: [
        OutlinedButton(
          onPressed: _isProcessing ? null : () => _handleVerification(false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Colors.red.shade300),
            foregroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Tolak'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : () => _handleVerification(true),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFFF59E0B), // PJ Color
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Verifikasi Laporan'),
        ),
      ],
    );
  }
}
