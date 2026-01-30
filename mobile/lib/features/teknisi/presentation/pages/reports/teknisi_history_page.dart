import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/presentation/pages/shared_all_reports_page.dart';

/// History page showing completed reports with filters using SharedAllReportsPage
class TeknisiHistoryPage extends StatelessWidget {
  const TeknisiHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedAllReportsPage(
      appBarTitle: 'Riwayat Laporan',
      appBarColor: AppTheme.teknisiColor,
      appBarIconColor: Colors.white,
      appBarTitleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      initialStatuses: const [ReportStatus.selesai, ReportStatus.approved],
      role: 'technician',
      showBackButton:
          false, // It's a main tab usually, or navigated to? If main tab, false. If pushed, true.
      // Usually History is a main tab in bottom nav for Technician?
      // Checking TeknisiScaffold... probably. But assume false for consistency with "Tab" look if it's a root page.
      // If it's used in a TabBarView (like inside Home), it shouldn't have an AppBar?
      // SharedAllReportsPage has `showAppBar` param.
      // The previous TeknisiHistoryPage had an AppBar.
      // So I will keep showAppBar: true.
      onReportTap: (reportId, status) {
        context.push('/teknisi/report/$reportId');
      },
    );
  }
}
