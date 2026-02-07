import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/providers/auth_provider.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/domain/enums/user_role.dart';
import 'package:mobile/features/report_common/presentation/providers/report_detail_provider.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';

class TeknisiReportDetailPage extends ConsumerWidget {
  final String reportId;

  const TeknisiReportDetailPage({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(reportDetailProvider(reportId));
    final currentUser = ref.watch(currentUserProvider).value;
    final currentStaffId = currentUser?['id']?.toString();

    if (detailState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (detailState.error != null || detailState.report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Laporan')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(detailState.error ?? 'Laporan tidak ditemukan'),
              const Gap(16),
              ElevatedButton(
                onPressed: () => ref
                    .read(reportDetailProvider(reportId).notifier)
                    .fetchReport(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final report = detailState.report!;

    return ReportDetailBase(
      report: report,
      viewerRole: UserRole.teknisi,
      actionButtons: _buildActionButtons(
        context,
        ref,
        report,
        currentStaffId,
        detailState.isProcessing,
      ),
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Report report,
    String? currentStaffId,
    bool isProcessing,
  ) {
    if (currentStaffId == null || report.assignedTo != currentStaffId) {
      return [];
    }

    final notifier = ref.read(reportDetailProvider(reportId).notifier);

    if (report.status == ReportStatus.diproses) {
      return [
        ElevatedButton.icon(
          onPressed: isProcessing
              ? null
              : () => _handleStart(context, notifier),
          icon: isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.play),
          label: Text(isProcessing ? 'Memproses...' : 'Mulai Penanganan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    } else if (report.status == ReportStatus.penanganan) {
      return [
        OutlinedButton.icon(
          onPressed: isProcessing
              ? null
              : () => _handlePause(context, notifier, currentStaffId),
          icon: const Icon(LucideIcons.pauseCircle),
          label: const Text('Pause'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => context.push('/teknisi/report/$reportId/complete'),
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
          onPressed: isProcessing
              ? null
              : () => _handleResume(context, notifier),
          icon: isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.playCircle),
          label: Text(isProcessing ? 'Memproses...' : 'Lanjutkan Pekerjaan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    } else if (report.status == ReportStatus.recalled) {
      return [
        ElevatedButton.icon(
          onPressed: isProcessing
              ? null
              : () => _handleStart(context, notifier),
          icon: isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.rotateCcw),
          label: Text(isProcessing ? 'Memproses...' : 'Mulai Kembali'),
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

  Future<void> _handleStart(
    BuildContext context,
    ReportDetailNotifier notifier,
  ) async {
    try {
      final staffId = await _getStaffId(notifier);
      if (staffId != null) {
        await notifier.acceptTask(staffId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penanganan dimulai'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memulai penanganan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePause(
    BuildContext context,
    ReportDetailNotifier notifier,
    String staffIdStr,
  ) async {
    final staffId = int.tryParse(staffIdStr);
    if (staffId == null) return;

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
                try {
                  await notifier.pauseTask(staffId, reason);
                  if (!messenger.mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Pengerjaan ditunda (Pause)'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e) {
                  debugPrint('Error pausing task: $e');
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

  Future<void> _handleResume(
    BuildContext context,
    ReportDetailNotifier notifier,
  ) async {
    try {
      final staffId = await _getStaffId(notifier);
      if (staffId != null) {
        await notifier.resumeTask(staffId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengerjaan dilanjutkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error resuming task: $e');
    }
  }

  Future<int?> _getStaffId(ReportDetailNotifier notifier) async {
    final user = await authService.getCurrentUser();
    return user != null ? int.tryParse(user['id'].toString()) : null;
  }
}
