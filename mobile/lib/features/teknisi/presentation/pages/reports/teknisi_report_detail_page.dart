import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/services/auth_service.dart';
import 'package:mobile/core/services/location_service.dart';
import 'package:mobile/core/services/sse_service.dart';
import 'package:mobile/core/services/websocket_service.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/core/providers/auth_provider.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/domain/enums/user_role.dart';
import 'package:mobile/features/report_common/presentation/providers/report_detail_provider.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';

class TeknisiReportDetailPage extends ConsumerStatefulWidget {
  final String reportId;

  const TeknisiReportDetailPage({super.key, required this.reportId});

  @override
  ConsumerState<TeknisiReportDetailPage> createState() =>
      _TeknisiReportDetailPageState();
}

class _TeknisiReportDetailPageState
    extends ConsumerState<TeknisiReportDetailPage> {
  Timer? _trackingTimer;
  StreamSubscription? _logSubscription;
  bool _isTravalLoading = false;

  @override
  void initState() {
    super.initState();
    _connectSSE();
  }

  @override
  void dispose() {
    _disconnectSSE();
    _stopTracking();
    super.dispose();
  }

  void _connectSSE() {
    sseService.connect(widget.reportId);
    _logSubscription = sseService.logsStream.listen((logs) {
      // When new logs arrive, refresh the report detail to get latest state
      if (mounted) {
        ref.read(reportDetailProvider(widget.reportId).notifier).fetchReport();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Riwayat laporan diperbarui'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _disconnectSSE() {
    _logSubscription?.cancel();
    sseService.disconnect();
  }

  void _manageTracking(Report? report, String? currentStaffId) {
    if (report == null) return;

    // Only track if I am the assigned technician and status is penanganan
    final isAssignedToMe = report.assignedTo == currentStaffId;
    final isHandling = report.status == ReportStatus.penanganan;

    if (isAssignedToMe && isHandling) {
      _startTracking(report.id, currentStaffId!);
    } else {
      _stopTracking();
    }
  }

  void _startTracking(String reportId, String staffId) {
    if (_trackingTimer != null && _trackingTimer!.isActive) return;

    webSocketService.connect(reportId);

    // Send location immediately then every 10 seconds
    _sendLocationUpdate(reportId, staffId);
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _sendLocationUpdate(reportId, staffId);
    });

    debugPrint('[TRACKING] Started tracking for report $reportId');
  }

  Future<void> _sendLocationUpdate(String reportId, String staffId) async {
    final position = await locationService.getCurrentPosition();
    if (position != null) {
      webSocketService.sendLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        role: 'teknisi',
        senderName: 'Technician', // Ideally get name from user provider
      );
    }
  }

  void _stopTracking() {
    if (_trackingTimer != null) {
      _trackingTimer!.cancel();
      _trackingTimer = null;
      webSocketService.disconnect();
      debugPrint('[TRACKING] Stopped tracking');
    }
  }

  Future<void> _handleAcceptTask() async {
    setState(() => _isTravalLoading = true);
    try {
      final user = await authService.getCurrentUser();
      final staffId = user?['id'];

      if (staffId == null) throw Exception('Staff ID not found');

      final response = await apiService.dio.post(
        '/technician/reports/${widget.reportId}/accept',
        data: {'staffId': int.parse(staffId.toString())},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Penanganan dimulai.'),
              backgroundColor: Colors.green,
            ),
          );
          ref
              .read(reportDetailProvider(widget.reportId).notifier)
              .fetchReport();
        }
      } else {
        throw Exception('Gagal memulai penanganan');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isTravalLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(reportDetailProvider(widget.reportId));
    final currentUser = ref.watch(currentUserProvider).value;
    final currentStaffId = currentUser?['id']?.toString();

    // Listen to state changes to manage tracking
    ref.listen(reportDetailProvider(widget.reportId), (previous, next) {
      if (next.report != null) {
        _manageTracking(next.report, currentStaffId);
      }
    });

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
                    .read(reportDetailProvider(widget.reportId).notifier)
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
      onReportChanged: () => ref
          .read(reportDetailProvider(widget.reportId).notifier)
          .fetchReport(),
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
      // If diproses (pool) and not assigned, or assigned to others
      // logic for accepting from pool usually handled by report status + pool logic
      // But assuming 'diproses' means allocated to this technician specifically or pool
      // If it's in the pool (assignedTo is null), technician can take it.
      // But helper sends 'assignedTo'.
      // If report.assignedTo is null, anyone can take? Not handled here explicitly.
      // Assuming 'assignedTo' matches.

      // Exception: If status is 'diproses' and 'assignedTo' is null (Pool).
    }

    final notifier = ref.read(reportDetailProvider(widget.reportId).notifier);

    // 1. TERIMA & MULAI PENANGANAN (Status: Diproses)
    if (report.status == ReportStatus.diproses) {
      return [
        ElevatedButton.icon(
          onPressed: _isTravalLoading || isProcessing
              ? null
              : _handleAcceptTask,
          icon: _isTravalLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.playCircle),
          label: Text(
            _isTravalLoading ? 'Memproses...' : 'Terima & Mulai Penanganan',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    }
    // 3. PAUSE / SELESAI (Status: Penanganan)
    else if (report.status == ReportStatus.penanganan) {
      return [
        OutlinedButton.icon(
          onPressed: isProcessing
              ? null
              : () => _handlePause(context, notifier, currentStaffId!),
          icon: const Icon(LucideIcons.pauseCircle),
          label: const Text('Pause'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
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
    }
    // 4. RESUME (Status: OnHold)
    else if (report.status == ReportStatus.onHold) {
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
    }
    // 5. RECALLED
    else if (report.status == ReportStatus.recalled) {
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
