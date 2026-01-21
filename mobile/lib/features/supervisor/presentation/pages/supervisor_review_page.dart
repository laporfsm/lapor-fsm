import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/report.dart';
import 'package:mobile/core/data/mock_report_data.dart';
import 'package:mobile/core/widgets/report_detail_base.dart';
import 'package:mobile/theme.dart';

class SupervisorReviewPage extends StatefulWidget {
  final String reportId;
  const SupervisorReviewPage({super.key, required this.reportId});

  @override
  State<SupervisorReviewPage> createState() => _SupervisorReviewPageState();
}

class _SupervisorReviewPageState extends State<SupervisorReviewPage> {
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
      viewerRole: UserRole.supervisor,
      actionButtons: _buildActionButtons(),
    );
  }

  List<Widget> _buildActionButtons() {
    // Only show actions if status is Selesai (needs approval) or Ditolak (review rejection)
    if (_report.status == ReportStatus.selesai ||
        _report.status == ReportStatus.ditolak) {
      return [
        OutlinedButton(
          onPressed: () {
            setState(() {
              _report = _report.copyWith(
                status: ReportStatus.recalled,
                logs: [
                  ReportLog(
                    id: 'new_recall',
                    fromStatus: _report.status,
                    toStatus: ReportStatus.recalled,
                    action: ReportAction.recalled,
                    actorId: 'spv1',
                    actorName: 'Supervisor',
                    actorRole: 'Supervisor',
                    timestamp: DateTime.now(),
                    reason: 'Perbaikan belum tuntas',
                  ),
                  ..._report.logs,
                ],
              );
            });
            context.pop();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Tolak / Recall'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _report = _report.copyWith(
                status: ReportStatus.approved,
                supervisorName: 'Supervisor',
                logs: [
                  ReportLog(
                    id: 'new_approve',
                    fromStatus: _report.status,
                    toStatus: ReportStatus.approved,
                    action: ReportAction.approved,
                    actorId: 'spv1',
                    actorName: 'Supervisor',
                    actorRole: 'Supervisor',
                    timestamp: DateTime.now(),
                  ),
                  ..._report.logs,
                ],
              );
            });
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Laporan disetujui'),
                backgroundColor: Colors.green,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.supervisorColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Setujui'),
        ),
      ];
    }
    return [];
  }
}
