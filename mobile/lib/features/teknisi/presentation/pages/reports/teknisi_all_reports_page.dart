import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/presentation/pages/shared_all_reports_page.dart';
import 'package:mobile/core/theme.dart';

/// All reports page for Teknisi - using standardized SharedAllReportsPage
class TeknisiAllReportsPage extends StatelessWidget {
  final String? initialStatus;
  final String? initialPeriod;
  final bool initialEmergency;
  final int? assignedTo; // Added parameter

  const TeknisiAllReportsPage({
    super.key,
    this.initialStatus,
    this.initialPeriod,
    this.initialEmergency = false,
    this.assignedTo,
  });

  @override
  Widget build(BuildContext context) {
    // Convert status string to ReportStatus list
    List<ReportStatus>? initialStatuses;
    if (initialStatus != null && initialStatus!.isNotEmpty) {
      final statusList = initialStatus!.split(',');
      initialStatuses = statusList
          .map(
            (s) => ReportStatus.values.firstWhere(
              (e) => e.name.toLowerCase() == s.toLowerCase(),
              orElse: () => ReportStatus.diproses,
            ),
          )
          .toList();
    }

    return SharedAllReportsPage(
      appBarTitle: 'Semua Laporan',
      appBarColor: AppTheme.secondaryColor, // Blue for Teknisi
      appBarIconColor: Colors.white,
      appBarTitleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      initialStatuses: initialStatuses,
      initialPeriod: initialPeriod,
      initialEmergency: initialEmergency,
      assignedTo: assignedTo, // Pass assignedTo
      onReportTap: (reportId, status) {
        context.push('/teknisi/report/$reportId');
      },
      showBackButton: true,
      role: 'technician',
    );
  }
}
