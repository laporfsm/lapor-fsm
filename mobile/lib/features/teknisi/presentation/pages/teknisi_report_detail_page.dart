import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/report_common/domain/entities/report.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/core/enums/user_role.dart';
import 'package:mobile/core/models/report_log.dart'; // Keep logs in core for now or check if moved
import 'package:mobile/core/data/mock_report_data.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';
import 'package:mobile/theme.dart';

class TeknisiReportDetailPage extends StatefulWidget {
  final String reportId;

  const TeknisiReportDetailPage({super.key, required this.reportId});

  @override
  State<TeknisiReportDetailPage> createState() =>
      _TeknisiReportDetailPageState();
}

class _TeknisiReportDetailPageState extends State<TeknisiReportDetailPage> {
  late Report _report;

  @override
  void initState() {
    super.initState();
    _report = MockReportData.getReportOrDefault(widget.reportId);
  }

  @override
  Widget build(BuildContext context) {
    return ReportDetailBase(
      report: _report,
      viewerRole: UserRole.teknisi,
      actionButtons: _buildActionButtons(),
    );
  }

  List<Widget> _buildActionButtons() {
    // Status: diproses - Teknisi bisa mulai penanganan
    if (_report.status == ReportStatus.diproses) {
      return [
        ElevatedButton.icon(
          onPressed: _startHandling,
          icon: const Icon(LucideIcons.play),
          label: const Text('Mulai Penanganan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    }
    // Status: penanganan - Teknisi bisa pause atau selesaikan
    else if (_report.status == ReportStatus.penanganan) {
      return [
        // Pause Button
        OutlinedButton.icon(
          onPressed: _pauseReport,
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
    } else if (_report.status == ReportStatus.onHold) {
      return [
        ElevatedButton.icon(
          onPressed: _resumeReport,
          icon: const Icon(LucideIcons.playCircle),
          label: const Text('Lanjutkan Pekerjaan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];
    }
    return [];
  }

  void _startHandling() {
    setState(() {
      final now = DateTime.now();
      _report = _report.copyWith(
        status: ReportStatus.penanganan,
        handledBy: ['Budi Santoso'],
        logs: [
          ReportLog(
            id: 'start_handling_${now.millisecondsSinceEpoch}',
            fromStatus: ReportStatus.diproses,
            toStatus: ReportStatus.penanganan,
            action: ReportAction.handling,
            actorId: 'tech1',
            actorName: 'Budi Santoso',
            actorRole: 'Teknisi',
            timestamp: now,
            reason: 'Mulai penanganan laporan',
          ),
          ..._report.logs,
        ],
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Penanganan dimulai'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _pauseReport() {
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
              // TODO: Add Photo Upload Implementation
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
                final now = DateTime.now();
                setState(() {
                  _report = _report.copyWith(
                    status: ReportStatus.onHold,
                    pausedAt: now,
                    holdReason: reason,
                    logs: [
                      ReportLog(
                        id: 'hold_${now.millisecondsSinceEpoch}',
                        fromStatus: _report.status,
                        toStatus: ReportStatus.onHold,
                        action: ReportAction.paused,
                        actorId: 'tech1',
                        actorName: 'Budi Santoso',
                        actorRole: 'Teknisi',
                        timestamp: now,
                        reason: reason.isEmpty ? "Ditunda sementara" : reason,
                      ),
                      ..._report.logs,
                    ],
                  );
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pengerjaan ditunda (Pause)'),
                    backgroundColor: Colors.orange,
                  ),
                );
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

  void _resumeReport() {
    final now = DateTime.now();
    // Calculate pause duration
    int pauseDuration = 0;
    if (_report.pausedAt != null) {
      pauseDuration = now.difference(_report.pausedAt!).inSeconds;
    }

    setState(() {
      _report = _report.copyWith(
        status: ReportStatus.penanganan,
        clearPausedAt: true,
        totalPausedDurationSeconds:
            _report.totalPausedDurationSeconds + pauseDuration,
        logs: [
          ReportLog(
            id: 'resume_${now.millisecondsSinceEpoch}',
            fromStatus: ReportStatus.onHold,
            toStatus: ReportStatus.penanganan,
            action: ReportAction.resumed,
            actorId: 'tech1',
            actorName: 'Budi Santoso',
            actorRole: 'Teknisi',
            timestamp: now,
            reason: 'Pengerjaan dilanjutkan',
          ),
          ..._report.logs,
        ],
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengerjaan dilanjutkan'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
