import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/presentation/pages/shared_all_reports_page.dart';
import 'package:mobile/core/theme.dart';

class SupervisorReportsPage extends StatelessWidget {
  final Map<String, String>? queryParams;

  const SupervisorReportsPage({super.key, this.queryParams});

  @override
  Widget build(BuildContext context) {
    final status = queryParams?['status'];
    final period = queryParams?['period'];
    final emergency = queryParams?['emergency'] == 'true'; // Parse boolean

    // Parse status string to List<ReportStatus> if present
    List<ReportStatus>? initialStatuses;
    if (status != null) {
      try {
        final matchingStatus = ReportStatus.values.firstWhere(
          (s) => s.name.toLowerCase() == status.toLowerCase(),
        );
        initialStatuses = [matchingStatus];
      } catch (_) {
        // Ignore invalid status
      }
    }

    return SharedAllReportsPage(
      initialStatuses: initialStatuses,
      initialPeriod: period,
      initialEmergency: emergency,
      onReportTap: (reportId, reportStatus) {
        context.push(
          '/supervisor/review/$reportId',
          extra: {'status': reportStatus},
        );
      },
      appBarTitle: 'Semua Laporan',
      appBarColor: AppTheme.supervisorColor,
      appBarIconColor: Colors.white,
      appBarTitleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      showBackButton: true,
      showAppBar: true,
    );
  }
}
