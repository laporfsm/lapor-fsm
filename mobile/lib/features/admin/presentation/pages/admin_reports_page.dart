import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/report_common/presentation/pages/shared_all_reports_page.dart';
import 'package:mobile/theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/features/admin/services/export_service.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedAllReportsPage(
      appBarTitle: 'Semua Laporan',
      appBarColor: AppTheme.adminColor,
      appBarIconColor: Colors.white,
      appBarTitleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      showBackButton: false, // Main tab
      onReportTap: (reportId, status) {
        context.push('/admin/reports/$reportId');
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            ExportService.exportData(context, 'Laporan', 'laporan'),
        backgroundColor: AppTheme.adminColor,
        tooltip: 'Export Laporan',
        child: const Icon(LucideIcons.download, color: Colors.white),
      ),
    );
  }
}
