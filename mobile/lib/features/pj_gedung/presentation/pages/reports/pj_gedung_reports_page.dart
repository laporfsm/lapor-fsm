import 'package:flutter/material.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/pj_gedung/presentation/widgets/pj_gedung_report_list_body.dart';
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
    final emergencyParam = queryParams['emergency'] == 'true';

    // Convert status string to ReportStatus list logic is no longer needed in the widget
    // as we pass the string directly to the provider via the widget.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Laporan'),
        backgroundColor: AppTheme.pjGedungColor, // Use proper theme color
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: PjGedungReportListBody(
        status: statusParam ?? '',
        period: periodParam,
        isEmergency: emergencyParam,
        showSearch: true,
        onReportTap: (reportId, status) {
          context.push('/pj-gedung/report/$reportId');
        },
      ),
    );
  }
}
