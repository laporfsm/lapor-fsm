import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/widgets/report_detail_wrapper.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/domain/enums/user_role.dart';

import 'package:mobile/core/widgets/custom_dialog.dart';

class PJGedungReportDetailPage extends StatefulWidget {
  final String reportId;

  const PJGedungReportDetailPage({super.key, required this.reportId});

  @override
  State<PJGedungReportDetailPage> createState() =>
      _PJGedungReportDetailPageState();
}

class _PJGedungReportDetailPageState extends State<PJGedungReportDetailPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return ReportDetailWrapper(
      reportId: widget.reportId,
      viewerRole: UserRole.pjGedung,
      appBarColor: const Color(0xFF059669), // PJ Gedung Theme Color
      actionButtonsBuilder: (report, refresh) =>
          _buildActionButtons(context, report, refresh),
    );
  }

  List<Widget>? _buildActionButtons(
    BuildContext context,
    Report report,
    Future<void> Function() refresh,
  ) {
    // Only show Verify/Reject for Pending reports that are NOT emergency
    if (report.status == ReportStatus.pending && !report.isEmergency) {
      return [
        OutlinedButton.icon(
          onPressed: _isProcessing
              ? null
              : () => _handleRejectWithReason(context, report, refresh),
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
          onPressed: _isProcessing
              ? null
              : () => _handleVerifyWithConfirm(context, report, refresh),
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

  Future<bool> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    Color confirmColor = const Color(0xFFF59E0B),
  }) async {
    return await ConfirmationDialog.show(
          context,
          title: title,
          message: message,
          confirmColor: confirmColor,
        ) ??
        false;
  }

  Future<String?> _showReasonDialog(BuildContext context) async {
    return await ReasonDialog.show(
      context,
      title: 'Tolak Laporan',
      message: 'Apakah Anda yakin ingin menolak laporan ini?',
      hintText: 'Alasan penolakan...',
      confirmLabel: 'Tolak',
      confirmColor: Colors.red,
    );
  }

  Future<void> _handleVerifyWithConfirm(
    BuildContext context,
    Report report,
    Future<void> Function() refresh,
  ) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Verifikasi Laporan',
      message: 'Apakah Anda yakin ingin memverifikasi laporan ini?',
      confirmColor: const Color(0xFFF59E0B),
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    await _handleVerification(context, report, refresh, true);
  }

  Future<void> _handleRejectWithReason(
    BuildContext context,
    Report report,
    Future<void> Function() refresh,
  ) async {
    final reason = await _showReasonDialog(context);
    if (reason == null) return;
    if (!context.mounted) return;
    await _handleVerification(context, report, refresh, false, reason: reason);
  }

  Future<void> _handleVerification(
    BuildContext context,
    Report report,
    Future<void> Function() refresh,
    bool approve, {
    String? reason,
  }
  ) async {
    setState(() => _isProcessing = true);

    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        // Convert staffId to int (user['id'] is stored as String in SharedPreferences)
        final staffId = int.parse(user['id'].toString());

        if (approve) {
          await reportService.verifyReport(report.id, staffId);
        } else {
          await reportService.rejectReportPJGedung(
            report.id,
            staffId,
            reason ?? 'Ditolak oleh PJ Gedung',
          );
        }

        await refresh();
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve ? 'Laporan berhasil diverifikasi.' : 'Laporan ditolak.',
            ),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
        if (!approve && context.mounted) context.pop();
      }
    } catch (e) {
      debugPrint('Error processing verification: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal ${approve ? 'memverifikasi' : 'menolak'} laporan: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
