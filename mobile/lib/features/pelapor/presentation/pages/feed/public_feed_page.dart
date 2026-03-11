import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/report_common/presentation/pages/shared_all_reports_page.dart';

/// Public Feed Page for Pelapor
/// Uses SharedAllReportsPage for consistent UI
class PublicFeedPage extends StatelessWidget {
  const PublicFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SharedAllReportsPage(
      appBarTitle: 'Public Feed',
      appBarColor: AppTheme.primaryColor,
      appBarIconColor: Colors.white,
      appBarTitleStyle: const TextStyle(
        color: Colors.white,
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
