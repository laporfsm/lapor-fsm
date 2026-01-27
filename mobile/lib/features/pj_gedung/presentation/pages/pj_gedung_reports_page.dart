import 'package:flutter/material.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/presentation/pages/shared_all_reports_page.dart';
import 'package:mobile/features/pj_gedung/presentation/pages/pj_gedung_dashboard_page.dart';
import 'package:go_router/go_router.dart';

/// PJ Gedung Reports Page - wrapper for SharedAllReportsPage
class PJGedungReportsPage extends StatelessWidget {
  final Map<String, String> queryParams;

  const PJGedungReportsPage({super.key, this.queryParams = const {}});

  @override
  Widget build(BuildContext context) {
    // Parse query params
    final statusParam = queryParams['status'];
    final periodParam = queryParams['period'];

    // Convert status string to ReportStatus list
    List<ReportStatus>? initialStatuses;
    if (statusParam != null && statusParam.isNotEmpty) {
      final statusList = statusParam.split(',');
      initialStatuses = statusList
          .map(
            (s) => ReportStatus.values.firstWhere(
              (e) => e.name.toLowerCase() == s.toLowerCase(),
              orElse: () => ReportStatus.pending,
            ),
          )
          .toList();
    }

    return SharedAllReportsPage(
      appBarTitle: 'Laporan',
      appBarColor: pjGedungColor,
      initialStatuses: initialStatuses,
      initialPeriod: periodParam,
      onReportTap: (reportId, status) {
        context.push('/pj-gedung/report/$reportId');
      },
      showBackButton: true,
    );
  }
}
