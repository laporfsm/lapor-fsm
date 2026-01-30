import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/report_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/widgets/report_detail_wrapper.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/domain/enums/user_role.dart';

class TeknisiReportDetailPage extends StatefulWidget {
  final String reportId;

  const TeknisiReportDetailPage({super.key, required this.reportId});

  @override
  State<TeknisiReportDetailPage> createState() =>
      _TeknisiReportDetailPageState();
}

class _TeknisiReportDetailPageState extends State<TeknisiReportDetailPage> {
  bool _isProcessing = false;
  String? _currentStaffId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await authService.getCurrentUser();
    if (mounted) {
      setState(() => _currentStaffId = user?['id']?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReportDetailWrapper(
      reportId: widget.reportId,
      viewerRole: UserRole.teknisi,
      actionButtonsBuilder: (report, refresh) =>
          _buildActionButtons(context, report, refresh),
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    Report report,
    Future<void> Function() refresh,
  ) {
    // SECURITY: Only assigned technician can take actions
    if (_currentStaffId == null || report.assignedTo != _currentStaffId) {
      return []; // Read-only view
    }

    // Status: diproses - Teknisi bisa mulai penanganan
    if (report.status == ReportStatus.diproses) {
      return [
        ElevatedButton.icon(
          onPressed: _isProcessing
              ? null
              : () => _startHandling(context, report, refresh),
          icon: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.play),
          label: Text(_isProcessing ? 'Memproses...' : 'Mulai Penanganan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    }
    // Status: penanganan - Teknisi bisa pause atau selesaikan
    else if (report.status == ReportStatus.penanganan) {
      return [
        // Pause Button
        OutlinedButton.icon(
          onPressed: _isProcessing
              ? null
              : () => _pauseReport(context, report, refresh),
          icon: const Icon(LucideIcons.pauseCircle),
          label: const Text('Pause'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        // Selesaikan Button
        ElevatedButton.icon(
          onPressed: () =>
              context.push('/teknisi/report/${widget.reportId}/complete'),
          icon: const Icon(LucideIcons.checkCircle2),
          label: const Text('Selesaikan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    } else if (report.status == ReportStatus.onHold) {
      return [
        ElevatedButton.icon(
          onPressed: _isProcessing
              ? null
              : () => _resumeReport(context, report, refresh),
          icon: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.playCircle),
          label: Text(_isProcessing ? 'Memproses...' : 'Lanjutkan Pekerjaan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    } else if (report.status == ReportStatus.recalled) {
      // Status: recalled - Supervisor minta revisi, teknisi bisa mulai kembali
      return [
        ElevatedButton.icon(
          onPressed: _isProcessing
              ? null
              : () => _startHandling(context, report, refresh),
          icon: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.rotateCcw),
          label: Text(_isProcessing ? 'Memproses...' : 'Mulai Kembali'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    }
    return [];
  }

  void _startHandling(
    BuildContext context,
    Report report,
    Future<void> Function() refresh,
  ) async {
    setState(() => _isProcessing = true);
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final staffId = int.parse(user['id'].toString());
        await reportService.acceptTask(report.id, staffId);
        await refresh();
        if (!mounted || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penanganan dimulai'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error accepting report: $e');
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai penanganan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _pauseReport(
    BuildContext context,
    Report report,
    Future<void> Function() refresh,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        String reason = '';
        return AlertDialog(
          title: const Text('Tunda Pengerjaan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Masukkan alasan penundaan (misal: menunggu sparepart):',
              ),
              const Gap(12),
              TextField(
                onChanged: (value) => reason = value,
                decoration: const InputDecoration(
                  hintText: 'Alasan penundaan...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                setState(() => _isProcessing = true);
                try {
                  final user = await authService.getCurrentUser();
                  if (user != null) {
                    final staffId = int.parse(user['id'].toString());
                    await reportService.pauseTask(report.id, staffId, reason);
                    await refresh();
                    if (!messenger.mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Pengerjaan ditunda (Pause)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error pausing report: $e');
                } finally {
                  if (mounted) setState(() => _isProcessing = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tunda'),
            ),
          ],
        );
      },
    );
  }

  void _resumeReport(
    BuildContext context,
    Report report,
    Future<void> Function() refresh,
  ) async {
    setState(() => _isProcessing = true);
    try {
      final user = await authService.getCurrentUser();
      if (user != null) {
        final staffId = int.parse(user['id'].toString());
        await reportService.resumeTask(report.id, staffId);
        await refresh();
        if (!mounted || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengerjaan dilanjutkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error resuming report: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
