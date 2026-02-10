import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/supervisor/presentation/widgets/supervisor_report_list_body.dart';

class SupervisorReportsPage extends StatelessWidget {
  final Map<String, String>? queryParams;

  const SupervisorReportsPage({super.key, this.queryParams});

  @override
  Widget build(BuildContext context) {
    final status = queryParams?['status'];
    final period = queryParams?['period'];
    final emergency = queryParams?['emergency'] == 'true'; // Parse boolean

    // Parse status string to List<ReportStatus> if present
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Laporan'),
        backgroundColor: AppTheme.supervisorColor,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SupervisorReportListBody(
        status: status ?? '',
        period: period,
        isEmergency: emergency,
        showSearch: true,
        onReportTap: (reportId, reportStatus) {
          context.push(
            '/supervisor/review/$reportId',
            extra: {'status': reportStatus},
          );
        },
      ),
    );
  }
}
