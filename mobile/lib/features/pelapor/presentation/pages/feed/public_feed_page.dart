import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/report_common/domain/enums/report_status.dart';
import 'package:mobile/features/report_common/presentation/pages/shared_all_reports_page.dart';
import 'package:mobile/theme.dart';

/// Public Feed Page for Pelapor
/// Uses SharedAllReportsPage for consistent UI
class PublicFeedPage extends StatelessWidget {
  const PublicFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedAllReportsPage(
      appBarTitle: 'Public Feed',
      appBarColor: Colors.white,
      appBarIconColor: Colors.black,
      appBarTitleStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      showBackButton: false, // Main tab, no back button
      enableDateFilter: false, // Hide calendar as requested
      onReportTap: (reportId, status) {
        context.push('/report-detail/$reportId');
      },
    );
  }
}
